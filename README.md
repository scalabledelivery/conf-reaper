# Conf Reaper
Deletes pods that are using configmaps and secrets that are updated.

## Installation
```
# kubectl apply -f deploy.yaml
```

Then just add the following annotations to your pods.
```
annotations:
  configMapModifyPolicy: "DELETE"
  secretModifyPolicy: "DELETE"
```
