from sqlalchemy import Column, Integer, String
from database import Base
class Patient(Base):
    __tablename__ = "patients"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, index=True) # Removed unique=True
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)
    mobile = Column(String, unique=True, index=True) # Added unique=True
    name = Column(String)

class Doctor(Base):
    __tablename__ = "doctors"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, index=True) # Removed unique=True
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)
    mobile = Column(String, unique=True, index=True) # Added unique=True
    name = Column(String)
    specialty = Column(String, nullable=True)