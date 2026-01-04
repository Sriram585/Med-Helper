document.addEventListener('DOMContentLoaded', () => {
    loadSidebarHistory();
    loadFullHistory();
    setupVoiceInput();
});

// --- NAVIGATION & VIEWS ---
function switchView(viewId) {
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
    const buttons = document.querySelectorAll('.nav-item');
    if(viewId === 'dashboard') buttons[0].classList.add('active');
    if(viewId === 'history') buttons[1].classList.add('active');
    if(viewId === 'profile') buttons[2].classList.add('active');

    document.querySelectorAll('.view-section').forEach(el => el.style.display = 'none');
    document.getElementById(`view-${viewId}`).style.display = 'block';

    const titles = {
        'dashboard': ['Dashboard', 'AI-Powered Symptom Checker'],
        'history': ['Medical History', 'Your past consultations log'],
        'profile': ['User Profile', 'Manage your personal details']
    };
    document.getElementById('page-title').innerText = titles[viewId][0];
    document.getElementById('page-subtitle').innerText = titles[viewId][1];

    if (viewId === 'history') loadFullHistory();
}

// --- VOICE INPUT ---
let recognition;
function setupVoiceInput() {
    const btn = document.getElementById('btn-mic');
    const input = document.getElementById('symptoms');

    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
        btn.style.display = 'none';
        console.warn("Speech Recognition not supported in this browser.");
        return;
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    recognition = new SpeechRecognition();
    recognition.continuous = false;
    recognition.interimResults = true;
    recognition.lang = 'en-US';

    recognition.onstart = () => {
        btn.classList.add('listening');
    };

    recognition.onend = () => {
        btn.classList.remove('listening');
    };

    recognition.onresult = (event) => {
        const transcript = Array.from(event.results)
            .map(result => result[0])
            .map(result => result.transcript)
            .join('');
        
        // If final result, append
        if (event.results[0].isFinal) {
             input.value = transcript;
        } else {
            // Optional: Show placeholder while talking
            input.setAttribute("placeholder", transcript + "...");
        }
    };
}

function toggleVoiceInput() {
    const btn = document.getElementById('btn-mic');
    if (!recognition) return;

    if (btn.classList.contains('listening')) {
        recognition.stop();
    } else {
        recognition.start();
    }
}

// --- MAIN ANALYSIS LOGIC ---
async function analyzeSymptoms() {
    const input = document.getElementById('symptoms');
    const resultsContainer = document.getElementById('results-container');
    const loader = document.getElementById('loader');

    if (!input.value.trim()) {
        alert("Please describe your symptoms.");
        return;
    }

    resultsContainer.innerHTML = '';
    loader.style.display = 'block';

    try {
        const response = await fetch('http://127.0.0.1:8000/analyze', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ symptoms: input.value })
        });

        const data = await response.json();
        loader.style.display = 'none';

        if (!data.results || data.results.length === 0) {
            resultsContainer.innerHTML = `<div style="text-align:center; padding:40px; color:#94a3b8;">No matches found.</div>`;
            return;
        }

        saveHistory(input.value);

        data.results.slice(0, 3).forEach((item, index) => {
            const card = document.createElement('div');
            card.className = 'result-card';
            const tagClass = item.confidence > 75 ? 'high-conf' : 'med-conf';

            card.innerHTML = `
                <div class="card-summary" onclick="toggleCard(this)">
                    <div class="card-header">
                        <div class="card-title">${item.disease}</div>
                        <div class="confidence-tag ${tagClass}">${item.confidence}% Match</div>
                    </div>
                    <p class="card-desc">${item.description || "Details unavailable."}</p>
                    <div class="card-stats">
                        <span><i class="fas fa-pills"></i> ${item.medication.length} Meds</span>
                        <span><i class="fas fa-leaf"></i> ${item.diet.length} Diet Tips</span>
                    </div>
                </div>
                <div class="details-view">
                    <div class="details-padding">
                        <div class="detail-block">
                            <div class="detail-title">Medication</div>
                            <div>${(item.medication||[]).map(m => `<span class="chip chip-med">${m}</span>`).join('')}</div>
                        </div>
                        <div class="detail-block">
                            <div class="detail-title">Diet</div>
                            <div>${(item.diet||[]).map(d => `<span class="chip chip-diet">${d}</span>`).join('')}</div>
                        </div>
                        <div class="detail-block">
                            <div class="detail-title">Precautions</div>
                            <ul style="padding-left:20px; font-size:0.9rem; color:#475569;">
                                ${(item.precautions||[]).map(p => `<li>${p}</li>`).join('')}
                            </ul>
                        </div>
                        <button class="btn-export" onclick="alert('Downloading report...')"><i class="fas fa-download"></i> Download Report</button>
                    </div>
                </div>
            `;
            resultsContainer.appendChild(card);
        });

    } catch (e) {
        loader.style.display = 'none';
        alert("Server Error. Is the backend running?");
    }
}

function toggleCard(header) {
    const card = header.parentElement;
    document.querySelectorAll('.result-card.expanded').forEach(c => {
        if(c !== card) c.classList.remove('expanded');
    });
    card.classList.toggle('expanded');
}

// --- HISTORY MANAGEMENT ---
function saveHistory(text) {
    let history = JSON.parse(localStorage.getItem('mediHistory') || '[]');
    if (history.length > 0 && history[0].text === text) return;
    history.unshift({ text: text, date: new Date().toLocaleDateString() });
    if(history.length > 20) history.pop();
    localStorage.setItem('mediHistory', JSON.stringify(history));
    loadSidebarHistory();
}

function loadSidebarHistory() {
    const list = document.getElementById('sidebar-history');
    const history = JSON.parse(localStorage.getItem('mediHistory') || '[]');
    if (history.length === 0) {
        list.innerHTML = '<div class="empty-history" style="font-style:italic; color:#cbd5e1;">No recent scans</div>';
        return;
    }
    list.innerHTML = history.slice(0, 5).map(item => `
        <div class="history-item" onclick="restoreSearch('${item.text}')">
            <i class="fas fa-search" style="margin-right:8px; font-size:0.8rem;"></i> ${item.text}
        </div>
    `).join('');
}

function loadFullHistory() {
    const container = document.getElementById('full-history-list');
    const history = JSON.parse(localStorage.getItem('mediHistory') || '[]');
    if (history.length === 0) {
        container.innerHTML = '<div style="text-align:center; padding:40px; color:#94a3b8;">No history found.</div>';
        return;
    }
    container.innerHTML = history.map(item => `
        <div class="full-history-item">
            <div>
                <div class="h-text">${item.text}</div>
                <div class="h-date">${item.date}</div>
            </div>
            <button class="btn-redo" onclick="restoreSearch('${item.text}')">Analyze Again</button>
        </div>
    `).join('');
}

function clearHistory() {
    if(confirm("Are you sure you want to delete all history?")) {
        localStorage.removeItem('mediHistory');
        loadSidebarHistory();
        loadFullHistory();
    }
}

function restoreSearch(text) {
    switchView('dashboard');
    document.getElementById('symptoms').value = text;
    analyzeSymptoms();
}

// --- SOS ---
function triggerSOS() { document.getElementById('sos-overlay').style.display = 'flex'; }
function closeSOS() { document.getElementById('sos-overlay').style.display = 'none'; }