variable "server_port" {
  description = "The port the server will use for rabbitmq"
  default = 5672
}

variable "master_count"
{
    default = 1
}

#cooldown - The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start
variable "aws_autoscaling_cooldown"
{
    default = 120
}

variable "aws_appautoscaling_cooldown"
{
    default = 300
}

## worker_min_capacity and worker_max_capacity for aws_appautoscaling_target
variable "worker_min_capacity"
{
    default = 1
}

#max capacity is required, setting large number that it should be not reached
variable "worker_max_capacity"
{
    default = 1000
}

