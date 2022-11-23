# # First retrieving the AWS Route 53 domain zone ID

# data "aws_route53_zone" "main" {
#   name         = var.aws_route53_domain
#   private_zone = false
# }


# # Creating the AWS Route 53 A Record

# resource "aws_route53_record" "www" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = var.aws_route53_subdomain
#   type    = "A"

#   alias {
#     name                   = aws_lb.main.dns_name
#     zone_id                = aws_lb.main.zone_id
#     evaluate_target_health = true
#   }
# }