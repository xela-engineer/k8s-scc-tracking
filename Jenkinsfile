pipeline {
    agent { docker 'maven:3.3.3' }
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
