from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
from hashing import Hash

# Create tables
models.Base.metadata.create_all(bind=engine)

def seed():
    db = SessionLocal()
    
    # 1. Check/Create Doctor
    doctor = db.query(models.Doctor).filter(models.Doctor.username == "doc").first()
    if not doctor:
        print("Creating Doctor: Dr. Sarah Smith (user: doc, pass: doc)")
        doc = models.Doctor(
            name="Dr. Sarah Smith",
            username="doc",
            email="sarah@medimind.com",
            mobile="9999999999",
            password_hash=Hash.bcrypt("doc"),
            specialty="General Physician"
        )
        db.add(doc)
    
    # 2. Check/Create Patient
    patient = db.query(models.Patient).filter(models.Patient.username == "pat").first()
    if not patient:
        print("Creating Patient: John Doe (user: pat, pass: pat)")
        pat = models.Patient(
            name="John Doe",
            username="pat",
            email="john@medimind.com",
            mobile="8888888888",
            password_hash=Hash.bcrypt("pat")
        )
        db.add(pat)

    db.commit()
    db.close()
    print("Seeding Complete.")

if __name__ == "__main__":
    seed()
