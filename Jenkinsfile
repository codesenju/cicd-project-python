env.IMAGE = 'codesenju/python-test'
// env.GITHUB_TOKEN_ID = 'github_token'
env.DOCKERHUB_CREDENTIAL_ID = 'dockerhub'
//env.GITHUB_REPO = 'cicd-project-python'
//env.GITHUB_USERNAME = 'codesenju'

pipeline {
    agent {label 'k8s-agent'}
    environment {
    GITHUB_TOKEN = credentials('github_token')
    GITHUB_REPO = 'cicd-project-python'
    GITHUB_USERNAME = 'codesenju'
  }

    stages {
    /* Skip Install stage
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
    */
        
stage('Checkout') {
    steps {
         script {
               //withCredentials([string(credentialsId: "${env.GITHUB_TOKEN_ID}", variable: "GITHUB_TOKEN")]) {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [],
                    submoduleCfg: [],
                    userRemoteConfigs: [[
                        url: "https://$GITHUB_TOKEN@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"
                    ]]
                ])
           //}
       }
    }
}

        stage('Approval') {
            steps {
                script {
                    try {
                        input(id: 'userInput', message: 'Do you want to proceed?', ok: 'Proceed')
                    } catch (err) {
                        env.APPROVED = false
                        error('Aborted')
                    }
                    env.APPROVED = true
                }
            }
        }
        stage('Build and Push Docker Image') {
            steps {
                    script {
                       sh '''
                            if ! command -v trivy &> /dev/null
                            then
                                echo "Trivy is not installed. Installing now."
                                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.22.0
                            else
                                echo "Trivy is already installed."
                            fi
                            trivy --version
                        '''
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
