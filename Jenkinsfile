env.IMAGE = 'codesenju/python-test'
env.GITHUB_REPO = 'cicd-project-python'
env.GITHUB_USERNAME = 'codesenju'
env.GITHUB_TOKEN_ID = 'github_token'
env.DOCKERHUB_CREDENTIAL_ID = 'dockerhub'

pipeline {
    agent {label 'k8s-agent'}
    
    stages {
        stage("Install"){
            steps {
                // Kustomize
                sh "echo Install kustomize"
                sh "curl -sLo /tmp/kustomize.tar.gz  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.0.3/kustomize_v5.0.3_linux_amd64.tar.gz"
                sh "tar xzvf /tmp/kustomize.tar.gz -C /usr/bin/ && chmod +x /usr/bin/kustomize && rm -rf /tmp/kustomize.tar.gz"
                sh "kustomize version"
                // Trivy
                sh "echo Install trivy"
                sh "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.22.0"
                sh "trivy --version"
                // Argocd
                sh "echo Install Argocd"
                sh "curl -sLo /usr/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.7.2/argocd-linux-amd64 && chmod +x /usr/bin/argocd"
                sh "argocd version --client"
            }
        }
        stage('Checkout') {
            steps {
                withCredentials([string(credentialsId: "${env.GITHUB_TOKEN_ID}", variable: "GITHUB_TOKEN")]) {
                    sh "git clone --branch main --depth 1 --single-branch --no-tags --quiet https://$GITHUB_TOKEN@github.com/${env.GITHUB_USERNAME}/${env.GITHUB_REPO}.git"
                }
            }
        }
        stage('Build and Push Docker Image') {
            steps {
                dir("${env.GITHUB_REPO}") {
                    script {
                        docker.withRegistry("https://registry.hub.docker.com", "${env.DOCKERHUB_CREDENTIAL_ID}") {
                            /* Scan for IaC misconfigurations */
                            sh "trivy fs --exit-code 0 --severity HIGH --no-progress --security-checks vuln,config ./"
                            sh "trivy fs --exit-code 1 --severity CRITICAL --no-progress --security-checks vuln,config ./"
                            def customImage = docker.build("${env.IMAGE}:${env.BUILD_NUMBER}", "--network=host .")
                            /* Scan image for vulnerabilities */
                            sh "trivy image --exit-code 0 --severity HIGH --no-progress ${env.IMAGE}:${env.BUILD_NUMBER}"
                            sh "trivy image --exit-code 1 --severity CRITICAL --no-progress ${env.IMAGE}:${env.BUILD_NUMBER}"
                            /* Push the container to the custom Registry */
                            customImage.push()
                        }
                    }
                }
            }
        }
    }
}
