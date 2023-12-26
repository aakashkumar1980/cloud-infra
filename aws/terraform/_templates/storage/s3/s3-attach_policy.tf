resource "aws_s3_bucket_policy" "s3-attach_policy" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = var.policy

}
