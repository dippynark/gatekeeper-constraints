FROM golang:1.15.4 as builder

WORKDIR /workspace

COPY go.mod go.mod
COPY go.sum go.sum

RUN go mod download

COPY cmd/ cmd/

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a cmd/move/move.go

FROM ubuntu:18.04

COPY --from=builder /workspace/move /usr/local/bin

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/move"]
