pipeline {
    agent {
        label 'spot-agents'
    }
    environment {
        AWS_DEFAULT_REGION = 'eu-west-1'              
        AWS_ACCOUNT_ID     = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()           
        SONAR_TOKEN        = credentials('sonarcloud-token')          
        SONAR_PROJECT_KEY  = credentials('sonarcloud-project-key')    
        SONAR_ORGANIZATION = credentials('sonarcloud-organization')   
        IMAGE_REPO_NAME    = 'fastapi-app'
        IMAGE_TAG          = "${env.BUILD_NUMBER}"
        ECR_REGISTRY       = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
        IMAGE_URI          = "${ECR_REGISTRY}/${IMAGE_REPO_NAME}:${IMAGE_TAG}"
        DEPLOY_GIT_REPO    = credentials('deploy-manifests-repo-url')
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Quality Gauntlet: Secret Scanning (Gitleaks)') {
            steps {
                script {
                    echo "Running Gitleaks to detect hardcoded secrets..."
                    // Docker Out Of Docker (DooD) execution
                    def status = sh(script: 'docker run --rm -v ${WORKSPACE}:/path zricethezav/gitleaks:latest detect --source="/path" -v', returnStatus: true)
                    if (status != 0) {
                        currentBuild.result = 'FAILURE'
                        error('Gitleaks detected secrets! Failing the pipeline.')
                    }
                }
            }
        }

        stage('Quality Gauntlet: SAST (SonarCloud)') {
            steps {
                script {
                    echo "Running SonarCloud SAST..."
                    def scannerHome = tool 'sonar-scanner-8'

                    withSonarQubeEnv('SonarCloud') { 
                        sh '''
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.organization=${SONAR_ORGANIZATION} \
                            -Dsonar.sources=/backend/src
                        '''
                    }
                }
            }
        }

        stage('Quality Gauntlet: SCA (OWASP Dependency Check)') {
            steps {
                script {
                    echo "Running OWASP Dependency Check..."
                    def status = sh(script: 'docker run --rm -v ${WORKSPACE}:/src owasp/dependency-check --scan /src --format HTML --format JSON --out /src/reports', returnStatus: true)
                    // You could parse the JSON report to explicitly check for High/Critical if needed
                    if (status != 0) {
                        currentBuild.result = 'FAILURE'
                        error('OWASP Dependency-Check failed! Inspect reports/dependency-check-report.html')
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/dependency-check-report.html', allowEmptyArchive: true
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    echo "Building Docker Image..."
                    sh "docker build -t ${IMAGE_URI} ."
                }
            }
        }

        stage('Quality Gauntlet: Image Scan (Trivy)') {
            steps {
                script {
                    echo "Generating Trivy Report..."
                    // Run 1: Save the report (doesn't fail the build)
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${WORKSPACE}:/workspace aquasec/trivy image --format json --output /workspace/trivy-report.json ${IMAGE_URI}"

                    echo "Enforcing Trivy Quality Gate..."
                    // Run 2: Enforce the gate (fails the build if vulnerable)
                    def status = sh(script: "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_URI}", returnStatus: true)
                    if (status != 0) {
                        currentBuild.result = 'FAILURE'
                        error('Trivy detected HIGH or CRITICAL vulnerabilities in the image! Failing the pipeline.')
                    }
                }
            }
            post {
                always {
                    // Archive the JSON report for the lab deliverables
                    archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('Quality Gauntlet: SBOM Generation (Syft)') {
            steps {
                script {
                    echo "Generating SBOM with Syft..."
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/syft ${IMAGE_URI} -o cyclonedx-json > sbom.json"
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'sbom.json', allowEmptyArchive: true
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                script {
                    echo "Logging into Amazon ECR..."
                    sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    
                    echo "Pushing Image to ECR..."
                    sh "docker push ${IMAGE_URI}"
                }
            }
        }

        stage('Update Deploy Manifests Repository') {
            steps {
                script {
                    echo "Cloning Deployment Manifests Repository..."
                    
                    // Inject the GitHub Username and PAT into the shell environment securely
                    withCredentials([usernamePassword(credentialsId: 'deploy-git-credentials-id', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PAT')]) { 
                        sh '''
                            # Strip the 'https://' from the URL so we can inject the credentials
                            REPO_DOMAIN_PATH=$(echo $DEPLOY_GIT_REPO | sed 's~https://~~')
                            AUTH_REPO_URL="https://${GIT_USER}:${GIT_PAT}@${REPO_DOMAIN_PATH}"

                            # Clone using the authenticated URL
                            git clone $AUTH_REPO_URL deploy-manifests
                            cd deploy-manifests
                            
                            # READ from the template, substitute the placeholder, and GENERATE a fresh taskdef.json
                            sed "s|<IMAGE_URI_PLACEHOLDER>|${IMAGE_URI}|g" taskdef.template.json > taskdef.json
                            
                            git config --global user.email "jenkins@example.com"
                            git config --global user.name "Jenkins Pipeline"
                            
                            # Add both the template (if changed) and the newly generated taskdef.json
                            git add appspec.yaml taskdef.template.json taskdef.json
                            git commit -m "Deploy Build: ${BUILD_NUMBER}" || echo "No changes to commit"
                            
                            # Push directly to main using the authenticated URL
                            git push $AUTH_REPO_URL main
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}