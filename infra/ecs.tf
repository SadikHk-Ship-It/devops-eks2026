resource "aws_ecs_express_gateway_service" "wishifai" {

  execution_role_arn = "arn:aws:iam::244530008913:role/ecsTaskExecutionRole"

  infrastructure_role_arn = "arn:aws:iam::244530008913:role/service-role/ecsInfrastructureRoleForExpressServices"

  health_check_path = "/api/health"

  task_role_arn = aws_iam_role.wishifai_task_role.arn

  primary_container {

    image = "244530008913.dkr.ecr.eu-west-1.amazonaws.com/${var.ecr_repository}:${var.image_tag}"

    container_port = 8080

    environment {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.wishifai.bucket
    }

    environment {
      name  = "AWS_REGION"
      value = var.aws_region
    }
  }
}