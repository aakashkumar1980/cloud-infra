/**
 * Input Variables
 *
 * @var profile - The environment to deploy (dev, stage, prod).
 *                Must match an AWS CLI profile in ~/.aws/credentials.
 *                Also determines which config files to load from configs/<profile>/.
 */
variable "profile" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}
