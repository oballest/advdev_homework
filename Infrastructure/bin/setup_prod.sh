#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student
echo "Setting up the right permissions to the jenkis sevice account"
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-prod
oc policy add-role-to-group  system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev

echo "Setting up the replicated MongoDb in project ${GUID}-parks-prod"
oc new-app -f Infrastructure/templates/mongodc-rs-template.yml -n ${GUID}-parks-prod --param MONGODB_USER=mongodb_user --param MONGODB_PASSWORD=redhat_01 --param MONGODB_DATABASE=parks --param MONGODB_REPLICA_NAME=rs0 --param MONGODB_SERVICE_NAME=mongodb

echo "Setting config maps for mlbparks Green"
oc create configmap mlbparks-green-config --from-literal="APPNAME=MLB Parks (Green)" -n ${GUID}-parks-prod

echo "Setting up deployment config mlbparks Green"
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/mlbparks-green --remove-all -n ${GUID}-parks-prod
oc set probe dc/mlbparks-green -n ${GUID}-parks-prod --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/mlbparks-green -n ${GUID}-parks-prod --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/mlbparks-green --from configmap/mlbparks-green-config -n ${GUID}-parks-prod
oc set env dc/mlbparks-green DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb_user DB_PASSWORD=redhat_01 DB_NAME=parks DB_REPLICASET=rs0 -n ${GUID}-parks-prod
oc set deployment-hook dc/mlbparks-green --post -n ${GUID}-parks-prod --failure-policy=retry -c mlbparks-green -- curl -v mlbparks-green.${GUID}-parks-prod.svc.cluster.local:8080/ws/data/load/

echo "Exposing service mlbparks Green"
oc expose dc mlbparks-green --port=8080 --labels=type=parksmap-backend -n ${GUID}-parks-prod

echo "Setting config maps for mlbparks Blue"
oc create configmap mlbparks-blue-config --from-literal="APPNAME=MLB Parks (Blue)" -n ${GUID}-parks-prod

echo "Setting up deployment config mlbparks Green"
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/mlbparks-blue --remove-all -n ${GUID}-parks-prod
oc set probe dc/mlbparks-blue -n ${GUID}-parks-prod --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/mlbparks-blue -n ${GUID}-parks-prod --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/mlbparks-blue --from configmap/mlbparks-blue-config -n ${GUID}-parks-prod
oc set env dc/mlbparks-blue DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb_user DB_PASSWORD=redhat_01 DB_NAME=parks DB_REPLICASET=rs0 -n ${GUID}-parks-prod
oc set deployment-hook dc/mlbparks-blue --post -n ${GUID}-parks-prod --failure-policy=retry -c mlbparks-blue -- curl -v mlbparks-blue.${GUID}-parks-prod.svc.cluster.local:8080/ws/data/load/
