# =============================================================================
# import.tf  —  Added ALONGSIDE main.tf's existing aws_s3_bucket.app_logs —
# this is the realistic case: bringing one new resource into an already-real
# codebase, not starting from an empty folder. Replace
# "i-replace-with-a-real-id" with the real instance ID from the EC2 instance
# you launch by hand in how_to_run.md's Step 2, before applying this.
#
# This file should hold ONLY the import block below — nothing else. It's
# throwaway scaffolding for a one-time migration: once the import is applied,
# delete this whole file (how_to_run.md Step 6). The resource block itself
# belongs in main.tf, not here.
# =============================================================================

# --- Step 1: declare the import (matches §3) -----------------------------------
import {
  to = aws_instance.legacy
  id = "i-replace-with-a-real-id"
}
