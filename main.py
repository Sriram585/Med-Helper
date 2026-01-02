import os
import json
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from groq import AsyncGroq
from dotenv import load_dotenv

# Load Environment Variables
load_dotenv()

app = FastAPI()

# Enable CORS
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

@app.post("/analyze")
async def analyze_symptoms(request: SymptomRequest):
    if not request.symptoms.strip():
        raise HTTPException(status_code=400, detail="Symptoms cannot be empty")

    try:
        # --- FILE HANDLING START ---
        # 1. Open the text file
        try:
            with open("prompt.txt", "r") as file:
                prompt_template = file.read()
        except FileNotFoundError:
            raise HTTPException(status_code=500, detail="prompt.txt file not found")

        # 2. Inject user symptoms into the text
        # We use replace() instead of f-strings to avoid issues with JSON curly braces
        final_prompt = prompt_template.replace("{{SYMPTOMS}}", request.symptoms)
        # --- FILE HANDLING END ---

        # API Call
        chat_completion = await client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful medical API that outputs only valid raw JSON."
                },
                {
                    "role": "user",
                    "content": final_prompt,
                }
            ],
            model="llama-3.3-70b-versatile",
            temperature=0.5,
            response_format={"type": "json_object"}
        )

        ai_response = chat_completion.choices[0].message.content
        
        if ai_response is None:
            raise HTTPException(status_code=500, detail="AI returned an empty response")

        result = json.loads(ai_response)
        return result

    except Exception as e:
        print(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)