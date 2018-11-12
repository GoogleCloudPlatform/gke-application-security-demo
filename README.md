# Best Practices for Securing Containerized Applications in Kubernetes Engine

## Table of Contents

<!-- TOC -->

* [Introduction](#introduction)
* [Architecture](#architecture)
  * [Containers](#containers)
  * [AppArmor](#apparmor)
  * [The container configurations](#the-container-configurations)
* [Prerequisites](#prerequisites)
  * [Tools](#tools)
  * [Versions](#versions)
* [Deployment](#deployment)
  * [Authenticate gcloud](#authenticate-gcloud)
  * [Configure gcloud settings](#configuring-gcloud-settings)
  * [Setup this project](#setup-this-project)
  * [Provisioning the Kubernetes Engine Cluster](#provisioning-the-kubernetes-engine-cluster)
* [Validation](#validation)
* [Tear Down](#tear-down)
* [Troubleshooting](#troubleshooting)
* [Relevant Material](#relevant-material)

<!-- TOC -->

## Introduction

This guide demonstrates a series of best practices that will allow the user to improve the security of their containerized applications deployed to Kubernetes Engine.

The [principle of least privilege]((https://en.wikipedia.org/wiki/Principle_of_least_privilege))
is widely recognized as an important design consideration in enhancing the protection of critical systems from faults and malicious behavior. It suggests that every component must be able to access **only** the information and resources that are necessary for its legitimate purpose. This guide will go about showing the user how to improve a container's security by providing a systematic approach to effectively remove unnecessary privileges.

## Architecture

### Containers

At their core, containers help make implementing security best practices easier by providing the user with an easy interface to run processes in a chroot environment as an unprivileged user and removing all but the kernel [capabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html) needed to run the application. By default, all containers are run in the root user namespace so running containers as a non-root user is important.

### AppArmor

On occasion, an application will need to access a kernel resource that requires special privileges normally granted only to the root user. However, running the application as a user with root privileges is a bad solution as it provides the application with access to the entire system. Instead, the kernel provides a set of capabilities that can be granted to a process to allow it coarse-grained access to only the kernel resources it needs and nothing more.

Using kernel modules such as AppArmor, Kubernetes provides an easy interface to both run the containerized application as a non-root user in the process namespace and restrict the set of capabilities granted to the process.

### The container configurations

This demonstration will deploy five containers in a private cluster:

1. A container run as the root user in the container in the Dockerfile
1. A container run as a user created in the container in the Dockerfile
1. A container that Kubernetes started as a non-root user despite the Dockerfile not specifying it be run as a non-root user
1. A container with a lenient AppArmor profile that allows all non-root permissions.
1. A container with an AppArmor profile applied to disallow the `/proc/cpuinfo` endpoint from being properly read

Each container will be exposed outside the clusters as an internal load balancer.

The containers themselves are running a simple Go web server with five endpoints. The endpoints differ in terms of the privileges they need to complete the request. A non-root user cannot read a file owned by root. The `nobody` user cannot read `/proc/cpuinfo` when that privilege is being blocked by AppArmor.

1. An endpoint to get the container's hostname
1. An endpoint to get the username, UID, and GID of identity running the server
1. An endpoint to read a file owned by the `root` user
1. An endpoint to read a file owned by the `nobody` user
1. An endpoint to read the `/proc/cpuinfo` file

## Prerequisites

### Run Demo in a Google Cloud Shell

Click the button below to run the demo in a [Google Cloud Shell](https://cloud.google.com/shell/docs/).

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/gke-application-security-demo.git&amp;cloudshell_image=gcr.io/graphite-cloud-shell-images/terraform:latest&amp;cloudshell_tutorial=README.md)


All the tools for the demo are installed. When using Cloud Shell execute the following
command in order to setup gcloud cli. When executing this command please setup your region and zone.

```console
gcloud init
```

### Tools
1. [Terraform >= 0.11.7](https://www.terraform.io/downloads.html)
2. [Google Cloud SDK version >= 204.0.0](https://cloud.google.com/sdk/docs/downloads-versioned-archives)
3. [kubectl matching the latest GKE version](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
4. bash or bash compatible shell
5. [GNU Make 3.x or later](https://www.gnu.org/software/make/)
6. A Google Cloud Platform project where you have permission to create
   networks

#### Install Cloud SDK
The Google Cloud SDK is used to interact with your GCP resources.
[Installation instructions](https://cloud.google.com/sdk/downloads) for multiple platforms are available online.

#### Install kubectl CLI

The kubectl CLI is used to interteract with both Kubernetes Engine and kubernetes in general.
[Installation instructions](https://cloud.google.com/kubernetes-engine/docs/quickstart)
for multiple platforms are available online.

#### Install Terraform

Terraform is used to automate the manipulation of cloud infrastructure. Its
[installation instructions](https://www.terraform.io/intro/getting-started/install.html) are also available online.

## Deployment

The steps below will walk you through using terraform to deploy a Kubernetes Engine cluster that you will then use for exploring multiple types of container security configurations.

### Authenticate gcloud

Prior to running this demo, ensure you have authenticated your gcloud client by running the following command:

```console
gcloud auth application-default login
```

### Configure gcloud settings

Run `gcloud config list` and make sure that `compute/zone`, `compute/region` and `core/project` are populated with values that work for you. You can set their values with the following commands:

```console
# Where the region is us-east1
gcloud config set compute/region us-east1

Updated property [compute/region].
```

```console
# Where the zone inside the region is us-east1-c
gcloud config set compute/zone us-east1-c

Updated property [compute/zone].
```

```console
# Where the project name is my-project-name
gcloud config set project my-project-name

Updated property [core/project].
```

### Setup this project

This project requires the following Google Cloud Service APIs to be enabled:

* `compute.googleapis.com`
* `container.googleapis.com`
* `cloudbuild.googleapis.com`

In addition, the terraform configuration takes three parameters to determine where the Kubernetes Engine cluster should be created:

* `project`
* `region`
* `zone`

For simplicity, these parameters are to be specified in a file named `terraform.tfvars`, in the `terraform` directory. To ensure the appropriate APIs are enabled and to generate the `terraform/terraform.tfvars` file based on your gcloud defaults, run:

```console
make setup-project
```

This will enable the necessary Service APIs, and it will also generate a `terraform/terraform.tfvars` file with the following keys. The values themselves will match the output of `gcloud config list`:

```console
$ cat terraform/terraform.tfvars

project="YOUR_PROJECT"
region="YOUR_REGION"
zone="YOUR_ZONE"
```

If you need to override any of the defaults, simply replace the desired value(s) to the right of the equals sign(s). Be sure your replacement values are still double-quoted.

### Provisioning the Kubernetes Engine Cluster

Next, apply the terraform configuration with:

```console
# From within the project root, use make to apply the terraform
make tf-apply
```

This will take a few minutes to complete.  The following is the last few lines of successful output.

```console
...snip...
google_container_cluster.primary: Still creating... (2m20s elapsed)
google_container_cluster.primary: Still creating... (2m30s elapsed)
google_container_cluster.primary: Still creating... (2m40s elapsed)
google_container_cluster.primary: Still creating... (2m50s elapsed)
google_container_cluster.primary: Still creating... (3m0s elapsed)
google_container_cluster.primary: Still creating... (3m10s elapsed)
google_container_cluster.primary: Still creating... (3m20s elapsed)
google_container_cluster.primary: Still creating... (3m30s elapsed)
google_container_cluster.primary: Still creating... (3m40s elapsed)
google_container_cluster.primary: Creation complete after 3m44s (ID: gke-security-best-practices)

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
```

Once that has completed, remote into the bastion instance using SSH:

```console
gcloud compute ssh gke-application-security-bastion
```

Apply the manifests for the cluster using the deployment script:

```console
./scripts/deploy.sh
```

This will take a minute or two to complete.  The final output should be similar to:

```console
namespace/apparmor created
configmap/apparmor-profiles created
daemonset.apps/apparmor-loader created
deployment.apps/armored-hello-user created
service/armored-hello-user created
deployment.apps/armored-hello-denied created
service/armored-hello-denied created
deployment.apps/hello-override created
service/hello-override created
deployment.apps/hello-root created
service/hello-root created
deployment.apps/hello-user created
service/hello-user created

...snip...

Service hello-root has not allocated an IP yet.
Service hello-root has not allocated an IP yet.
Service hello-root IP has been allocated
Service hello-user has not allocated an IP yet.
Service hello-user has not allocated an IP yet.
Service hello-user has not allocated an IP yet.
Service hello-user has not allocated an IP yet.
Service hello-user IP has been allocated
Service hello-override IP has been allocated
Service armored-hello-user IP has been allocated
Service armored-hello-denied IP has been allocated
```

At this point, the environment should be completely set up.

## Validation

To test all of the services in one command, run the validation script from the scripts directory of the bastion host:

```console
./scripts/validate.sh
```

This script queries each of the services to get:

* the hostname of the pod being queried
* the username, UID, and GID of the process the pod's web server is running as
* the contents of a file owned by root
* the contents of a file owned by a non-root user
* the first 5 lines of content from `/proc/cpuinfo`

The first service, `hello-root`, has an output similar to:

```console
Querying service running natively as root
You are querying host hello-root-54fdf49bf7-8bjmm
User: root
UID: 0
GID: 0
You have read the root.txt file.
You have read the user.txt file.
processor : 0
vendor_id : GenuineIntel
cpu family  : 6
model   : 63
model name  : Intel(R) Xeon(R) CPU @ 2.30GHz
```

and it clearly shows that it is running as `root` and can perform all actions.

The third service, `hello-user`, has an output similar to:

```console
Querying service containers running natively as user
You are querying host hello-user-76957b5645-hvfw2
User: nobody
UID: 65534
GID: 65534
unable to open root.txt: open root.txt: permission denied
You have read the user.txt file.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   804  100   804    0     0   156k      0 --:--:-- --:--:-- --:--:--  196k
processor       : 0
vendor_id       : GenuineIntel
cpu family      : 6
model           : 45
model name      : Intel(R) Xeon(R) CPU @ 2.60GHz
```

which shows that it is running as `nobody` (65534) and therefore can read user.txt but not root.txt.

The third service, `hello-override`, has an output similar to:

```console
Querying service containers normally running as root but overridden by Kubernetes
You are querying host hello-override-7c6c4b6c4-szmrh
User: nobody
UID: 65534
GID: 65534
unable to open root.txt: open root.txt: permission denied
You have read the user.txt file.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   804  100   804    0     0   144k      0 --:--:-- --:--:-- --:--:--  157k
processor       : 0
vendor_id       : GenuineIntel
cpu family      : 6
model           : 45
model name      : Intel(R) Xeon(R) CPU @ 2.60GHz
```

and it shows that the container is running as the `nobody` user of id `65534`.  Therefore, it can again read the `user.txt` file and read from `/proc/cpuinfo`.

The fourth service, `armored-hello-user`, has an output similar to:

```console
Querying service containers with an AppArmor profile allowing reading /proc/cpuinfo
You are querying host armored-hello-user-5645cd4496-qls6q
User: nobody
UID: 65534
GID: 65534
unable to open root.txt: open root.txt: permission denied
You have read the user.txt file.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   804  100   804    0     0   148k      0 --:--:-- --:--:-- --:--:--  157k
processor       : 0
vendor_id       : GenuineIntel
cpu family      : 6
model           : 45
model name      : Intel(R) Xeon(R) CPU @ 2.60GHz
```

and it shows that the leniently armored container still has the default access of the
`nobody` user.

The fifth and final service, `armored-hello-denied`, has an output similar to:

```console
Querying service containers with an AppArmor profile blocking the reading of /proc/cpuinfo
You are querying host armored-hello-denied-6fccb988dd-sxhmz
User: nobody
UID: 65534
GID: 65534
unable to open root.txt: open root.txt: permission denied
You have read the user.txt file.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    63  100    63    0     0  12162      0 --:--:-- --:--:-- --:--:-- 12600
unable to open root.txt: open /proc/cpuinfo: permission denied
```

and it shows that the container is prohibited by AppArmor policy from reading the `user.txt` and `/proc/cpuinfo`.

## Tear Down

To tear down the environment, use :

```console
./scripts/teardown.sh
```

It's output should look like the following:

```console
daemonset.apps "apparmor-loader" deleted
configmap "apparmor-profiles" deleted
namespace "apparmor" deleted
deployment.apps "armored-hello-user" deleted
service "armored-hello-user" deleted
deployment.apps "armored-hello-denied" deleted
service "armored-hello-denied" deleted
deployment.apps "hello-override" deleted
service "hello-override" deleted
deployment.apps "hello-root" deleted
service "hello-root" deleted
deployment.apps "hello-user" deleted
service "hello-user" deleted
```

After that script completes, log out of the bastion host and run the following to destroy the environment:

```console
make tf-destroy
```

Terraform will destroy the environment and indicate when it has completed:

```console
...snip...
module.network.google_compute_subnetwork.cluster-subnet: Destroying... (ID: us-east1/kube-net-subnet)
google_service_account.admin: Destruction complete after 0s
module.network.google_compute_subnetwork.cluster-subnet: Still destroying... (ID: us-east1/kube-net-subnet, 10s elapsed)
module.network.google_compute_subnetwork.cluster-subnet: Still destroying... (ID: us-east1/kube-net-subnet, 20s elapsed)
module.network.google_compute_subnetwork.cluster-subnet: Destruction complete after 25s
module.network.google_compute_network.gke-network: Destroying... (ID: kube-net)
module.network.google_compute_network.gke-network: Still destroying... (ID: kube-net, 10s elapsed)
module.network.google_compute_network.gke-network: Still destroying... (ID: kube-net, 20s elapsed)
module.network.google_compute_network.gke-network: Destruction complete after 25s

Destroy complete! Resources: 7 destroyed.
```

## Troubleshooting

### Terraform destroy does not finish cleanly. The error will look something like

```console
Error: Error applying plan:

1 error(s) occurred:

* module.network.google_compute_network.gke-network (destroy): 1 error(s) occurred:

* google_compute_network.gke-network: The network resource 'projects/seymourd-sandbox/global/networks/kube-net' is already being used by 'projects/seymourd-sandbox/global/firewalls/k8s-29e43f3a2accf594-node-hc'


Terraform does not automatically rollback in the face of errors. Instead, your Terraform state file has been partially updated with any resources that successfully completed. Please address the error above and apply again to incrementally change your infrastructure.

```

Solution: the cluster does not always cleanly remove all of the GCP resources associated with a service before the cluster is deleted. You will need to manually clean up the remaining resources using either the Cloud Console or gcloud.

### The install script fails with a `Permission denied` when running Terraform

The credentials that Terraform is using do not provide the necessary permissions to create resources in the selected projects. Ensure that the account listed in `gcloud config list` has necessary permissions to create resources. If it does, regenerate the application default credentials using `gcloud auth application-default login`.

### Invalid fingerprint error during Terraform operations

Terraform occasionally complains about an invalid fingerprint, when updating certain resources. If you see the error below, simply re-run the command. ![terraform fingerprint error](./img/terraform_fingerprint_error.png)

## Relevant Material

* [Capabilities documentation](http://man7.org/linux/man-pages/man7/capabilities.7.html)
* [Docker security documentation](https://docs.docker.com/engine/security/security/)
* [AppArmor](https://wiki.ubuntu.com/AppArmor)
* [Kubernetes Engine Release Notes](https://cloud.google.com/kubernetes-engine/release-notes)

**This is not an officially supported Google product**