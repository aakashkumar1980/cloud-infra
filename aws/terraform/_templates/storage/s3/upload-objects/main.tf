resource "aws_s3_bucket_object" "upload-objects" {
  for_each = fileset("${var.base_path}/", "**/*")

  bucket       = var.bucket_id
  key          = each.value
  source       = "${var.base_path}/${each.value}"
  content_type = lookup(var.mime_types, regex("\\.[^.]+$", each.value), null)
  etag         = filemd5("${var.base_path}/${each.value}")
}
