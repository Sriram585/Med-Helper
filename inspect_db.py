from sqlalchemy import create_engine, inspect, text

# Connect to DB
engine = create_engine("sqlite:///./sql_app.db")

try:
    with engine.connect() as conn:
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        
        print(f"Tables found: {tables}")
        
        for table in tables:
            print(f"\n--- Data in '{table}' ---")
            try:
                result = conn.execute(text(f"SELECT * FROM {table}"))
                rows = result.fetchall()
                if not rows:
                    print("(Empty)")
                else:
                    # Print headers
                    print(result.keys()) 
                    for row in rows:
                        print(row)
            except Exception as e:
                print(f"Error reading {table}: {e}")

except Exception as e:
    print(f"Database Error: {e}")