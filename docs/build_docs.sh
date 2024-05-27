#!/usr/bin/env bash
set -ex pipefail

FILES=()
PATHS=(
    "apis/client/v1beta1/openstackclient_types.go"
    "apis/core/v1beta1/openstackcontrolplane_types.go"
    "apis/core/v1beta1/openstackversion_types.go"
)

# Getting APIs from Services
SERVICE_PATH=($(MODCACHE=$(go env GOMODCACHE) awk '/openstack-k8s-operators/ && ! /lib-common/ && ! /openstack-operator/ && ! /infra/ && ! /replace/ {print ENVIRON["MODCACHE"] "/" $1 "@" $2 "/v1beta1/*_types.go"}' apis/go.mod))
for SERVICE in ${SERVICE_PATH[@]};do
    PATHS+=($(ls ${SERVICE}))
done

# Getting APIs from Infra
INFRA_PATH=($(MODCACHE=$(go env GOMODCACHE) awk '/openstack-k8s-operators/ && /infra/ {print ENVIRON["MODCACHE"] "/" $1 "@" $2 "/"}' apis/go.mod))
PATTERNS=("memcached/v1beta1/*_types.go"  "network/v1beta1/*_types.go"  "rabbitmq/v1beta1/*_types.go")
for INFRA in ${PATTERNS[@]};do
    ls ${INFRA_PATH}${INFRA}
    PATHS+=($(ls ${INFRA_PATH}${INFRA}))
done

# Adding -f to all API paths
for API_PATH in ${PATHS[@]};do
    FILES+=$(echo " -f $API_PATH")
done

# Build docs from APIs
${CRD_MARKDOWN} $FILES -n OpenStackClient -n OpenStackControlPlane -n OpenStackVersion > docs/assemblies/custom_resources.md
bundle exec kramdoc --auto-ids docs/assemblies/custom_resources.md && rm docs/assemblies/custom_resources.md
sed -i "s/=== Custom/== Custom/g" docs/assemblies/custom_resources.adoc

# Render HTML
cd docs
${MAKE} html BUILD=upstream
${MAKE} html BUILD=downstream
