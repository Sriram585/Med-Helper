
from sqlalchemy import create_engine, inspect, text
import os
from dotenv import load_dotenv

# Load env to get DATABASE_URL
load_dotenv()

db_url = os.getenv("DATABASE_URL")
if not db_url:
    print("DATABASE_URL not set in .env")
    exit(1)

# Fix postgres:// -> postgresql://
if db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql://", 1)

print(f"Connecting to: {db_url.split('@')[-1]}") # Print only host part for security

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        
        print(f"Tables found: {tables}")
        
        for table in tables:
            print(f"\n--- Data in '{table}' ---")
            try:
                # Limit to 10 rows to avoid flooding
                result = conn.execute(text(f"SELECT * FROM {table} LIMIT 10"))
                keys = result.keys()
                rows = result.fetchall()
                
                print(list(keys))
                if not rows:
                    print("(Empty)")
                else:
                    for row in rows:
                        print(row)
            except Exception as e:
                print(f"Error reading {table}: {e}")

except Exception as e:
    print(f"Database Error: {e}")