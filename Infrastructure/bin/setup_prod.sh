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

#Setting up permissions
echo "Setting up the right permissions to the jenkis sevice account"
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-prod
oc policy add-role-to-group  system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev

echo "Setting up the replicated MongoDb in project ${GUID}-parks-prod"
oc new-app -f Infrastructure/templates/mongodc-rs-template.yml -n ${GUID}-parks-prod --param MONGODB_USER=mongodb_user --param MONGODB_PASSWORD=redhat_01 --param MONGODB_DATABASE=parks --param MONGODB_REPLICA_NAME=rs0 --param MONGODB_SERVICE_NAME=mongodb

#validating the image stream mlbparks from the development project
while : ; do
   echo "Checking if the imagestream mlbparks exist"
   oc get is mlbparks -n ${GUID}-parks-dev
   if [ "$?" == "0" ]
   then
    break
   fi
   echo "...no. Sleeping 10 seconds."
   sleep 10
done

echo "Setting config maps for mlbparks Green"
oc create configmap mlbparks-green-config --from-literal="APPNAME=MLB Parks (Green)" -n ${GUID}-parks-prod

echo "Setting up deployment config mlbparks Green"
oc new-app ${GUID}-parks-dev/mlbparks:0.0 --name=mlbparks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
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

echo "Setting up deployment config mlbparks Blue"
oc new-app ${GUID}-parks-dev/mlbparks:0.0 --name=mlbparks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/mlbparks-blue --remove-all -n ${GUID}-parks-prod
oc set probe dc/mlbparks-blue -n ${GUID}-parks-prod --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/mlbparks-blue -n ${GUID}-parks-prod --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/mlbparks-blue --from configmap/mlbparks-blue-config -n ${GUID}-parks-prod
oc set env dc/mlbparks-blue DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb_user DB_PASSWORD=redhat_01 DB_NAME=parks DB_REPLICASET=rs0 -n ${GUID}-parks-prod
oc set deployment-hook dc/mlbparks-blue --post -n ${GUID}-parks-prod --failure-policy=retry -c mlbparks-blue -- curl -v mlbparks-blue.${GUID}-parks-prod.svc.cluster.local:8080/ws/data/load/

#validating the image stream nationalparks from the development project
while : ; do
   echo "Checking if the imagestream nationalparks exist"
   oc get is nationalparks -n ${GUID}-parks-dev
   if [ "$?" == "0" ]
   then
    break
   fi
   echo "...no. Sleeping 10 seconds."
   sleep 10
done

echo "Setting config maps for nationalparks Green"
oc create configmap nationalparks-green-config --from-literal="APPNAME=National Parks (Green)" -n ${GUID}-parks-prod

echo "Setting up deployment config nationalparks Green"
oc new-app ${GUID}-parks-dev/nationalparks:0.0 --name=nationalparks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/nationalparks-green --remove-all -n ${GUID}-parks-prod
oc set probe dc/nationalparks-green -n ${GUID}-parks-prod --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/nationalparks-green -n ${GUID}-parks-prod --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/nationalparks-green --from configmap/nationalparks-green-config -n ${GUID}-parks-prod
oc set env dc/nationalparks-green DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb_user DB_PASSWORD=redhat_01 DB_NAME=parks DB_REPLICASET=rs0 -n ${GUID}-parks-prod
oc set deployment-hook dc/nationalparks-green --post -n ${GUID}-parks-prod --failure-policy=retry -c nationalparks-green -- curl -v nationalparks-green.${GUID}-parks-prod.svc.cluster.local:8080/ws/data/load/

echo "Exposing service nationalparks Green"
oc expose dc nationalparks-green --port=8080 --labels=type=parksmap-backend -n ${GUID}-parks-prod

echo "Setting config maps for nationalparks Blue"
oc create configmap nationalparks-blue-config --from-literal="APPNAME=National Parks (Blue)" -n ${GUID}-parks-prod

echo "Setting up deployment config nationalparks Blue"
oc new-app ${GUID}-parks-dev/nationalparks:0.0 --name=nationalparks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/nationalparks-blue --remove-all -n ${GUID}-parks-prod
oc set probe dc/nationalparks-blue -n ${GUID}-parks-prod --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/nationalparks-blue -n ${GUID}-parks-prod --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/nationalparks-blue --from configmap/nationalparks-blue-config -n ${GUID}-parks-prod
oc set env dc/nationalparks-blue DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb_user DB_PASSWORD=redhat_01 DB_NAME=parks DB_REPLICASET=rs0 -n ${GUID}-parks-prod
oc set deployment-hook dc/nationalparks-blue --post -n ${GUID}-parks-prod --failure-policy=retry -c nationalparks-blue -- curl -v nationalparks-blue.${GUID}-parks-prod.svc.cluster.local:8080/ws/data/load/

#validating the image stream parksmap from the development project
while : ; do
   echo "Checking if the imagestream parksmap exist"
   oc get is parksmap -n ${GUID}-parks-dev
   if [ "$?" == "0" ]
   then
    break
   fi
   echo "...no. Sleeping 10 seconds."
   sleep 10
done

echo "Setting config maps for Parksmap Green"
oc create configmap parksmap-green-config --from-literal="APPNAME=ParksMap (Green)" -n ${GUID}-parks-prod

echo "Setting up deployment config Parksmap Green"
oc new-app ${GUID}-parks-dev/parksmap:0.0 --name=parksmap-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers  dc/parksmap-green --remove-all -n ${GUID}-parks-prod
oc set probe dc/parksmap-green -n ${GUID}-parks-prod --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/parksmap-green -n ${GUID}-parks-prod --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/parksmap-green --from configmap/parksmap-green-config -n ${GUID}-parks-prod

echo "Exposing service parksmap Green"
oc expose dc parksmap-green --port=8080 -n ${GUID}-parks-prod

echo "Exposing parksmap service Green"
oc expose service parksmap-green --name=parksmap -n ${GUID}-parks-prod

echo "Setting config maps for Parksmap Blue"
oc create configmap parksmap-blue-config --from-literal="APPNAME=ParksMap (Blue)" -n ${GUID}-parks-prod

echo "Setting up deployment config Parksmap Blue"
oc new-app ${GUID}-parks-dev/parksmap:0.0 --name=parksmap-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers  dc/parksmap-blue --remove-all -n ${GUID}-parks-prod
oc set probe dc/parksmap-blue -n ${GUID}-parks-prod --liveness --failure-threshold=3 --initial-delay-seconds=30 -- echo ok
oc set probe dc/parksmap-blue -n ${GUID}-parks-prod --readiness --failure-threshold=3 --initial-delay-seconds=60 --get-url=http://:8080/ws/healthz/
oc set env dc/parksmap-blue --from configmap/parksmap-blue-config -n ${GUID}-parks-prod

echo "Exposing service parksmap Blue"
oc expose dc parksmap-blue --port=8080 -n ${GUID}-parks-prod




