pipeline {
    agent { any }
    stages {
        stage('build') {
            steps {
                echo "Building app..."
            }
        }
        stage('Code Scan') {
              steps {
                  sh 'scanning app...'
              }
          }
        stage('test') {
              steps {
                  sh 'Testing app...'
              }
          }
        stage('deploy') {
              steps {
                  sh 'Deploying app...'
              }
          }
    }
}
