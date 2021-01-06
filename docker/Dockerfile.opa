FROM ubuntu:18.04

RUN apt-get update && apt-get install -y curl

ARG OPA_VERSION
RUN curl -L -o opa "https://openpolicyagent.org/downloads/v${OPA_VERSION}/opa_linux_amd64" && \
  chmod 755 ./opa && \
  mv opa /usr/local/bin

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/opa"]
