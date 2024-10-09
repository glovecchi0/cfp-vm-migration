apiVersion: v1
kind: Secret
metadata:
  name: devstack-credentials
  namespace: default
stringData:
  "username": "DEVSTACK_USERNAME"
  "password": "DEVSTACK_PASSWORD"
  "project_name": "DEVSTACK_PROJECT_NAME"
  "domain_name": "DEVSTACK_DOMAIN_NAME"
