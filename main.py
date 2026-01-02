import os
import json
import re
import csv
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

# --- 1. LOAD DATABASE & SYMPTOM LIST ---
def load_data():
    # Load Disease DB
    try:
        with open("medical_data.json", "r") as f:
            db = json.load(f)
    except FileNotFoundError:
        print("❌ medical_data.json missing.")
        db = {}

    # Load Severity Weights & Master Symptom List
    weights = {}
    master_list = []
    try:
        with open("Symptom-severity.csv", "r") as f:
            reader = csv.reader(f)
            next(reader) # Skip header
            for row in reader:
                if len(row) >= 2:
                    # Store as "skin rash" (clean format)
                    s_clean = row[0].replace('_', ' ').strip().lower()
                    weights[s_clean] = int(row[1])
                    master_list.append(s_clean)
    except FileNotFoundError:
        print("⚠️ Symptom-severity.csv missing.")
    
    print(f"✅ Loaded {len(master_list)} unique symptoms for matching.")
    return db, weights, master_list

MEDICAL_DB, SYMPTOM_WEIGHTS, MASTER_SYMPTOMS = load_data()

# --- 2. AI SYMPTOM EXTRACTION (The Fix) ---
async def extract_symptoms_ai(user_text):
    """
    Uses LLM to map messy user text ('i have headche nd fever') 
    to exact database keys (['headache', 'high fever']).
    """
    prompt = f"""
    You are a precise medical entity extractor.
    
    **TASK:** Analyze the User Input and map it to the closest matches in the Valid Symptoms List.
    - Handle typos (e.g., "fevr" -> "high fever").
    - Handle synonyms (e.g., "tummy ache" -> "stomach pain").
    - Ignore irrelevant words ("i have", "nd", "maybe").
    
    **VALID SYMPTOMS LIST:**
    {json.dumps(MASTER_SYMPTOMS)}

    **USER INPUT:** "{user_text}"

    **OUTPUT:** Return ONLY a valid JSON List of strings from the Valid List.
    Example: ["itching", "skin rash"]
    If no match, return [].
    """

    try:
        chat = await client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.3-70b-versatile",
            temperature=0.0, # Zero temp for strict matching
            response_format={"type": "json_object"}
        )
        
        result = json.loads(chat.choices[0].message.content)
        
        # Handle different return formats keys
        if isinstance(result, dict):
            # If AI returns {"symptoms": [...]}, extract the list
            return list(result.values())[0]
        elif isinstance(result, list):
            return result
        return []

    except Exception as e:
        print(f"⚠️ Extraction Error: {e}")
        return []

# --- 3. SCORING ENGINE (Weighted) ---
def calculate_disease_scores(confirmed_symptoms):
    """
    Calculates disease probability based on the AI-extracted symptoms.
    """
    if not confirmed_symptoms:
        return []

    scored_results = []
    
    # Pre-calculate set for speed
    user_symptom_set = set(confirmed_symptoms)

    for disease, data in MEDICAL_DB.items():
        # Get disease symptoms (clean them to match master list format)
        disease_symptoms = set([s.replace('_', ' ').lower() for s in data.get('symptoms', [])])
        
        # Find Intersection
        matches = user_symptom_set.intersection(disease_symptoms)
        
        if matches:
            # 1. Calculate Weighted Score
            raw_score = sum(SYMPTOM_WEIGHTS.get(m, 1) for m in matches)
            
            # 2. Calculate Coverage (How much of the disease did we match?)
            # This prevents "Itching" (Weight 1) from triggering a serious disease 
            # that requires 10 other symptoms.
            total_disease_weight = sum(SYMPTOM_WEIGHTS.get(s, 1) for s in disease_symptoms)
            if total_disease_weight == 0: total_disease_weight = 1
            
            # Final Score combines Raw Impact + Coverage
            final_metric = (raw_score / total_disease_weight) * 100
            
            scored_results.append({
                "disease": disease,
                "score": final_metric,
                "matched_symptoms": list(matches),
                "medication": data.get('medication', [])
            })

    # Sort by Score
    scored_results.sort(key=lambda x: x['score'], reverse=True)
    
    # Normalize top result to ~95-98% for UI confidence
    if scored_results:
        top_score = scored_results[0]['score']
        for item in scored_results:
            # Scale relative to the winner
            item['confidence'] = int((item['score'] / top_score) * 98)

    return scored_results

# --- 4. API ENDPOINT ---
@app.post("/analyze")
async def analyze_symptoms(request: SymptomRequest):
    print(f"📩 Raw Input: {request.symptoms}")
    
    # STEP 1: AI Extraction (Solves "nd", typos, phrasing)
    extracted_symptoms = await extract_symptoms_ai(request.symptoms)
    print(f"🔍 Extracted: {extracted_symptoms}")
    
    if not extracted_symptoms:
        return {"results": []}

    # STEP 2: Mathematical Scoring
    top_matches = calculate_disease_scores(extracted_symptoms)[:3]
    
    if not top_matches:
        return {"results": []}

    # STEP 3: Generate Details (Diet/Workout)
    diseases_to_process = [
        {"name": item['disease'], "meds": item['medication']} 
        for item in top_matches
    ]

    prompt_details = f"""
    You are a medical expert.
    Conditions: {json.dumps([d['name'] for d in diseases_to_process])}

    Generate a JSON List of objects (same order) with:
    - "description" (short string)
    - "diet" (list of strings)
    - "workout" (list of strings)
    - "precautions" (list of strings)
    
    Return JSON List only.
    """

    try:
        chat = await client.chat.completions.create(
            messages=[{"role": "user", "content": prompt_details}],
            model="llama-3.3-70b-versatile",
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        
        # Parse Response
        raw_text = chat.choices[0].message.content
        # Remove markdown if present
        raw_text = re.sub(r"```json\s*|```", "", raw_text).strip()
        ai_data = json.loads(raw_text)
        
        if isinstance(ai_data, dict):
            ai_data = list(ai_data.values())[0]

        # Merge Results
        final_results = []
        for i, match in enumerate(top_matches):
            if i < len(ai_data):
                merged = {
                    "disease": match['disease'],
                    "confidence": match['confidence'],
                    "medication": match['medication'],
                    "description": ai_data[i].get('description', 'Details unavailable'),
                    "diet": ai_data[i].get('diet', []),
                    "workout": ai_data[i].get('workout', []),
                    "precautions": ai_data[i].get('precautions', [])
                }
                final_results.append(merged)

        return {"results": final_results}

    except Exception as e:
        print(f"❌ Error: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)