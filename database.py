
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

load_dotenv()

# 1. Get DB URL from Env
# We expect a Cloud DB URL (e.g. Supabase Postgres)
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

if not SQLALCHEMY_DATABASE_URL:
    # Fail loud if no DB is provided, or provide a dummy default if strictness varies
    # User asked to "remove local db logic", so we shouldn't default to sqlite.
    raise ValueError("DATABASE_URL is not set. Please set it to your Cloud DB URL (e.g. Supabase).")

# Fix for some cloud providers (like Heroku/Vercel) returning 'postgres://' instead of 'postgresql://'
if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)

# 2. Create the Engine
# Postgres does NOT need "check_same_thread"
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# 3. Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 4. Base class for models
Base = declarative_base()

# 5. Dependency helper for FastAPI
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()