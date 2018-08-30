# hyperflow-terraform-ecs

This project contains infrustructure configuration files for deployment of HyperFlow and workflows on Amazon ECS/EC2 + Docker with autoscaling. The files are as follows:
 
- main.tf - definition of master ec2 instances, cluster lunch configuration for new instances and cluster name
- alarms.tf - alarm definitions
- autoscaling_policy.tf - auto scaling policy for aws instance and auto scaling policy for services
- security_group.tf - definition of security groups for iam instances
- tasks_and_services.tf - definition of task for master and worker container, definition of 2 services one to manage master task and one form managing worker tasks
- variables_const.tf - definitions of variables that usually will be not changed by user
- variables.tf - definitions of variables that should be changed by user according to their needs
- iam.tf - [Iam roles, profiles, policy](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/IAM_policies.html), IAM role specifies the permissions.
- output.tf - return dns address to master node
- task-hyperflow-master.json and task-hyperflow-worker.json contain templates of task definitions. Based on those definitions, ECS will start new containers with appropriate environment variables.

# User Variables
The most important variables from the user perspective are defined in the variables.tf file

- ecs_cluster_name - name of cluster that will be created
- launch_config_instance_type - ([EC2 instance types](https://aws.amazon.com/ec2/instance-types/)) to be used, e.g. t2.micro, t2.small, etc. 
- asg_min - minimum number of instances of EC2 in auto scaling group
- asg_max - maximum number of instances of EC2 in auto scaling group
- asg_desired - desired number of instances of EC2 after initialization of cluster

The master machine is outside the auto scaling group, so it is possible to set asg_min=0
 
- ecs_ami_id - id of dedicated and optimized ami for lunching container instances, [every region have different ami id](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html). It is also possible to create and use own ami.

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

 
- key_pair_name - name of key used to connect to ec2 instance with ssh, it is optional
- ACCESS_KEY - access key used by executor to communicate with S3
- SECRET_ACCESS_KEY - secret access key used by executor to communicate with S3
- ec2_instance_scaling_adjustment - numbers of ec2 instances that should be added or removed with corresponding alarm
- worker_scaling_adjustment - numbers of workers that should be added or removed with corresponding alarm
- hyperflow_master_container - master container containing rabbitmq
- hyperflow_worker_container - worker container containing selected version on executor

# Step by step instruction: deployment and running Montage workflow on Amazon ECS

This step-by-step guide assumes that you run the HyperFlow engine from your local machine. This soon will be fixed, so that the engine is automatically deployed on the Master node in the cloud. 

1. Install redis (on your local machine, required for the Hyperflow engine):

    apt install redis

2. Prepare an ECS user with the following roles:
    * AmazonEC2FullAccess 
    * AmazonS3FullAccess 
    * AmazonECS_FullAccess
    * IAMFullAccess

    It is also posible to use an Administrator IAM user.  

3. Initialize terraform 

   install terraform acording to https://www.terraform.io/intro/getting-started/install.html

   Example ubuntu:

   wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip

   unzip terraform_0.11.7_linux_amd64.zip

   Set AWS credentials:
   * export AWS_ACCESS_KEY_ID=(your access key id)
   * export AWS_SECRET_ACCESS_KEY=(your secret access key)

   Get infrastructure definition files:
   git clone https://github.com/hyperflow-wms/hyperflow-terraform-ecs.git

   cd ./hyperflow-terraform-ecs

   ~/terraform init

4. Setup the monitoring service machine (Grafana and InfluxDB)

    On a remote server (e.g. an EC2 instance) perform:

    git clone https://github.com/hyperflow-wms/hyperflow-grafana.git --recurse-submodules

    cd hyperflow-grafana

    sudo apt update

    sudo apt install docker-compose

    sudo docker-compose up -d

    Open ports:
    * grafana 3000
    * influxDB 8083, 8086, 25826

4. Prepare Montage data 
  
    Download data example to be procesed: https://s3.amazonaws.com/hyperflowdataexample/data_examples.zip

    wget https://s3.amazonaws.com/hyperflowdataexample/data_examples.zip

    unzip -a data_examples.zip

    extract file

    Upload data from data_examples/data0.25/0.25/ to S3 on us-east-1(N. Virginia). Currently uploading data to other regions will not work. Note that here S3 bucket name and path are assumed to be 'hyperfloweast-2' and '0.25/input/', but you can set them as you like.

5. Create the infrastructure

    terraform apply -var ‘ACCESS_KEY=XXXXXXXXXXXXXXXXX’ -v ‘SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx’ -var ‘influx_db_url=http://<influx_url>:8086/hyperflow_tests’

    example influx_db_url=http://ec2-18-219-231-96.us-east-2.compute.amazonaws.com:8086/hyperflow_tests


6. Run the workflow 

    sudo docker run -v ~/workspacemgr/data/data0.25/0.25/workdir/:/workdir -e AMQP_URL='amqp://<rabbit_mq>:5672' -e SECRET_ACCESS_KEY='XXXXXXXXXXXXXXXXXX' -e ACCESS_KEY="XXXXXXXXXXXXXXX" -e S3_BUCKET='hyperfloweast-2' -e S3_PATH='0.25/input/' -e METRIC_COLLECTOR="http:/<influx_db>:8086/hyperflow_tests" --net=host -it krysp89/hyperflow-hflow 

    --net=host - Use host networking, provide easy way to connect to redis that is running on localhost 

    Remember to map volume containing dag.json to /workdir: 

    -v ~/workspacemgr/data/data0.25/0.25/workdir/:/workdir 


    Other environment variables are identical with variables passed to hflow 

7. Destroy the infrastructure

   terraform destroy
   
   
# Additional features 

1. Use separate Container for task execution 

    When executing hflow set CONTAINER variable to use selected container for execution of tasks. 

    CONTAINER="krysp89/hyperflow-montage" AMQP_URL="amqp://<rabbit_mq>:5672" S3_BUCKET="hyperfloweast-2" S3_PATH="2.0/input/" hflow run ~/workspacemgr/data/data2.0/2.0/workdir/dag.json -s 

2. Download feature 

    Executor will not remove downloaded files after finishing task. Executor will check if file was already downloaded to reduce download time. To enable feature it is required to pass variable feature_download="ENABLED" to terraform. 

    terraform apply -var feature_download="ENABLED" -var "ACCESS_KEY=$AWS_ACCESS_KEY_ID" -var "SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" -var "influx_db_url=http://<influx_db>:8086/hyperflow_tests" 
 
 
