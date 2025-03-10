# Copyright 2019 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.12.7

# default the go proxy
ARG goproxy=https://proxy.golang.org

# run this with docker build --build_arg $(go env GOPROXY) to override the goproxy
ENV GOPROXY=$goproxy

WORKDIR /tmp
# install a couple of dependencies
RUN curl -L https://dl.k8s.io/v1.14.4/kubernetes-client-linux-amd64.tar.gz | tar xvz
RUN mv /tmp/kubernetes/client/bin/kubectl /usr/local/bin
RUN curl https://get.docker.com | sh

WORKDIR /workspace
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY cmd/ cmd/
COPY api/ api/
COPY controllers/ controllers/
COPY kind/ kind/
COPY third_party/ third_party/
COPY cloudinit/ cloudinit/

# Allow containerd to restart pods by calling /restart.sh (mostly for tilt + fast dev cycles)
# TODO: Remove this on prod and use a multi-stage build
COPY third_party/forked/rerun-process-wrapper/start.sh .
COPY third_party/forked/rerun-process-wrapper/restart.sh .

RUN go install -v ./cmd/manager
RUN mv /go/bin/manager /manager

ENTRYPOINT ["./start.sh", "/manager"]
