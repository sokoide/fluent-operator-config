#!/bin/bash

# delete fluentbits
kubectl get fluentbit -A |grep -v NAMESPACE | awk '{print "kubectl delete fluentbit -n "$1" "$2}' | sh

# delete per namespace (user) configs
kubectl get fluentbitconfig -A |grep -v NAMESPACE | awk '{print "kubectl delete fluentbitconfig -n "$1" "$2}' | sh
kubectl get output -A |grep -v NAMESPACE | awk '{print "kubectl delete output -n "$1" "$2}' | sh

# delete system configs
kubectl get clusterfluentbitconfig | grep -v NAMESPACE | cut -d ' ' -f 1 |xargs -n 1 kubectl delete clusterfluentbitconfig


