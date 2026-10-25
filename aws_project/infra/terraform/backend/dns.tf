locals {
  origin_domain = "origin.${data.terraform_remote_state.dns.outputs.domain_name}"
}

resource "aws_route53_record" "origin" {
  zone_id = data.terraform_remote_state.dns.outputs.zone_id
  name    = local.origin_domain
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }
}
