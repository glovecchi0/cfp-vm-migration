apiVersion: migration.harvesterhci.io/v1beta1
kind: OpenstackSource
metadata:
  name: devstack
  namespace: default
spec:
  endpoint: "DEVSTACK_AUTH_ENDPOINT"
  region: "RegionOne"
  credentials:
    name: devstack-credentials
    namespace: default
