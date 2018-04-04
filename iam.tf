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
}

resource "aws_iam_role_policy" "instance" {
  name   = "ECSInstanceRole"
  role   = "${aws_iam_role.app_instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}