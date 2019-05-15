
resource "aws_kms_key" "vault" {
  description             = "Key for Vault auto-seal"
  deletion_window_in_days = 10

  tags {
    owner = "${var.owner}"
    name = "${var.namespace}"
  }
}

resource "aws_kms_alias" "vault" {
  name = "alias/${var.namespace}-vault-unseal-key"
  target_key_id = "${aws_kms_key.vault.key_id}"
}

resource "aws_iam_role" "assume_role_vault" {
  name = "${var.namespace}-iam_role_vault"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "assume_role_consul" {
  name = "${var.namespace}-iam_role_consul"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "vault" {
  name = "${var.namespace}-instance_profile_vault"
  role = "${aws_iam_role.assume_role_vault.name}"
}

resource "aws_iam_instance_profile" "consul" {
  name = "${var.namespace}-instance_profile_consul"
  role = "${aws_iam_role.assume_role_consul.name}"
}

data "aws_iam_policy_document" "vault_unseal_policy" {

  statement {
    sid    = "AllowKMS"
    effect = "Allow"

    resources = [
      "${aws_kms_key.vault.arn}",
    ]

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey"
    ]
  }
}

data "aws_iam_policy_document" "consul_autojoin_policy" {

  statement {
    sid    = "AllowEC2"
    effect = "Allow"

    resources = [
      "*",
    ]
   
    actions = [
      "ec2:DescribeInstances"
    ]
  }
}
resource "aws_iam_role_policy" "vault" {
  name   = "${var.namespace}-iam_role_policy"
  role   = "${aws_iam_role.assume_role_vault.name}"
  policy = "${data.aws_iam_policy_document.vault_unseal_policy.json}"
}

resource "aws_iam_role_policy" "consul" {
  name   = "${var.namespace}-iam_role_policy"
  role   = "${aws_iam_role.assume_role_consul.name}"
  policy = "${data.aws_iam_policy_document.consul_autojoin_policy.json}"
}
