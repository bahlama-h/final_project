pipeline {
    agent {
        // Using a Docker agent with Docker installed
        docker {
            image 'docker:27.1.1' // Replace with a Docker image that has Docker installed if needed
            args '--privileged' // Allows the Docker container to run in a privileged mode, which is needed for Docker-in-Docker
        }
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        AWS_CREDENTIALS = credentials('aws-credentials')
        VERSION = "1.0.${env.BUILD_ID}"
        IMAGE_NAME = "bahmah2024/browny-app"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/bahlama-h/final_project.git', branch: 'main'
            }
        }

        stage('Setup Docker Buildx') {
            steps {
                script {
                    sh 'docker buildx create --use'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${env.IMAGE_NAME}:${env.VERSION}", "./microservice/browny-app")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-credentials') {
                        docker.image("${env.IMAGE_NAME}:${env.VERSION}").push()
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('Terraform_final') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('Terraform_final') {
                    sh 'terraform plan -var-file=en_vars/dev.tfvars'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('Terraform_final') {
                    sh 'terraform apply -var-file=en_vars/dev.tfvars -auto-approve'
                }
            }
        }
    }

    post {
        success {
            mail to: 'bah260619@gmail.com',
                 subject: "Jenkins Build Successful: ${env.JOB_NAME} ${env.BUILD_NUMBER}",
                 body: "Good news! The Jenkins job ${env.JOB_NAME} build number ${env.BUILD_NUMBER} has succeeded."
        }
        failure {
            mail to: 'bah260619@gmail.com',
                 subject: "Jenkins Build Failed: ${env.JOB_NAME} ${env.BUILD_NUMBER}",
                 body: "Unfortunately, the Jenkins job ${env.JOB_NAME} build number ${env.BUILD_NUMBER} has failed. Please check the Jenkins console for more details."
        }
    }
}
