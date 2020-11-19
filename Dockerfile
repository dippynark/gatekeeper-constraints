FROM golang:1.15.4 as builder

WORKDIR /workspace

COPY go.mod go.mod
COPY go.sum go.sum

RUN go mod download

COPY cmd/ cmd/

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a cmd/move/move.go

# https://github.com/plexsystems/konstraint
RUN GO111MODULE=on go get github.com/plexsystems/konstraint

FROM debian:10.6

COPY --from=builder /workspace/move /usr/local/bin
COPY --from=builder /go/bin/konstraint /usr/local/bin

RUN apt-get update && apt-get install -y \
  curl \
  make \
  git \
  docker.io

# jx
ARG JX_VERSION
RUN curl -L "https://github.com/jenkins-x/jx-cli/releases/download/v${JX_VERSION}/jx-cli-linux-amd64.tar.gz" | tar xzv && \
  mv jx /usr/local/bin && \
  jx upgrade plugins

# helm
ARG HELM_VERSION
ENV DESIRED_VERSION="v${HELM_VERSION}"
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# opa
RUN curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64 && \
  chmod 755 ./opa && \
  mv opa /usr/local/bin

# kpt
ARG KPT_VERSION
RUN curl -LO "https://github.com/GoogleContainerTools/kpt/releases/download/v${KPT_VERSION}/kpt_linux_amd64-${KPT_VERSION}.tar.gz" && \
  tar xzf "kpt_linux_amd64-${KPT_VERSION}.tar.gz" && \
  chmod +x kpt && \
  mv kpt /usr/local/bin

# kubectl
ARG KUBECTL_VERSION
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable-${KUBECTL_VERSION}.txt)/bin/linux/amd64/kubectl && \
  chmod +x ./kubectl && \
  mv kubectl /usr/local/bin

WORKDIR /workspace
