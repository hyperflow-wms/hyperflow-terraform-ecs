# Definition of alarms and information when they should appear
# alarm_actions define what to do based on policy when alarm appear
resource "aws_cloudwatch_metric_alarm" "queue_lenth_high" {
  alarm_actions       = [ "${aws_autoscaling_policy.up.arn}" ,"${aws_appautoscaling_policy.hyperflow_worker_up.arn}" ]
  alarm_description   = "hyperflow alarm"
  alarm_name          = "${var.ecs_cluster_name}_queue_lenth_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "${var.alarm_evaluation_periods}" 
  metric_name         = "QueueLength"
  namespace           = "hyperflow"
  period              = "${var.alarm_high_period}"
  statistic           = "Average"
  threshold           = "${var.alarm_threshold_high}"

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
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "${var.alarm_evaluation_periods}" 
  metric_name         = "QueueLength"
  namespace           = "hyperflow"
  period              = "${var.alarm_low_period}"
  statistic           = "Average"
  threshold           = "${var.alarm_threshold_low}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.hyperflow_cluster.name}"
  }

  depends_on = [
    "aws_autoscaling_policy.down",
    "aws_appautoscaling_policy.hyperflow_worker_down"
  ]
}