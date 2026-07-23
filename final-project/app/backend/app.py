"""Minimal backend for the final-project 3-tier demo.

Reads DB credentials from AWS Secrets Manager, connects to Postgres, and
exposes two endpoints:
  GET /health     - liveness check
  GET /api/count  - inserts a row and returns the total row count

Environment variables:
  DB_SECRET_NAME  - Secrets Manager secret name/ARN holding
                    {"username", "password", "host", "port", "dbname"}
  AWS_REGION      - region the secret lives in (default: us-east-1)

Local/dev escape hatch: if DB_HOST is set, credentials are read directly
from env vars instead of Secrets Manager (see docker-compose.yml).
"""
import json
import os

import boto3
import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)

DB_SECRET_NAME = os.environ.get("DB_SECRET_NAME", "final-project/db-credentials")
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")

_db_conn = None


def get_db_credentials():
    if os.environ.get("DB_HOST"):
        return {
            "host": os.environ["DB_HOST"],
            "port": int(os.environ.get("DB_PORT", 5432)),
            "dbname": os.environ.get("DB_NAME", "postgres"),
            "username": os.environ.get("DB_USER", "postgres"),
            "password": os.environ.get("DB_PASSWORD", "postgres"),
        }
    client = boto3.client("secretsmanager", region_name=AWS_REGION)
    response = client.get_secret_value(SecretId=DB_SECRET_NAME)
    return json.loads(response["SecretString"])


def get_connection():
    global _db_conn
    if _db_conn is None or _db_conn.closed:
        creds = get_db_credentials()
        _db_conn = psycopg2.connect(
            host=creds["host"],
            port=creds.get("port", 5432),
            dbname=creds["dbname"],
            user=creds["username"],
            password=creds["password"],
        )
        _db_conn.autocommit = True
        with _db_conn.cursor() as cur:
            cur.execute(
                "CREATE TABLE IF NOT EXISTS visits ("
                "id SERIAL PRIMARY KEY, created_at TIMESTAMP DEFAULT NOW())"
            )
    return _db_conn


@app.get("/health")
def health():
    return jsonify(status="ok"), 200


@app.get("/api/count")
def count():
    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute("INSERT INTO visits DEFAULT VALUES")
        cur.execute("SELECT COUNT(*) FROM visits")
        total = cur.fetchone()[0]
    return jsonify(count=total), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
