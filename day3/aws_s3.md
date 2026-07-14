# AWS Resource Deep Dive — S3 (Simple Storage Service)

> This doc is about **S3 itself** — the AWS service, independent of Terraform. For how to
> *manage* S3 with Terraform, see [`first_resource.md`](2.%20first_resource/first_resource.md).
> Basic → advanced, in order. Skim ahead if you already know a section.

---

## 1. What S3 is, in one sentence

S3 is AWS's **object storage** service: you store arbitrary files ("objects") inside containers
("buckets") and access them over HTTPS, with virtually unlimited capacity and no servers to
manage.

---

## 2. Core vocabulary (basic)

| Term | Meaning |
|------|---------|
| **Bucket** | A top-level container for objects. Globally unique name, created in one region. |
| **Object** | A single file (any type, up to 5TB) plus metadata. |
| **Key** | The object's full name/path inside the bucket, e.g. `logs/2026/app.log`. There is no real folder hierarchy — the "/" is just a character in the key. Consoles *simulate* folders by grouping keys with a common prefix. |
| **Region** | Buckets live in one AWS region. The *name* is globally unique across all of AWS, but the *data* physically sits in that one region (unless you set up replication). |
| **Prefix** | The part of a key before the last "/" — used to filter/list "folders" of objects and to scope IAM policies or lifecycle rules to a subset of a bucket. |
| **ARN** | `arn:aws:s3:::bucket-name` for the bucket, `arn:aws:s3:::bucket-name/key` for an object. |

---

## 3. Durability, availability, and consistency (basic)

- **Durability: 99.999999999%** ("eleven nines") — S3 replicates every object across multiple
  facilities within a region. Losing an object due to an S3 hardware failure is astronomically
  unlikely.
- **Availability** varies by storage class (99.9%-99.99% typically) — the percentage of time the
  service itself is reachable, a different guarantee from durability.
- **Consistency:** S3 is **strongly consistent** for all operations (since Dec 2020) — as soon as
  a `PUT` succeeds, every subsequent `GET`/`LIST` sees it. Older material describing S3 as
  "eventually consistent" is out of date.

---

## 4. Storage classes (basic → intermediate)

Trade retrieval speed and availability for price. All are still "eleven nines" durable.

| Class | Use case | Retrieval |
|-------|----------|-----------|
| **Standard** | Frequently accessed data (default) | Milliseconds |
| **Intelligent-Tiering** | Access pattern unknown/changing | Milliseconds; auto-moves objects between tiers |
| **Standard-IA** (Infrequent Access) | Backups, older data accessed occasionally | Milliseconds, but a per-GB retrieval fee |
| **One Zone-IA** | Same as IA but only one AZ — cheaper, less resilient | Milliseconds |
| **Glacier Instant Retrieval** | Archive accessed rarely, needed instantly | Milliseconds |
| **Glacier Flexible Retrieval** | Archive, retrieval can wait | Minutes to hours |
| **Glacier Deep Archive** | Long-term compliance archives, cheapest storage AWS offers | ~12 hours |

**Lifecycle rules** (see §8) automate moving objects between classes as they age, without any
application code changes.

---

## 5. Security & access control (intermediate)

Four layers, usually used together, not as alternatives:

1. **IAM policies** (identity-based) — attached to a user/role, say what *that identity* can do
   to S3 in general or to specific buckets.
2. **Bucket policies** (resource-based) — attached to the bucket itself, say who (which
   principal/account) can do what *to this bucket*. The only way to grant **cross-account**
   access without the other account assuming a role.
3. **Block Public Access** — an account- and bucket-level setting that overrides *any* policy or
   ACL trying to make something public. **AWS enables this by default on all new buckets** — you
   must explicitly disable it (per-setting) to allow public access, which is why "accidentally
   public" S3 buckets are much rarer today than in the mid-2010s incidents you may have read
   about.
4. **ACLs (Access Control Lists)** — the legacy, pre-IAM access mechanism. AWS now recommends
   **disabling ACLs entirely** (bucket owner enforced) and using policies instead; ACLs mainly
   still matter for cross-account object ownership edge cases.

**Encryption:**
- **SSE-S3** — AWS manages the keys, encryption is on by default for all new buckets/objects.
- **SSE-KMS** — you manage the key (rotation, access policy, audit trail via CloudTrail) via AWS
  KMS; needed for stricter compliance requirements.
- **SSE-C** — you supply your own encryption key with every request; AWS never stores it. Rare in
  practice.
- **In transit:** enforce HTTPS-only access via a bucket policy condition on `aws:SecureTransport`.

---

## 6. Versioning & object lock (intermediate)

- **Versioning** — once enabled (and it **cannot be fully disabled again, only suspended**), every
  `PUT` to the same key creates a new version instead of overwriting; a "deleted" object just gets
  a delete marker, and the prior version is still retrievable. Protects against accidental
  overwrite/delete, at the cost of storing every version (billed).
- **MFA Delete** — an extra layer requiring MFA to permanently delete a version or change
  versioning state, for especially sensitive buckets.
- **Object Lock (WORM)** — Write-Once-Read-Many: makes objects genuinely undeletable/unmodifiable
  until a retention date, even by the account root user. Used for regulatory compliance (e.g.
  financial records retention).

---

## 7. Static website hosting (intermediate)

A bucket can serve `index.html`/`error.html` directly over HTTP(S) as a website endpoint. Two
approaches, in order of what AWS recommends today:
- **S3 + CloudFront (recommended)** — bucket stays fully private (Origin Access Control), the CDN
  is the only thing that can read it, and you get HTTPS, caching, and a custom domain "for free."
  This is what the course's real-app lab builds later.
- **S3 website endpoint directly** — simpler, but HTTP-only (no free HTTPS on the S3 endpoint
  itself) and the bucket must be public. Mostly a legacy/learning pattern now.

---

## 8. Lifecycle rules (intermediate → advanced)

Automate what happens to objects over time, scoped by prefix/tag:
- Transition to a cheaper storage class after N days (e.g. Standard → Standard-IA after 30 days →
  Glacier after 90 days).
- Expire (delete) objects after N days.
- Clean up incomplete multipart uploads (a common source of surprise storage cost — a failed
  upload can leave orphaned parts billed forever until this rule cleans them up).
- Expire old *versions* specifically (important once versioning is on, or storage cost silently
  grows forever).

---

## 9. Replication (advanced)

- **CRR (Cross-Region Replication)** — asynchronously copies objects to a bucket in another
  region. Used for disaster recovery, latency reduction for global users, or regulatory data
  residency requirements.
- **SRR (Same-Region Replication)** — copies within the same region, e.g. to separate a
  production account's data into a security/audit account, or to aggregate logs from many buckets.
- Requires versioning enabled on both source and destination buckets.

---

## 10. Performance & scale (advanced)

- S3 automatically scales request rate; the old advice to "randomize key prefixes for
  performance" is **no longer necessary** on the modern S3 request-routing architecture (post-2018).
- **Multipart upload** — required above 5GB, recommended above ~100MB; splits an upload into
  parallel parts, each retryable independently.
- **S3 Transfer Acceleration** — routes uploads through CloudFront edge locations for
  geographically distant clients.
- **S3 Select / Glacier Select** — run a SQL-like filter *inside* S3 to retrieve only the rows/
  columns you need from a CSV/JSON/Parquet object, instead of downloading the whole file first.

---

## 11. Cost model (advanced, but you should know this cold)

Billed on four independent axes — forgetting one is the usual source of a surprise bill:
1. **Storage** — per GB-month, varies by class.
2. **Requests** — per-request cost, `PUT`/`POST`/`LIST` cost more than `GET`.
3. **Data transfer OUT** to the internet (transfer *in*, and transfer to same-region AWS services
   like CloudFront/EC2, is free).
4. **Retrieval fees** on IA/Glacier classes, and **early-deletion fees** if you delete/transition
   an object before its class's minimum storage duration (e.g. Glacier Deep Archive has a 180-day
   minimum).

---

## 12. Common architecture patterns (advanced)

- **Static website / SPA hosting** — S3 + CloudFront.
- **Data lake** — raw + processed data, partitioned by key prefix (e.g.
  `s3://bucket/year=2026/month=07/`), queried in place by Athena/Redshift Spectrum without ever
  loading it into a database.
- **Backup/DR target** — versioned + replicated + lifecycle-managed for cost.
- **Terraform's own remote state backend** — you'll build this yourself on Day 9.
- **Event-driven pipelines** — S3 event notifications trigger a Lambda function the moment an
  object is uploaded (e.g. auto-generate a thumbnail, kick off a processing job).

---

## 13. Common mistakes at every level

- **Public bucket by accident** — mitigated today by Block Public Access being on by default;
  don't disable it without a specific, reviewed reason.
- **Forgetting lifecycle rules on a versioned bucket** — storage cost grows forever as old
  versions accumulate silently.
- **Not cleaning up incomplete multipart uploads** — billed storage with nothing to show for it.
- **Treating the "/" in a key as a real folder** — renaming a "folder" means copying every object
  to new keys and deleting the old ones; there is no atomic rename operation in S3.
- **Using ACLs for new buckets** — use bucket policies + Block Public Access instead; ACLs are a
  legacy mechanism AWS recommends disabling.

---

## Quick reference — AWS CLI

```bash
aws s3 ls                                    # list your buckets
aws s3 ls s3://my-bucket/ --recursive        # list every object (key) in a bucket
aws s3 cp file.txt s3://my-bucket/key.txt    # upload
aws s3 cp s3://my-bucket/key.txt -           # download and print to stdout
aws s3 sync ./local-folder s3://my-bucket/   # sync a whole directory
aws s3 rb s3://my-bucket --force             # delete a bucket AND everything in it
```
