from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker

SQL_URL = "sqlite:///./sql_app.db"
engine = create_engine(SQL_URL)
SessionLocal = sessionmaker(bind=engine)
session = SessionLocal()

def check_tables():
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"Tables in DB: {tables}")
    
    for table in tables:
        print(f"\n--- Data in '{table}' ---")
        try:
            with engine.connect() as conn:
                result = conn.execute(text(f"SELECT * FROM {table}"))
                rows = result.fetchall()
                if not rows:
                    print("(Empty)")
                for row in rows:
                    print(row)
        except Exception as e:
            print(f"Error reading {table}: {e}")

if __name__ == "__main__":
    check_tables()
