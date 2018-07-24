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

# shellcheck source=terraform/modules/instance/scripts/utils.sh

source "$ROOT"/utils.sh

# Clean up the apparmor namespace
kubectl delete -f "$ROOT"/../manifests/apparmor-loader-ds.yaml
kubectl delete -f "$ROOT"/../manifests/apparmor-configmap.yaml
kubectl delete -f "$ROOT"/../manifests/apparmor-namespace.yaml

# Clean up the default namespace
kubectl delete -f "$ROOT"/../manifests/armored-run-as-user.yaml
kubectl delete -f "$ROOT"/../manifests/armored-run-as-user-denied.yaml
kubectl delete -f "$ROOT"/../manifests/override-root-with-user.yaml
kubectl delete -f "$ROOT"/../manifests/run-as-root.yaml
kubectl delete -f "$ROOT"/../manifests/run-as-user.yaml
