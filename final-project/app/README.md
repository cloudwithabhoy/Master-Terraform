# The Application

A deliberately minimal 3-tier demo — just enough to prove the infrastructure actually works end
to end (ECR pull, security-group chain, Secrets Manager, RDS connectivity), not a real product.

- **`backend/`** — Flask app. Reads DB credentials from Secrets Manager (or `DB_HOST`/etc. env
  vars for local testing), connects to Postgres, exposes `/health` and `/api/count`.
- **`frontend/`** — Flask app. Calls the backend's `/api/count` and renders the result as a
  simple HTML page.

## Test it locally first, before touching AWS at all

```bash
cd final-project/app
docker compose up --build
```

Then open **http://localhost:3000** — each refresh increments the counter, proving
frontend → backend → Postgres works, entirely on your machine, no AWS involved yet.

## Building and pushing to ECR (once the `ecr` module exists)

```bash
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com

docker build -t <account-id>.dkr.ecr.<region>.amazonaws.com/final-project-backend:latest ./backend
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/final-project-backend:latest

docker build -t <account-id>.dkr.ecr.<region>.amazonaws.com/final-project-frontend:latest ./frontend
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/final-project-frontend:latest
```

This will eventually become its own GitHub Actions workflow ("app CI," separate from the
Terraform plan/apply workflows) — not built yet.
