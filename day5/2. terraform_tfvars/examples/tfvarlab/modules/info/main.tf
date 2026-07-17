# =============================================================================
# modules/info/main.tf  —  No `provider` block — inherits the root's, which
# was itself configured using var.region (the value that won the whole
# precedence chain). data.aws_region below independently confirms that.
# =============================================================================

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
