# How to Test
Setup the mock deployment in the default namespace.
```
# kubectl apply -f mock-deploy.yaml
```

These two commands will `MODIFY` the configmap and secret in the deployment with a randomized secret value.
```
# cat <<EOF | kubectl apply -f -
---
apiVersion: v1
data:
  file.txt: |
      $(openssl rand -hex 12)
kind: ConfigMap
metadata:
  name: delete-this-cmap
EOF
```

```
# cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: delete-this-secret
stringData:
  secret.txt: hello world $(openssl rand -hex 12)
EOF
```

See the deployment pods were restarted:
```
# kubectl get pods | grep -E '^(NAME|delete-this-deployment)'
```

Clean up after you've tested.
```
# kubectl delete -f mock-deploy.yaml
```