#!/bin/bash
BUCKET_HOST=$(oc get -n openshift-logging configmap loki-bucket-odf -o jsonpath='{.data.BUCKET_HOST}')
BUCKET_NAME=$(oc get -n openshift-logging configmap loki-bucket-odf -o jsonpath='{.data.BUCKET_NAME}')
BUCKET_PORT=$(oc get -n openshift-logging configmap loki-bucket-odf -o jsonpath='{.data.BUCKET_PORT}')
ACCESS_KEY_ID=$(oc get -n openshift-logging secret loki-bucket-odf -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
SECRET_ACCESS_KEY=$(oc get -n openshift-logging secret loki-bucket-odf -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)
oc create secret generic logging-loki-odf -n openshift-logging \
   --from-literal=access_key_id=${ACCESS_KEY_ID} \
   --from-literal=access_key_secret=${SECRET_ACCESS_KEY} \
   --from-literal=bucketnames=${BUCKET_NAME} \
   --from-literal=endpoint=https://${BUCKET_HOST}:${BUCKET_PORT}
