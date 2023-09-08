pipeline {
    agent {label 'k8s-agent'}
    
   stages {
        stage('Checkout') {
            steps {
                withCredentials([string(credentialsId: 'github_token', variable: 'GITHUB_TOKEN')]) {
                    sh 'git clone --branch main --depth 1 --single-branch --no-tags --quiet https://$GITHUB_TOKEN@github.com/codesenju/cicd-project-python.git'
                }
            }
        }
        stage('Build and Push Docker Image') {
            steps {
            dir('cicd-project-python') {
                script {
                  docker.withRegistry('https://registry.hub.docker.com', 'dockerhub') {
                    def customImage = docker.build("codesenju/test-python:${env.BUILD_NUMBER}")
                      /* Push the container to the custom Registry */
                       customImage.push()
                  }
                }
            }
            }
        }
    }
}
