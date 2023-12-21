
pipeline {
    agent any 
    environment {
        compile_file_name = 'K8S-SCC-tracking'
    }
    stages {
        
        stage('build') {
            when {
                branch "main"
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'OCP_login',
                        usernameVariable: 'OCP_URL', 
                        passwordVariable: 'OCP_TOKEN')
                ]){
                    sh "echo ${passwordVariable} "
                }

                sh """
                    echo "Building shell script to exec file: ${compile_file_name}"
                    
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
    post {
        failure {
        // notify users when the Pipeline fails
        mail to: 'alex23woo@gmail.com',
            subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
            body: "Something is wrong with ${env.BUILD_URL}"
        }
    }
}
