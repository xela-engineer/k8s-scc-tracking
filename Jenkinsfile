pipeline {
    agent any 
    stages {
        stage('build') {
            steps {
                echo "Building app..."
            }
        }
        stage('Code Scan') {
              steps {
                echo "scanning app..."
              }
          }
        stage('test') {
              steps {
                echo "Testing app..."
              }
          }
        stage('deploy') {
              steps {
                echo "Deploying app..."
              }
          }
    }
}
