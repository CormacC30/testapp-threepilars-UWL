#!/bin/bash

#Deploy the Uiplugin
oc patch console.operator cluster -n openshift-storage --type json -p '[{"op": "add", "path": "/spec/plugins", "value": ["odf-console"]}]'

TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)

while true; do                                                                                                                                                                                                    
      if oc exec -n openshift-storage $TOOLS_POD -- ceph status 2>/dev/null | grep -q HEALTH_OK; then
          ((consecutive++))                                                                                                                                                                                         
          echo "[$(date)] HEALTH_OK confirmed (${consecutive}/2)"
          if [ $consecutive -ge 2 ]; then                                                                                                                                                                           
              echo "Ceph cluster healthy on consecutive checks - exiting loop"
              break
          fi
          echo "Sleeping 2 minutes before re-check..."
          sleep 120
      else
          consecutive=0
          echo "[$(date)] HEALTH_OK not found, retrying in 30s..."
          sleep 30
      fi
  done

echo "The storage cluster is ready..."
