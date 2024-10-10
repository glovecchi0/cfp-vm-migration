# DevStack to Harvester VM Migration

Manage Your Migration to Harvester: Automate the Transition of Virtual Machines from OpenStack.

## Prerequisite

### Before you start the migration process, you need to ensure that you have access to the following:

1. **DevStack Cluster:** A working DevStack OpenStack cluster that you want to migrate VMs from. You can set up a DevStack environment by following the guide in [this](https://github.com/glovecchi0/devstack-on-gcp) GitHub project.

2. **Harvester Cluster:** A Harvester cluster that will be the target of the VM migration. To set up a Harvester cluster, you can follow the guide in [this](https://github.com/glovecchi0/harvester-equinix-tf) GitHub project.

Ensure that you have both clusters up and running before proceeding with the migration.

## Setup Instructions

### 1. Clone the Repository

Clone this repository to your local machine:

```bash
$ git clone git@github.com:glovecchi0/devstack-vm-migration-to-harvester.git
$ cd devstack-vm-migration-to-harvester
```

### 2. Configure the `variables` File

Before running the script, you need to configure the environment-specific variables. You will find a `variables.example` file in the root directory.

Copy this example file and rename it to `variables`:

```bash
$ cp variables.example variables
```

Then, open the variables file and configure it with your cluster details. Below is an example configuration:

Example `variables` File

```
# DevStack credentials
DEVSTACK_USERNAME="admin"
DEVSTACK_PASSWORD="SecretPassword1"
DEVSTACK_PROJECT="admin"
DEVSTACK_DOMAIN="default"
DEVSTACK_AUTH_ENDPOINT="https://PUBLIC_IP/identity/v3"

# VM migration details
VM_NAME="basic"
DEVSTACK_NETWORK="public"
HARVESTER_NETWORK="default/vlan1" #example namespace/vm-network -> default/vlanX

# SSL Certificate in PEM format (multi-line)
DEVSTACK_SSL_CERT="
-----BEGIN CERTIFICATE-----
MIIDzDCCArSgAwIBAgIUGVcqzWU6Bs1KPlxBGjq1cKf0YK0wDQYJKoZIhvcNAQEL
BAMMDTM1LjIzNi4xMi4xMTMwHhcNMjQxMDA5MDcxMzU2WhcNMjUxMDA5MDcxMzU2
WjBtMQswCQYDVQQGEwJVUzEOMAwGA1UECAwFU3RhdGUxDTALBgNVBAcMBENpdHkx
AwwNMzUuMjM2LjEyLjExMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
ALmaJBgeSjaGKFbQW81soxxA+ZOz6UQ4uiTkVMP5kiZ6fojc7w6hQ5fj5qK2Dubk
p94O27KVQJdYKVIZWl/+kMXc2HaX/WJhbS5WJsdqrlpHBoAMXR0qKiB8gye4V8B+
4loKn/L3ZX/d8xABUk3R/qL/Cw7NjPBzmCibdEG9q4C+sGUpXrkRLGO6tsOmcogK
MvbkmqEF2JTAMB8GA1UdIwQYMBaAFEZodVUmlhmtY1vzMvbkmqEF2JTAMA8GA1Ud
K+aI1+lPEMrNqdy8s0+gztBBkrEgY27CN0RxnS+e1zZNIGdqBlOSPoFkK9KMhNOe
c/0KpF1yHwZ65QJ8ke6LDCBsaDSGzwoRmz/MNHS1G6jHoZ02ILY6+SNVZvGK0HSo
rGvtSyuUCwlOFYiWUhw8HA==
-----END CERTIFICATE-----
" #connect via SSH to the DevStack node, become root and read the contents of the file /etc/ssl/certs/devstack/selfsigned.crt

# Path to Harvester kubeconfig
HARVESTER_KUBECONFIG_PATH="/Users/username/suse/harvester-equinix-tf/examples/custom-vm-network/username_kube_config.yml"
```

### 3. Run the Migration Script

Once the `variables` file is correctly configured, you can execute the migration script. The script will validate your configuration, apply Kubernetes resources, and handle the migration.

Run the script:

```bash
$ sh migration.sh
```

### 4. Monitor the Migration

After running the script and deploying the necessary files, you can monitor the status of the migration by checking the logs of the VM import controller pod. Use the following command to follow the logs of the VM import controller:

```bash
$ kubectl -n harvester-system logs -f $(kubectl -n harvester-system get pods -l app.kubernetes.io/instance=vm-import-controller -o custom-columns=":metadata.name") -f
```

This command allows you to view the real-time logs of the `harvester-vm-import-controller` pod, where you can observe the details of the VM migration process.

##### Real Example 

For instance, after executing the migration script, you might see logs similar to the following:

```bash
$ kubectl -n harvester-system logs -f $(kubectl -n harvester-system get pods -l app.kubernetes.io/instance=vm-import-controller -o custom-columns=":metadata.name") -f
time="2024-10-09T09:41:56Z" level=info msg="Applying CRD vmwaresources.migration.harvesterhci.io"
time="2024-10-09T09:41:56Z" level=info msg="Applying CRD openstacksources.migration.harvesterhci.io"
time="2024-10-09T09:41:56Z" level=info msg="Applying CRD virtualmachineimports.migration.harvesterhci.io"
time="2024-10-09T09:41:56Z" level=info msg="Starting migration.harvesterhci.io/v1beta1, Kind=VirtualMachineImport controller"
time="2024-10-09T09:41:56Z" level=info msg="Starting migration.harvesterhci.io/v1beta1, Kind=OpenstackSource controller"
time="2024-10-09T09:41:56Z" level=info msg="Starting harvesterhci.io/v1beta1, Kind=VirtualMachineImage controller"
time="2024-10-09T09:41:56Z" level=info msg="reconcilling openstack soure :default/devstack"
time="2024-10-09T09:41:56Z" level=info msg="Starting migration.harvesterhci.io/v1beta1, Kind=VmwareSource controller"
time="2024-10-09T09:41:57Z" level=info msg="found 1 servers"
time="2024-10-09T09:41:57Z" level=info msg="reconcilling openstack soure :default/devstack"
time="2024-10-09T13:08:06Z" level=error msg="error syncing 'default/openstack-demo': handler virtualmachine-import-job-change: waiting for vm default/openstack-demo to be powered off, requeuing"
time="2024-10-09T13:08:20Z" level=info msg="&{2b93e1ef-a0bc-4ae1-871d-83c0908bf4ec creating 5 nova 2024-10-09 13:08:20.369274 +0000 UTC 0001-01-01 00:00:00 +0000 UTC []   lvmdriver-1 274b4fea-f0eb-4728-a414-8269bd85eb0d  map[] b735e7bd9d2d42918b7e0684910617c1 true false   false}"
time="2024-10-09T13:08:31Z" level=info msg="attempting to create new image from volume"
time="2024-10-09T13:15:53Z" level=info msg="vm openstack-demo in namespace default imported successfully"
^C
```

These logs indicate the progress and completion status of the VM migration.

**This script works perfectly from the macOS terminal; if you use any other Linux distribution, remove '' from the sed command.**
