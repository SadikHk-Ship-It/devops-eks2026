variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "candidate_number" {
  description = "Candidate number"
  type        = string
  default     = "29"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "ecr_repository" {
  description = "ECR repo name"
  type        = string
  default     = "devops-eks2026"
}