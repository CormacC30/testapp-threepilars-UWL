#!/bin/bash

#Deploy the Uiplugin
oc patch console.operator cluster -n openshift-storage --type json -p '[{"op": "add", "path": "/spec/plugins", "value": ["odf-console"]}]'

TOOLS_POD=""
until [ -n "$TOOLS_POD" ]; do
    echo "[$(date)] Waiting for rook-ceph-tools pod..."
    sleep 10
    TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
done
echo "[$(date)] Found tools pod: $TOOLS_POD"

while true; do
    CEPH_STATUS=$(oc exec -n openshift-storage $TOOLS_POD -- ceph status 2>/dev/null)

    HEALTH_OK=$(echo "$CEPH_STATUS" | grep -c "HEALTH_OK")
    read TOTAL_OSDS UP_OSDS IN_OSDS <<< $(echo "$CEPH_STATUS" | awk '/osd:/ {print $2, $4, $8}')
    ALL_PGS_CLEAN=$(echo "$CEPH_STATUS" | awk '/pgs:/ {count=0; for(i=1;i<=NF;i++) if($i ~ /active\+clean/) count++; print (count==1 && $(i-2)+0>0) ? "yes" : "no"}')

    echo "[$(date)] health=${HEALTH_OK:+HEALTH_OK} osds=${TOTAL_OSDS:-?} total, ${UP_OSDS:-?} up, ${IN_OSDS:-?} in | pgs_clean=${ALL_PGS_CLEAN:-?}"

    if [ "$HEALTH_OK" -ge 1 ] && \
       [ -n "$TOTAL_OSDS" ] && [ "$TOTAL_OSDS" -eq "$UP_OSDS" ] && [ "$TOTAL_OSDS" -eq "$IN_OSDS" ] && \
       [ "$ALL_PGS_CLEAN" = "yes" ]; then
        ((consecutive++))
        echo "[$(date)] All checks passed (${consecutive}/2)"
        if [ $consecutive -ge 2 ]; then
            echo "Ceph cluster healthy on consecutive checks - exiting loop"
            break
        fi
        echo "Sleeping 2 minutes before re-check..."
        sleep 120
    else
        consecutive=0
        echo "[$(date)] Checks failed, retrying in 30s..."
        sleep 30
    fi
done

echo "The storage cluster is ready..."
