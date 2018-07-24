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

# this function waits for a services load balancer to be assigned a public IP
wait_for_svc () {
  RETRIES_REMAINING=30
  while [[ $(kubectl get svc -l app="$1" -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}') == "" ]]; do
    if [[ $RETRIES_REMAINING -eq 0 ]]; then
      echo "Retry limit exceeded; exiting..."
      exit 1
    fi
    echo "Service $1 has not allocated an IP yet."
    RETRIES_REMAINING=$(("$RETRIES_REMAINING" - 1))
    sleep 10
  done
  echo "Service $1 IP has been allocated"
}

# this function hits every endpoint of app.go based on the service name
# passed in as the sole argument
query_svc () {
    curl -q http://"$1"/hostname
    curl -q http://"$1"/getuser
    curl -q http://"$1"/rootfile
    curl -q http://"$1"/userfile
    curl -q http://"$1"/procfile | head -5
    echo ""
}
