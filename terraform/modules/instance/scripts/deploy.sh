#!/usr/bin/env bash

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


# Stop immediately if something goes wrong
set -euo pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# importing utils.sh which contains utility functions used in multiple files
# shellcheck source=terraform/modules/instance/scripts/utils.sh
source "$ROOT"/utils.sh

# first we create a kubernetes namespace called 'apparmor'
kubectl apply -f "$ROOT"/../manifests/apparmor-namespace.yaml
# next we create a configmap containing two apparmor profiles as text
kubectl apply -f "$ROOT"/../manifests/apparmor-configmap.yaml
# next we use a daemonset to launch the apparmor-loader container on each
# host, which uses the apparmor config maps to know what to load
kubectl apply -f "$ROOT"/../manifests/apparmor-loader-ds.yaml
# next we run an image as user 'app' with the 'armored-hello-user' apparmor profile
kubectl apply -f "$ROOT"/../manifests/armored-run-as-user.yaml
# next we run an image as user 'app' with the 'armored-hello-denied' apparmor profile
kubectl apply -f "$ROOT"/../manifests/armored-run-as-user-denied.yaml
# next we show off how to use a securityContext block to override the images
# configured user
kubectl apply -f "$ROOT"/../manifests/override-root-with-user.yaml
# next we run an image as root with no apparmor profile
kubectl apply -f "$ROOT"/../manifests/run-as-root.yaml
# and last we run an image as 'app' with no apparmor profile
kubectl apply -f "$ROOT"/../manifests/run-as-user.yaml

# Wait for the services to be allocated IPs before declaring the deployment
# complete.
wait_for_svc hello-root
wait_for_svc hello-user
wait_for_svc hello-override
wait_for_svc armored-hello-user
wait_for_svc armored-hello-denied
