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
# Verifies that all source files contain the necessary copyright boilerplate
# snippet.

# this code waits for the backend services to be deleted
LIST='hello-root|hello-user|hello-override|armored-hello-user|armored-hello-denied'
REGION="$(gcloud config get-value compute/region)"

# obtain all backend service names
STR="$(gcloud compute backend-services list | awk '{print $1}' | awk '!/NAME/')"

# convert the names of backend services to a list
ARR="$(echo "${STR}" | tr ' ' '\n')"

# loop all the backend services
for ITEM in $ARR
do
    # find a backend service created by this application
    RES=$(gcloud compute backend-services describe "$ITEM" --region="$REGION" | grep -E "$LIST|group")
    if [[ $RES == *"description"* ]]; then

        # get the name of the backend service "group" (ie k8s-ig--d0bf239d98a9d918)
        # shellcheck disable=SC2034
        IFS=' ' read -r var1 var2 var3 <<< "$RES"
        NAME=${var2##*/}

        # wait for all backend services to be deleted in that "group" (max time 5 minutes)
        RETRIES_REMAINING=30
        while [[ $(gcloud compute backend-services list | grep "$NAME") != "" ]]; do
            if [[ $RETRIES_REMAINING -eq 0 ]]; then
              echo "Retry limit exceeded; exiting..."
              exit 1
            fi
            echo "Wait for the BACKEND $NAME being deleted."
            RETRIES_REMAINING=$(("$RETRIES_REMAINING" - 1))
            sleep 10
        done
        echo "Service $NAME has been deleted."

        # delete the particular firewall rule (ie k8s-d0bf239d98a9d918-node-hc)
        gcloud compute firewall-rules delete "${NAME/-ig-/}-node-hc" --quiet >/dev/null 2>&1

        # wait for the firewall rules to be deleted (max time 5 minutes)
        RETRIES_REMAINING=30
        while [[ $(gcloud compute firewall-rules list --format=json | grep "${NAME/-ig-/}") != "" ]]; do
            if [[ $RETRIES_REMAINING -eq 0 ]]; then
              echo "Retry limit exceeded; exiting..."
              exit 1
            fi
            echo "Wait for the Firewall ${NAME/-ig-/} being deleted."
            RETRIES_REMAINING=$(("$RETRIES_REMAINING" - 1))
            sleep 10
        done
        echo "Firewall ${NAME/-ig-/} has been deleted."
        exit 0
    fi
done


