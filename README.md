# hyperflow-terraform-ecs
Project is divided into several template files that that initialize container service on Amazon cloud :
 
main.tf - definition of master ec2 instances, cluster lunch configuration for new instances and cluster name

alarms.tf - alarm definitions

autoscaling_policy.tf - auto scaling policy for aws instance and auto scaling policy for services

security_group.tf - definition of security groups for iam instances

tasks_and_services.tf - definition of task for master and worker container, definition of 2 services one to manage master task and one form managing worker tasks

variables_const.tf - definitions of variables that usually will be not changed by user

variables.tf - definitions of variables that should be changed by user according to their needs

iam.tf - [Iam roles, profiles, policy](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/IAM_policies.html)

output.tf - return dns address to master node
 
# User Variables
Most important variables from user perspective should be in variables.tf file

ecs_cluster_name - name of cluster that will be created
launch_config_instance_type - type of instance user would like to use for ec2 eg:
* t2.micro
* t2.small
* t2.medium
* t2.large
* t2.xlarge
* t2.2xlarge

More types on [amazone](https://aws.amazon.com/ec2/instance-types/)
 
asg_min - minimum number of instances of ec2 in auto scaling group

asg_max - maximum number of instances of ec2 in auto scaling group

asg_desired - desired number of instances of ec2 after initialization of cluster

Currently master machine is outside autos calling group this is why it is possible to set asg_min=0
 
ecs_ami_id - id of dedicated and optimized ami for lunching container instances, [every region have different ami id](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html). It is also possible to create and use own ami.

|Region            | AMI ID      |
|------------------|-------------|
|us-east-2         |ami-1b90a67e |   
|us-east-1         |ami-cb17d8b6 |
|us-west-2         |ami-05b5277d |
|us-west-1         |ami-9cbbaffc |
|eu-west-3         |ami-914afcec |
|eu-west-2         |ami-a48d6bc3 |
|eu-west-1         |ami-bfb5fec6 |
|eu-central-1      |ami-ac055447 |
|ap-northeast-2    |ami-ba74d8d4 |
|ap-northeast-1    |ami-5add893c |
|ap-southeast-2    |ami-4cc5072e |
|ap-southeast-1    |ami-acbcefd0 |
|ca-central-1      |ami-a535b2c1 |
|ap-south-1        |ami-2149114e |
|sa-east-1         |ami-d3bce9bf |

 
key_pair_name - name of key used to connect to ec2 instance with ssh, it is optional
 
ACCESS_KEY - access key used by executor to communicate with S3

SECRET_ACCESS_KEY - secret access key used by executor to communicate with S3

ec2_instance_scaling_adjustment - numbers of ec2 instances that should be added or removed with corresponding alarm

worker_scaling_adjustment - numbers of workers that should be added or removed with corresponding alarm
 
hyperflow_master_container - master container containing rabbitmq

hyperflow_worker_container - worker container containing selected version on executor
 
# Deployment
 
1. Clone repository

   git clone https://github.com/krystianpawlik/hyperflow-terraform-ecs.git
 
2. Initialize terraform 

   cd ./hyperflow-terraform-ecs

   terraform init
 
3. Set user attributes according to your need, example:

   ecs_region = "us-east-1"

   ecs_cluster_name = "ecs_test_cluster_hyperflow"

   launch_config_instance_type = "t2.micro"

   asg_min = 0

   asg_max = 5

   asg_desired = 0

   aws_ecs_service_worker_desired_count = 2

   ecs_ami_id = "ami-cad827b7"

   key_pair_name = ""

   ACCESS_KEY = ""

   SECRET_ACCESS_KEY = ""

   worker_scaling_adjustment = 3

   ec2_instance_scaling_adjustment = 1

   hyperflow_master_container = "krysp89/hyperflow-master:latest"

   hyperflow_worker_container = "krysp89/hyperflow-worker:latest"

   Those parameters could be edited in variable.tf file or passed with –var option from command lin.

   For safety reasons ACCESS_KEY and SECRET_ACCESS_KEY should be passed from command line.
 
4. Deploy ecs on your cloud
   
   terraform apply -var ACCESS_KEY=$AWS_ACCESS_KEY_ID   -var SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
 
   Terraform script will return address of master with hyperflow_master_address variable
 
5. Start monitoring and metric notification
 

