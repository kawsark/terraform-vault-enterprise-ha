resource "aws_lb" "vault_lb" {
  name               = "${var.namespace}-alb"
  internal           = "${var.alb_internal}"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.mvd-sg.id}"]
  subnets            = ["${aws_subnet.mvd-public-1.id}","${aws_subnet.mvd-public-2.id}",]

  tags {
    owner = "${var.owner}"
  }
}

resource "aws_lb_target_group" "vault_tg_8200" {
  name               = "${var.namespace}-alb-tg-8200"
  port               = 8200
  protocol           = "HTTP"
  vpc_id             = "${aws_vpc.mvd_vpc.id}"
  target_type        = "instance"

  health_check {
    path      = "/v1/sys/health"
    protocol  = "HTTP"
    matcher   = "200"
    interval = "10"
    healthy_threshold = "2"
    unhealthy_threshold = "2"
  }

  tags {
    owner = "${var.owner}"
  }
}

resource "aws_lb_listener" "vault_8200" {
  load_balancer_arn   = "${aws_lb.vault_lb.arn}"
  port                = "8200"
  protocol            = "HTTPS"
  ssl_policy          = "ELBSecurityPolicy-2016-08"
  certificate_arn     = "${aws_acm_certificate.cert.arn}"

  default_action {
    type              = "forward"
    target_group_arn  = "${aws_lb_target_group.vault_tg_8200.arn}"
  }

  depends_on = ["aws_acm_certificate_validation.cert"]

}

resource "aws_lb_target_group_attachment" "vault_0" {
  target_group_arn    = "${aws_lb_target_group.vault_tg_8200.arn}"
  target_id           = "${module.n4.id}"
  port                = 8200
}

resource "aws_lb_target_group_attachment" "vault_1" {
  target_group_arn    = "${aws_lb_target_group.vault_tg_8200.arn}"
  target_id           = "${module.n5.id}"
  port                = 8200
}

# Data source to lookup zone id
data "aws_route53_zone" "pes" {
  name = "${var.route53_zone}"
  #private_zone = true for private zone
}
resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.hostname}"
  validation_method = "DNS"
}

# This allows ACM to validate the new certificate
resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.pes.zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

# This allows ACM to validate the new certificate
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

resource "aws_route53_record" "vault" {
  zone_id = "${data.aws_route53_zone.pes.zone_id}"
  name    = "${var.hostname}"
  type    = "A"

  alias {
    name    = "${aws_lb.vault_lb.dns_name}"
    zone_id = "${aws_lb.vault_lb.zone_id}"
    evaluate_target_health = false
  }
}