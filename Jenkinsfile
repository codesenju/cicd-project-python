env.ENV = 'dev'
env.IMAGE = 'codesenju/python-test'
/* Docker */
env.DOCKERHUB_CREDENTIAL_ID = 'dockerhub'
/* Github  */
env.GITHUB_CRDENTIAL_ID = 'git-ssh-pvt'
env.GITHUB_REPO = 'cicd-project-python'
env.GITHUB_USERNAME = 'codesenju'
env.APP_NAME = 'cicd-project-python'
env.K8S_MANIFESTS_REPO = 'cicd-project-python-k8s'
/* AWS */
env.CLUSTER_NAME = 'uat'
env.AWS_REGION = 'us-east-1'

pipeline {
    
      triggers {
    githubPush()
  }
  
    agent {label 'k8s-agent'}
    
    //environment {
        /* Set environment variables */

    //}
    
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
                    def gitUrl = "git@github.com:${GITHUB_USERNAME}/${GITHUB_REPO}.git"
                    def gitCredentialId = "${GITHUB_CRDENTIAL_ID}"
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'app-directory']],
                    submoduleCfg: [],
                    userRemoteConfigs: [[
                        credentialsId: gitCredentialId,
                        url: gitUrl
                    ]]
                ])
       }
    }
} 
        /*
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
        */
        stage('Build and Push Docker Image') {
            steps {
                dir('app-directory'){
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
                        // Create Artifacts which we can use if we want to continue our pipeline for other stages 
                        sh '''
                             printf '[{"app_name":"%s","image_name":"%s","image_tag":"%s"}]' "${APP_NAME}" "${IMAGE}" "${BUILD_NUMBER}" > build.json
                        '''
                    }
            }
            }
        }
         stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build.json', fingerprint: true
            }
        }

stage('Pre-Deploy') {
    steps {
        script {
            sh 'echo Install kustomize cli...'
            sh 'curl -sLo /tmp/kustomize.tar.gz  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.0.3/kustomize_v5.0.3_linux_amd64.tar.gz'
            sh 'tar xzvf /tmp/kustomize.tar.gz -C /usr/bin/ && chmod +x /usr/bin/kustomize && rm -rf /tmp/kustomize.tar.gz'
            sh 'kustomize version'
            sh 'echo Install kubectl cli...'
            sh 'curl -o /usr/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.4/2023-08-16/bin/linux/amd64/kubectl && chmod +x /usr/bin/kubectl'
            sh 'kubectl version --short --client'
            sh "echo 'Install Argocd cli & Authenticate with Argocd Server...'"
            sh 'curl -sLo /usr/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.7.2/argocd-linux-amd64 && chmod +x /usr/bin/argocd'
            sh 'argocd version --client'
            
            sh 'aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}'
            // Set the image in the kustomization file
            // sh "kustomize edit set image ${env.IMAGE}:${env.BUILD_NUMBER}"

            // Deploy the application
            sh "kubectl cluster-info"
        }
    }
}

stage('Deploy') {
    steps {
            sh 'echo Install kustomize cli...'
            sh 'curl -sLo /tmp/kustomize.tar.gz  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.0.3/kustomize_v5.0.3_linux_amd64.tar.gz'
            sh 'tar xzvf /tmp/kustomize.tar.gz -C /usr/bin/ && chmod +x /usr/bin/kustomize && rm -rf /tmp/kustomize.tar.gz'
            sh 'kustomize version'
                script {
                    def gitUrl = "git@github.com:${GITHUB_USERNAME}/${K8S_MANIFESTS_REPO}.git"
                    def gitCredentialId = "${GITHUB_CRDENTIAL_ID}"
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'k8s-directory']],
                    submoduleCfg: [],
                    userRemoteConfigs: [[
                        credentialsId: gitCredentialId,
                        url: gitUrl
                    ]]
                ])
                dir("k8s-directory/k8s/${ENV}"){
                sh 'git status'
                sh 'git branch -r'
                sh 'cat kustomization.yaml | head -n 13'
                sh 'kustomize edit set image KUSTOMIZE=${IMAGE}:${BUILD_NUMBER}'
                sh 'cat kustomization.yaml | head -n 13'
                sh 'git config --global user.email "devops@jenkins-pipeline.com"'
                sh 'git config --global user.name "jenkins-k8s-agent"'
                sh 'git add kustomization.yaml'
                sh 'git commit -m "Updated ${APP_NAME} image to ${IMAGE}:${BUILD_NUMBER}" || true'
                // Push the changes
                // sh 'ssh || true'
                // sh 'apt-get install -y ssh > /dev/null'
                sh 'git status'
                withCredentials([sshUserPrivateKey(credentialsId: gitCredentialId, keyFileVariable: 'SSH_KEY')]) {
                    sh 'eval `ssh-agent -s` && ssh-add $SSH_KEY && ssh -o StrictHostKeyChecking=no git@github.com || true && git push origin HEAD:main'
                }
                }
       }
    }
}
stage('Post-Deploy') {
    steps {
    'echo "Authenticate with Argocd Server..."'
    'ARGOCD_CREDS=$(aws secretsmanager get-secret-value --secret-id iac-my-argocd-secret --query SecretString --output text)'
    'ARGOCD_USERNAME=$(echo $ARGOCD_CREDS | jq -r .username)'
    'ARGOCD_PASSWORD=$(echo $ARGOCD_CREDS | jq -r .password)'
    'ARGOCD_SERVER=$(echo $ARGOCD_CREDS | jq -r .server)'
    'argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD'
    'argocd version'
    }
}

    }
}