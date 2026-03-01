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
                // Capture the Jenkins agent container ID for DooD --volumes-from usage
                script {
                    env.AGENT_CONTAINER_ID = sh(script: 'cat /etc/hostname', returnStdout: true).trim()
                }
            }
        }

        stage('Quality Gauntlet: Secret Scanning (Gitleaks)') {
            steps {
                script {
                    echo "Running Gitleaks to detect hardcoded secrets..."
                    // DooD: Use --volumes-from to share the agent container's filesystem
                    def status = sh(script: "docker run --rm --volumes-from ${AGENT_CONTAINER_ID} -w ${WORKSPACE} zricethezav/gitleaks:latest detect --source=${WORKSPACE} --no-git -v", returnStatus: true)
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
                    // Updated to match your Jenkins UI tool name
                    def scannerHome = tool 'sonar-scanner'

                    withSonarQubeEnv('SonarCloud') { 
                        // Updated to triple-double quotes (""") so Groovy actually reads ${scannerHome}
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.organization=${SONAR_ORGANIZATION} \
                            -Dsonar.sources=./backend/src
                        """
                    }
                }
            }
        }

        stage('Quality Gauntlet: SCA (Trivy FS)') {
            steps {
                script {
                    echo "Running Trivy Filesystem SCA Scan on Python dependencies..."
                    // DooD: Use --volumes-from to share the agent container's filesystem

                    // Run 1: Generate the SCA report
                    sh "docker run --rm --volumes-from ${AGENT_CONTAINER_ID} -w ${WORKSPACE} aquasec/trivy fs --format json --output ${WORKSPACE}/sca-report.json ${WORKSPACE}/backend"

                    // Run 2: Enforce the Quality Gate
                    def status = sh(script: "docker run --rm --volumes-from ${AGENT_CONTAINER_ID} -w ${WORKSPACE} aquasec/trivy fs --exit-code 1 --severity HIGH,CRITICAL ${WORKSPACE}/backend", returnStatus: true)

                    if (status != 0) {
                        currentBuild.result = 'FAILURE'
                        error('Trivy SCA detected HIGH or CRITICAL vulnerabilities in your Python packages!')
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'sca-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    echo "Building Docker Image..."
                    sh "docker build -t ${IMAGE_URI} ./backend"
                }
            }
        }

        stage('Quality Gauntlet: Image Scan (Trivy)') {
            steps {
                script {
                    echo "Generating Trivy Report..."
                    // DooD: --volumes-from inherits both the workspace AND the docker.sock mount
                    // Run 1: Save the report (doesn't fail the build)
                    sh "docker run --rm --volumes-from ${AGENT_CONTAINER_ID} -w ${WORKSPACE} aquasec/trivy image --ignorefile ${WORKSPACE}/backend/.trivyignore --format json --output ${WORKSPACE}/trivy-report.json ${IMAGE_URI}"

                    echo "Enforcing Trivy Quality Gate..."
                    // Run 2: Enforce the gate (fails the build if vulnerable)
                    def status = sh(script: "docker run --rm --volumes-from ${AGENT_CONTAINER_ID} aquasec/trivy image --ignorefile ${WORKSPACE}/backend/.trivyignore --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_URI}", returnStatus: true)
                    if (status != 0) {
                        currentBuild.result = 'FAILURE'
                        error('Trivy detected HIGH or CRITICAL vulnerabilities in the image! Failing the pipeline.')
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('Quality Gauntlet: SBOM Generation (Syft)') {
            steps {
                script {
                    echo "Generating SBOM with Syft..."
                    // DooD: --volumes-from inherits the docker.sock mount from the agent container
                    sh "docker run --rm --volumes-from ${AGENT_CONTAINER_ID} -w ${WORKSPACE} anchore/syft ${IMAGE_URI} -o cyclonedx-json > ${WORKSPACE}/sbom.json"
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
                        // Fetch Source Git context for a professional commit message
                        def rawCommitMsg = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
                        // Ensure we escape double quotes for the shell command below, taking only the first line of the original commit msg
                        def commitHeader = rawCommitMsg.split('\n')[0].replace('\"', '\\\"') 
                        def commitHash = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                        def authorName = sh(script: "git show -s --format='%an'", returnStdout: true).trim()

                        sh """
                            # Strip the 'https://' from the URL so we can inject the credentials
                            REPO_DOMAIN_PATH=\$(echo \${DEPLOY_GIT_REPO} | sed 's~https://~~')
                            AUTH_REPO_URL="https://\${GIT_USER}:\${GIT_PAT}@\${REPO_DOMAIN_PATH}"

                            # Clone using the authenticated URL
                            git clone \${AUTH_REPO_URL} deploy-manifests
                            cd deploy-manifests
                            
                            # READ from the template, substitute the placeholder, and GENERATE a fresh taskdef.json
                            sed "s|<IMAGE_URI_PLACEHOLDER>|${IMAGE_URI}|g" taskdef.template.json > taskdef.json
                            
                            git config --global user.email "jenkins@example.com"
                            git config --global user.name "Jenkins Pipeline"
                            
                            # Add both the template (if changed) and the newly generated taskdef.json
                            git add appspec.yaml taskdef.template.json taskdef.json
                            
                            # Construct professional commit message
                            COMMIT_MESSAGE="build(deploy): update ECS task definition for AuraScale
                            
                            Triggered by CI Pipeline Build #${BUILD_NUMBER}
                            
                            Source Control Details:
                            - Commit Hash: ${commitHash}
                            - Commit Message: ${commitHeader}
                            - Author: ${authorName}
                            
                            Jenkins Job: ${env.BUILD_URL}
                            Docker Image: ${IMAGE_URI}"
                            
                            git commit -m "\${COMMIT_MESSAGE}" || echo "No changes to commit"
                            
                            # Push directly to main using the authenticated URL
                            git push \${AUTH_REPO_URL} main
                        """
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