

![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

# Simple Flask Movie Suggester :bulb:

This project is a simple Flask web app that returns a random popular movie suggestion from The Movie Database’s (TMDB) API.

A serverless architecture is being used to deploy the app. The main reason being the app is a very small application that just makes a single API call to TMDB API each time the page is refreshed, so the compute power needed is low. 

Containerising the app gives it the advantages of being lightweight and portable and then using the Amazon Elastic Container Service containers can quickly be ran with lower compute costs and it also removes the overhead of managing any infrastructure.

For future releases I’ve created a full CI/CD pipeline using GitHub actions workflows. The CI/CD workflow automates code pushes from GitHub, builds the new image, using the Terraform files it deploys any AWS infrastructure changes and finally the new image is deployed.

The solution is completely re-usable for deploying different container images, from different container registeries (that Amazon ECS supports) and you can change how many containers you'd like to spin up. This is mainly achieved by not hardcoding values, GitHub Actions workflows, Github Secrets and Terraform for the Infrastructure as the variables can easyily be changed from the CLI.

# Table of contents :bookmark:
- [Simple Flask Movie Suggester :bulb:](#simple-flask-movie-suggester-bulb)
- [Table of contents :bookmark:](#table-of-contents-bookmark)
  - [AWS Infrastructure deployed by Terraform :cloud:](#aws-infrastructure-deployed-by-terraform-cloud)
      - [AWS Architecture Diagram:](#aws-architecture-diagram)
  - [Terraform Structure :computer:](#terraform-structure-computer)
  - [Prerequisites  :warning:](#prerequisites--warning)
    - [Terraform ](#terraform-)
    - [AWS Credentials ](#aws-credentials-)
    - [AWS CLI ](#aws-cli-)
    - [Python ](#python-)
    - [Docker ](#docker-)
    - [The Movie Database (TMDB) API Key ](#the-movie-database-tmdb-api-key-)
  - [Required AWS resources: :warning:](#required-resources-warning)
    - [S3 Bucket](#s3-bucket)
    - [DynamoDB Table](#dynamodb-table)
    - [Amazon ECR Repository](#amazon-ecr-repository)
  - [Initial Setup: :construction\_worker:](#initial-setup-construction_worker)
  - [Build \& Push Docker Image  :wrench:](#build--push-docker-image--wrench)
  - [Deploy AWS Infrastructure (Terraform) :cloud:](#deploy-aws-infrastructure-terraform-cloud)
  - [Github Secrets :key:](#github-secrets-key)
  - [Future Releases: CI/CD Workflow :memo:](#future-releases-cicd-workflow-memo)
  - [Destroying Infrastructure :rotating\_light:](#destroying-infrastructure-rotating_light)

  
## AWS Infrastructure deployed by Terraform <a name="aws-infra"></a>:cloud:
#### AWS Architecture Diagram

The Terraform files with this GitHub Repository folder `terraform` will deploy the following AWS Infrastructure:

* **Networking:** VPC, NAT Gateway, 3 Public Subnets, Route tables and assocations for the public subnets and 2 security groups (For the ALB and one for the traffic from container to ALB)
* **Application Load Balancer:** The configuration for the ALB using each of the 3 Public Subnets, ALB target group, ALB listener for the ALB target groups.
* **Amazon Elastic Container Service (Amazon ECS):** The ECS cluster is deployed, the required role for the ECS cluster is created, ECS Task Definition with the configuration and the ECS service which maintains the desired amount of containers in the cluster. The ECS service runs behind the above Load balancer to distribute traffic across and in the ennd the containers in the cluster are deployed with the below configuration:
  *  Fargate as the Compute Service
  *  CPU: 256 # .25 vCPU
  *  Memory: 512 # 0.5 GB
  *  Container image url and name is pulled from Amazon ECR
  *  Port mappings for the container (Port 80)

## Terraform Structure <a name="tf-structure"></a>:computer:

For this project I've not used a main.tf file or modules but instead split the different AWS components into different Terraform .tf files as shown below.

**Directory structure:**


![image](https://github.com/itsham-sajid/flask-web-app/blob/testing/images/terraform-structure.png?raw=true)



The first file Terraform will read is the` 0 - provider.tf` file, which tells Terraform which provider to use and the AWS region is also declared.


```
0 - provider.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

```


The Terraform state is being stored remotely in a Amazon S3 bucket, so here we define this and the DynamoDB table for Terraform's state locking feature. State locking helps if your making changes to the infrastructure, the state file is locked for you and it'll prevent others from making any changes to the infrastructure at the same time.

:warning: **Note:**  These sensitive values are not stored within the GitHub repository. Intially you would need to create these AWS resources and then manaully define these values through the Terraform CLI. However,  later for  the CI/CD pipeline these values are stored within GitHub secrets and are referenced within the GitHub Actions workflow files for automation.



```
1 - backend.tf

terraform {
  backend "s3" {
    bucket         = "bucket-name"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "dynamo-table"

  }
}

```


The `2 - networking.tf` Terraform file first declares the VPC resource to be created. Three Public Subnets are created with each having Public IP addresseses assigned to them. Each public subnet has a route table assosaction assigned to route traffic to the Internet Gateway. The internet gateway resource allows access to the internet.

Lastly, two security groups are created. The first security group is for allowing the container deployed on the ECS cluster, it's inbound tarffic will be allowed to reach the Application Load Balancer. The second security group allows inbound port 80 traffic from anywhere and later in the `3 - application-lb.tf ` this will be applied to the Application Load Balancer.



```
2 - networking.tf 

# Creating VPC

resource "aws_vpc" "web-app" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "${var.application_tag} - VPC"
    env  = var.env_tag
  }
}

#NAT Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.web-app.id

  tags = {
    name = "${var.application_tag} - IGW"
    env  = var.env_tag
  }

}


# Public Subnets
resource "aws_subnet" "public-eu-west-2a" {
  vpc_id                  = aws_vpc.web-app.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    name = "${var.application_tag} - Public Subnet eu-west-2a"
    env  = var.env_tag
  }

}

resource "aws_subnet" "public-eu-west-2b" {
  vpc_id                  = aws_vpc.web-app.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    name = "${var.application_tag} - Public Subnet eu-west-2b"
    env  = var.env_tag
  }
}

resource "aws_subnet" "public-eu-west-2c" {
  vpc_id                  = aws_vpc.web-app.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = true

  tags = {
    name = "${var.application_tag} - Public Subnet eu-west-2c"
    env  = var.env_tag
  }

}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.web-app.id

  tags = {
    name = "${var.application_tag} - Public VPC route"
    env  = var.env_tag
  }

}

A route table is created and assigned to the VPC. A routb

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id


}

resource "aws_route_table_association" "public-eu-west-2a" {
  subnet_id      = aws_subnet.public-eu-west-2a.id
  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "public-eu-west-2b" {
  subnet_id      = aws_subnet.public-eu-west-2b.id
  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "public-eu-west-2c" {
  subnet_id      = aws_subnet.public-eu-west-2c.id
  route_table_id = aws_route_table.public.id

}


resource "aws_security_group" "container-sg" {
  name        = "ContainerFromAlb-SG"
  description = "Allows inbound traffic from the ALB security group"
  vpc_id      = aws_vpc.web-app.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    security_groups  = [aws_security_group.alb.id]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    name = "${var.application_tag} - ALB Inbound Secuirty Group"
    env  = var.env_tag
  }
}

resource "aws_security_group" "alb" {
  name        = "ApplicationLoadBalancer-SG"
  description = "Allows inbound port 80 traffic from anywhere"
  vpc_id      = aws_vpc.web-app.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    name = "${var.application_tag} - ALB Inbound Traffic Securiy Group"
    env  = var.env_tag
  }

}

```


The `3 - application-lb.tf`  Terraform file is where the Application Load Balancer will be created. The Amazon ECS service where the container will be deployed will utilise this to distribute traffic evenly across the number of containers that are running.

The distrubution of the traffic will work by first creating a listener resource for inbound public HTTP traffic, this is then forwarded to target groups. The targets groups have the Amazon ECS containers registered to them so traffic can be distrubited between them.



```
3 - application-lb.tf 

resource "aws_lb" "main" {
  name               = var.aws_alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public-eu-west-2a.id, aws_subnet.public-eu-west-2b.id, aws_subnet.public-eu-west-2c.id]

  enable_deletion_protection = false

  tags = {
    name = "${var.application_tag} - Application Load Balancer"
    env  = var.env_tag
  }

}

resource "aws_alb_target_group" "main" {
  name        = var.aws_alb_target_group_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.web-app.id
  target_type = "ip"

  tags = {
    name = "${var.application_tag} - ALB Target Group A"
    env  = var.env_tag
  }


}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main.id
  }

  tags = {
    name = "${var.application_tag} - ALB Listener"
    env  = var.env_tag
  }

}

```


The `4 - ecs-cluster.tf ` Terraform file first declares the ECS Cluster resource to be created. For the management of containers in the ECS cluster it needs to `AssumeRole` two IAM Roles. The first IAM role we'll need is the ECS Task Execution Role, so we can pull the image that's being stored in the Amazon Elastic Container Registry (ECR). The next role we need is the EcsTaskPolicy to create the tasks in the Amazon ECS cluster.



```
4 - ecs-cluster.tf  

resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name

  tags = {
    name = "${var.application_tag} - ECS Cluster"
    env  = var.env_tag
  }


}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid = "EcsTaskPolicy"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = [
      "*"
    ]
  }
  statement {

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = [
      "*"
    ]
  }

  statement {

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }

}

resource "aws_iam_role" "Execution_Role" {
  name               = "ecsExecution-1"
  assume_role_policy = data.aws_iam_policy_document.role_policy.json

  inline_policy {
    name   = "EcsTaskExecutionPolicy"
    policy = data.aws_iam_policy_document.ecs_task_policy.json
  }


}


data "aws_iam_policy_document" "role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


```


In the ` - ecs-task-definition.tf` file this is where we create the Amazon ECS Task Definition, which is required for running containers in the ECS cluster.The Task Definition for this project defines the following parameters:

* The launch type being is AWS Fargate
* The networking mode for the containers
* The CPU and Memory each container will use in this task
* The Flask application runs on port 80, so a port mapping is requried between the container and the host.



```
5 - ecs-task-definition.tf

# Creating the ECS task definition


resource "aws_ecs_task_definition" "main" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_definition_cpu_allocation    #.25 vCPU
  memory                   = var.ecs_task_definition_memory_allocation # 0.5 GB
  task_role_arn            = aws_iam_role.Execution_Role.arn
  execution_role_arn       = aws_iam_role.Execution_Role.arn
  container_definitions = jsonencode([{
    name      = "${var.ecs_container_name}"
    image     = "${var.ecr_container_image_url}"
    cpu       = "${var.ecs_task_definition_cpu_allocation}"    #.25 vCPU
    memory    = "${var.ecs_task_definition_memory_allocation}" # 0.5 GB
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]
    }
  ])

  tags = {
    name = "${var.application_tag} - ECS Fargate Task"
    env  = var.env_tag
  }
}



```



The `6 - ecs-service.tf` Terraform file creates the Amazon ECS Service that will run using the previous Task Definition. The `desired_amount` line will allows us to define how many containers to run. It's responsible for maintaining the desired amout of containers using the `REPLICA` scheduling strategy. The ECS service also will spread the containers across the three public subnets that were previously declared in the VPC Terraform file. The ECS Service also adds the configures the container to the Application Load Balancer target group.




```

6 - ecs-service.tf

resource "aws_ecs_service" "main" {
  name                = var.aws_ecs_service_name
  cluster             = aws_ecs_cluster.main.id
  task_definition     = aws_ecs_task_definition.main.id
  desired_count       = var.aws_ecs_service_desired_count
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.container-sg.id]
    subnets          = [aws_subnet.public-eu-west-2a.id, aws_subnet.public-eu-west-2b.id, aws_subnet.public-eu-west-2c.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = var.ecs_container_name
    container_port   = "80"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    name = "${var.application_tag} - ECS Service"
    env  = var.env_tag
  }

}


```


The below `7 - variables.tf` variables file holds all variables that have been assigned. All the varialbes have `default` values while the following below have values that must be declared.

* ecs_container_name
* ecr_container_image_url

The purpose of this is to allow new container images or container registries to be used. Also, other varialbes could aslo be added to make improvements to the solution.



```

7 - variables.tf

variable "env_tag" {
  description = "Prod Environment tag"
  type        = string
  default     = "Prod"
}

variable "application_tag" {
  description = "Application tag"
  type        = string
  default     = "Movie App"
}

variable "aws_alb_name" {
  description = "Application Load Balancer Name"
  type        = string
  default     = "web-app-alb"

}

variable "aws_alb_target_group_name" {
  description = "Application Load Balancer Target Group Name"
  type        = string
  default     = "alb-target-group"

}


variable "ecs_container_name" {
  description = "Container name for ECS task definition"
  type        = string

}

variable "ecr_container_image_url" {
  description = "Amazon ECR container image url"
  type        = string
}


variable "ecs_task_definition_cpu_allocation" {
  description = "Amazon ECR container image url"
  type        = number
  default     = 256
}

variable "ecs_task_definition_memory_allocation" {
  description = "Amazon ECR container image url"
  type        = number
  default     = 512
}

variable "ecs_cluster_name" {
  description = "Amazon ECS Cluster Name"
  type        = string
  default     = "app-cluster"

}

variable "aws_ecs_service_name" {
  description = "Amazon ECS Service Name"
  type        = string
  default     = "app-service"

}

variable "aws_ecs_service_desired_count" {
  description = "Amazon ECS Service Name"
  type        = number
  default     = 2

}

```



## Prerequisites <a name="prerequisites"></a> :warning:
### Terraform <a name="terraform"></a>
**Version used: v1.3.5**

Follow the instructions here to install Terraform <a href="https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli" target="_blank">here</a>



### AWS Credentials <a name="aws-credentials"></a>

An AWS account, an IAM User with Programmatic access, Access key ID and a Secret access key are required.

This can creataed by following the instructions <a href="https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-" target="_blank">here</a>


Only for the purpose of demonstartion I've created an IAM user with full `AdministratorAccess` access. 



### AWS CLI <a name="aws-cli"></a>
**Version used: aws-cli/2.9.0**

Refer to the following guide to install the AWS CLI <a href="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" target="_blank">here</a>

Once the AWS CLI is installed run the below command within a terminal and follow the on-screen prompts to enter your Access Key ID, Secret Key, choose default region and the default ouput format.


```
aws configure
```

#### Python <a name="python"></a>
**Python 3.10.6**

Depending on what OS your running the instructions will be different. 

Refer to the instructions <a href="https://python.land/installing-python" target="_blank">here</a> on installing for Windows, Linux or Mac.

**Note:**The app has been tested to work on Python 3.8, 3.9 or 3.10

#### Docker <a name="docker"></a>
**Version used: 20.10.19**

Again, depending on what OS your using the instructions will be different.Refer to the instructions <a href="https://gist.github.com/rstacruz/297fc799f094f55d062b982f7dac9e41" target="_blank">here</a>


#### The Movie Database (TMDB) API Key <a name="tmdb"></a>

For this project the The Movie Database (TMDB) API is being used to retrieve the list of popular movies.

To obtain a API Key it's free and easy. First create an an account <a href="https://www.themoviedb.org/signup" target="_blank">here</a>


Then you can obtain your API key from <a href="https://www.themoviedb.org/settings/api" target="_blank">here</a>


## Required resources: :warning:

### S3 Bucket

The Terraform config is setup to use a S3 bucket to store the state file and use a DynamoDB table for Terraforms state locking feature. To create the bucket run the below command in the AWS CLI and changing the `values` to your own.s


**Note:** For this project I've chose to host all AWS infrastruture in eu-west-2, hence the `LocationConstraint` parameter is being declared as this is required for creating buckets in eu-west-2.

```
aws s3api create-bucket --bucket <value> --region <value> --create-bucket-configuration LocationConstraint=eu-west-2 --acl private
```

### DynamoDB Table

Run the below command to create a DynamoDB table

To  use the Terraform state locking feature, which locks the state file and preventes it from being accessed it for another use a DynamoDB must be created. Navigate to the <a href="https://eu-west-2.console.aws.amazon.com/dynamodbv2" target="_blank">here</a>. Click `create table` and setup the table as shown below:

![image](https://github.com/itsham-sajid/flask-web-app/blob/testing/images/dynamodb.png?raw=true)


  
### Amazon ECR Repository

Run the below command to create an Amazon ECR Repository. Change the `image-repo` and `eu-west-2` values as required.

```
aws ecr create-repository \
    --repository-name image-repo \
    --region eu-west-2 \
```


## Initial Setup: :construction_worker:

First start by cloning this GitHub Repo:

```
git clone git@github.com:itsham-sajid/flask-web-app.git
```


The folder structure for the Flask project is as follows:

![image](https://github.com/itsham-sajid/flask-web-app/blob/testing/images/flask.png?raw=true)


Before the app can be run The Movie Database (TMDB) API key must be saved as environment variable, so the app can use the API key to retrieve the list of movies.

Run the below command to save the API Key to a .env file

```
echo API_KEY=<YOUR-API-KEY> > .env
```

Now, you can run the Flask app from within the `flask-web-app` folder and run the below command

```
python3 -m flask run --host=0.0.0.0
```

This will start the Flask development server on the local address: http://127.0.0.1:5000



## Build & Push Docker Image <a name="docker"></a> :wrench:

To build and push the docker image, Amazon has a list of the commands you need to run and to access these commands you just have to login into the AWS Console > Navigate to Amazon ECR > Select your repository > and select the button "View push commands"

Below is a screenshot as an example:
![image](https://github.com/itsham-sajid/flask-web-app/blob/testing/images/ecr.png?raw=true)



## Deploy AWS Infrastructure (Terraform) <a name="aws-terraform"></a>:cloud:

**Note:** As explained previously, sensitive values are not hardcoded within this GitHub project so you must declare this manually via the Terraform CLI. However, for the CI/CD workflow they will need to be added to GitHub secrets, as the GitHub secrets variables are delcared within the CI/CD workflow files for automation.

First, you'll need to run the below command and replaces the `values` with your own. This intiliases the Terraform backend, stores the Terraform state remotely within a S3 bucket, knows which DynamoDB table to use for state locking and the AWS region.

```
terraform init -backend-config='bucket=<value>' -backend-config='key=<value>' -backend-config='region=<value>' -backend-config='dynamodb_table=<value>'

```

Next, there are two more values that are needed `ecr_container_image_url` and `ecs_container_name`. The reason for this is again so these values can be changed and aren't hardcoded e.g. if you want to use a different image regisry like Docker or wanted to use another container name.

We can declare these values together while running a `terraform plan`:

```
terraform plan -var 'ecr_container_image_url=<value>' -var 'ecs_container_name=<value>'

```

Lastly, review the output and run a `terraform apply`

```
terraform apply

```

Once complete this will bring up the AWS infrastructure.



## Github Secrets <a name="githubsecrets"></a>:key:

GitHub Secrets allows for secure secret management and these can also be declared within GitHub Actions Workflow.

Where a variable that starts with `${{ secrets.` Example: `${{ secrets.AWS_ACCESS_KEY_ID }}` it's being referenced directly from the respositories GitHub Secrets.

GitHub secrets can be assinged by going to **Settings on the respository > Actions > New repository secret**

Below is the list of the total GitHub Secrets that are required to succesfully run the CI/CD pipeline:

| Name                           |    Purpose                            |
|--------------------------------|:-------------------------------------:|
| API_KEY                        |  The movie database API key           |
| AWS_ACCESS_KEY_ID              |    AWS Access Key ID                  |
| AWS_DYNAMODB_TABLE             | DynamoDB table name                   |
| AWS_ECR_CONTAINER_IMAGE_URL    |  Amazon ECR Container Image URL       |
| AWS_ECS_CONTAINER_NAME         |    Amazon ECS Container Name          |
| AWS_IMAGE_TAG                  | The Image tag for buidling the image  |
| AWS_REGION                     |  AWS Region                           |
| AWS_SECRET_ACCESS_KEY          |    AWS Secret Access Key              |
| BUCKET_TF_STATE                | Name of the S3 Bucket                 |
| ECR_REPOSITORY                 |  Name of the ECR Repository           |
| TF_STATE_KEY                   |    The Terraform State key name       |



Below is an example of the Github Secrets are references within the GitHub Acitons workflow. Where the `terrafom init` command runs to setup the backend, instead of hard coding these values to the workflow file, they reference the GitHub secret with the require values.<br />
<br />
```
name: "Terraform Plan"
 
on:
  pull_request:

env:
  TF_LOG: INFO
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

jobs:
 terraform:
   name: "Terraform Plan"
   runs-on: ubuntu-latest
   defaults:
     run: 
      working-directory: ./terraform

   steps:
   - name: Checkout the repository to the runner
     uses: actions/checkout@v2
      
   - name: Setup Terraform with specified version on the runner
     uses: hashicorp/setup-terraform@v2
     with:
      terraform_version: 1.3.0 
    
   - name: Terraform init
     id: init
     run: terraform init -backend-config='bucket=${{ secrets.BUCKET_TF_STATE}}' -backend-config='key=${{ secrets.TF_STATE_KEY }}' -backend-config='region=${{ secrets.AWS_REGION }}' -backend-config='dynamodb_table=${{ secrets.AWS_DYNAMODB_TABLE }}'

```


The next section explains the CI/CD pipeline and what action each worflow takes.


## Future Releases: CI/CD Workflow <a name="cicd"></a>:memo:

Below is an explanation of how the CI/CD pipeline works. The GitHub Actions workflow files are stored within the `.github/workflows` folder.

1. Developer pushes code to GitHub Repostiry. Git Hub Actions will trigger the first workflow:
   - >  **Quality check code** (using pylint)

2. Devloper next creates a Pull request to merge changes, the next workflow that will trigger:
   - >   **Terraform plan:** This is to report any changes to the infrastructure. The output of the Terraform plan is saved to a 
        file which will be used later for the Terraform Apply workflow. The engineer will also see on the pull request of the Terraform plan output to observe any changes to the AWS infrastructure before merging.

3. Once code is merged to the main branch the following workflows will be triggered only on the condition the Terraform Plan was
   a success
   - >   **Terraform Apply:** This workflow will update the AWS infrasctrure before the new container image is built and deployed.

4. The next worklow will buid the new container image. This workflow will only build the image on the condition the Terraform Apply
   workflow was a success

   - > Image is built using the Dockerfile, the image is tagged and pushed to the **Amazon ECR Registry**

5. The final workflow will run on the Condition the previous build image workflow was a success:

   - > Deploy image to **Amazon ECS Cluster**
 

**Below is a diagraming explain the flow of the CI/CD pipeline**


![image](https://github.com/itsham-sajid/flask-web-app/blob/testing/images/CI_CD%20pipeline%20example.png?raw=true)


## Destroying Infrastructure <a name="destroy"></a>:rotating_light:

To destroy the Terraform AWS Infrastrucutre simply run a Terraform destroy while in the `terraform` folder and manaully approve the deletion. <br />


```
terraform destroy
```


Deleting the Amazon ECR Repository run the below AWS CLI command:<br />


```
aws s3api delete-bucket --bucket <bucket-name> --region <aws-region> 
```


Delete the Amazon S3 bucket<br />

```
aws 
```

Delete the Dynamo DB table<br />

```
aws dynamodb delete-table \
    --table-name <table-name> 
```


