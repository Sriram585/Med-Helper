
from sqlalchemy import create_engine, inspect, text
import os
from dotenv import load_dotenv

load_dotenv()

db_url = os.getenv("DATABASE_URL")
if not db_url:
    print("DATABASE_URL not set")
    exit(1)

if db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql://", 1)

try:
    engine = create_engine(db_url)
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"Tables in DB: {tables}")
    
    for table in tables:
        print(f"\n--- Data in '{table}' ---")
        try:
            with engine.connect() as conn:
                result = conn.execute(text(f"SELECT * FROM {table} LIMIT 5"))
                rows = result.fetchall()
                if not rows:
                    print("(Empty)")
                else:
                    for row in rows:
                        print(row)
        except Exception as e:
            print(f"Error reading {table}: {e}")
except Exception as e:
    print(f"Error: {e}")
