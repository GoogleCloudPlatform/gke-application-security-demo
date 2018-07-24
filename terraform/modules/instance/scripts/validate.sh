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

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Stop immediately if something goes wrong
set -euo pipefail

# shellcheck source=terraform/modules/instance/scripts/utils.sh
source "$ROOT"/utils.sh

# wait_for_svc is a function defined in utils.sh
wait_for_svc hello-root
wait_for_svc hello-user
wait_for_svc hello-override
wait_for_svc armored-hello-user
wait_for_svc armored-hello-denied

RUN_AS_ROOT=$(kubectl get svc -l app=hello-root -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')
RUN_AS_USER=$(kubectl get svc -l app=hello-user -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')
RUN_AS_OVERRIDE=$(kubectl get svc -l app=hello-override -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')
RUN_AS_ARMORED=$(kubectl get svc -l app=armored-hello-user -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')
RUN_AS_DENIED=$(kubectl get svc -l app=armored-hello-denied -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')


# the query_svc function is defined in utils.sh
# Each call to query_svc hits all five endpoints of app.go
# The output will depend on the privileges of the pod being queried
# You can get a better idea of the expected outputs in the Validation section
# of the README
echo -e "===\\n\\nQuerying service running natively as root"
query_svc "$RUN_AS_ROOT"

echo -e "===\\n\\nQuerying service containers running natively as user 'nobody'"
query_svc "$RUN_AS_USER"

echo -e "===\\n\\nQuerying service containers running with user overridden to be 'nobody'"
query_svc "$RUN_AS_OVERRIDE"

echo -e "===\\n\\nQuerying service containers with an AppArmor profile allowing reading /proc/cpuinfo"
query_svc "$RUN_AS_ARMORED"

echo -e "===\\n\\nQuerying service containers with an AppArmor profile blocking the reading of /proc/cpuinfo"
query_svc "$RUN_AS_DENIED"
