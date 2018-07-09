# hyperflow-terraform-ecs
Project is divided into several template files that that initialize container service on Amazon cloud :
 
main.tf - definition of master ec2 instances, cluster lunch configuration for new instances and cluster name

alarms.tf - alarm definitions

autoscaling_policy.tf - auto scaling policy for aws instance and auto scaling policy for services

security_group.tf - definition of security groups for iam instances

tasks_and_services.tf - definition of task for master and worker container, definition of 2 services one to manage master task and one form managing worker tasks

variables_const.tf - definitions of variables that usually will be not changed by user

variables.tf - definitions of variables that should be changed by user according to their needs

iam.tf - [Iam roles, profiles, policy](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/IAM_policies.html), IAM role specifies the permissions.

output.tf - return dns address to master node

Files task-hyperflow-master.json and task-hyperflow-worker.json contain templates of task definitions. Based on those definitions ecs will start new containers with appropriate environment variables.

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
 
# Deployment without InfluxDB, Grafana and ECS Plugin
 
1. Clone repository

   git clone https://github.com/krystianpawlik/hyperflow-terraform-ecs.git
 
2. Initialize terraform 

   cd ./hyperflow-terraform-ecs

   terraform init

   Set AWS credentials:

   export AWS_ACCESS_KEY_ID=(your access key id)
   
   export AWS_SECRET_ACCESS_KEY=(your secret access key)
 
3. Set user attributes according to your needs, example:

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

   hyperflow_master_container = "krysp89/hyperflow-master-plugin:latest"

   hyperflow_worker_container = "krysp89/hyperflow-master-plugin:latest"

   Those parameters could be edited in variable.tf file or passed with –var option from command line.

   For safety reasons ACCESS_KEY and SECRET_ACCESS_KEY should be passed from command line.
 
4. Deploy ecs on your cloud
   
   terraform apply -var ACCESS_KEY=$AWS_ACCESS_KEY_ID   -var SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
 
   Terraform script will return address of master with hyperflow_master_address variable
 

# Basic deployment with InfluxDB, Grafana and ECS Plugin

0. Install

    apt install git

    apt install npm

    apt install redis

    apt install unzip

    apt install redis


1. Prepare hyperflow
   
   git clone https://github.com/dice-cyfronet/hyperflow.git

   cd hyperflow

   npm install

   cd ..

   add hfId, wfid and procid to options in hyperflow/functions/amqpCommand.js lines 45 to be sent to executor

      ```javascript
      //extend options
      var extendedOptions = {
        ...options,
        hfId: config.hfId,
        wfid: config.appId,
        procId: config.procId
      };


      var jobMessage = {

        "executable": config.executor.executable,

        "args":       config.executor.args,

        "env":        (config.executor.env || {}),

        "inputs":     ins.map(identity),

        "outputs":    outs.map(identity),

        "options":    extendedOptions

      };
      ```

   Change default storage in hyperflow/functions/amqpCommand.config.js

     ```javascript
     //S3 storage
     exports.options = {
         "storage": "s3",
         "bucket": S3_BUCKET,
         "prefix": S3_PATH
     };

    //exports.options = {
    //    "storage": "local",
    //    "workdir": WORKDIR
    //};

    ```

    Install redis

    apt install redis

    Sometimes require to comment out ipv6 from configuration file to prevent problems with "TCP listening socket ::1:6379: bind: Cannot assign requested address"

    service redis-server start

2. Prepare ECS user with roles:
    * AmazonEC2FullAccess 
    * AmazonS3FullAccess 
    * AmazonECS_FullAccess
    * IAMFullAccess

    It is also posible to use administrator acess

3. Initialize terraform 

   install terraform acording to https://www.terraform.io/intro/getting-started/install.html

   Example ubuntu:

   wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip

   unzip terraform_0.11.7_linux_amd64.zip

   Set AWS credentials:
   * export AWS_ACCESS_KEY_ID=(your access key id)
   * export AWS_SECRET_ACCESS_KEY=(your secret access key)

   git clone https://github.com/krystianpawlik/hyperflow-terraform-ecs.git

   cd ./hyperflow-terraform-ecs

   ~/terraform init

4. Prepare plugin

   git clone https://github.com/krystianpawlik/hyperflow-ecs-monitoring-plugin.git

   cd hyperflow-ecs-monitoring-plugin

   npm install 

   make a symbolic link to hyperflow-ecs-monitoring-plugin directory in $HOME/node_modules/ sometime require to create folder $HOME/node_modules/

   mkdir $HOME/node_modules
   
   ln -s ~/hyperflow-ecs-monitoring-plugin ~/node_modules/hyperflow-ecs-monitoring-plugin

5. Setup grafana influxDB

    On remote server perform:

    git clone https://github.com/krystianpawlik/hyperflow-grafana.git --recurse-submodules

    cd hyperflow-grafana

    sudo apt update

    sudo apt install docker-compose

    sudo docker-compose up -d

    Open ports:
    * grafana 3000
    * influxDB 8083, 25826

6. Prepare date for hflow
  
    Download data example to be procesed: https://s3.amazonaws.com/hyperflowdataexample/data_examples.zip

    wget https://s3.amazonaws.com/hyperflowdataexample/data_examples.zip

    unzip -a data_examples.zip

    extract file

    Upload data of data_examples/data0.25/0.25/ to S3 on us-east-1(N. Virginia) uploadin data to other regions will not work with current version of executor


7. Deploy terraform

    ~/terraform apply -var ‘ACCESS_KEY=XXXXXXXXXXXXXXXXX’ -v ‘SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx’ -var ‘influx_db_url=http://<influx_url>:8086/hyperflow_tests’

    example influx_db_url=http://ec2-18-219-231-96.us-east-2.compute.amazonaws.com:8086/hyperflow_tests


8. Start hflow

    METRIC_COLLECTOR_TYPE="influxdb" METRIC_COLLECTOR="http://ec2-18-219-231-96.us-east-2.compute.amazonaws.com:8086/hyperflow_tests" ACCESS_KEY=XXXXXXXXXXXXXXXXX SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx AMQP_URL="amqp://ec2-18-207-152-214.compute-1.amazonaws.com:5672"  S3_BUCKET="hyperfloweast-2" S3_PATH="0.25/input/" ~/hyperflow/bin/hflow run ~/data_examples/data0.25/0.25/workdir/dag.json -s -p hyperflow-ecs-monitoring-plugin


# Basic deployment with InfluxDB, Grafana and hyperflow-hflow container

1. Install

    apt install redis

2. Prepare ECS user with roles:
    * AmazonEC2FullAccess 
    * AmazonS3FullAccess 
    * AmazonECS_FullAccess
    * IAMFullAccess

    It is also posible to use administrator acess

3. Initialize terraform 

   install terraform acording to https://www.terraform.io/intro/getting-started/install.html

   Example ubuntu:

   wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip

   unzip terraform_0.11.7_linux_amd64.zip

   Set AWS credentials:
   * export AWS_ACCESS_KEY_ID=(your access key id)
   * export AWS_SECRET_ACCESS_KEY=(your secret access key)

   git clone https://github.com/krystianpawlik/hyperflow-terraform-ecs.git

   cd ./hyperflow-terraform-ecs

   ~/terraform init

4. Setup grafana influxDB

    On remote server perform:

    git clone https://github.com/krystianpawlik/hyperflow-grafana.git --recurse-submodules

    cd hyperflow-grafana

    sudo apt update

    sudo apt install docker-compose

    sudo docker-compose up -d

    Open ports:
    * grafana 3000
    * influxDB 8083, 25826

4. Prepare date for hflow
  
    Download data example to be procesed: https://s3.amazonaws.com/hyperflowdataexample/data_examples.zip

    wget https://s3.amazonaws.com/hyperflowdataexample/data_examples.zip

    unzip -a data_examples.zip

    extract file

    Upload data of data_examples/data0.25/0.25/ to S3 on us-east-1(N. Virginia) uploadin data to other regions will not work with current version of executor

5. Deploy terraform

    ~/terraform apply -var ‘ACCESS_KEY=XXXXXXXXXXXXXXXXX’ -v ‘SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx’ -var ‘influx_db_url=http://<influx_url>:8086/hyperflow_tests’

    example influx_db_url=http://ec2-18-219-231-96.us-east-2.compute.amazonaws.com:8086/hyperflow_tests


6. Start hyperflow-hflow container 

    sudo docker run -v ~/workspacemgr/data/data0.25/0.25/workdir/:/workdir -e AMQP_URL='amqp://<rabbit_mq>:5672' -e SECRET_ACCESS_KEY='XXXXXXXXXXXXXXXXXX' -e ACCESS_KEY="XXXXXXXXXXXXXXX" -e S3_BUCKET='hyperfloweast-2' -e S3_PATH='0.25/input/' -e METRIC_COLLECTOR="http:/<influx_db>:8086/hyperflow_tests" --net=host -it krysp89/hyperflow-hflow 

    --net=host - Use host networking, provide easy way to connect to redis that is running on localhost 

    Remember to map volume containing dag.json to /workdir: 

    -v ~/workspacemgr/data/data0.25/0.25/workdir/:/workdir 


    Other environment variables are identical with variables passed to hflow 

