pipeline {
    agent { docker { image 'demo:0.0.1' } }
      stages {
        stage('log version info') {
      steps {
        sh 'curl ifconfig.io'
      }
    }
  }
}
