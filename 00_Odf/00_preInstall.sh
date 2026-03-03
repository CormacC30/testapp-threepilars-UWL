#!/bin/bash

for NODE in `oc get node -l node-role.kubernetes.io/worker -o name | head -n 3` ; do oc label $NODE cluster.ocs.openshift.io/openshift-storage= ; done 
