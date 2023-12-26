# expose the created resources
output "output-keypair" {
  value = aws_key_pair.keypair
}
