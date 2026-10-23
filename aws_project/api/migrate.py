import os
import pathlib

import psycopg
from psycopg.conninfo import make_conninfo

conninfo = make_conninfo(
    host=os.environ["DB_HOST"],
    port=os.environ.get("DB_PORT", "5432"),
    dbname=os.environ.get("DB_NAME", "bankapi"),
    user=os.environ["DB_USER"],
    password=os.environ["DB_PASSWORD"],
    sslmode=os.environ.get("DB_SSLMODE", "require"),
    connect_timeout=10,
)

migrations_dir = pathlib.Path(__file__).parent / "migrations"

with psycopg.connect(conninfo, autocommit=True) as conn:
    for path in sorted(migrations_dir.glob("*.sql")):
        print(f"Applying {path.name}", flush=True)
        conn.execute(path.read_text())

print("Migrations applied", flush=True)
