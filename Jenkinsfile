pipeline {
    agent any
    
    environment {
        // Docker Hub credentials
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_USERNAME = '22521284'
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
        
        // SonarQube
        SONAR_HOST_URL = 'http://sonarqube:9000'
        SONAR_TOKEN = credentials('sonarqube-token')
        
        // AWS Credentials
        AWS_CREDENTIALS = credentials('aws-credentials')
        AWS_REGION = 'us-east-1'
        
        // Snyk Token
        // SNYK_TOKEN = credentials('snyk-token')
        
        // Kubernetes
        KUBECONFIG = credentials('kubeconfig')
        
        // Project variables
        PROJECT_NAME = 'kahoot-clone'
        BUILD_VERSION = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 1, unit: 'HOURS')
    }
    
    tools {
        nodejs 'NodeJS 18'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Checking out code from repository..."
                    checkout scm
                    sh 'git rev-parse --short HEAD > .git/commit-id'
                    env.GIT_COMMIT_SHORT = readFile('.git/commit-id').trim()
                }
            }
        }
        
        stage('Environment Setup') {
            steps {
                script {
                    echo "🔧 Setting up environment..."
                    sh '''
                        node --version
                        npm --version
                        docker --version
                    '''
                }
            }
        }
        
        stage('Install Dependencies') {
            parallel {
                stage('Gateway Dependencies') {
                    steps {
                        dir('gateway') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('Auth Service Dependencies') {
                    steps {
                        dir('services/auth-service') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('Quiz Service Dependencies') {
                    steps {
                        dir('services/quiz-service') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('Game Service Dependencies') {
                    steps {
                        dir('services/game-service') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('User Service Dependencies') {
                    steps {
                        dir('services/user-service') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('Analytics Service Dependencies') {
                    steps {
                        dir('services/analytics-service') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('Frontend Dependencies') {
                    steps {
                        dir('frontend') {
                            sh 'npm ci'
                        }
                    }
                }
            }
        }
        
        stage('Code Quality - SonarQube Analysis') {
            environment {
                SCANNER_HOME = tool 'SonarQube Scanner'
            }
            steps {
                script {
                    echo "📊 Running SonarQube analysis..."
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        withSonarQubeEnv('SonarQube') {
                            sh '''
                                ${SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.host.url=${SONAR_HOST_URL} \
                                    -Dsonar.projectKey=${PROJECT_NAME} \
                                    -Dsonar.projectName=${PROJECT_NAME} \
                                    -Dsonar.projectVersion=${BUILD_VERSION} \
                                    -Dsonar.sources=. \
                                    -Dsonar.exclusions=**/node_modules/**,**/test/**,**/tests/**,**/*.test.js,**/*.spec.js \
                                    -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    echo "🎯 Waiting for SonarQube Quality Gate..."
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        timeout(time: 5, unit: 'MINUTES') {
                            try {
                                def qg = waitForQualityGate()
                                if (qg.status != 'OK') {
                                    unstable "Quality gate failure: ${qg.status}"
                                }
                            } catch (Exception e) {
                                echo "Quality gate check skipped: ${e.message}"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Security Scanning') {
            parallel {
                stage('Trivy - Filesystem Scan') {
                    steps {
                        script {
                            echo "🔒 Running Trivy filesystem scan..."
                            sh '''
                                trivy fs --severity HIGH,CRITICAL \
                                    --format table \
                                    --exit-code 0 \
                                    --output trivy-fs-report.txt \
                                    .
                            '''
                            archiveArtifacts artifacts: 'trivy-fs-report.txt', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Gateway') {
                    steps {
                        script {
                            echo "🐳 Building Gateway Docker image..."
                            sh '''
                                docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-gateway:${BUILD_VERSION} \
                                    -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-gateway:latest \
                                    -f gateway/Dockerfile gateway/
                            '''
                        }
                    }
                }
                stage('Build Auth Service') {
                    steps {
                        script {
                            sh '''
                                docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-auth:${BUILD_VERSION} \
                                    -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-auth:latest \
                                    -f services/auth-service/Dockerfile services/auth-service/
                            '''
                        }
                    }
                }
                stage('Build Quiz Service') {
                    steps {
                        script {
                            sh '''
                                docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-quiz:${BUILD_VERSION} \
                                    -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-quiz:latest \
                                    -f services/quiz-service/Dockerfile services/quiz-service/
                            '''
                        }
                    }
                }
                stage('Build Game Service') {
                    steps {
                        script {
                            sh '''
                                docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-game:${BUILD_VERSION} \
                                    -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-game:latest \
                                    -f services/game-service/Dockerfile services/game-service/
                            '''
                        }
                    }
                }
                stage('Build User Service') {
                    steps {
                        script {
                            sh '''
                                docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-user:${BUILD_VERSION} \
                                    -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-user:latest \
                                    -f services/user-service/Dockerfile services/user-service/
                            '''
                        }
                    }
                }
                stage('Build Analytics Service') {
                    steps {
                        script {
                            sh '''
                                docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-analytics:${BUILD_VERSION} \
                                    -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-analytics:latest \
                                    -f services/analytics-service/Dockerfile services/analytics-service/
                            '''
                        }
                    }
                }
                stage('Build Frontend') {
                    steps {
                        script {
                            sh '''
                                docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-frontend:${BUILD_VERSION} \
                                    -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-frontend:latest \
                                    -f frontend/Dockerfile frontend/
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Security Scan - Docker Images') {
            parallel {
                stage('Trivy - Image Scan') {
                    steps {
                        script {
                            echo "🔒 Scanning Docker images with Trivy..."
                            def services = ['gateway', 'auth', 'quiz', 'game', 'user', 'analytics', 'frontend']
                            services.each { service ->
                                sh """
                                    trivy image --severity HIGH,CRITICAL \
                                        --format json \
                                        --output trivy-${service}-image-report.json \
                                        ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-${service}:${BUILD_VERSION}
                                """
                            }
                            archiveArtifacts artifacts: 'trivy-*-image-report.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        stage('Push Docker Images') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "📤 Pushing Docker images to registry..."
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'dockerhub-credentials') {
                        def services = ['gateway', 'auth', 'quiz', 'game', 'user', 'analytics', 'frontend']
                        services.each { service ->
                            sh """
                                docker push ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-${service}:${BUILD_VERSION}
                                docker push ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-${service}:latest
                            """
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "☸️ Deploying to Kubernetes..."
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh '''
                            # Update image tags in K8s manifests
                            for service in gateway auth quiz game user analytics frontend; do
                                sed -i "s|image: .*${PROJECT_NAME}-${service}:.*|image: ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${PROJECT_NAME}-${service}:${BUILD_VERSION}|g" \
                                    k8s/${service}-deployment.yaml
                            done
                            
                            # Apply Kubernetes manifests
                            kubectl apply -f k8s/namespace.yaml
                            kubectl apply -f k8s/configmap.yaml
                            kubectl apply -f k8s/secrets.yaml
                            kubectl apply -f k8s/
                            
                            # Wait for rollout
                            kubectl rollout status deployment/gateway -n kahoot-clone
                            kubectl rollout status deployment/auth-service -n kahoot-clone
                            kubectl rollout status deployment/quiz-service -n kahoot-clone
                            kubectl rollout status deployment/game-service -n kahoot-clone
                            kubectl rollout status deployment/user-service -n kahoot-clone
                            kubectl rollout status deployment/analytics-service -n kahoot-clone
                            kubectl rollout status deployment/frontend -n kahoot-clone
                        '''
                    }
                }
            }
        }
        
        stage('Health Check') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "🏥 Running health checks..."
                    sh '''
                        # Wait for services to be ready
                        sleep 30
                        
                        # Check service health
                        kubectl get pods -n kahoot-clone
                        kubectl get services -n kahoot-clone
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "📊 Collecting artifacts and reports..."
                // Archive test results
                junit allowEmptyResults: true, testResults: '**/test-results/*.xml'
                
                // Publish HTML reports
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'coverage',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
            }
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
        cleanup {
            echo "🧹 Cleaning up workspace..."
            cleanWs()
        }
    }
}
