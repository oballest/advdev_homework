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
oc project ${GUID}-sonar
oc new-app --file=Infrastructure/templates/sonarqube-template.yml --param SONAR_DB_USER=sonar --param SONAR_DB_PASSWORD=sonar --param SONAR_DB_NAME=sonar
