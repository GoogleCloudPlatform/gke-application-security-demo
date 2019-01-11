# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Make will use bash instead of sh
SHELL := /usr/bin/env bash

# All is the first target in the file so it will get picked up when you just run 'make' on its own
lint: check_shell check_python check_golang check_terraform check_docker check_base_files check_headers check_trailing_whitespace

# The .PHONY directive tells make that this isn't a real target and so
# the presence of a file named 'check_shell' won't cause this target to stop
# working
.PHONY: check_shell
check_shell:
	@source test/make.sh && check_shell

.PHONY: check_python
check_python:
	@source test/make.sh && check_python

.PHONY: check_golang
check_golang:
	@source test/make.sh && golang

.PHONY: check_terraform
check_terraform:
	@source test/make.sh && check_terraform

.PHONY: check_docker
check_docker:
	@source test/make.sh && docker

.PHONY: check_base_files
check_base_files:
	@source test/make.sh && basefiles

.PHONY: check_shebangs
check_shebangs:
	@source test/make.sh && check_bash

.PHONY: check_trailing_whitespace
check_trailing_whitespace:
	@source test/make.sh && check_trailing_whitespace

.PHONY: check_headers
check_headers:
	@echo "Checking file headers"
	@python3.7 test/verify_boilerplate.py

.PHONY: build_app
build_app:
				docker run --rm --mount type=bind,source="$$(pwd)"/containers,target=/gosrc -w /gosrc golang:1.10.3 go build -v -o app

.PHONY: build_root_image
build_root_image:
				cd containers && docker build -t hello-run-as-root:1.0.0 -f root_Dockerfile .

.PHONY: build_user_image
build_user_image:
				cd containers && docker build -t hello-run-as-user:1.0.0 -f user_Dockerfile .

.PHONY: push_root_image
push_root_image:
				docker tag hello-run-as-root:1.0.0 gcr.io/"$$(gcloud config get-value project)"/hello-run-as-root:1.0.0
				docker push gcr.io/"$$(gcloud config get-value project)"/hello-run-as-root:1.0.0

.PHONY: push_user_image
push_user_image:
				docker tag hello-run-as-user:1.0.0 gcr.io/"$$(gcloud config get-value project)"/hello-run-as-user:1.0.0
				docker push gcr.io/"$$(gcloud config get-value project)"/hello-run-as-user:1.0.0


.PHONY: setup-project
setup-project:
				# Enables the Google Cloud APIs needed
				./enable-apis.sh
				# Runs generate-tfvars.sh
				./generate-tfvars.sh

.PHONY: tf-apply
tf-apply:
				# Downloads the terraform providers and applies the configuration
				cd terraform && terraform init && terraform apply -auto-approve

.PHONY: tf-destroy
tf-destroy:
				# Wait for the related backend services to be deleted and then
				# delete all the resources created by terraform
				./waitfor_svc_deleted.sh && cd terraform && terraform destroy -auto-approve
