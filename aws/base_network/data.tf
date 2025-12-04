/**
 * Data Sources
 *
 * Fetches the list of available availability zones in each region.
 * This is used to map zone letters (a, b, c) to actual zone names
 * like us-east-1a, eu-west-2b, etc.
 *
 * TERRAFORM LIMITATION:
 *   Data sources with provider aliases cannot use for_each.
 *   Each region requires its own data source block.
 */

# ─────────────────────────────────────────────────────────────────────────────
# N. Virginia Region (us-east-1)
# ─────────────────────────────────────────────────────────────────────────────
data "aws_availability_zones" "nvirginia" {
  provider = aws.nvirginia
  state    = "available"
}

# ─────────────────────────────────────────────────────────────────────────────
# London Region (eu-west-2)
# ─────────────────────────────────────────────────────────────────────────────
data "aws_availability_zones" "london" {
  provider = aws.london
  state    = "available"
}
