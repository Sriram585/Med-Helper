import os
import json
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from groq import AsyncGroq # Using the Async client
from dotenv import load_dotenv

# Load Environment Variables
load_dotenv()

# Initialize FastAPI App
app = FastAPI()

# Enable CORS (Allows your HTML file to talk to this API)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins (for development)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Async Groq Client
client = AsyncGroq(
    api_key=os.environ.get("GROQ_API_KEY"),
)

# Define Request Model (Data Validation)
class SymptomRequest(BaseModel):
    symptoms: str

@app.post("/analyze")
async def analyze_symptoms(request: SymptomRequest):
    if not request.symptoms.strip():
        raise HTTPException(status_code=400, detail="Symptoms cannot be empty")

    try:
        # Prompt Engineering
        prompt = f"""
        You are a medical AI assistant. The user is describing these symptoms: "{request.symptoms}".
        
        Provide a helpful response structured STRICTLY as a JSON object with exactly these 5 keys:
        1. "description": A brief medical assessment of what might be happening.
        2. "diet": Bullet points of recommended foods or drinks.
        3. "medication": Common over-the-counter medications (include a disclaimer).
        4. "precautions": Immediate steps to avoid worsening the condition.
        5. "workout": A safe workout or movement plan (or advice to rest).

        Do not use Markdown formatting. Return raw JSON only.
        """

        # Async API Call to Groq
        chat_completion = await client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful medical API that outputs only valid raw JSON."
                },
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
            model="llama3-70b-8192",
            temperature=0.5,
            response_format={"type": "json_object"}
        )

        # Parse Response
        ai_response = chat_completion.choices[0].message.content
        result = json.loads(ai_response)
        
        return result

    except Exception as e:
        print(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to process request")

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)