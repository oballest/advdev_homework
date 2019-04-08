#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student
echo "finding out if the mlbparks-blue service exists"
oc get svc mlbparks-blue -n ${GUID}-parks-prod
if [ "$?" == "0" ]
then
  echo "mlbparks-blue does exist switching over mlbparks-green "
  oc delete svc mlbparks-blue -n ${GUID}-parks-prod
  oc expose dc mlbparks-green --port=8080 -n ${GUID}-parks-prod
fi
echo "Done switching mlbparks service $?"

echo "finding out if the nationalparks-blue service exists"
oc get svc nationalparks-blue -n ${GUID}-parks-prod
if [ "$?" == "0" ]
then
  echo "nationalparks-blue does exist switching over mlbparks-green "
  oc delete svc nationalparks-blue -n ${GUID}-parks-prod
  oc expose dc nationalparks-green --port=8080 -n ${GUID}-parks-prod
fi
echo "Done switching nationalparks service $?"

echo "Pointing the parksmap route to the green service"
oc patch route parksmap --patch='{ "spec": { "to": { "name": "parksmap-green" }}}' -n ${GUID}-parks-prod
echo "Done resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services - $?"
