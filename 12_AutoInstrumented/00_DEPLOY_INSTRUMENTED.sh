#!/bin/bash

set -uo pipefail


# Helper function to run commands and handle AlreadyExists errors
execute() {
    local cmd="$@"
    local output
    local exit_code

    output=$($cmd 2>&1) || exit_code=$?

    if [ ${exit_code:-0} -eq 0 ]; then
        echo -e "$cmd"
        return 0
    elif echo "$output" | grep -q "AlreadyExists"; then
        echo -e "Resource already exists (skipping): $cmd"
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

