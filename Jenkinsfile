pipeline {
    agent any 
    stages {
        
        stage('build') {
            when {
                branch "master"
            }
            steps {
                sh """
                    echo "Building app..."
                    tree
                """
                
            }
        }
        stage('Code Scan') {
            when {
                branch "master"
            }
            steps {
                echo "scanning app..."
            }
        }
        stage('test') {
            when {
                branch "master"
            }
            steps {
                sh """
                    echo "Testing app..."
                    /usr/bin/shellcheck -s sh ./script/main.sh
                """
            }
        }
        stage('deploy') {
            when {
                branch "master"
            }
            steps {
                echo "Deploying app..."
            }
        }
    }
}
