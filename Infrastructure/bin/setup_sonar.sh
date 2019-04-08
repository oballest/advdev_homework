#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student
oc new-app --file=Infrastructure/templates/sonarqube-template.yml --param SONAR_DB_USER=sonar --param SONAR_DB_PASSWORD=sonar --param SONAR_DB_NAME=sonar -n ${GUID}-sonarqube

while : ; do
   echo "Checking if Sonarqube is Ready..."
   oc get pod -n ${GUID}-sonarqube|grep '\-1\-'|grep -v postgres|grep -v deploy|grep "1/1"
   [[ "$?" == "1" ]] || break
   echo "...no. Sleeping 10 seconds."
   sleep 10
done
