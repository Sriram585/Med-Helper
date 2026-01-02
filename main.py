import os
import json
import difflib
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

# --- LOAD DATABASE ---
def load_medical_db():
    try:
        with open("medical_data.json", "r") as f:
            return json.load(f)
    except FileNotFoundError:
        print("WARNING: medical_data.json not found. Database features disabled.")
        return {}

MEDICAL_DB = load_medical_db()

# --- SMART MATCHING LOGIC ---
def find_best_match(user_input):
    user_input = user_input.lower()
    known_symptoms = list(MEDICAL_DB.keys())
    
    # 1. Exact/Partial Match
    for symptom in known_symptoms:
        if symptom in user_input:
            return symptom, MEDICAL_DB[symptom]
            
    # 2. Fuzzy Match (Typo tolerance)
    matches = difflib.get_close_matches(user_input, known_symptoms, n=1, cutoff=0.6)
    if matches:
        return matches[0], MEDICAL_DB[matches[0]]
        
    return None, None

@app.post("/analyze")
async def analyze_symptoms(request: SymptomRequest):
    if not request.symptoms.strip():
        raise HTTPException(status_code=400, detail="Symptoms cannot be empty")

    try:
        # 1. Read the Prompt File
        try:
            with open("prompt.txt", "r") as f:
                prompt_template = f.read()
        except FileNotFoundError:
            raise HTTPException(status_code=500, detail="prompt.txt file missing")

        # 2. Check Database for Matches
        matched_symptom, db_data = find_best_match(request.symptoms)
        
        # 3. Construct the Context Block
        if matched_symptom:
            # We found data! Format it for the AI.
            print(f"DEBUG: Database hit for '{matched_symptom}'")
            context_block = f"""
            **TRUSTED DATABASE MATCH FOUND:** {matched_symptom.upper()}
            - Required Medications: {", ".join(db_data['medication'])}
            - Required Diet Focus: {db_data['diet_focus']}
            - Required Workout: {db_data['workout_type']}
            
            Instruction: You MUST prioritize these recommendations in your final JSON output.
            """
        else:
            # No data found. Give general instructions.
            print("DEBUG: Database miss. Using General AI.")
            context_block = "No specific database match found. Use general medical safety protocols. Prioritize conservative treatments (e.g., Rest, Hydration)."

        # 4. Inject Data into Prompt (File Handling)
        final_prompt = prompt_template.replace("{{SYMPTOMS}}", request.symptoms)
        final_prompt = final_prompt.replace("{{CONTEXT_BLOCK}}", context_block)

        # 5. Call Groq
        chat_completion = await client.chat.completions.create(
            messages=[
                {"role": "system", "content": "You are a medical API that outputs only valid raw JSON."},
                {"role": "user", "content": final_prompt}
            ],
            model="llama-3.3-70b-versatile",
            temperature=0.3, # Keep it low to ensure it follows the Context
            response_format={"type": "json_object"}
        )

        ai_response = chat_completion.choices[0].message.content
        result = json.loads(ai_response)
        return result

    except Exception as e:
        print(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)