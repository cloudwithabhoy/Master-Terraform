"""Minimal frontend for the final-project 3-tier demo.

Calls the backend's /api/count endpoint and renders the result as a simple
HTML page - this is what proves frontend -> backend -> database actually
works end to end, not just that instances can boot.

Environment variables:
  BACKEND_URL - base URL of the backend, e.g. http://<backend-private-ip>:8080
"""
import os

import requests
from flask import Flask

app = Flask(__name__)

BACKEND_URL = os.environ.get("BACKEND_URL", "http://localhost:8080")


@app.get("/health")
def health():
    return "ok", 200


@app.get("/")
def index():
    try:
        resp = requests.get(f"{BACKEND_URL}/api/count", timeout=5)
        resp.raise_for_status()
        visit_count = resp.json()["count"]
        return f"""
        <html>
          <body style="font-family: sans-serif; text-align: center; margin-top: 10%;">
            <h1>3-Tier Demo</h1>
            <p>This page has been viewed <strong>{visit_count}</strong> times.</p>
            <p style="color: gray;">Frontend (EC2) &rarr; Backend (EC2) &rarr; RDS PostgreSQL</p>
          </body>
        </html>
        """, 200
    except Exception as exc:
        return f"<h1>Frontend is up, but the backend call failed:</h1><pre>{exc}</pre>", 502


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
