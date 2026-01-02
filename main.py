import os
import json
import re
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from groq import AsyncGroq
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = AsyncGroq(
    api_key=os.environ.get("GROQ_API_KEY"),
)

class SymptomRequest(BaseModel):
    symptoms: str

# --- 1. LOAD DATABASE (For Medication Lookup) ---
def load_medical_db():
    try:
        # We try to load the file to get the medications
        with open("medical_data.json", "r") as f:
            data = json.load(f)
            print(f"✅ Database loaded: {len(data)} entries found.")
            return data
    except FileNotFoundError:
        print("❌ ERROR: medical_data.json not found.")
        return {}

MEDICAL_DB = load_medical_db()

# --- 2. MATCHING LOGIC ---
def find_best_match(user_text):
    """
    Finds the disease in the DB to retrieve the correct medications.
    """
    user_text = user_text.lower().strip()
    best_disease = None
    highest_score = 0

    # A. Exact Match
    for disease in MEDICAL_DB.keys():
        if disease in user_text:
            return disease, MEDICAL_DB[disease]

    # B. Symptom Keyword Match
    user_words = set(re.findall(r'\w+', user_text))
    
    for disease, data in MEDICAL_DB.items():
        # We check the symptoms list in the DB to find the disease
        db_symptoms = data.get('symptoms', [])
        
        score = 0
        disease_symptoms_str = " ".join(db_symptoms).lower()
        
        for word in user_words:
            if len(word) > 3 and word in disease_symptoms_str:
                score += 1
        
        if score > highest_score:
            highest_score = score
            best_disease = disease

    if highest_score >= 1:
        return best_disease, MEDICAL_DB[best_disease]
    
    return None, None

def clean_json_string(json_string):
    cleaned = re.sub(r"```json\s*", "", json_string)
    cleaned = re.sub(r"```", "", cleaned)
    return cleaned.strip()

# --- 3. API ENDPOINT ---
@app.post("/analyze")
async def analyze_symptoms(request: SymptomRequest):
    print(f"\n📩 Input: {request.symptoms}")
    
    # Step A: Identify Disease & Fetch Meds from File
    matched_disease, db_data = find_best_match(request.symptoms)

    if matched_disease:
        print(f"✅ MATCH: {matched_disease.upper()}")
        
        # 1. GET MEDS FROM FILE (Strict)
        file_meds = db_data.get('medication', [])
        
        # 2. CONSTRUCT PROMPT (Hybrid)
        # We give the AI the file meds, but ask it to generate the rest.
        final_prompt = f"""
        You are a medical expert API.
        
        **Patient Diagnosis:** {matched_disease.upper()}
        **Patient Symptoms:** "{request.symptoms}"
        
        **INSTRUCTIONS:**
        1. **MEDICATION (Strict):** You MUST output the following list exactly. Do not add or remove anything: 
           {json.dumps(file_meds)}
           
        2. **OTHER FIELDS (Generative):** Use your own medical knowledge to generate:
           - A short 'description' of the disease.
           - A 'diet' plan (list of foods).
           - 'workout' or lifestyle tips (list).
           - 'precautions' (list).

        **OUTPUT FORMAT (JSON ONLY):**
        {{
            "description": "string",
            "medication": ["string", "string"],
            "diet": ["string", "string"],
            "workout": ["string", "string"],
            "precautions": ["string", "string"]
        }}
        """
    else:
        # Fallback if disease not in JSON
        print("⚠️ No Match. Using pure AI.")
        final_prompt = f"""
        User symptoms: "{request.symptoms}".
        Identify the likely condition. 
        Generate valid JSON with: description, medication (general advice only), diet, workout, precautions.
        """

    # Step B: Call Groq
    try:
        chat_completion = await client.chat.completions.create(
            messages=[
                {"role": "system", "content": "You are a medical API. Return valid JSON only."},
                {"role": "user", "content": final_prompt}
            ],
            model="llama-3.3-70b-versatile",
            temperature=0.3, # Slight creativity allowed for diet/workout
            response_format={"type": "json_object"}
        )

        response_text = chat_completion.choices[0].message.content
        return json.loads(clean_json_string(response_text))

    except Exception as e:
        print(f"❌ Error: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)