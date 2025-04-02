# Microservice Deployment

This directory contains a multi-service application with the following components:

- **Backend**: A Flask application that provides a REST API for task management
- **Database**: A MariaDB database for storing task data
- **Proxy**: An NGINX server that acts as a reverse proxy for the backend
- **Metrics**: A Prometheus sidecar container for collecting metrics

## Architecture

```
                   +------------+
                   |            |
                   |   NGINX    |
                   |   Proxy    |
                   |            |
                   +-----+------+
                         |
                         v
                   +------------+
                   |            |
                   |   Flask    |
                   |  Backend   |
                   |            |
                   +-----+------+
                         |
                         v
          +------------+ | +------------+
          |            | | |            |
          | Prometheus | | |  MariaDB   |
          |  Metrics   | | |  Database  |
          |            | | |            |
          +------------+ | +------------+
                         |
```

## Running the Application

To run the application, use Docker Compose:

```bash
cd microservices
docker-compose up -d
```

This will start all the services defined in the `docker-compose.yml` file.

## Accessing the Application

- The application is accessible at http://localhost
- The API endpoints are:
  - `GET /`: Welcome message
  - `GET /tasks`: List all tasks
  - `GET /health`: Health check endpoint

## Pushing to AWS ECR

To push the images to AWS ECR, follow these steps:

1. Create ECR repositories for each service:

```bash
aws ecr create-repository --repository-name microservices/backend
aws ecr create-repository --repository-name microservices/proxy
```

2. Authenticate Docker to your ECR registry:

```bash
aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.<your-region>.amazonaws.com
```

3. Build and tag the images:

```bash
docker-compose build
docker tag microservices_backend:latest <your-account-id>.dkr.ecr.<your-region>.amazonaws.com/microservices/backend:latest
docker tag microservices_proxy:latest <your-account-id>.dkr.ecr.<your-region>.amazonaws.com/microservices/proxy:latest
```

4. Push the images to ECR:

```bash
docker push <your-account-id>.dkr.ecr.<your-region>.amazonaws.com/microservices/backend:latest
docker push <your-account-id>.dkr.ecr.<your-region>.amazonaws.com/microservices/proxy:latest
```

## Deploying to ECS Fargate

The Terraform configuration in the parent directory includes the necessary resources to deploy these containers to ECS Fargate.
