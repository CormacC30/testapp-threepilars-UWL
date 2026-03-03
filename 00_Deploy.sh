#!/bin/bash

#Operators
oc create -Rf 01_Operators/

#Test App
oc create -Rf 02_App/

#Logging 
03_Logging/01_commands.sh
oc create -f 03_Logging/02_objectclaim.yaml
03_Logging/03_bucketsecret.sh
oc create -f 03_Logging/04_loggingstack.yaml
oc create -f 03_Logging/05_alertingrule.yaml

#Otel 
oc create -f 04_Opentelemetry/01_collector.yaml  

#Tempo
oc create -f 05_Tempo/
05_Tempo/02_bucketsecret.sh
oc create -f 05_Tempo/03_tempo.yaml
co create -f 05_Tempo/04_uiplugin

#User workload
oc create -Rf 06_UserWorkload/
