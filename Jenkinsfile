
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
                sh """
                    echo "Building shell script to exec file: ${compile_file_name}"
                    shc -vrf ./script/main.sh -o k8s-scc
                """
            }
        }

        stage('Code Scan') {
            when {
                branch "main"
            }
            steps {
                sh """
                    echo "Code quality scanning..."
                    #shellcheck disable=SC2140
                    /usr/bin/shellcheck -s bash ./script/main.sh
                """
            }
        }
        stage('Test') {
            when {
                branch "main"
            }
            steps {
                sh """
                    echo "Testing app..."
                """
                withCredentials([
                    usernamePassword(
                        credentialsId: 'OCP_login',
                        usernameVariable: 'OCP_URL', 
                        passwordVariable: 'OCP_TOKEN')
                ]){
                    sh """
                        ./k8s-scc "${OCP_URL}" "${OCP_TOKEN}"
                    """    
                }
            }
        }
        
        stage('deploy') {
            when {
                branch "release"
            }
            steps {
                echo "Deploying app..."
            }
        }
    }
    post {
        failure {
            // notify users when the Pipeline fails
            // mail to: 'alex23woo@gmail.com',
            //     subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
            //     body: "Something is wrong with ${env.BUILD_URL}"
            slackSend( channel: "#Jenkins", token: "slack_webhook token", color: "good", message: "${custom_msg()}")
        }
    }
}

def custom_msg()
{
  def JENKINS_URL= "localhost:8888"
  def JOB_NAME = env.JOB_NAME
  def BUILD_ID= env.BUILD_ID
  def JENKINS_LOG= " FAILED: Job [${env.JOB_NAME}] Logs path: ${JENKINS_URL}/job/${JOB_NAME}/${BUILD_ID}/consoleText"
  return JENKINS_LOG
}