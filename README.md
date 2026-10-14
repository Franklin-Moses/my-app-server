DevOps CI/CD Pipeline for React Application
1. Project Overview
This project demonstrates the end-to-end deployment of a React application using Docker, Docker Compose, Bash scripting, GitHub, Docker Hub, Jenkins, AWS EC2, and an open-source monitoring solution.
The objective is to automate application building, container image publishing, and deployment while maintaining separate development and production image repositories.
Application Repository: https://github.com/sriram-R-krishnan/devops-build
Forked Repository : https://github.com/Franklin-Moses/my-app-server.git
Project Objectives
•	Deploy the application over HTTP on port 80.
•	Containerize the application using Docker.
•	Use Docker Compose to manage the application container.
•	Automate image building and deployment using Bash scripts.
•	Maintain source code in GitHub using dev and master branches.
•	Publish development images to the public Docker Hub dev repository.
•	Publish production images to the private Docker Hub prod repository.
•	Implement Jenkins-based CI/CD with automatic GitHub build triggers.
•	Deploy the application on an AWS EC2 t2.micro instance.
•	Configure security groups to allow public application access and restrict SSH access to the developer's IP address.
•	Monitor application availability and configure notifications for application downtime.
2. Tools and Technologies
Technology	Purpose
React	Frontend application
Git and GitHub	Version control and source code management
Docker	Application containerization
Docker Compose	Container lifecycle management
Bash	Build and deployment automation
Docker Hub	Container image registry
Jenkins	CI/CD pipeline automation
AWS EC2	Application hosting
AWS Security Groups	Network access control
Uptime Kuma	Application availability monitoring
HTTP	Application access on port 80

3. Application Setup
Clone the application repository and enter the project directory.
git clone https://github.com/sriram-R-krishnan/devops-build.git
cd devops-build
Inspect the repository and identify the application framework, package manager, build command, and production output directory.
Install the application dependencies and build the React application according to the instructions in the repository.
For an npm-based project, the commands may be:
npm install
npm run build
The exact build output directory depends on the application configuration. The Dockerfile must copy the correct production build output.

4. Dockerization
Create a Dockerfile in the application root directory.
For a React application that generates a static production build, an Nginx-based image can serve the application over HTTP.
Example Dockerfile for a project whose build output is dist/:
FROM nginx:alpine

COPY dist/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
If the application generates a build/ directory instead, update the COPY instruction accordingly.
Build the Docker image
docker build -t devops-build:latest .
Test the application locally
docker run -d \
  --name devops-build-test \
  -p 8080:80 \
  devops-build:latest
Open the following URL in a browser:
http://localhost:8080
Verify that the application loads correctly.
Check the container status:
docker ps
docker logs devops-build-test
Remove the test container when finished:
docker rm -f devops-build-test

5. Docker Compose
Create a docker-compose.yml file to manage the application container.
services:
  web:
    image: ${APP_IMAGE:-devops-build:latest}
    container_name: devops-build-app
    ports:
      - "80:80"
    restart: unless-stopped
This configuration publishes the application on host port 80 and restarts the container unless it has been explicitly stopped.
Start the application:
docker compose up -d
Check the running services:
docker compose ps
docker compose logs
Stop the application when required:
docker compose down

6. Bash Automation Scripts
Create two scripts in the project root: build.sh and deploy.sh.
6.1 build.sh
This script builds the application image and tags it for the selected environment.
#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="my-app-server"
IMAGE_TAG="${1:-dev}"

echo "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
echo "Build completed successfully: ${IMAGE_NAME}:${IMAGE_TAG}"

6.2 deploy.sh
This script deploys the selected image to a target server over SSH. It assumes Docker and Docker Compose are already installed on the server and that SSH authentication is configured.

#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="my-app-server"
IMAGE_TAG="${1:-dev}"
CONTAINER_NAME="my-app-server-deploy"
HOST_PORT="${2:-80}"

echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} on port ${HOST_PORT}..."

if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
    echo "Error: image ${IMAGE_NAME}:${IMAGE_TAG} was not found locally."
    exit 1
fi

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${HOST_PORT}:80" \
    "${IMAGE_NAME}:${IMAGE_TAG}"

echo "Deployment completed: http://localhost:${HOST_PORT}"

Before using the script:
•	Confirm the EC2 operating system and SSH username.
•	Install Docker and the Docker Compose plugin on the target server.
•	Configure SSH access using a private key with appropriate permissions.
•	Ensure the server can authenticate to Docker Hub when pulling a private production image.
•	Restrict access to deployment credentials and avoid printing secrets in logs.
Example deployment:
export SERVER="YOUR_EC2_PUBLIC_IP"
export SSH_USER="ubuntu"
export SSH_KEY="$HOME/.ssh/your-ec2-key.pem"
export APP_IMAGE="YOUR_DOCKERHUB_USERNAME/dev:latest"

bash deploy.sh
The deployment script transfers the Compose file and starts the selected image. Jenkins should invoke it with the correct image for the relevant branch.

7. GitHub Version Control
The source code is maintained in GitHub. The dev branch is used for development, and master is used for production releases.
Create the required ignore files
Create .dockerignore:
.git
.github
node_modules
npm-debug.log*
.env
.env.*
!.env.example
coverage
Add other generated build directories or files as appropriate for the application. Do not exclude the production build directory if the Dockerfile needs it.
Create .gitignore:
node_modules/
dist/
build/
coverage/
.env
.env.*
!.env.example
*.log
.DS_Store
Do not commit passwords, access keys, private SSH keys, or other secrets.
Configure the development branch using Git CLI
git status
git switch -c dev
git add .
git commit -m "Add Docker and CI/CD project configuration"
git push -u origin dev
If the dev branch already exists, use git switch dev instead of creating it again.
After development testing, merge dev into master through the project's approved merge process. The production pipeline must run only after the merge reaches master.
Use Git CLI for all Git operations, including creating branches, committing changes, pushing code, and merging branches.

8. Docker Hub Configuration
Create two repositories under your Docker Hub account.
Repository	Visibility	Purpose
YOUR_DOCKERHUB_USERNAME/dev	Public	Development images
YOUR_DOCKERHUB_USERNAME/prod	Private	Production images
Replace YOUR_DOCKERHUB_USERNAME with your actual Docker Hub username.
Development image workflow
For code pushed to the dev branch:
1.	Jenkins checks out the latest development code.
2.	Jenkins builds the Docker image.
3.	Jenkins tags the image for the dev repository.
4.	Jenkins pushes the image to Docker Hub.
5.	Jenkins deploys the development image if the deployment stage is enabled.
Example image:
YOUR_DOCKERHUB_USERNAME/dev:latest
Production image workflow
When development changes are merged into master:
1.	Jenkins checks out master.
2.	Jenkins builds the production image.
3.	Jenkins tags the image for the private prod repository.
4.	Jenkins authenticates using stored production registry credentials.
5.	Jenkins pushes the image to the private repository.
6.	Jenkins deploys the production image to the target environment.
Example image:
YOUR_DOCKERHUB_USERNAME/prod:latest
For traceability, use an additional immutable build tag such as the Git commit SHA. Avoid relying on latest alone for production releases.
9. Jenkins CI/CD Pipeline
Install and configure Jenkins on the designated build server.
Prerequisites
•	Jenkins with a compatible Java runtime.
•	Git.
•	Docker Engine or another supported Docker build environment.
•	Required Docker and Git integrations.
•	GitHub integration and Pipeline support.
•	SSH access to the deployment server.
•	Docker Hub credentials configured in Jenkins Credentials.
Install only the plugins needed for the selected pipeline design.
GitHub integration
Configure the Jenkins job to use:
https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY.git
Configure branch discovery and build triggers for both dev and master.
Set up the GitHub webhook to notify Jenkins of pushes. The Jenkins endpoint and webhook configuration must match the actual Jenkins deployment.
Verify that:
•	A push to dev triggers a build.
•	A push or merge to master triggers a build.
•	Credentials are not stored directly in the Jenkinsfile.
•	The build logs show the checked-out branch and commit.
Pipeline behavior
Git branch	Docker Hub destination	Expected action
dev	Public dev repository	Build, push, and deploy development image
master	Private prod repository	Build, push, and deploy production image
Use a declarative Jenkinsfile with separate stages for checkout, build, image tagging, registry login, image push, and deployment.
The pipeline should select the destination repository from the checked-out branch and fail safely for unsupported branches.
Use Jenkins Credentials bindings for Docker Hub credentials and SSH keys. Never hardcode passwords or private keys in the Jenkinsfile.
For production, consider requiring a successful development build and an approved merge before publishing or deploying the production image.
10. AWS EC2 Deployment
Launch an EC2 instance using the t2.micro instance type, subject to regional availability and account eligibility.
Configure the instance with a supported Linux operating system and install Docker and Docker Compose.
Security Group Configuration
Configure the inbound rules as follows:
Type	Protocol	Port	Source	Purpose
HTTP	TCP	80	0.0.0.0/0	Public application access
SSH	TCP	22	YOUR_PUBLIC_IP/32	Restricted administrative access
The application is intended to be accessible to anyone over HTTP. SSH must be restricted to the developer's current public IP address.
Do not open SSH to 0.0.0.0/0.
If Jenkins is hosted on a separate server, configure the necessary deployment connectivity without exposing unnecessary management ports publicly.
Deployment validation
After deployment, open:
http://YOUR_EC2_PUBLIC_IP
Confirm that the application loads successfully.
On the EC2 instance, run:
docker ps
docker compose ps
docker compose logs
Also verify that the application responds over HTTP:
curl -I http://localhost
A successful HTTP response and a running container provide evidence that the application is deployed. Record the public IP or DNS name used for the submission.
11. Application Monitoring and Notifications
Use Uptime Kuma, an open-source availability-monitoring tool, to monitor the deployed application.
Configure an HTTP monitor for:
http://YOUR_EC2_PUBLIC_IP/
Set a suitable monitoring interval and timeout. Where possible, use an expected HTTP status or response-content check to detect failures that return an HTTP response but do not serve the intended application.
Monitoring configuration
1.	Install Uptime Kuma using a supported deployment method.
2.	Create an HTTP(s) monitor for the application endpoint.
3.	Verify that the monitor reports the application as UP.
4.	Configure an available notification provider, such as email or a supported messaging integration.
5.	Enable notifications for DOWN events.
6.	Disable recovery notifications if the requirement is to receive alerts only when the application goes down.
7.	Test the monitoring and notification workflow in a controlled manner.
8.	Capture screenshots showing the monitor status and alert configuration.
Protect the monitoring dashboard with authentication. Do not expose its administrative interface publicly without appropriate access controls.
Monitoring limitation: If Uptime Kuma runs on the same EC2 instance as the application, an instance-wide failure may also stop the monitor. For stronger monitoring, run it on a separate host or use an external monitoring service.
12. Repository Structure
The final repository should contain the following files, adjusted to the actual application structure:
devops-build/
├── Dockerfile
├── docker-compose.yml
├── build.sh
├── deploy.sh
├── Jenkinsfile
├── .dockerignore
├── .gitignore
├── README.md
├── package.json
├── package-lock.json
├── src/
├── public/
└── screenshots/
    ├── jenkins/
    ├── aws/
    ├── dockerhub/
    ├── deployment/
    └── monitoring/
Keep the existing application files and directory structure intact. Include only the directories and configuration files that are actually present in your implementation.
13. Validation and Testing
Before submitting the project, verify each stage.
Component	Validation
React application	Application builds without errors
Docker	Image builds successfully
Docker Compose	Container starts and serves the application
Bash scripts	Build and deployment scripts execute successfully
GitHub	Code is pushed to the dev branch
Docker Hub	Development and production images appear in their respective repositories
Jenkins	Builds are triggered by GitHub changes
Development pipeline	dev pushes publish to the public dev repository
Production pipeline	Merges into master publish to the private prod repository
AWS	EC2 instance is running and security group rules are correct
Deployment	Application is accessible over HTTP on port 80
Monitoring	HTTP health check reports UP and downtime notifications work
Mark a component as complete only after verifying it in the relevant tool or service.

17. Conclusion
This POC demonstrates how a React application can be containerized, version-controlled, built, published, and deployed through an automated CI/CD workflow.
The development and production branches provide a clear separation between development changes and production releases. Docker Hub stores the resulting container images, Jenkins automates the pipeline, AWS EC2 hosts the application, and Uptime Kuma monitors application availability.
The final submission should include the GitHub repository, verified Docker image names, deployed application URL, successful pipeline evidence, AWS security configuration, and monitoring screenshots.

