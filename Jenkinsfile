pipeline {
    agent any 
    stages {
        
        stage('build') {
            when {
                branch "main"
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
                branch "main"
            }
            steps {
                echo "scanning app..."
            }
        }
        stage('test') {
            when {
                branch "main"
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
                branch "main"
            }
            steps {
                echo "Deploying app..."
            }
        }
    }
}
