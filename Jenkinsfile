pipeline {
    agent {label 'k8s-agent'}
    environment {
        IMAGE='codesenju/cicd-project-python'
    }
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE:$BUILD_NUMBER .'
            }
        }
        
        stage('Publish to Dockerhub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh 'docker login -u $USERNAME -p $PASSWORD'
                    sh 'docker push $IMAGE:$BUILD_NUMBER'
                }
            }
        }
    }
}
