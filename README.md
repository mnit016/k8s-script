# K8s Script
This repo to store helpful script with K8s

## Get all requested Memory & CPU on K8s
This script will only select running pods and its containers (not initContainers)
### Require
- Nodejs (Calculate float number line 59,60)
- Bash version > 4.0
```
./get_all_request_resources.sh
```

