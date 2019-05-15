# Render userdata
data "template_file" "consul_userdata" {
  template = "${file("${path.module}/scripts/consul-server.tpl")}"
  vars {
    dc = "${var.consul_dc}"
    #retry_join  = "[\"${lookup(var.private_ip_map,"n2")}\",\"${lookup(var.private_ip_map,"n3")}\"]"
    retry_join  = "[\"provider=aws tag_key=app tag_value=consul-ent-${var.namespace}-${var.consul_dc}\"]"
    consul_server_count = "${var.consul_server_count}"
    consul_license="${var.consul_license}"
  }
}

data "template_file" "n4_userdata" {
  template = "${file("${path.module}/scripts/vault-server.tpl")}"
  vars {
    dc = "${var.consul_dc}"
    retry_join  = "[\"${lookup(var.private_ip_map,"n1")}\",\"${lookup(var.private_ip_map,"n2")}\",\"${lookup(var.private_ip_map,"n3")}\"]"
    vault_license="${var.vault_license}"
    aws_region = "${var.aws_region}"
    kms_key_id = "${aws_kms_key.vault.arn}"
  }
}

data "template_file" "n5_userdata" {
  template = "${file("${path.module}/scripts/vault-server.1.tpl")}"
  vars {
    dc = "${var.consul_dc}"
    retry_join  = "[\"${lookup(var.private_ip_map,"n1")}\",\"${lookup(var.private_ip_map,"n2")}\",\"${lookup(var.private_ip_map,"n3")}\"]"
    vault_license="${var.vault_license}"
    aws_region = "${var.aws_region}"
    kms_key_id = "${aws_kms_key.vault.arn}"
  }
}