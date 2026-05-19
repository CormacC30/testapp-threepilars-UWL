#!/bin/bash

set -euo pipefail

oc new-project ns3
oc create deployment test-py --image quay.io/rhn-support-ccostell/ping-py:latest -n ns3
oc expose deployment test-py -n ns3 --port 8090
oc expose svc test-py -n ns3
oc create -f 01_INSTRUMENTATION.yaml
oc patch deployment test-py -n ns3 -p '{"spec": {"template": {"metadata": {"annotations": {"instrumentation.opentelemetry.io/inject-python": "true"}}}}}'
oc -n ns3 rollout restart deployment test-py
