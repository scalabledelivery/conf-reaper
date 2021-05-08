#!/bin/bash
function kube_api(){
    curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc.cluster.local${@}
}

function process_entry(){
    TYPE=${1}
    NAMESPACE=${2}
    NAME=${3}
    [ "${TYPE}" == "ConfigMap" ] && pod_search_configmaps ${NAMESPACE} ${NAME}
    [ "${TYPE}" == "Secret" ] && pod_search_secrets ${NAMESPACE} ${NAME}
}

# Finds pods in namespace using configmap
function pod_search_configmaps(){
    NAMESPACE=${1}
    CONFIGMAP_NAME=${2}
    kube_api /api/v1/pods \
    | jq -r --unbuffered '
        .items[]
        | select(.spec.volumes[].configMap.name == "'${CONFIGMAP_NAME}'"), select(.spec.containers[].env[]?.valueFrom.configMapKeyRef.name == "'${CONFIGMAP_NAME}'")
        | .metadata
        | select(.namespace == "'${NAMESPACE}'")
        | select(.annotations.configMapModifyPolicy == "DELETE") | .namespace + " " + .name' \
    | while read -r line; do reap_pod $line configMap/${CONFIGMAP_NAME}; done
}

# Finds pods in namespace using configmap
function pod_search_secrets(){
    NAMESPACE=${1}
    SECRET_NAME=${2}
    kube_api /api/v1/pods \
    | jq -r --unbuffered '
        .items[]
        | select(.spec.volumes[].secret.secretName == "'${SECRET_NAME}'"), select(.spec.containers[].env[]?.valueFrom.secretKeyRef.name == "'${SECRET_NAME}'")
        | .metadata
        | select(.namespace == "'${NAMESPACE}'")
        | select(.annotations.secretModifyPolicy == "DELETE") | .namespace + " " + .name' \
    | while read -r line; do reap_pod $line secret/${SECRET_NAME}; done
}

# Reaps pods in namespace by pod name to reload a modified config map
function reap_pod(){
    NAMESPACE=${1}
    POD_NAME=${2}
    CONFIGMAP_NAME=${3}
    echo $(date --utc) Deleting pod "${NAMESPACE}/${POD_NAME}" to reload "${CONFIGMAP_NAME}"
    kube_api "/api/v1/namespaces/${NAMESPACE}/pods/${POD_NAME}" -X DELETE > /dev/null
}

# let the plumbing begin...
curl --parallel --silent --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
https://kubernetes.default.svc.cluster.local/api/v1/watch/{configmaps,secrets} \
| jq -r --unbuffered '
    . 
    | select(.type == "MODIFIED")
    | .object.kind + " " + .object.metadata.namespace + " " + .object.metadata.name' \
| while read -r line; do process_entry $line; done
