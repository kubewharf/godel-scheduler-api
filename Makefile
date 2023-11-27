# Copyright 2023 The Godel Scheduler Authors.
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

GOPROXY := $(shell go env GOPROXY)
ifeq ($(GOPROXY),)
GOPROXY := https://proxy.golang.org
endif
export GOPROXY

# Directories
TOOLS_DIR := hack/tools
BIN_DIR := bin
TOOLS_BIN_DIR := $(TOOLS_DIR)/$(BIN_DIR)

# Binaries
CONTROLLER_GEN := $(abspath $(TOOLS_BIN_DIR)/controller-gen)

all: generate

## --------------------------------------
## Binaries
## --------------------------------------

$(CONTROLLER_GEN): $(TOOLS_DIR)/go.mod ## Build controller-gen from tools folder.
	cd $(TOOLS_DIR); \
		go build -tags=tools -o $(BIN_DIR)/controller-gen \
		sigs.k8s.io/controller-tools/cmd/controller-gen

## --------------------------------------
## Generate / Manifests
## --------------------------------------

.PHONY: generate
generate: $(CONTROLLER_GEN) 
	$(MAKE) generate-manifests
	$(MAKE) generate-go

.PHONY: generate-go ## Generate go client codes
generate-go: hack/update-codegen.sh 
	./hack/update-codegen.sh

.PHONY: generate-manifests ## Generate CRD manifests
generate-manifests: $(CONTROLLER_GEN)
	$(CONTROLLER_GEN) \
		paths=./pkg/apis/... \
		crd:crdVersions=v1,allowDangerousTypes=true \
		output:crd:dir=./config/crd/bases 

## --------------------------------------
## Cleanup / Verification
## --------------------------------------

.PHONY: clean
clean: ## Remove all generated files
	$(MAKE) clean-bin

.PHONY: clean-bin
clean-bin: ## Remove all generated binaries
	rm -rf bin
	rm -rf hack/tools/bin
