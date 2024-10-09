apiVersion: migration.harvesterhci.io/v1beta1
kind: VirtualMachineImport
metadata:
  name: openstack-demo
  namespace: default
spec: 
  virtualMachineName: "DEVSTACK_VM_TO_MIGRATE_NAME"
  networkMapping:
  - sourceNetwork: "DEVSTACK_VM_TO_MIGRATE_NETWORK"
    destinationNetwork: "HARVESTER_NEW_VM_NETWORK"
  sourceCluster: 
    name: devstack
    namespace: default
    kind: OpenstackSource
    apiVersion: migration.harvesterhci.io/v1beta1
