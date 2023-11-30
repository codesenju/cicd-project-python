pipeline {
parameters {
    //string(name: 'ENV', defaultValue: 'dev', description: '')
    //string(name: 'IMAGE', defaultValue: 'codesenju/python-test', description: 'Docker image name')
    string(name: 'DOCKERHUB_CREDENTIAL_ID', defaultValue: 'dockerhub_credentials', description: '')
    string(name: 'DOCKER_REGISTRY', defaultValue: 'docker.io', description: 'Docker container registry')
    string(name: 'GITHUB_USERNAME', defaultValue: 'codesenju', description: 'Github username')
    string(name: 'GITHUB_CRDENTIAL_ID', defaultValue: 'github_pvt_key', description: 'Jenkins github credential id')
    //string(name: 'GITHUB_REPO', defaultValue: 'cicd-project-python', description: 'Repository name')
    //string(name: 'APP_NAME', defaultValue: 'cicd-project-python', description: 'Name of app ( same as GITHUB_REPO )')
    //string(name: 'K8S_MANIFESTS_REPO', defaultValue: 'cicd-project-k8s', description: 'Gitops k8s manifest repository name')
    string(name: 'CLUSTER_NAME', defaultValue: 'uat', description: 'EKS cluster name')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region')
    string(name: 'ARGOCD_CLUSTER_NAME', defaultValue: 'in-cluster', description: 'Argocd destination cluster name')
    string(name: 'APP_SONAR_TOKEN', defaultValue: 'petclinic_sonar_token', description: 'SonarQube application token')
    // choice(name: 'LANGUAGE',choices: ['Python', 'Java'],description: 'Select the language of the application to build')
}

  triggers {
    githubPush()
  }
 
    // agent {label 'k8s-agent'}
        agent {kubernetes {
        yaml '''
kind: "Pod"
spec:
  nodeSelector:
    karpenter.sh/provisioner-name: "jenkins-agent"
  serviceAccount: jenkins-agent-sa
  tolerations:
    - key: "dedicated-jenkins-agent"
      operator: "Equal"
      effect: "NoExecute"
  containers:
  - name: python
    image: python:3.9.18-bullseye
    command:
    - cat
    tty: true
  - name: "maven"
    image: "maven:3.9.4-eclipse-temurin-21-alpine"
    command:
    - cat
    tty: true
  - name: "jnlp"
    image: "codesenju/jenkins-inbound-agent:k8s"
    # env:
    #   - name: DOCKER_HOST # the docker daemon can be accessed on the standard port on localhost
    #   value: "127.0.0.1"
    securityContext: 
      runAsUser: 0
    volumeMounts:
    - mountPath: "/var/run/"
      name: "docker-socket"
  - name: "dind"
    # env:
    # - name: DOCKER_TLS_CERTDIR
    #   value: ""
    image: "docker:19.03.13-dind"
    securityContext:
      privileged: true  # the Docker daemon can only run in a privileged container
    volumeMounts:
    - name: "docker-socket"
      mountPath: "/var/run"
  volumes:
  - name: "docker-socket"
    emptyDir: {}
    '''
    } }
    //environment {
        /* Set environment variables */

    //}
    
stages {
 
// // SKIP IF USING JENKINS ORGANISATION FOLDERS
// stage('Checkout') {
//     steps {
//          script {
//                     def gitUrl = "git@github.com:${params.GITHUB_USERNAME}/${params.GITHUB_REPO}.git"
//                     def gitCredentialId = "${params.GITHUB_CRDENTIAL_ID}"
//                 checkout([
//                     $class: 'GitSCM',
//                     branches: [[name: '*/main']],
//                     doGenerateSubmoduleConfigurations: false,
//                     extensions: [[$class: 'ScmName', name:"${params.GITHUB_REPO}"], [$class: 'RelativeTargetDirectory', relativeTargetDir: 'app-directory']],
//                     submoduleCfg: [],
//                     userRemoteConfigs: [[
//                         credentialsId: gitCredentialId,
//                         url: gitUrl
//                     ]]
//                 ])
//        }
//     }
// } 
        stage('Read properties') {
            steps {
                script {
                    // Read properties file
                    def props = readProperties file: 'config.properties'

                    // Convert properties to environment variables
                    props.each { key, value ->
                        env."${key}" = "${value}"
                    }

                    // Send a message based on the language property
                    if (env.LANGUAGE == 'Python') {
                        echo "Detected ${env.LANGUAGE} App"
                    } else if (env.LANGUAGE == 'Java') {
                        echo "Detected ${env.LANGUAGE} App"
                    } else {
                        error "Unsupported language: ${env.LANGUAGE}"
                    }
               
                }
            }
        }

        stage('Parallel Tests') {
            parallel {
                stage('Quality Tests') {
                    steps {

                        script {
 
                            switch(env.LANGUAGE) {

                                case 'Python':

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
                                    /* Scan for IaC misconfigurations */
                                    sh "trivy fs --exit-code 0 --severity HIGH --no-progress --security-checks vuln,config ./ || true"
                                    sh "trivy fs --exit-code 1 --severity CRITICAL --no-progress --security-checks vuln,config ./ || true"

                                    break
                                case 'Java':

                                    container('maven'){
                                        withCredentials([string(credentialsId: params.APP_SONAR_TOKEN, variable: 'TOKEN')]) {
                                            sh '''
                                              mvn -DskipTests verify sonar:sonar \
                                              -Dsonar.projectKey=petclinic \
                                              -Dsonar.host.url=https://sonarqube.lmasu.co.za \
                                              -Dsonar.login=${TOKEN} \
                                              -Dsonar.qualitygate.wait=true
                                               '''
                                        }
                                    }
                                    
                                    break

                             }//switch-END
                     }//end-script
                    }
                } // end IaC
                stage('Unit Tests') {
                    steps {
                            script {

                              if (env.LANGUAGE == 'Python') {

                                  container('python'){
                                  sh '''
                                   pip install -r requirements.txt
                                   pytest
                                   '''
                                  }

                              } else if (env.LANGUAGE == 'Java') {

                                  container('maven'){
                                      sh '''
                                       mvn test
                                       '''
                                      }

                              }

                            }//script-end
                    }
                } // end Unit Test
                stage('Security Tests') {
                    steps {
                        script {

                            switch(env.LANGUAGE) {

                                case 'Python':
                                
                                    container('python'){
                                     sh '''
                                      pip install -r requirements.txt
                                      bandit web.py
                                      safety check -r requirements.txt
                                      '''
                                    }

                                    break

                                 case 'Java':

                                    container('maven'){
                                        sh '''
                                         mvn org.owasp:dependency-check-maven:check
                                         '''
                                    }

                                    break
                                    
                            }//switch-END

                        } //script-end
                    }//steps-end
                } // end Security Tests
            }//parallel-end
        } //Parallel Test END
        

        stage('Build, Scan and Push') {
            steps {
                    script {

                        env.GIT_COMMIT_ID = sh(script: 'git rev-parse --short HEAD',returnStdout: true).trim()
  
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
                              
                            
                          withCredentials([usernamePassword(credentialsId: params.DOCKERHUB_CREDENTIAL_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                              
                              sh '''
                              echo ${DOCKER_PASSWORD} | docker login --username ${DOCKER_USERNAME} --password-stdin ${DOCKER_REGISTRY}
                          
                              docker buildx create --use --name builder --buildkitd-flags '--allow-insecure-entitlement network.host'
  
                              docker buildx build --load \
                                                  --cache-to type=registry,ref=${DOCKER_REGISTRY}/${IMAGE}:cache \
                                                  --cache-from type=registry,ref=${DOCKER_REGISTRY}/${IMAGE}:cache \
                                                  -t ${DOCKER_REGISTRY}/${IMAGE}:${BUILD_NUMBER}-${GIT_COMMIT_ID} \
                                                  .
                              
                              # Scan image for vulnerabilities - NB! Trivy has rate limiting
                              # If you would like to scan the image using trivy on your host machine, you need to mount docker.sock
                              trivy image --exit-code 0 --severity HIGH --no-progress ${DOCKER_REGISTRY}/${IMAGE}:${BUILD_NUMBER}-${GIT_COMMIT_ID} || true
                              trivy image --exit-code 1 --severity CRITICAL --no-progress ${DOCKER_REGISTRY}/${IMAGE}:${BUILD_NUMBER}-${GIT_COMMIT_ID} || true
  
                              docker push ${DOCKER_REGISTRY}/${IMAGE}:${BUILD_NUMBER}-${GIT_COMMIT_ID}
                              '''
                            
                          }//end-withCredentials
  
                          // Create Artifacts which we can use if we want to continue our pipeline for other stages/pipelines
                          sh '''
                               printf '[{"app_name":"%s","image_name":"%s","image_tag":"%s"}]' "${APP_NAME}" "${DOCKER_REGISTRY}/${IMAGE}" "${BUILD_NUMBER}-${GIT_COMMIT_ID}" > build.json
                          '''
           
                   }//end-script
            }
        }
        
         stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build.json', fingerprint: true
            }
        }

stage('Deploy - DEV') {
    steps { 
        script {
          
            sh '''
              echo Install kubectl cli...
              curl -o /usr/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.4/2023-08-16/bin/linux/amd64/kubectl && chmod +x /usr/bin/kubectl
              kubectl version --short --client
              echo 'Install Argocd cli & Authenticate with Argocd Server...'
              curl -sLo /usr/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.7.2/argocd-linux-amd64 && chmod +x /usr/bin/argocd
              argocd version --client
              echo Install kustomize cli...
              curl -sLo /tmp/kustomize.tar.gz  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.0.3/kustomize_v5.0.3_linux_amd64.tar.gz
              tar xzvf /tmp/kustomize.tar.gz -C /usr/bin/ && chmod +x /usr/bin/kustomize && rm -rf /tmp/kustomize.tar.gz
              kustomize version
            '''
            sh 'aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}'
            // sh "kubectl cluster-info"
              
                    def gitUrl = "git@github.com:${params.GITHUB_USERNAME}/${params.K8S_MANIFESTS_REPO}.git"
                // Updating k8s repo with non gitSCM method to aviod non stop build triggers
                // Alternative to second SCM we will clone manually
                withCredentials([sshUserPrivateKey(credentialsId: params.GITHUB_CRDENTIAL_ID, keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                          export ENV=dev
                          eval `ssh-agent -s`
                          ssh-add $SSH_KEY
                          ssh -o StrictHostKeyChecking=no git@github.com || true
                          export TEMPDIR=$(mktemp -d)
                          cd $TEMPDIR    
                          git clone git@github.com:${GITHUB_USERNAME}/${K8S_MANIFESTS_REPO}.git
                          cd ${K8S_MANIFESTS_REPO}/${APP_NAME}/k8s/${ENV}
                          ls -la
                          git status
                          git remote -v
                          cat kustomization.yaml | head -n 13
                          kustomize edit set image KUSTOMIZE=${IMAGE}:${BUILD_NUMBER}-${GIT_COMMIT_ID}
                          cat kustomization.yaml | head -n 13
                          git config --global user.email "devops@jenkins-pipeline.com"
                          git config --global user.name "jenkins-k8s-agent"
                          git add kustomization.yaml
                          git commit -m "Updated ${APP_NAME} image to ${IMAGE}:${BUILD_NUMBER}-${GIT_COMMIT_ID}" || true
                          git status
                          git push origin HEAD:main
                       '''
                }//end-withCredentials
                //}//end-dir
             
           // Argocd Deployment - DEV
            sh 'echo "Authenticate with Argocd Server..."'
            def ARGOCD_CREDS = sh(script: 'aws secretsmanager get-secret-value --secret-id iac-my-argocd-secret --query SecretString --output text', returnStdout: true).trim()
             wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: ARGOCD_CREDS]]]) {  
                  withEnv(["SECRET=${ARGOCD_CREDS}"]){
                      
                       def ARGOCD_USERNAME = sh(script: 'echo $SECRET | jq -r .username',returnStdout: true).trim()
                       def ARGOCD_SERVER = sh(script: 'echo $SECRET | jq -r .server', returnStdout: true).trim()
                       def ARGOCD_PASSWORD = sh(script: 'echo $SECRET | jq -r .password',returnStdout: true).trim()
                       
                    // Masks argocd username, password and server
                    wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: ARGOCD_PASSWORD],[password: ARGOCD_USERNAME], [password: ARGOCD_SERVER]]]) {
                        withEnv(["USERNAME=${ARGOCD_USERNAME}", "PASSWORD=${ARGOCD_PASSWORD}","SERVER=${ARGOCD_SERVER}"]){
                           sh 'argocd login $SERVER --username $USERNAME --password $PASSWORD'
                               sh 'ls -la'
                               sh 'cat argocd.yaml'
                               // Assuming repo already added to argocd server
                            // Create argocd app if it doesn't exist already
                              def status = sh(script: 'argocd app get ${APP_NAME}', returnStatus: true)
                              if (status != 0) {
                                 sh 'echo Argocd app doesnt exist, creating app...'
                                 sh 'cat argocd.yaml | envsubst'
                                 sh 'cat argocd.yaml | envsubst | argocd app create --upsert -f -'
                               } else {
                                  echo 'Argocd app already exists.'
                               }
                               sh '''
                                 argocd app get ${APP_NAME} --refresh
                                 argocd app wait ${APP_NAME}
                                '''
                        }//end-withEnv
                    } //end-wrap
                  }//end-withEnv

             }//end-wrap

       }//end-script
    }//end-steps
}//end-stage-deploy
}//end-stages
}//end-pipeline