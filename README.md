# Project Overview

This repository contains a simple Flask web application (with HTML templates and static assets) that connects to a MySQL database on Amazon RDS. The app is containerized with Docker and deployed to AWS ECS. A Jenkins CI/CD pipeline automates the workflow: on code commit, Jenkins builds the Flask app into a Docker image, pushes it to Amazon ECR, and then runs `terraform apply` to update the ECS service to use the new image. AWS Secrets Manager and Systems Manager Parameter Store are used to manage configuration and database credentials securely. This project includes all application code and Terraform infrastructure as code; it assumes you have an AWS account and a Jenkins server ready to run the pipeline.

## Architecture

The high-level architecture uses several AWS services. The Flask app runs in containers on **Amazon ECS** (Fargate or EC2-backed, as defined by the Terraform config). The application connects to an **Amazon RDS** MySQL database for persistent storage. Docker images are stored in **Amazon ECR**. Jenkins orchestrates the CI/CD pipeline: it pulls the latest code, builds the Docker image, pushes to ECR, and then updates the ECS service. This mirrors typical AWS deployment patterns – e.g. using ECS for containers and RDS for managed databases. The Terraform templates in this repo define the VPC, ECS cluster/service, RDS instance, and related resources so that running `terraform apply` can provision or update the infrastructure.

- **Jenkins CI/CD:** On each commit (or manual trigger), Jenkins runs the pipeline defined in `Jenkinsfile`. It builds the Docker image and pushes it to ECR, then applies Terraform to roll out the new image.  
- **AWS Infrastructure:** The ECS service runs the Flask container. The RDS instance hosts the MySQL database. AWS Systems Manager and Secrets Manager hold the configuration and secrets (see below).  
- **Networking & Security:** Security groups and IAM roles (defined in Terraform) ensure that only the ECS tasks can connect to the RDS database. Load balancer and subnet configurations (if included in Terraform) handle external traffic.  

## Prerequisites

- **AWS Account & Permissions:** You need an AWS account with sufficient IAM permissions to create/modify ECS, ECR, RDS, Secrets Manager, Parameter Store, and related resources.  
- **Jenkins Setup:** A Jenkins server (or EC2 instance) with Docker and AWS CLI installed. The Jenkins user should have access to Docker and the AWS CLI. Jenkins should have credentials configured for an AWS IAM user or role with rights to push to ECR and update ECS/RDS.  
- **Terraform:** The Terraform CLI should be installed on the Jenkins machine (or where the pipeline runs Terraform). The `main.tf` file in this repo defines all necessary AWS resources.  
- **Repository:** Clone this GitHub repository or point your Jenkins job to this repo’s URL.  
- **Secrets/Parameters:** Prepare an AWS Secrets Manager secret for your RDS credentials and Parameter Store entries for any non-sensitive config.  

## Usage Instructions

1. **Connect Jenkins to this Repo:** Create a Jenkins Pipeline job (or use Multibranch Pipeline) that points to this Git repository.  
2. **Configure AWS Credentials:** Add AWS credentials to Jenkins global credentials.  
3. **Pipeline Trigger:** Set up a trigger or run the job manually. Jenkins executes the `Jenkinsfile`.  
4. **Build & Push Docker Image:** Jenkins builds and pushes the image to ECR.  
5. **Run Terraform:** Jenkins runs `terraform apply` to update the ECS task definition.  
6. **Verify Deployment:** Check the ECS service in the AWS console or view the app endpoint.  

> **Note:** Adjust Jenkinsfile or Terraform variables if your setup differs.

## Secrets Management

- **AWS Secrets Manager:** Store sensitive data like MySQL username/password here. ECS tasks or app code retrieve these at runtime.  
- **AWS Systems Manager (Parameter Store):** Store non-sensitive config such as hostnames. Tasks can reference these values by name.

## Terraform Notes

The `main.tf` file provisions:

- **Networking:** VPC, subnets, security groups, IAM roles.  
- **RDS Instance:** MySQL database instance.  
- **ECS Cluster & Service:** Cluster, task definition, service for the Flask container.  
- **ECR:** ECR repository (or expects one to exist).  

Modify as needed before running `terraform init`, `plan`, and `apply`.

## License

This project is provided under the **MIT License**.
