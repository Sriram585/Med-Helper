document.addEventListener('DOMContentLoaded', () => {
    const analyzeBtn = document.getElementById('analyzeBtn');
    
    analyzeBtn.addEventListener('click', generatePlan);
});

async function generatePlan() {
    const input = document.getElementById('symptomsInput').value;
    const btnText = document.getElementById('btnText');
    const loader = document.getElementById('loader');
    const results = document.getElementById('resultsArea');

    if(input.trim() === "") {
        alert("Please describe your symptoms first.");
        return;
    }

    // UI Loading State
    btnText.style.display = 'none';
    loader.style.display = 'inline-block';
    results.classList.remove('active');

    try {
        // Fetch from FastAPI Backend
        const response = await fetch('http://127.0.0.1:8000/analyze', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ symptoms: input })
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.detail || 'Network response was not ok');
        }

        const data = await response.json();

        // Update UI
        document.getElementById('descContent').innerHTML = formatText(data.description);
        document.getElementById('dietContent').innerHTML = formatText(data.diet);
        document.getElementById('medContent').innerHTML = formatText(data.medication);
        document.getElementById('precContent').innerHTML = formatText(data.precautions);
        document.getElementById('workoutContent').innerHTML = formatText(data.workout);

        // Reset UI
        btnText.style.display = 'inline-block';
        loader.style.display = 'none';
        btnText.innerText = "Regenerate Plan";
        results.classList.add('active');

    } catch (error) {
        console.error('Error:', error);
        alert("Error: " + error.message);
        
        btnText.style.display = 'inline-block';
        loader.style.display = 'none';
        btnText.innerText = "Try Again";
    }
}

function formatText(text) {
    if (Array.isArray(text)) {
        return text.map(item => `• ${item}`).join('<br>');
    }
    // Safety check for null/undefined
    if (!text) return "No information provided.";
    return text.replace(/\n/g, '<br>').replace(/- /g, '• ');
}