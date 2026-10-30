resource "aws_s3_bucket" "wishifai" {
  bucket = "wishifai-${var.candidate_number}"
}