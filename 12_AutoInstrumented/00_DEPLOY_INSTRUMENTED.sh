#!/bin/bash

set -uo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to run commands and handle AlreadyExists errors
execute() {
    local cmd="$@"
    local output
    local exit_code

    output=$($cmd 2>&1) || exit_code=$?

    if [ ${exit_code:-0} -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $cmd"
        return 0
    elif echo "$output" | grep -q "AlreadyExists"; then
        echo -e "${YELLOW}⚠${NC} Resource already exists (skipping): $cmd"
        return 0
    else
        echo "Error executing: $cmd"
        echo "$output"
        return $exit_code
    fi
}

# Create or use existing project
echo "Creating project ns3..."
execute oc new-project ns3

# Create deployment
echo "Creating deployment test-py..."
execute oc create deployment test-py --image quay.io/rhn-support-ccostell/ping-py:latest -n ns3

# Expose deployment as service
echo "Exposing deployment as service..."
execute oc expose deployment test-py -n ns3 --port 8090

# Expose service as route
echo "Exposing service as route..."
execute oc expose svc test-py -n ns3

# Create instrumentation
echo "Creating instrumentation..."
execute oc create -f 01_INSTRUMENTATION.yaml

# Patch deployment with instrumentation annotation
echo "Patching deployment with instrumentation annotation..."
oc patch deployment test-py -n ns3 -p '{"spec": {"template": {"metadata": {"annotations": {"instrumentation.opentelemetry.io/inject-python": "true"}}}}}'

# Restart deployment
echo "Restarting deployment..."
oc -n ns3 rollout restart deployment test-py

echo -e "${GREEN}Deployment complete!${NC}"
