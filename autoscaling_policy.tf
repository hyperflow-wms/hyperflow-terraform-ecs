
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
