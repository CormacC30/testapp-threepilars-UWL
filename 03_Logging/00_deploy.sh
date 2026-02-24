#!/bin/bash
./01_commands.sh
oc create -f 02_objectclaim.yaml
./03_bucketsecret.sh
oc create -f 04_loggingstack
oc creatre -f 05_alertingrule.yaml
