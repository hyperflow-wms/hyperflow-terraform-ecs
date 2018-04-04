## hyperflow master thesis

## region
provider "aws" {
  region = "us-east-1"
}


## Could be configured further
##resource "aws_vpc" "main" {
##  cidr_block = "10.0.0.0/16"
##}


## Security Groups

resource "aws_security_group" "sg-hyperflow" {
  name = "terraform-hyperflowmaster-sg"

  # Inbound HTTP from anywhere
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound ssh
  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}



#IAM

resource "aws_iam_role" "ecs_service" {
  name = "hyperflow-instecs-serviceance-role"
  assume_role_policy = "${file("ecs-service-role.json")}"
}

resource "aws_iam_role" "app_instance" {
  name = "hyperflow-instance-role"
  assume_role_policy = "${file("ec2-instance-role.json")}"
}


resource "aws_iam_instance_profile" "app" {
  name  = "hyperflow-instance-profile"
  role = "${aws_iam_role.app_instance.name}"
}

data "template_file" "instance_profile" {
  template = "${file("ecs-profile-policy.json")}"

#  vars {
#    app_log_group_arn      = "${aws_cloudwatch_log_group.ecs-app.arn}"
#    ecs_log_group_arn      = "${aws_cloudwatch_log_group.ecs.arn}"
#    ecs_config_bucket_name = "${var.ecs_config_bucket_name}"
#  }
}


resource "aws_iam_role_policy" "instance" {
  name   = "ECSInstanceRole"
  role   = "${aws_iam_role.app_instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

resource "aws_autoscaling_policy" "up" {
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.app.name}"
  cooldown               = 120
  name                   = "${var.ecs_cluster_name}_asg_up"
  scaling_adjustment     = "${var.ec2_instance_scaling_adjustment}"

  depends_on = [
    "aws_autoscaling_group.app"
  ]
}

resource "aws_autoscaling_policy" "down" {
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.app.name}"
  cooldown               = 120
  name                   = "${var.ecs_cluster_name}_asg_down"
  scaling_adjustment     = "${var.ec2_instance_scaling_adjustment_down}"

  depends_on = [
    "aws_autoscaling_group.app"
  ]
}


resource "aws_cloudwatch_metric_alarm" "queue_lenth_high" {
  alarm_actions       = [ "${aws_autoscaling_policy.up.arn}" ,"${aws_appautoscaling_policy.hyperflow_worker_up.arn}" ]
  alarm_description   = "hyperflow alarm"
  alarm_name          = "${var.ecs_cluster_name}_queue_lenth_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "QueueLength"
  namespace           = "hyperflow"
  period              = 10
  statistic           = "Average"
  threshold           = 100

  dimensions {
    ClusterName = "${aws_ecs_cluster.hyperflow_cluster.name}"
  }

  depends_on = [
    "aws_autoscaling_policy.up",
    "aws_appautoscaling_policy.hyperflow_worker_up"
  ]
}

resource "aws_cloudwatch_metric_alarm" "queue_lenth_low" {
  alarm_actions       = [ "${aws_autoscaling_policy.down.arn}" ,"${aws_appautoscaling_policy.hyperflow_worker_down.arn}" ]
  alarm_description   = "hyperflow alarm"
  alarm_name          = "${var.ecs_cluster_name}_queue_lenth_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "QueueLength"
  namespace           = "hyperflow"
  period              = 10
  statistic           = "Average"
  threshold           = -1

  dimensions {
    ClusterName = "${aws_ecs_cluster.hyperflow_cluster.name}"
  }

  depends_on = [
    "aws_autoscaling_policy.down",
    "aws_appautoscaling_policy.hyperflow_worker_down"
  ]
}


resource "aws_instance" "hyperflowmaster" {

  ami                    = "${var.ecs_ami_id}"
  instance_type               = "${var.launch_config_instance_type}"
  
  iam_instance_profile = "${aws_iam_instance_profile.app.name}"

  vpc_security_group_ids = ["${aws_security_group.sg-hyperflow.id}"]
  tags {
    Name = "terraform-hyperflowmaster"
  }

  key_name="hyperfloweast1"

  user_data = "#!/bin/bash\necho ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config"

}


## 
## LaunchConfig

resource "aws_launch_configuration" "ecs-test-hyperflow-alc" {
  name = "${var.ecs_cluster_name}-LaunchConfig"
  security_groups = [
    "${aws_security_group.sg-hyperflow.id}",
  ]

  key_name = "${var.key_pair_name}"
  image_id                    = "${var.ecs_ami_id}"
  instance_type               = "${var.launch_config_instance_type}"
  associate_public_ip_address = false
  iam_instance_profile = "${aws_iam_instance_profile.app.name}"
  user_data = "#!/bin/bash\necho ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "app" {
  name                 = "${var.ecs_cluster_name}-ASG"
  availability_zones   = ["us-east-1a","us-east-1b","us-east-1c", "us-east-1d", "us-east-1e" ,"us-east-1f"]

  min_size             = "${var.asg_min}"
  max_size             = "${var.asg_max}"
  desired_capacity     = "${var.asg_desired}"
  launch_configuration = "${aws_launch_configuration.ecs-test-hyperflow-alc.name}"
  health_check_type    = "EC2"

  lifecycle { create_before_destroy = true }

  depends_on = [
    "aws_launch_configuration.ecs-test-hyperflow-alc"
  ]

}

## ECS Cluster

resource "aws_ecs_cluster" "hyperflow_cluster" {
  name = "${var.ecs_cluster_name}"
}

data "template_file" "task_definition_hyperflow_master" {
  template = "${file("${path.module}/task-hyperflow-master.json")}"

  vars {
    image_url        = "${var.hyperflow_master_container}"
    container_name   = "hyperflow-master"
    host_port        = 5672
    container_port   = 5672
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
  desired_count      = 1
  ##iam_role           = "${aws_iam_role.ecs_service.name}"

  depends_on = [
    "aws_iam_role.ecs_service",
  ]
}



data "template_file" "task_definition_hyperflow_worker" {
  template = "${file("${path.module}/task-hyperflow-worker.json")}"

  vars {
    image_url        = "${var.hyperflow_worker_container}"
    container_name   = "hyperflow-worker"
    master_ip        = "${aws_instance.hyperflowmaster.public_dns}"
    acess_key        = "${var.ACCESS_KEY}"
    secret_key       = "${var.SECRET_ACCESS_KEY}"
  }
}



resource "aws_ecs_task_definition" "task_hyperflow_worker" {
  family                = "task_definition_hyperflow_worker"
  container_definitions = "${data.template_file.task_definition_hyperflow_worker.rendered}"

  depends_on = [
    "data.template_file.task_definition_hyperflow_worker",
  ]
}

resource "aws_ecs_service" "hyperflow-service-worker" {
  name               = "hyperflow-service-worker"
  cluster            = "${aws_ecs_cluster.hyperflow_cluster.id}"
  task_definition    = "${aws_ecs_task_definition.task_hyperflow_worker.arn}"
  desired_count      = 2

  depends_on = [
    "aws_iam_role.ecs_service",
    "aws_ecs_service.hyperflow-service-master",
  ]
}


resource "aws_appautoscaling_target" "hyperflow_worker_target" {
  service_namespace = "ecs"
  resource_id = "service/${aws_ecs_cluster.hyperflow_cluster.name}/${aws_ecs_service.hyperflow-service-worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn = "${aws_iam_role.app_instance.arn}"
  min_capacity = 1
  max_capacity = 20

  depends_on = [
    "aws_ecs_cluster.hyperflow_cluster",
    "aws_ecs_service.hyperflow-service-worker"
  ]

}

resource "aws_appautoscaling_policy" "hyperflow_worker_up" {
  name                      = "hyperflow_worker_up"
  service_namespace         = "ecs"
  resource_id               = "service/${var.ecs_cluster_name}/${aws_ecs_service.hyperflow-service-worker.name}"
  scalable_dimension        = "ecs:service:DesiredCount"

  adjustment_type           = "ChangeInCapacity"
  cooldown                  = 300
  metric_aggregation_type   = "Average"

  step_adjustment {
    metric_interval_lower_bound = 0
    scaling_adjustment = "${var.worker_scaling_adjustment}"
  }
  depends_on = [
    "aws_appautoscaling_target.hyperflow_worker_target"
  ]
}



resource "aws_appautoscaling_policy" "hyperflow_worker_down" {
  name                      = "hyperflow_worker_down"
  service_namespace         = "ecs"
  resource_id               = "service/${var.ecs_cluster_name}/${aws_ecs_service.hyperflow-service-worker.name}"
  scalable_dimension        = "ecs:service:DesiredCount"

  adjustment_type           = "ChangeInCapacity"
  cooldown                  = 300
  metric_aggregation_type   = "Average"

  step_adjustment {
    metric_interval_lower_bound = 0
    scaling_adjustment = "${var.worker_scaling_adjustment_down}"
  }
  depends_on = [
    "aws_appautoscaling_target.hyperflow_worker_target"
  ]
}






