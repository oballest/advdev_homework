// Jenkinsfile for MLBParks
// Set the tag for the development image: version + build number
def devTag      = "0.0-0"
// Set the tag for the production image: version
def prodTag     = "0.0"
def artifact	= ""
podTemplate(
  label: "skopeo-pod",
  cloud: "openshift",
  inheritFrom: "maven",
  containers: [
    containerTemplate(
      name: "jnlp",
      image: "docker-registry.default.svc:5000/${GUID}-jenkins/jenkins-slave-appdev",
      resourceRequestMemory: "1Gi",
      resourceLimitMemory: "2Gi"
    )
  ]
) {
  node('skopeo-pod') {
    echo "GUID: ${GUID}"
    echo "CLUSTER: ${CLUSTER}"

    // Your Pipeline Code goes here. Make sure to use the ${GUID} and ${CLUSTER} parameters where appropriate
    // You need to build the application in directory `MLBParks`.
    // Also copy "../nexus_settings.xml" to your build directory
    // and replace 'GUID' in the file with your ${GUID} to point to >your< Nexus instance
    // Checkout Source Code
    stage('Creating service') {
     echo "Creating service"
     
    
     openshift.withCluster() {
      openshift.withProject("5359-parks-prod") {
	 def dc = openshift.selector("dc", "mlbparks-blue")
	 dc.expose("--port=8080", "--labels=type=parksmap-backend", "-n 5359-parks-prod")
      }
     }
    }
  }
}

// Convenience Functions to read variables from the pom.xml
// Do not change anything below this line.
def getVersionFromPom(pom) {
  def matcher = readFile(pom) =~ '<version>(.+)</version>'
  matcher ? matcher[0][1] : null
}
def getGroupIdFromPom(pom) {
  def matcher = readFile(pom) =~ '<groupId>(.+)</groupId>'
  matcher ? matcher[0][1] : null
}
def getArtifactIdFromPom(pom) {
  def matcher = readFile(pom) =~ '<artifactId>(.+)</artifactId>'
  matcher ? matcher[0][1] : null
}
