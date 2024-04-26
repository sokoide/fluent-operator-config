#!/bin/bash

./clean.sh

ls ../*.yaml |grep -v clusteroutput | grep -v clusterinput | xargs -n 1 kubectl apply -f

