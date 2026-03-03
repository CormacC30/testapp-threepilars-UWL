#!/bin/bash

#Install Odf
00_Install_Odf/00_preInstall.sh
oc create -Rf 00_Install_Odf/01_subscription_odf.yaml

#check operator has installed before configuring the storagecluster
#IMPROVE - by checking the operator status
sleep 300

oc create -Rf 00_Install_Odf/02_storagecluster.yaml
00_Install_Odf/03_postInstall.sh

#Operators
oc create -Rf 01_Operators/

#Test App
oc create -Rf 02_App/

#wait for operators to install
#IMPROVE - by checking the operator status
sleep 300

#Logging 
03_Logging/01_commands.sh
oc create -f 03_Logging/02_objectclaim.yaml
03_Logging/03_bucketsecret.sh
oc create -f 03_Logging/04_loggingstack.yaml
oc create -f 03_Logging/05_alertingrule.yaml

#Otel 
oc create -f 04_Opentelemetry/01_collector.yaml  

#Tempo
oc create -f 05_Tempo/01_objectclaim.yaml
05_Tempo/02_bucketsecret.sh
oc create -f 05_Tempo/03_tempo.yaml
oc create -f 05_Tempo/04_uiplugin

#User workload
oc create -Rf 06_UserWorkload/
