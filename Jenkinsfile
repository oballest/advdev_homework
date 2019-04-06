// Jenkinsfile for MLBParks
// Set the tag for the development image: version + build number
def devTag      = "0.0-0"
// Set the tag for the production image: version
def prodTag     = "1.0"
def artifact	= "mlbparks"
def destApp = "mlbparks-blue" 
def activeApp = "mlbparks-green"
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
     
     echo "Aplicacion actual ${activeApp} aplicacion de destino ${destApp}"
    
     openshift.withCluster() {
      openshift.withProject("5359-parks-prod") {
         try{
	     def svc = openshift.selector("svc/${destApp}").object()
	     echo "servicio seleccionado ${svc}"
	     activeApp = svc.object().spec.selector.app
	     destApp = "mlbparks-green"
         } catch ( e ) {
	    echo "servicio No Encontrado, se utiliza configuración inicial"
         }
	 echo "Aplicacion actual ${activeApp} aplicacion de destino ${destApp}"
	 echo "Active Application:      " + activeApp
         echo "Destination Application: " + destApp
         
         // Update the Image on the Production Deployment Config
         def dc = openshift.selector("dc/${destApp}").object()
         dc.spec.template.spec.containers[0].image="docker-registry.default.svc:5000/5359-parks-dev/${artifact}:${prodTag}"
         openshift.apply(dc)
         
         // Deploy the inactive application.
         openshift.selector("dc", "${destApp}").rollout().latest();
      
         // Wait for application to be deployed
         def dc_prod = openshift.selector("dc", "${destApp}").object()
         def dc_version = dc_prod.status.latestVersion
         def rc_prod = openshift.selector("rc", "${destApp}-${dc_version}").object()
         echo "Waiting for ${destApp} to be ready"
         while (rc_prod.spec.replicas != rc_prod.status.readyReplicas) {
            sleep 5
            rc_prod = openshift.selector("rc", "${destApp}-${dc_version}").object()
         }
      }
     }
    }
 //End ot the Blue/Green Production Deployment
  stage('Switch over to new Version') {
    echo "Executing production switch"
    openshift.withCluster() {
      openshift.withProject("5359-parks-prod") {
        //Actual service deletion
	openshift.selector("svc", ${activeApp}).delete()

	//Actual Deployment config
	def dc = openshift.selector("dc", ${destApp})
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
