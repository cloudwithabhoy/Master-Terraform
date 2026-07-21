# =============================================================================
# import.tf  —  Added ALONGSIDE main.tf's existing aws_s3_bucket.app_logs —
# this is the realistic case: bringing one new resource into an already-real
# codebase, not starting from an empty folder. Replace
# "i-replace-with-a-real-id" with the real instance ID from the EC2 instance
# you launch by hand in how_to_run.md's Step 2, before applying this.
# =============================================================================

# --- Step 1: declare the import (matches §3) -----------------------------------
import {
  to = aws_instance.legacy
  id = "i-replace-with-a-real-id"
}

# --- Step 2: a matching resource block ------------------------------------------
# Don't write this by hand — run:
#   terraform plan -generate-config-out="generated.tf"
# with the import block above and NO resource block yet, then review and move
# the generated content here instead. main.tf's aws_s3_bucket.app_logs will
# show "0 to change" in the same plan — proof the import doesn't touch your
# existing resources at all.
