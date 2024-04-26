#!/bin/bash

kubectl get secret -A|grep -v NAMESPACE|awk '{print "echo \"***\" "$2;print "kubectl get secret -o yaml -n "$1" "$2 "| yq '\''.data.\"fluent-bit.conf\"'\'' | base64 -d"}'  | sh
