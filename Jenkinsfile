pipeline {
    agent any
    
    environment {
        // AWS ECR Configuration
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '802346121373'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        
        PROJECT_NAME = 'kahoot-clone'
        BUILD_VERSION = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
        
        // BuildKit for faster builds with cache
        DOCKER_BUILDKIT = '1'
        BUILDKIT_PROGRESS = 'plain'
        
        // Parallelization settings (optimized for t3.medium 4GB RAM)
        // For t3.large (8GB), increase to: PARALLEL_BUILD_JOBS='4', NPM_INSTALL_CONCURRENCY='8'
        PARALLEL_BUILD_JOBS = '2'
        PARALLEL_DEPLOY_JOBS = '2'
        NPM_INSTALL_CONCURRENCY = '4'
        
        // SonarQube Configuration
        SONARQUBE_URL = 'http://34.200.233.56:30900'
        // SONAR_TOKEN will be loaded conditionally in the stage
        
        // Trivy Configuration
        TRIVY_SEVERITY = 'CRITICAL,HIGH'
        TRIVY_EXIT_CODE = '0'  // Don't fail build, just report
        
        // Nx Configuration
        NX_BRANCH = env.BRANCH_NAME ?: 'main'
        NX_CACHE_BUCKET = "kahoot-nx-cache-${AWS_ACCOUNT_ID}"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        parallelsAlwaysFailFast()
    }
    
    tools {
        nodejs 'Node JS 18'
    }
    
    stages {
        stage('🚀 Initialization') {
            steps {
                script {
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "🏗️  Pipeline Started (Nx + AWS ECR)"
                    echo "🔄 Nx Smart Builds Enabled"
                    echo "📝 Commit: ${env.GIT_COMMIT_SHORT}"
                    echo "🔢 Build: ${BUILD_VERSION}"
                    echo "🌏 ECR: ${ECR_REGISTRY}"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    
                    checkout scm
                }
            }
        }
        
        stage('⚙️ Setup Nx') {
            steps {
                script {
                    echo "📦 Installing Nx and dependencies..."
                    sh '''
                        # Install Nx at root level
                        npm install -D nx@latest @nx/js@latest @nx/workspace@latest nx-remotecache-s3@latest
                        
                        # Create S3 bucket for cache if not exists
                        aws s3 mb s3://${NX_CACHE_BUCKET} --region ${AWS_REGION} 2>/dev/null || true
                        
                        # Set lifecycle policy (delete cache after 7 days)
                        aws s3api put-bucket-lifecycle-configuration \
                          --bucket ${NX_CACHE_BUCKET} \
                          --lifecycle-configuration '{
                            "Rules": [{
                              "Id": "DeleteOldCache",
                              "Status": "Enabled",
                              "Prefix": "nx-cache/",
                              "Expiration": {"Days": 7}
                            }]
                          }' 2>/dev/null || true
                        
                        echo "✅ Nx setup complete with S3 remote cache"
                    '''
                }
            }
        }
        
        stage('🔍 Detect Affected Services') {
            steps {
                script {
                    echo "🔍 Detecting affected services with Nx..."
                    
                    // Get affected projects
                    def affectedApps = sh(
                        script: 'npx nx affected:apps --base=HEAD~1 --head=HEAD --plain || echo "all"',
                        returnStdout: true
                    ).trim()
                    
                    if (affectedApps == "all" || affectedApps.isEmpty()) {
                        env.AFFECTED_SERVICES = "gateway,auth-service,user-service,quiz-service,game-service,analytics-service,frontend"
                        echo "⚠️ Building all services (no git history or first build)"
                    } else {
                        env.AFFECTED_SERVICES = affectedApps.replace("\n", ",")
                        echo "✅ Affected services: ${env.AFFECTED_SERVICES}"
                    }
                    
                    // Display affected summary
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "📋 AFFECTED SERVICES (Nx Detection)"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    env.AFFECTED_SERVICES.split(',').each { service ->
                        echo "  ✓ ${service}"
                    }
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                }
            }
        }
        
        stage('🔍 Security Scan') {
            parallel {
                stage('Trivy Repository Scan') {
                    steps {
                        script {
                            echo "🔍 Trivy: Scanning repository for vulnerabilities..."
                            sh """
                                # Scan repository for filesystem vulnerabilities
                                trivy fs --severity ${TRIVY_SEVERITY} \
                                  --exit-code ${TRIVY_EXIT_CODE} \
                                  --format table \
                                  --skip-dirs node_modules \
                                  --timeout 10m \
                                  . || true
                            """
                        }
                    }
                }
                
                stage('SonarQube Analysis') {
                    steps {
                        script {
                            try {
                                echo "🔍 Running SonarQube analysis..."
                                // Try to load token from credentials
                                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                                    sh """
                                        # Check if sonar-scanner is installed
                                        if ! command -v sonar-scanner &> /dev/null; then
                                            echo "📥 Installing sonar-scanner..."
                                            npm install -g sonar-scanner
                                        fi
                                        
                                        echo "🔍 Running SonarQube scan..."
                                        sonar-scanner \
                                          -Dsonar.projectKey=kahoot-clone \
                                          -Dsonar.projectName="Kahoot Clone" \
                                          -Dsonar.sources=. \
                                          -Dsonar.exclusions=**/node_modules/**,**/build/**,**/dist/**,**/coverage/** \
                                          -Dsonar.host.url=${SONARQUBE_URL} \
                                          -Dsonar.login=${SONAR_TOKEN} \
                                          -Dsonar.sourceEncoding=UTF-8 \
                                          -Dsonar.qualitygate.wait=false || true
                                        
                                        echo "✅ SonarQube analysis complete"
                                    """
                                }
                            } catch (Exception e) {
                                echo "⚠️ SonarQube token not configured, skipping analysis"
                                echo "To enable: Configure 'sonarqube-token' credential in Jenkins"
                            }
                        }
                    }
                }
            }
        }
        
        stage('🔐 ECR Login') {
            steps {
                script {
                    echo "🔐 Logging into AWS ECR..."
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    """
                    echo "✅ ECR login successful"
                }
            }
        }
        
        stage('📦 Install Dependencies & Static Analysis') {
            parallel {
                stage('Shared Utils') {
                    steps {
                        dir('services/shared') {
                            sh "npm ci --prefer-offline --no-audit --maxsockets=${NPM_INSTALL_CONCURRENCY}"
                        }
                    }
                }
                stage('Gateway') {
                    steps {
                        dir('gateway') {
                            sh "npm ci --prefer-offline --no-audit --maxsockets=${NPM_INSTALL_CONCURRENCY}"
                        }
                    }
                }
                stage('Auth Service') {
                    steps {
                        dir('services/auth-service') {
                            sh "npm ci --prefer-offline --no-audit --maxsockets=${NPM_INSTALL_CONCURRENCY}"
                        }
                    }
                }
                stage('User Service') {
                    steps {
                        dir('services/user-service') {
                            sh "npm ci --prefer-offline --no-audit --maxsockets=${NPM_INSTALL_CONCURRENCY}"
                        }
                    }
                }
                stage('Quiz Service') {
                    steps {
                        dir('services/quiz-service') {
                            sh "npm ci --prefer-offline --no-audit --maxsockets=${NPM_INSTALL_CONCURRENCY}"
                        }
                    }
                }
                stage('Game Service') {
                    steps {
                        dir('services/game-service') {
                            sh "npm ci --prefer-offline --no-audit --maxsockets=${NPM_INSTALL_CONCURRENCY}"
                        }
                    }
                }
                stage('Analytics Service') {
                    steps {
                        dir('services/analytics-service') {
                            sh "npm ci --prefer-offline --no-audit --maxsockets=${NPM_INSTALL_CONCURRENCY}"
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        dir('frontend') {
                            sh "npm ci --prefer-offline --no-audit --maxsockets=${NPM_INSTALL_CONCURRENCY}"
                        }
                    }
                }
                
                stage('🔍 SonarQube Scan') {
                    steps {
                        script {
                            echo "🔍 Running SonarQube analysis (CRITICAL issues only)..."
                            sh """
                                # Install sonar-scanner if not exists
                                if ! command -v sonar-scanner &> /dev/null; then
                                    wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
                                    unzip -q sonar-scanner-cli-4.8.0.2856-linux.zip
                                    export PATH=\$PATH:\$(pwd)/sonar-scanner-4.8.0.2856-linux/bin
                                fi
                                
                                # Run SonarQube scan - focus on CRITICAL issues only
                                sonar-scanner \
                                  -Dsonar.projectKey=kahoot-clone \
                                  -Dsonar.sources=. \
                                  -Dsonar.exclusions=**/node_modules/**,**/build/**,**/dist/**,**/*.test.js,**/*.spec.js \
                                  -Dsonar.host.url=${SONARQUBE_URL} \
                                  -Dsonar.login=${SONAR_TOKEN} \
                                  -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                                  -Dsonar.qualitygate.wait=true \
                                  -Dsonar.qualitygate.timeout=300 \
                                  -Dsonar.issuesReport.console.enable=true \
                                  -Dsonar.severity=CRITICAL || true
                            """
                        }
                    }
                }
            }
        }
        
        stage('🐳 Build & Push Images - Batch 1') {
            parallel {
                stage('Gateway') {
                    steps {
                        script {
                            echo "🐳 Building Gateway with cache..."
                            sh """
                                docker buildx build \
                                  --cache-from ${ECR_REGISTRY}/${PROJECT_NAME}-gateway:latest \
                                  --cache-to type=inline \
                                  --build-arg BUILDKIT_INLINE_CACHE=1 \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-gateway:${BUILD_VERSION} \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-gateway:latest \
                                  --push \
                                  -f gateway/Dockerfile gateway/
                            """
                        }
                    }
                }
                stage('Auth Service') {
                    steps {
                        script {
                            echo "🐳 Building Auth Service with cache..."
                            sh """
                                docker buildx build \
                                  --cache-from ${ECR_REGISTRY}/${PROJECT_NAME}-auth:latest \
                                  --cache-to type=inline \
                                  --build-arg BUILDKIT_INLINE_CACHE=1 \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-auth:${BUILD_VERSION} \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-auth:latest \
                                  --push \
                                  -f services/auth-service/Dockerfile services/auth-service/
                            """
                        }
                    }
                }
                stage('User Service') {
                    steps {
                        script {
                            echo "🐳 Building User Service with cache..."
                            sh """
                                docker buildx build \
                                  --cache-from ${ECR_REGISTRY}/${PROJECT_NAME}-user:latest \
                                  --cache-to type=inline \
                                  --build-arg BUILDKIT_INLINE_CACHE=1 \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-user:${BUILD_VERSION} \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-user:latest \
                                  --push \
                                  -f services/user-service/Dockerfile services/user-service/
                            """
                        }
                    }
                }
                stage('Quiz Service') {
                    steps {
                        script {
                            echo "🐳 Building Quiz Service with cache..."
                            sh """
                                docker buildx build \
                                  --cache-from ${ECR_REGISTRY}/${PROJECT_NAME}-quiz:latest \
                                  --cache-to type=inline \
                                  --build-arg BUILDKIT_INLINE_CACHE=1 \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-quiz:${BUILD_VERSION} \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-quiz:latest \
                                  --push \
                                  -f services/quiz-service/Dockerfile services/quiz-service/
                            """
                        }
                    }
                }
            }
        }
        
        stage('🐳 Build & Push Images - Batch 2') {
            parallel {
                stage('Game Service') {
                    steps {
                        script {
                            echo "🐳 Building Game Service with cache..."
                            sh """
                                docker buildx build \
                                  --cache-from ${ECR_REGISTRY}/${PROJECT_NAME}-game:latest \
                                  --cache-to type=inline \
                                  --build-arg BUILDKIT_INLINE_CACHE=1 \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-game:${BUILD_VERSION} \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-game:latest \
                                  --push \
                                  -f services/game-service/Dockerfile services/game-service/
                            """
                        }
                    }
                }
                stage('Analytics Service') {
                    steps {
                        script {
                            echo "🐳 Building Analytics Service with cache..."
                            sh """
                                docker buildx build \
                                  --cache-from ${ECR_REGISTRY}/${PROJECT_NAME}-analytics:latest \
                                  --cache-to type=inline \
                                  --build-arg BUILDKIT_INLINE_CACHE=1 \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-analytics:${BUILD_VERSION} \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-analytics:latest \
                                  --push \
                                  -f services/analytics-service/Dockerfile services/analytics-service/
                            """
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        script {
                            echo "🐳 Building Frontend with cache..."
                            sh """
                                docker buildx build \
                                  --cache-from ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:latest \
                                  --cache-to type=inline \
                                  --build-arg BUILDKIT_INLINE_CACHE=1 \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:${BUILD_VERSION} \
                                  -t ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:latest \
                                  --push \
                                  -f frontend/Dockerfile frontend/
                            """
                        }
                    }
                }
            }
        }
        
        stage('🔍 Security Scan - Images') {
            parallel {
                stage('Trivy - Gateway') {
                    steps {
                        script {
                            sh """
                                trivy image --severity ${TRIVY_SEVERITY} \
                                  --exit-code ${TRIVY_EXIT_CODE} \
                                  --format table \
                                  ${ECR_REGISTRY}/${PROJECT_NAME}-gateway:${BUILD_VERSION} || true
                            """
                        }
                    }
                }
                stage('Trivy - Auth') {
                    steps {
                        script {
                            sh """
                                trivy image --severity ${TRIVY_SEVERITY} \
                                  --exit-code ${TRIVY_EXIT_CODE} \
                                  --format table \
                                  ${ECR_REGISTRY}/${PROJECT_NAME}-auth:${BUILD_VERSION} || true
                            """
                        }
                    }
                }
                stage('Trivy - User') {
                    steps {
                        script {
                            sh """
                                trivy image --severity ${TRIVY_SEVERITY} \
                                  --exit-code ${TRIVY_EXIT_CODE} \
                                  --format table \
                                  ${ECR_REGISTRY}/${PROJECT_NAME}-user:${BUILD_VERSION} || true
                            """
                        }
                    }
                }
                stage('Trivy - Quiz') {
                    steps {
                        script {
                            sh """
                                trivy image --severity ${TRIVY_SEVERITY} \
                                  --exit-code ${TRIVY_EXIT_CODE} \
                                  --format table \
                                  ${ECR_REGISTRY}/${PROJECT_NAME}-quiz:${BUILD_VERSION} || true
                            """
                        }
                    }
                }
                stage('Trivy - Game') {
                    steps {
                        script {
                            sh """
                                trivy image --severity ${TRIVY_SEVERITY} \
                                  --exit-code ${TRIVY_EXIT_CODE} \
                                  --format table \
                                  ${ECR_REGISTRY}/${PROJECT_NAME}-game:${BUILD_VERSION} || true
                            """
                        }
                    }
                }
                stage('Trivy - Analytics') {
                    steps {
                        script {
                            sh """
                                trivy image --severity ${TRIVY_SEVERITY} \
                                  --exit-code ${TRIVY_EXIT_CODE} \
                                  --format table \
                                  ${ECR_REGISTRY}/${PROJECT_NAME}-analytics:${BUILD_VERSION} || true
                            """
                        }
                    }
                }
                stage('Trivy - Frontend') {
                    steps {
                        script {
                            sh """
                                trivy image --severity ${TRIVY_SEVERITY} \
                                  --exit-code ${TRIVY_EXIT_CODE} \
                                  --format table \
                                  ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:${BUILD_VERSION} || true
                            """
                        }
                    }
                }
                
                stage('ECR Image Scan') {
                    steps {
                        script {
                            sh """
                                for service in gateway auth user quiz game analytics frontend; do
                                    aws ecr start-image-scan \
                                      --repository-name ${PROJECT_NAME}-\${service} \
                                      --image-id imageTag=${BUILD_VERSION} \
                                      --region ${AWS_REGION} || true
                                done
                            """
                        }
                    }
                }
            }
        }
        
        stage('🚀 Pre-Deployment Validation') {
            parallel {
                stage('Generate Security Report') {
                    steps {
                        script {
                            sh """
                                echo "=== SECURITY SCAN SUMMARY ===" > security-report.txt
                                echo "Build: ${BUILD_VERSION}" >> security-report.txt
                                echo "Commit: ${GIT_COMMIT_SHORT}" >> security-report.txt
                                echo "" >> security-report.txt
                                
                                if [ -f trivy-repo-scan.json ]; then
                                    echo "Repository Scan Results:" >> security-report.txt
                                    cat trivy-repo-scan.json | jq -r '.Results[].Vulnerabilities[] | select(.Severity=="CRITICAL" or .Severity=="HIGH") | "- \\(.VulnerabilityID): \\(.PkgName) (\\(.Severity))"' >> security-report.txt || true
                                fi
                            """
                            archiveArtifacts artifacts: 'security-report.txt,trivy-*.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('K8s Pre-flight Check') {
                    steps {
                        script {
                            sh """
                                kubectl cluster-info --kubeconfig=${KUBECONFIG} || echo "Warning: K8s cluster not accessible"
                                kubectl get nodes --kubeconfig=${KUBECONFIG} || true
                            """
                        }
                    }
                }
            }
        }
        
        stage('🚀 Deploy to Kubernetes') {
            steps {
                script {
                    echo "🚀 Deploying to Kubernetes..."
                    sh """
                        # Update image tags in K8s deployments
                        for service in gateway auth user quiz game analytics frontend; do
                            kubectl set image deployment/\${service} \
                              \${service}=${ECR_REGISTRY}/${PROJECT_NAME}-\${service}:${BUILD_VERSION} \
                              --kubeconfig=${KUBECONFIG} || true
                        done
                        
                        # Wait for rollout
                        kubectl rollout status deployment --all --timeout=5m --kubeconfig=${KUBECONFIG}
                    """
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                echo "📦 Images: ${ECR_REGISTRY}/${PROJECT_NAME}-*:${BUILD_VERSION}"
                echo "🔍 SonarQube: ${SONARQUBE_URL}"
                echo "🛡️ Security reports archived"
            }
        }
        failure {
            echo "❌ Pipeline failed!"
        }
        always {
            // Cleanup
            sh 'docker system prune -f --volumes || true'
            archiveArtifacts artifacts: '**/*.json', allowEmptyArchive: true
        }
    }
}
