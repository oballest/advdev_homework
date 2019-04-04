#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev
echo "Setting up MongoDb in project ${GUID}-parks-dev"
oc new-app mongodb-persistent --param MONGODB_USER=mongodb --param MONGODB_PASSWORD=mongodb --param MONGODB_DATABASE=parks
echo "Setting up build config for mlbparks"
oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
echo "Setting config maps for mlbparks"
oc create configmap mlbparks-config --from-literal="APPNAME=MLB Parks (Dev)" -n ${GUID}-parks-dev
echo "Setting up deployment config mlbparks"
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/mlbparks --remove-all -n ${GUID}-parks-dev
oc set probe dc/mlbparks -n ${GUID}-parks-dev --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/mlbparks -n ${GUID}-parks-dev --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/mlbparks --from configmap/mlbparks-config -n ${GUID}-parks-dev
oc set deployment-hook  dc/mlbparks --post -n ${GUID}-parks-dev -- curl -v '$(hostname)':8080/ws/data/load/
echo "Exposing service mlbparks"
oc expose dc mlbparks --port=8080 --labels=type=parksmap-backend -n ${GUID}-parks-dev

echo "Setting up build config for nationalparks"
oc new-build --binary=true --name="nationalparks" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
echo "Setting config maps for nationalparks"
oc create configmap nationalparks-config --from-literal="APPNAME=National Parks (Dev)" -n ${GUID}-parks-dev
echo "Setting up deployment config mlbparks"
oc new-app 5359-parks-dev/nationalparks:0.0-0 --name=nationalparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/nationalparks --remove-all -n ${GUID}-parks-dev
oc set probe dc/nationalparks -n ${GUID}-parks-dev --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/nationalparks -n ${GUID}-parks-dev --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/nationalparks --from configmap/nationalparks-config -n ${GUID}-parks-dev
oc set deployment-hook dc/nationalparks --post -n ${GUID}-parks-dev -- curl -v '$(hostname)':8080/ws/data/load/
echo "Exposing service nationalparks"
oc expose dc nationalparks --port=8080 --labels=type=parksmap-backend -n ${GUID}-parks-dev
