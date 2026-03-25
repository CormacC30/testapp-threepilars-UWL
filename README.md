# testapp-threepilars-UWL
I use this to demonstrate collecting metrics, logs and traces in Openshift - Using Openshift data foundation as the storage backend
A testapp is deployed with always firing alerts for both metrics and logs.

Demo App: https://github.com/coffeegoesincodecomesout/testapp-ThreePilars

User workload Monitoring is used to store "user" metrics.
The cluster logging and loki operators are used to collect and store logs.
Opentelemetry is used to collect traces.
Tempo is used to store traces. 

The cluster observability operator manages the UIPlugins. 

1. Run the Deploy script

```
./00_Deploy.sh
```

TODO

replace test app with one consisting of a front and backend.
 - https://github.com/coffeegoesincodecomesout/testapp-ThreePilars-Frontend 
 - https://github.com/coffeegoesincodecomesout/testapp-ThreePilars-backend 

Add Netobserv - with alerts

write some tests
