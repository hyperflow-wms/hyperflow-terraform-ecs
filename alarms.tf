

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