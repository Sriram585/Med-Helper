from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

import os

# 1. Get DB URL from Env (Prod)
# If running in Vercel and no DATABASE_URL is set, fallback to /tmp/sql_app.db (writable but ephemeral)
if os.environ.get("VERCEL") and not os.environ.get("DATABASE_URL"):
    SQLALCHEMY_DATABASE_URL = "sqlite:////tmp/sql_app.db"
else:
    SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sql_app.db")

# Fix for some cloud providers (like Heroku/Vercel) returning 'postgres://' instead of 'postgresql://'
if SQLALCHEMY_DATABASE_URL and SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)

# 2. Create the Engine
# SQLite needs "check_same_thread", Postgres/others do NOT.
connect_args = {}
if "sqlite" in SQLALCHEMY_DATABASE_URL:
    connect_args = {"check_same_thread": False}

engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args=connect_args)

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