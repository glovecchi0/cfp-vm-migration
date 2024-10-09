#!/bin/bash

# Load variables from the file
if [[ -f "./variables" ]]; then
    source ./variables
else
    echo "Error: variables file not found!"
    exit 1
fi

# Validate the SSL certificate format
function validate_certificate() {
    if [[ $DEVSTACK_SSL_CERT != *"-----BEGIN CERTIFICATE-----"* || $DEVSTACK_SSL_CERT != *"-----END CERTIFICATE-----"* ]]; then
        echo "Error: The SSL certificate must start with '-----BEGIN CERTIFICATE-----' and end with '-----END CERTIFICATE-----'."
        exit 1
    fi
}

# Check for leading spaces in the SSL certificate and report line numbers
function check_certificate_spaces() {
    line_number=0
    while IFS= read -r line; do
        line_number=$((line_number + 1))
        if [[ $line =~ ^\  ]]; then
            echo "Error: Line $line_number in the SSL certificate has leading spaces."
            exit 1
        fi
    done <<< "$DEVSTACK_SSL_CERT"
}

# Validate the auth endpoint URL format
function validate_url() {
    if [[ ! $DEVSTACK_AUTH_ENDPOINT =~ ^https://.+/identity/v3$ ]]; then
        echo "Error: The URL must be in the format 'https://your_endpoint/identity/v3'."
        exit 1
    fi
}

# Validate certificate and URL
validate_certificate
check_certificate_spaces
validate_url

# Substitute variables in devstack-credentials.yml.tpl (without touching the cert part)
sed -e "s/DEVSTACK_USERNAME/$DEVSTACK_USERNAME/" \
    -e "s/DEVSTACK_PASSWORD/$DEVSTACK_PASSWORD/" \
    -e "s/DEVSTACK_PROJECT_NAME/$DEVSTACK_PROJECT/" \
    -e "s/DEVSTACK_DOMAIN_NAME/$DEVSTACK_DOMAIN/" \
    devstack-credentials.yml.tpl > devstack-credentials.yml

# Prepare the SSL certificate with 4 spaces for each line
formatted_cert=$(echo "$DEVSTACK_SSL_CERT" | sed 's/^/    /')

# Append the formatted certificate to the devstack-credentials.yml
echo "  \"ca_cert\": |" >> devstack-credentials.yml
echo "$formatted_cert" >> devstack-credentials.yml

# Remove empty lines from devstack-credentials.yml
sed -i '' '/^[[:space:]]*$/d' devstack-credentials.yml

# Substitute variables in devstack-source.yml.tpl
sed -e "s|DEVSTACK_AUTH_ENDPOINT|$DEVSTACK_AUTH_ENDPOINT|" \
    devstack-source.yml.tpl > devstack-source.yml

# Remove empty lines from devstack-source.yml
sed -i '' '/^[[:space:]]*$/d' devstack-source.yml

# Substitute variables in vm-migration.yml.tpl
sed -e "s|DEVSTACK_VM_TO_MIGRATE_NAME|$VM_NAME|" \
    -e "s|DEVSTACK_VM_TO_MIGRATE_NETWORK|$DEVSTACK_NETWORK|" \
    -e "s|HARVESTER_NEW_VM_NETWORK|$HARVESTER_NETWORK|" \
    vm-migration.yml.tpl > vm-migration.yml

# Remove empty lines from vm-migration.yml
sed -i '' '/^[[:space:]]*$/d' vm-migration.yml

# Final output
echo "\nConfiguration files have been created successfully:"
echo " - devstack-credentials.yml"
echo " - devstack-source.yml"
echo " - vm-migration.yml"

# Export the Harvester KUBECONFIG file
export KUBECONFIG="$HARVESTER_KUBECONFIG_PATH"

# Enable the vm-import-controller addon 
kubectl apply -f vm-import-controller-addon.yml

# Check if vm-import-controller is enabled
while true; do
    # Get the status of the vm-import-controller addon
    addon_status=$(kubectl get addons -n harvester-system | grep vm-import-controller)

    # Check if the addon is enabled
    if [[ $addon_status == *"true"* ]]; then
        echo "vm-import-controller is enabled."
        break
    else
        echo "vm-import-controller is not enabled yet. Retrying in 5 seconds..."
        sleep 5
    fi
done

# Deploy the devstack-credentials.yml and devstack-source.yml files
kubectl apply -f devstack-credentials.yml
kubectl apply -f devstack-source.yml

# Wait until the OpenStack source status is clusterReady
while true; do
    # Get the status of the OpenStack source
    source_status=$(kubectl get openstacksources.migration.harvesterhci.io devstack)

    # Check if the status contains 'clusterReady'
    if [[ $source_status == *"clusterReady"* ]]; then
        echo "OpenStack source 'devstack' is clusterReady."
        break
    else
        echo "OpenStack source 'devstack' is not ready yet. Current status:\n$source_status"
        sleep 5
    fi
done

# Deploy the vm-import-controller-addon.yml file - VM MIGRATION
kubectl apply -f vm-migration.yml

# Monitor the migration
echo "\nTo monitor the migration progress, view the harvester-vm-import-controller pod logs:"
echo " kubectl -n harvester-system logs -f \$(kubectl -n harvester-system get pods -l app.kubernetes.io/instance=vm-import-controller -o custom-columns=\":metadata.name\") -f"
