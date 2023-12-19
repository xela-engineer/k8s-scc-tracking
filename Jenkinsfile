pipeline {
    agent any 
    stages {
        stage('build') {
            steps {
                sh """
                    echo "Building app..."
                    tree
                """
                
            }
        }
        stage('Code Scan') {
            steps {
                echo "scanning app..."
            }
        }
        stage('test') {
            steps {
                sh """
                    echo "Testing app..."
                    /usr/bin/shellcheck -s sh ./script/main.sh
                """
            }
        }
        stage('deploy') {
            steps {
                echo "Deploying app..."
            }
        }
    }
}
