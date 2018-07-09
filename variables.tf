variable "ecs_region"
{
  default = "us-east-1"
}

variable "ecs_cluster_name" {
  default = "ecs_test_cluster_hyperflow"
}

#address to influx db
#example default = "http://ec2-18-219-231-96.us-east-2.compute.amazonaws.com:8086/hyperflow_tests"
#http://<url>:8086/<database>
variable "influx_db_url"
{
  default = ""
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

variable "aws_ecs_service_worker_desired_count"
{
  default = 2
}

variable "worker_scaling_adjustment"
{
  default = 3
}

variable "ec2_instance_scaling_adjustment"
{
  default = 1
}

variable "ecs_ami_id" {
  default = "ami-cad827b7"
}

variable "key_pair_name" {
  default = ""
}


variable "ACCESS_KEY"
{
  default = ""
}

variable "SECRET_ACCESS_KEY"
{
  default = ""
}

variable "hyperflow_master_container"
{
  default = "krysp89/hyperflow-master-plugin:latest"
}

variable "hyperflow_worker_container"
{
  default = "krysp89/hyperflow-worker-plugin:latest"
}

variable "ec2_status_reporter"
{
  default = "krysp89/hyperflow-ec2-status-reporter:latest"
}

