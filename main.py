import os
import json
import re
import uvicorn
import uuid
from typing import List, Optional
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from groq import AsyncGroq
from dotenv import load_dotenv
import pypdf
import io

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = AsyncGroq(api_key=os.environ.get("GROQ_API_KEY"))

# --- MODELS ---
class SymptomRequest(BaseModel):
    symptoms: str

class ChatRequest(BaseModel):
    message: str
    history: List[dict] = [] # [{"role": "user", "content": "..."}]


class DietRequest(BaseModel):
    goal: str
    preferences: str
    calories: Optional[int] = 2000

class WorkoutRequest(BaseModel):
    goal: str
    level: str
    equipment: str

class LabReportRequest(BaseModel):
    report_text: str

# ==========================================
# 1. INTERNAL KNOWLEDGE (Replaces CSVs)
# ==========================================
# Weights for scoring (Severity 1-7)
INTERNAL_WEIGHTS = {
    "itching": 1, "skin rash": 3, "nodal skin eruptions": 4, "continuous sneezing": 4,
    "shivering": 5, "chills": 3, "joint pain": 3, "stomach pain": 5, "acidity": 3,
    "ulcers on tongue": 4, "vomiting": 5, "burning micturition": 6, "fatigue": 4,
    "weight gain": 3, "anxiety": 4, "cold hands and feets": 5, "mood swings": 3,
    "weight loss": 3, "restlessness": 5, "lethargy": 2, "patches in throat": 6,
    "irregular sugar level": 5, "cough": 4, "high fever": 7, "sunken eyes": 3,
    "breathlessness": 4, "sweating": 3, "dehydration": 4, "indigestion": 5,
    "headache": 3, "yellowish skin": 3, "dark urine": 4, "nausea": 5,
    "loss of appetite": 4, "pain behind the eyes": 4, "back pain": 3,
    "constipation": 4, "abdominal pain": 4, "diarrhoea": 6, "mild fever": 5,
    "yellow urine": 4, "yellowing of eyes": 4, "acute liver failure": 6,
    "swelling of stomach": 7, "blurred and distorted vision": 5, "phlegm": 5,
    "throat irritation": 4, "redness of eyes": 5, "sinus pressure": 4,
    "runny nose": 5, "congestion": 5, "chest pain": 7, "weakness in limbs": 7,
    "fast heart rate": 5, "pain during bowel movements": 5, "pain in anal region": 6,
    "bloody stool": 5, "irritation in anus": 6, "neck pain": 5, "dizziness": 4,
    "cramps": 4, "bruising": 4, "obesity": 4, "swollen legs": 5,
    "swollen blood vessels": 5, "puffy face and eyes": 5, "enlarged thyroid": 6,
    "brittle nails": 5, "swollen extremeties": 5, "excessive hunger": 4,
    "extra marital contacts": 5, "drying and tingling lips": 4, "slurred speech": 4,
    "knee pain": 3, "hip joint pain": 2, "muscle weakness": 2, "stiff neck": 4,
    "swelling joints": 5, "movement stiffness": 5, "spinning movements": 6,
    "loss of balance": 4, "unsteadiness": 4, "weakness of one body side": 4,
    "loss of smell": 3, "bladder discomfort": 4, "foul smell of urine": 5,
    "continuous feel of urine": 6, "passage of gases": 5, "internal itching": 4,
    "depression": 3, "irritability": 2, "muscle pain": 2, "altered sensorium": 2,
    "red spots over body": 3, "belly pain": 4, "abnormal menstruation": 6,
    "dischromic patches": 6, "watering from eyes": 4, "increased appetite": 5,
    "polyuria": 4, "family history": 5, "mucoid sputum": 4, "rusty sputum": 4,
    "lack of concentration": 3, "visual disturbances": 3, "coma": 7,
    "stomach bleeding": 6, "distention of abdomen": 4, "fluid overload": 4,
    "blood in sputum": 5, "prominent veins on calf": 6, "palpitations": 4,
    "painful walking": 2, "pus filled pimples": 2, "blackheads": 2, "scurring": 2,
    "skin peeling": 3, "silver like dusting": 3, "small dents in nails": 2,
    "inflammatory nails": 2, "blister": 4, "red sore around nose": 4,
    "yellow crust ooze": 4
}

# ==========================================
# 2. LOAD MEDICAL DATA (JSON ONLY)
# ==========================================
def load_json_file(filename, default_value):
    try:
        with open(filename, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return default_value

def save_json_file(filename, data):
    with open(filename, "w") as f:
        json.dump(data, f, indent=4)

MEDICAL_DB = load_json_file("medical_data.json", {})

# ==========================================
# 3. AI SYMPTOM EXTRACTION
# ==========================================
async def extract_symptoms_ai(user_text):
    """
    Cleans user input to match database keys.
    """
    valid_list = list(INTERNAL_WEIGHTS.keys())
    
    prompt = f"""
    Analyze user text: "{user_text}"
    Map to closest match in this list: {json.dumps(valid_list)}
    
    Rules:
    - Return JSON List of strings.
    - Fix typos ("hedache" -> "headache").
    - Map general terms to specific ones (e.g. "fever" -> "high fever", "cold" -> "continuous sneezing").
    - If unsure, include the closest match. Only return empty list if completely unrelated.
    """
    try:
        chat = await client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.3-70b-versatile",
            temperature=0.0,
            response_format={"type": "json_object"}
        )
        res = json.loads(chat.choices[0].message.content)
        print(f"DEBUG LLM RESPONSE: {res}")
        if isinstance(res, dict): return list(res.values())[0]
        return res
    except Exception as e:
        print(f"DEBUG ERROR: {e}")
        return []

# ==========================================
# 4. SCORING ENGINE
# ==========================================
def score_diseases(user_symptoms):
    if not MEDICAL_DB: return []
    
    scored = []
    user_set = set(user_symptoms)
    
    for disease, data in MEDICAL_DB.items():
        # Clean DB symptoms
        db_symptoms = set([s.replace('_', ' ').lower().strip() for s in data.get('symptoms', [])])
        
        matches = user_set.intersection(db_symptoms)
        
        if matches:
            # Score = Sum of Weights of Matched Symptoms
            raw_score = sum(INTERNAL_WEIGHTS.get(m, 1) for m in matches)
            
            # Normalization factor (Total weight of the disease)
            total_weight = sum(INTERNAL_WEIGHTS.get(s, 1) for s in db_symptoms) or 1
            
            # Confidence Percentage
            confidence = (raw_score / total_weight) * 100
            
            # Boost for multiple matches to favor specificity
            if len(matches) > 1: confidence += 15
            
            scored.append({
                "disease": disease,
                "confidence": min(int(confidence), 99),
                # "medication": data.get('medication', []), # REMOVED
                "matches": list(matches)
            })
            
    scored.sort(key=lambda x: x['confidence'], reverse=True)
    return scored[:3]

# ==========================================
# 5. GENERATIVE AI (Details)
# ==========================================
async def generate_details(matches):
    """
    Takes top matches and asks AI for Diet/Workout/Description/Precautions.
    """
    diseases = [m['disease'] for m in matches]
    
    prompt = f"""
    You are a medical expert.
    Diseases: {json.dumps(diseases)}
    
    For EACH disease, generate a JSON object with:
    - "description": Short medical summary.
    - "diet": List of 4 foods.
    - "workout": List of 3 activities.
    - "precautions": List of 3 tips.
    
    Return JSON LIST only. Order must match input.
    """
    
    try:
        chat = await client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.3-70b-versatile",
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        raw = chat.choices[0].message.content
        data = json.loads(re.sub(r"```json|```", "", raw).strip())
        
        if isinstance(data, dict):
            for v in data.values():
                if isinstance(v, list): return v
        return data
    except:
        return []

# ==========================================
# 6. MAIN API ROUTES
# ==========================================
@app.post("/analyze")
async def analyze(request: SymptomRequest):
    print(f"📩 Input: {request.symptoms}")
    
    # 1. Extract
    symptoms = await extract_symptoms_ai(request.symptoms)
    print(f"🔍 Extracted: {symptoms}")
    
    # 2. Score
    top_matches = score_diseases(symptoms)
    
    # 3. If No DB Match -> Pure AI Fallback
    if not top_matches:
        print("⚠️ No Database Match. Switching to Pure AI.")
        fallback_prompt = f"Diagnose: {request.symptoms}. Return JSON List of top 3 conditions with fields: disease, confidence(int), description, medication(list), diet(list), workout(list), precautions(list)."
        try:
            chat = await client.chat.completions.create(
                 messages=[{"role": "user", "content": fallback_prompt}],
                 model="llama-3.3-70b-versatile",
                 response_format={"type": "json_object"}
            )
            res = json.loads(chat.choices[0].message.content)
            if isinstance(res, dict):
                for v in res.values():
                    if isinstance(v, list): return {"results": v}
            return {"results": []}
        except Exception as e:
            return {"error": str(e)}

    # 4. If DB Match -> Hybrid Mode
    ai_details = await generate_details(top_matches)
    
    final_results = []
    for i, match in enumerate(top_matches):
        details = ai_details[i] if i < len(ai_details) else {}
        
        final_results.append({
            "disease": match['disease'],
            "confidence": match['confidence'],
            "medication": match['medication'], # Locked from JSON
            "description": details.get('description', 'N/A'),
            "diet": details.get('diet', []),
            "workout": details.get('workout', []),
            "precautions": details.get('precautions', [])
        })
        
    return {"results": final_results}

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    """
    General Health AI Chat.
    """
    messages = [{"role": "system", "content": "You are MediMind, a helpful and empathetic medical AI assistant. Provide concise, safe, and helpful medical information. Always advise consulting a doctor for serious issues."}]
    messages.extend(request.history)
    messages.append({"role": "user", "content": request.message})
    
    try:
        chat = await client.chat.completions.create(
            messages=messages,
            model="llama-3.3-70b-versatile",
            temperature=0.5,
            max_tokens=300
        )
        return {"response": chat.choices[0].message.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate/diet")
async def generate_diet(req: DietRequest):
    prompt = f"""
    Create a 7-day diet plan.
    Goal: {req.goal}
    Preferences: {req.preferences}
    Calories: {req.calories}
    
    Return JSON format: [{{ "day": "Monday", "meals": ["Breakfast...", "Lunch...", "Dinner...", "Snack..."] }}, ...]
    """
    try:
        chat = await client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.3-70b-versatile",
            response_format={"type": "json_object"}
        )
        res = json.loads(chat.choices[0].message.content)
        # Handle various return formats
        if "days" in res: return res["days"]
        if "plan" in res: return res["plan"] 
        if isinstance(res, dict): return list(res.values())[0]
        return res
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate/workout")
async def generate_workout(req: WorkoutRequest):
    prompt = f"""
    Create a weekly workout routine.
    Goal: {req.goal}
    Level: {req.level}
    Equipment: {req.equipment}
    
    Return JSON format: [{{ "day": "Monday", "focus": "Cardio", "exercises": ["30 mins run", "10 burpees"] }}, ...]
    """
    try:
        chat = await client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.3-70b-versatile",
            response_format={"type": "json_object"}
        )
        res = json.loads(chat.choices[0].message.content)
        if isinstance(res, dict): 
            # Try to find the list
            for v in res.values():
                if isinstance(v, list): return v
        return res
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/analyze_report")
async def analyze_report(req: LabReportRequest):
    prompt = f"""
    You are a friendly medical explanation assistant. 
    Analyze this raw lab report data: "{req.report_text}"
    
    1. Identify the key metrics provided (e.g. Hemoglobin, Glucose).
    2. Check if they are within standard normal ranges (general adult).
    3. Explain what each result means in simple terms.
    4. Flag anything that seems High or Low.
    5. Provide a short, reassuring summary.
    
    IMPORTANT: 
    - Use clear Markdown formatting.
    - Do NOT diagnose specific diseases. Use phrases like "may indicate" or "commonly seen in".
    - End with a disclaimer: "This is an AI explanation, not a doctor's diagnosis."
    """
    try:
        chat = await client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.3-70b-versatile",
            max_tokens=800
        )
        return {"analysis": chat.choices[0].message.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==========================================
# 7. SERVE FRONTEND (STATIC FILES)
# ==========================================

# 1. Serve the homepage
@app.get("/")
async def read_index():
    return FileResponse("index.html")

# 2. Serve CSS and JS specifically
@app.get("/style.css")
async def read_css():
    return FileResponse("style.css")

@app.get("/script.js")
async def read_js():
    return FileResponse("script.js")

# 3. Serve Images or other assets (Optional catch-all)
@app.get("/{filename}")
async def read_assets(filename: str):
    # Security: only serve safe files if they exist
    if os.path.exists(filename) and filename.endswith((".png", ".jpg", ".ico", ".json")):
        return FileResponse(filename)
    raise HTTPException(status_code=404, detail="File not found")

    
if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)