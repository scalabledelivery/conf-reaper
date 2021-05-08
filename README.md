# Conf Reaper
Deletes pods that are using configmaps and secrets that are updated.

## Installation
```
# kubectl apply -f https://raw.githubusercontent.com/scalabledelivery/conf-reaper/main/deploy.yaml
```

Then just add the following annotations to your pods.
```
annotations:
  configMapModifyPolicy: "DELETE"
  secretModifyPolicy: "DELETE"
```
