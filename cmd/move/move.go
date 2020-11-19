package main

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"github.com/jenkins-x/jx-helpers/pkg/stringhelpers"
	"github.com/jenkins-x/jx-helpers/pkg/yamls"
	"github.com/jenkins-x/jx-helpers/v3/pkg/cobras/helper"
	"github.com/jenkins-x/jx-helpers/v3/pkg/files"
	"github.com/jenkins-x/jx-helpers/v3/pkg/kyamls"
	"github.com/jenkins-x/jx-logging/v3/pkg/log"
	"github.com/mattn/go-zglob"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
	"sigs.k8s.io/kustomize/kyaml/yaml"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	pathSeparator = string(os.PathSeparator)
)

type Options struct {
	InputDir        string
	OutputDir       string
	ClusterDir      string
	NamespacesDir   string
	SingleNamespace string
	IgnoreKind      []string
}

func main() {
	o := &Options{}

	cmd := &cobra.Command{
		Use:   "move",
		Short: "Moves manifests into gitops structure",
		Run: func(cmd *cobra.Command, args []string) {
			err := o.Run()
			helper.CheckErr(err)
		},
	}
	cmd.Flags().StringVarP(&o.InputDir, "input-dir", "i", "", "the directory containing the generated resources")
	cmd.Flags().StringVarP(&o.OutputDir, "output-dir", "o", "", "the output directory")
	cmd.Flags().StringArrayVarP(&o.IgnoreKind, "ignore-kind", "", nil, "blacklist for resource kinds")

	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
	os.Exit(0)
}

func (o *Options) Run() error {
	if o.InputDir == "" {
		return errors.Errorf("--input-dir is not set")
	}
	if o.OutputDir == "" {
		return errors.Errorf("--output-dir is not set")
	}
	if o.ClusterDir == "" {
		o.ClusterDir = filepath.Join(o.OutputDir, "cluster")
	}
	if o.NamespacesDir == "" {
		o.NamespacesDir = filepath.Join(o.OutputDir, "namespaces")
	}

	g := filepath.Join(o.InputDir, "**/*")
	fileNames, err := zglob.Glob(g)
	if err != nil {
		return errors.Wrapf(err, "failed to glob files %s", g)
	}

	var namespaces []string
	for _, file := range fileNames {
		log.Logger().Debugf("processing input file %s", file)

		exists, err := files.FileExists(file)
		if err != nil {
			return errors.Wrapf(err, "failed to check if file exists %s", file)
		}
		if !exists {
			continue
		}

		err, namespace := o.moveFileToClusterOrNamespacesFolder(file)
		if err != nil {
			return errors.Wrapf(err, "failed to move file %s", file)
		}
		if namespace != "" {
			if stringhelpers.StringArrayIndex(namespaces, namespace) < 0 {
				namespaces = append(namespaces, namespace)
			}
		}
	}

	// now lets lazy create any namespace resources which don't exist in the cluster dir
	for _, namespace := range namespaces {
		err = o.lazyCreateNamespaceResource(namespace)
		if err != nil {
			return errors.Wrapf(err, "failed to lazily create namespace resource %s", namespace)
		}
	}

	return nil
}

func (o *Options) lazyCreateNamespaceResource(ns string) error {

	dir := filepath.Join(o.ClusterDir, "namespaces")
	err := os.MkdirAll(dir, files.DefaultDirWritePermissions)
	if err != nil {
		return errors.Wrapf(err, "failed to create dir %s", dir)
	}

	file := filepath.Join(dir, ns+"-ns.yaml")

	exists, err := files.FileExists(file)
	if err != nil {
		return errors.Wrapf(err, "failed to check if file exists %s", file)
	}
	if exists {
		return nil
	}

	namespace := &corev1.Namespace{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "v1",
			Kind:       "Namespace",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name: ns,
		},
	}
	err = yamls.SaveFile(namespace, file)
	if err != nil {
		return errors.Wrapf(err, "failed to save file %s", file)
	}

	return nil
}

func (o *Options) moveFileToClusterOrNamespacesFolder(file string) (error, string) {
	if !strings.HasSuffix(file, ".yaml") && !strings.HasSuffix(file, ".yml") {
		return nil, ""
	}

	data, err := ioutil.ReadFile(file)
	if err != nil {
		return errors.Wrapf(err, "failed to read file %s", file), ""
	}
	if isWhitespaceOrComments(string(data)) {
		log.Logger().Infof("ignoring empty yaml file %s", file)
		return nil, ""
	}

	node, err := yaml.ReadFile(file)
	if err != nil {
		return errors.Wrapf(err, "failed to load YAML file %s", file), ""
	}

	kind := kyamls.GetKind(node, file)
	for _, ignoreKind := range o.IgnoreKind {
		if kind == ignoreKind {
			return nil, ""
		}
	}
	namespace := kyamls.GetNamespace(node, file)
	outDir := filepath.Join(o.ClusterDir, strings.ToLower(kind)+"s")
	if strings.HasSuffix(strings.ToLower(kind), "s") {
		outDir = filepath.Join(o.ClusterDir, strings.ToLower(kind)+"es")
	}
	if strings.HasSuffix(strings.ToLower(kind), "cy") {
		outDir = filepath.Join(o.ClusterDir, strings.TrimRight(strings.ToLower(kind), "y")+"ies")
	}
	if !kyamls.IsClusterKind(kind) && namespace != "" {
		outDir = filepath.Join(o.NamespacesDir, namespace)
	}

	_, fileName := filepath.Split(file)
	outFile := filepath.Join(outDir, fileName)
	parentDir := filepath.Dir(outFile)
	err = os.MkdirAll(parentDir, files.DefaultDirWritePermissions)
	if err != nil {
		return errors.Wrapf(err, "failed to create dir %s", parentDir), ""
	}

	err = os.Rename(file, outFile)
	if err != nil {
		return errors.Wrapf(err, "failed to save %s", outFile), ""
	}

	return nil, namespace
}

func isWhitespaceOrComments(text string) bool {
	lines := strings.Split(text, "\n")
	for _, line := range lines {
		t := strings.TrimSpace(line)
		if t != "" && !strings.HasPrefix(t, "#") && !strings.HasPrefix(t, "--") {
			return false
		}
	}
	return true
}
