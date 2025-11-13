/**
 * Module Inputs
 *
 * region: AWS region string (e.g., "us-east-1")
 * vpcs:   map of VPC definitions (see sample below)
 * az_names: list of AZ names from data.aws_availability_zones
 * az_letter_to_ix: mapping to translate "a/b/c" → index in az_names
 * common_tags: merged tag set (lowercase)
 *
 * Example var.vpcs:
 * {
 *   vpc_a = {
 *     cidr = "10.0.0.0/24"
 *     subnets = [
 *       { id="1", name="public-a",  tier="public",  cidr="10.0.0.32/27", az="a" },
 *       { id="2", name="private-a", tier="private", cidr="10.0.0.96/27", az="a" }
 *     ]
 *   }
 * }
 *
 * Example var.az_names:
 *  [ "us-east-1", "eu-west-2" ]
 *
 * Example var.az_letter_to_ix:
 *  { a=0, b=1, c=2 }
 */
variable "region" { type = string }
variable "vpcs" { type = map(any) }
variable "az_names" { type = list(string) }
variable "az_letter_to_ix" { type = map(number) }
variable "common_tags" { type = map(string) }
