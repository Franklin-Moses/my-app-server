
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
        DOCKERHUB_USER = 'franklinmoses07'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def rawBranch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: env.GIT_LOCAL_BRANCH ?: ''
                    def branchName = rawBranch.substring(rawBranch.lastIndexOf('/') + 1)

                    if (!branchName) {
                        error('Unable to determine source branch from Jenkins environment.')
                    }

                    echo "Detected Git branch: ${branchName}"

                    if (branchName in ['main', 'master']) {
                        env.IMAGE_REPO = 'franklinmoses07/prod'
                    } else if (branchName == 'dev') {
                        env.IMAGE_REPO = 'franklinmoses07/dev'
                    } else {
                        error("Unsupported branch '${branchName}'. Expected dev, main, or master.")
                    }

                    env.SELECTED_BRANCH = branchName
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}"
                }

                sh 'docker build -t "$IMAGE_REPO:$IMAGE_TAG" -t "$IMAGE_REPO:latest" .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DH_USER',
                        passwordVariable: 'DH_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
                        docker push "$IMAGE_REPO:$IMAGE_TAG"
                        docker push "$IMAGE_REPO:latest"
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { env.SELECTED_BRANCH == 'dev' }
            }
            steps {
                sh '''
                    set -eu
                    docker pull "$IMAGE_REPO:$IMAGE_TAG"
                    docker rm -f my-app-server-app || true
                    docker run -d \
                        --name my-app-server-app \
                        --restart unless-stopped \
                        -p 80:80 \
                        "$IMAGE_REPO:$IMAGE_TAG"
                    for i in $(seq 1 20); do if curl --silent --show-error --fail --max-time 5 http://127.0.0.1/; then exit 0; fi; echo "Waiting for application HTTP response..."; sleep 3; done; echo "Health check failed after retries"; exit 1
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished. Check the stage results above.'
        }
    }
}


