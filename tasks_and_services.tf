#Definitions of Services and Tasks

data "template_file" "task_definition_hyperflow_worker" {
  template = "${file("${path.module}/task-hyperflow-worker.json")}"
  vars {
    image_url        = "${var.hyperflow_worker_container}"
    container_name   = "hyperflow-worker"
    master_ip        = "${aws_instance.hyperflowmaster.public_dns}"
    rabbitmq_port    = "${var.server_port}"
    acess_key        = "${var.ACCESS_KEY}"
    secret_key       = "${var.SECRET_ACCESS_KEY}"
    influxdb_url     = "${var.influx_db_url}"
    feature_download = "${var.feature_download}"
  }
}

resource "aws_ecs_task_definition" "task_hyperflow_worker" {
  family                = "task_definition_hyperflow_worker"
  container_definitions = "${data.template_file.task_definition_hyperflow_worker.rendered}"
  

  volume {
    name      = "tmp-storage"
    host_path = "/tmp"
  }
  volume {
    name      = "docker-socket"
    host_path = "/var/run/docker.sock"
  }


  depends_on = [
    "data.template_file.task_definition_hyperflow_worker",
  ]
}

resource "aws_ecs_service" "hyperflow-service-worker" {
  name               = "hyperflow-service-worker"
  cluster            = "${aws_ecs_cluster.hyperflow_cluster.id}"
  task_definition    = "${aws_ecs_task_definition.task_hyperflow_worker.arn}"
  desired_count      = "${var.aws_ecs_service_worker_desired_count}"

  depends_on = [
    "aws_iam_role.ecs_service",
    "aws_ecs_service.hyperflow-service-master",
  ]
}

data "template_file" "task_definition_hyperflow_master" {
  template = "${file("${path.module}/task-hyperflow-master.json")}"

  vars {
    image_url         = "${var.hyperflow_master_container}"
    container_name    = "hyperflow-master"
    host_port         = "${var.server_port}"
    container_port    = "${var.server_port}"
    influx_db_url = "${var.influx_db_url}"
    acess_key         = "${var.ACCESS_KEY}"
    secret_key        = "${var.SECRET_ACCESS_KEY}"
    rabbitmq_managment_port = "${var.server_plugin_port}"
  }
}

resource "aws_ecs_task_definition" "task_hyperflow_master" {
  family                = "task_definition_hyperflow_master"
  container_definitions = "${data.template_file.task_definition_hyperflow_master.rendered}"
  depends_on = [
    "data.template_file.task_definition_hyperflow_master",
  ]
}

resource "aws_ecs_service" "hyperflow-service-master" {
  name               = "hyperflow-service-master"
  cluster            = "${aws_ecs_cluster.hyperflow_cluster.id}"
  task_definition    = "${aws_ecs_task_definition.task_hyperflow_master.arn}"
  desired_count      = "${var.master_count}"
  depends_on = [
    "aws_iam_role.ecs_service",
  ]
}
