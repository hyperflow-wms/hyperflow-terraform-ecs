variable "ecs_cluster_name" {
  default = "ecs_test_cluster_hyperflow"
}

variable "launch_config_instance_type" {
  default = "t2.micro"
}

variable "asg_min" {
  default = 0
}

variable "asg_max" {
  default = 5
}

variable "asg_desired" {
  default = 0
}


variable "server_port" {
  description = "The port the server will use for rabbitmq"
  default = 5672
}

variable "ecs_ami_id" {
  default = "ami-cad827b7"
}


variable "key_pair_name" {
  default = "hyperfloweast1"
}

variable "ACCESS_KEY"
{
  default = ""
}

variable "SECRET_ACCESS_KEY"
{
  default = ""
}

variable "worker_scaling_adjustment"
{
  default = 3
}

variable "ec2_instance_scaling_adjustment"
{
  default = 1
}

variable "worker_scaling_adjustment_down"
{
  default = -3
}

variable "ec2_instance_scaling_adjustment_down"
{
  default = -1
}


variable "hyperflow_master_container"
{
  default = "krysp89/hyperflow-master:latest"
}


variable "hyperflow_worker_container"
{
  default = "krysp89/hyperflow-worker:latest"
}

