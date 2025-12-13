pipeline {
    agent any

    environment {
        // Replace 'yourusername' with your actual Docker Hub username
        DOCKER_HUB_USERNAME = 'yourusername'
        IMAGE_NAME = "${DOCKER_HUB_USERNAME}/weather-dashboard"
        IMAGE_TAG = "${BUILD_NUMBER}"

        // Pi connection details
        PI_HOST = 'rosenpi.local'  // or use '100.116.66.117'
        PI_USER = 'kevin'

        // Deployment details
        CONTAINER_NAME = 'weather-dashboard'
        HOST_PORT = '3000'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image for ARM64 (Raspberry Pi)...'
                sh '''
                    # Create buildx builder if it doesn't exist
                    docker buildx create --use --name pibuilder || true

                    # Build for ARM64 architecture
                    docker buildx build \
                        --platform linux/arm64 \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest \
                        --load \
                        .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub...'
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${IMAGE_NAME}:latest
                            docker logout
                        '''
                    }
                }
            }
        }

        stage('Deploy to rosenpi') {
            steps {
                echo 'Deploying to Raspberry Pi...'
                sshagent(['rosenpi-ssh']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${PI_USER}@${PI_HOST} << 'ENDSSH'
                            # Pull the latest image from Docker Hub
                            docker pull ${IMAGE_NAME}:latest

                            # Stop and remove existing container if it exists
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            # Run the new container
                            docker run -d \
                                --name ${CONTAINER_NAME} \
                                --restart unless-stopped \
                                -p ${HOST_PORT}:80 \
                                ${IMAGE_NAME}:latest

                            # Verify it's running
                            docker ps | grep ${CONTAINER_NAME}

                            # Clean up old/unused images
                            docker image prune -f
ENDSSH
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "============================================"
            echo "SUCCESS! Deployment complete."
            echo "Access your app at: http://${PI_HOST}:${HOST_PORT}"
            echo "============================================"
        }
        failure {
            echo "============================================"
            echo "FAILED! Check the logs above for errors."
            echo "============================================"
        }
        always {
            // Clean up local Docker images to save space
            sh 'docker image prune -f || true'
        }
    }
}
