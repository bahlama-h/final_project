pipeline {
    agent {
        docker {
            image 'bahmah2024/docker_image:latest' // Custom image with Docker and Terraform
            args '--privileged -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=""' // Ensure Docker configuration is accessible and override entrypoint
        }
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Git branch to build')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'sit'], description: 'Deployment environment')
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        AWS_CREDENTIALS = credentials('aws credentials')
        TELEGRAM_CHAT_ID = credentials('telegram-chat-id')
        VERSION = "1.0.${env.BUILD_ID}"
        IMAGE_NAME = "bahmah2024/browny-app"
        DOCKER_CONFIG = "${env.WORKSPACE}/.docker" // Custom Docker config directory within workspace
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Docker Buildx') {
            steps {
                script {
                    try {
                        // Create the custom Docker config directory within the workspace
                        sh 'mkdir -p $DOCKER_CONFIG'

                        // Set environment variables for Docker Buildx
                        sh 'export DOCKER_BUILDKIT=1'

                        // Create and use Buildx
                        sh 'docker buildx create --use'
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        error("Failed to setup Docker Buildx: ${e.message}")
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        docker.build("${env.IMAGE_NAME}:${env.VERSION}", "./microservice/browny-app")
                        docker.build("${env.IMAGE_NAME}:latest", "./microservice/browny-app")
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        error("Failed to build Docker image: ${e.message}")
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    try {
                        docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-credentials') {
                            docker.image("${env.IMAGE_NAME}:${env.VERSION}").push()
                            docker.image("${env.IMAGE_NAME}:latest").push()
                        }
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        error("Failed to push Docker image: ${e.message}")
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    script {
                        try {
                            sh 'terraform init'
                        } catch (Exception e) {
                            currentBuild.result = 'FAILURE'
                            error("Terraform init failed: ${e.message}")
                        }
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    script {
                        try {
                            sh "terraform plan -var-file=en_vars/${params.ENVIRONMENT}.tfvars -out=tfplan"
                        } catch (Exception e) {
                            currentBuild.result = 'FAILURE'
                            error("Terraform plan failed: ${e.message}")
                        }
                    }
                }
            }
        }

        stage('Approve Terraform Apply') {
            when { 
                expression { params.ENVIRONMENT == 'dev' }
            }
            steps {
                input "Deploy to Development?"
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    script {
                        try {
                            sh 'terraform apply -auto-approve tfplan'
                        } catch (Exception e) {
                            currentBuild.result = 'FAILURE'
                            error("Terraform apply failed: ${e.message}")
                        }
                    }
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                script {
                    try {
                        // Run the Docker container
                        sh 'docker run --rm -it ${env.IMAGE_NAME}:${env.VERSION} /bin/sh -c "echo Hello from the container!"'
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        error("Failed to run Docker container: ${e.message}")
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh 'docker system prune -f'
            }
        }
    }

    // post {
    //     success {
    //         script {
    //             try {
    //                 telegramSend(
    //                     message: "✅ *Jenkins Build Successful*\nJob: `${env.JOB_NAME}`\nBuild: `#${env.BUILD_NUMBER}`\nEnvironment: ${params.ENVIRONMENT}\n\nGood news! The Jenkins job has succeeded.",
    //                     chatId: env.TELEGRAM_CHAT_ID
    //                 )
    //             } catch (Exception e) {
    //                 echo "Failed to send success notification: ${e.message}"
    //             }
    //         }
    //     }
    //     failure {
    //         script {
    //             try {
    //                 telegramSend(
    //                     message: "❌ *Jenkins Build Failed*\nJob: `${env.JOB_NAME}`\nBuild: `#${env.BUILD_NUMBER}`\nEnvironment: ${params.ENVIRONMENT}\n\nUnfortunately, the Jenkins job has failed. Please check the Jenkins console for more details.",
    //                     chatId: env.TELEGRAM_CHAT_ID
    //                 )
    //             } catch (Exception e) {
    //                 echo "Failed to send failure notification: ${e.message}"
    //             }
    //         }
    //     }
    // }
}