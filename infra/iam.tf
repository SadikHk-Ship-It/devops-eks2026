resource "aws_iam_role" "wishifai_task_role" {
  name = "wishifai-task-role-${var.candidate_number}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "wishifai_policy" {
  name = "wishifai-policy-${var.candidate_number}"
  role = aws_iam_role.wishifai_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = [
          "${aws_s3_bucket.wishifai.arn}/*"
        ]
      },

      {
        Effect = "Allow"

        Action = [
          "rekognition:DetectLabels"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "bedrock:InvokeModel"
        ]

        Resource = "*"
      }
    ]
  })
}