# testapp-threepilars-UWL
I use this to demonstrate collecting metrics, logs and traces in Openshift.
A testapp is deployed with always firing alerts for both metrics and logs. 

Demo App: https://github.com/coffeegoesincodecomesout/testapp-ThreePilars

1. Run the Deploy script

```
./00_Deploy.sh
```
2. scale the testapp down and back up, inorder to deploy the OTEL sidecar 

```
oc scale -n ns1-uwl --replicas=0 deployment/threepilar-uwl-example-app
oc scale -n ns1-uwl --replicas=1 deployment/threepilar-uwl-example-app
```

TODO

Test the claude written wrapper script
replace test app with new one - https://github.com/coffeegoesincodecomesout/testapp-ThreePilars-Frontend 
