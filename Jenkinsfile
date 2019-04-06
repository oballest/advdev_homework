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
      image: "docker-registry.default.svc:5000/5359-jenkins/jenkins-slave-appdev",
      resourceRequestMemory: "1Gi",
      resourceLimitMemory: "2Gi"
    )
  ]
) {
  node('skopeo-pod') {
   
    stage('Creating service') {
     echo "Creating service"
     
     def destApp = "mlbparks-blue" 
     def activeApp = ""
     echo "Aplicacion actual ${activeApp} aplicacion de destino ${destApp}"
    
     openshift.withCluster() {
      openshift.withProject("5359-parks-prod") {
	 def svc = openshift.selector("dc/${destApp}")
	 echo "servicio seleccionado ${svc}"
         if(svc != null){
	   activeApp = svc.object().spec.selector.app
           destApp = "mlbparks-green"
	 } 
	 echo "Aplicacion actual ${activeApp} aplicacion de destino ${destApp}"
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
