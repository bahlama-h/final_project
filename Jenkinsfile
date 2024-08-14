pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        AWS_CREDENTIALS = credentials('aws-credentials') // Replace 'aws-credentials' with your Jenkins Credentials ID
        VERSION = "1.0.${env.BUILD_ID}"
        IMAGE_NAME = "bahmah2024/browny-app"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/bahlama-h/final_project.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker buildx create --use'
                    sh """
                        docker buildx build --platform linux/amd64,linux/arm64 \\
                        -t ${env.IMAGE_NAME}:${env.VERSION} \\
                        --push \\
                        ./microservice/browny-app
                    """
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
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials', // Your AWS Credentials ID
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('Terraform_final') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials', // Your AWS Credentials ID
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh 'terraform plan -var-file=en_vars/dev.tfvars'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('Terraform_final') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials', // Your AWS Credentials ID
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh 'terraform apply -var-file=en_vars/dev.tfvars -auto-approve'
                    }
                }
            }
        }
    }

    post {
        success {
            emailext(
                to: 'bah260619@gmail.com',
                subject: "SUCCESS: Job '${env.JOB_NAME}' (${env.BUILD_NUMBER})",
                body: "Good news! The job '${env.JOB_NAME}' completed successfully. \n\nBuild details: ${env.BUILD_URL}"
            )
        }
        failure {
            emailext(
                to: 'bah260619@gmail.com',
                subject: "FAILURE: Job '${env.JOB_NAME}' (${env.BUILD_NUMBER})",
                body: "Unfortunately, the job '${env.JOB_NAME}' failed. \n\nBuild details: ${env.BUILD_URL}"
            )
        }
        always {
            emailext(
                to: 'bah260619@gmail.com',
                subject: "Notification: Job '${env.JOB_NAME}' (${env.BUILD_NUMBER})",
                body: "The job '${env.JOB_NAME}' has finished with the status: ${currentBuild.currentResult}. \n\nBuild details: ${env.BUILD_URL}"
            )
        }
    }
}
