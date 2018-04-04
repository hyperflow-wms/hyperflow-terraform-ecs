output "hyperflow_master_address" {
  value = "${aws_instance.hyperflowmaster.public_dns}"
}