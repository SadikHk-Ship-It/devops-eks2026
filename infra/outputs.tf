output "bucket_name" {
  value = aws_s3_bucket.wishifai.bucket
}


output "service_url" {
  value = aws_ecs_express_gateway_service.wishifai.ingress_paths[0].endpoint
}