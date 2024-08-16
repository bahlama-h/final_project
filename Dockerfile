# Use the official Docker image as the base
FROM docker:24.0.6

# Set the Terraform version as a variable for easy updates
ARG TERRAFORM_VERSION=1.9.4

# Install necessary packages and Terraform
RUN apk add --no-cache wget unzip \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Verify installation
RUN terraform --version

# Set the default working directory
WORKDIR /workspace