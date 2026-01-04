document.addEventListener('DOMContentLoaded', () => {
    loadSidebarHistory();
    loadFullHistory();
    setupVoiceInput();
    loadMedications(); // Initial load
});

const API_BASE = 'http://127.0.0.1:8000';

// --- NAVIGATION & VIEWS ---
function switchView(viewId) {
    // 1. Sidebar Active State
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));

    // Map viewId to button index roughly (not perfect but works for this list)
    // 0: Dashboard, 1: Chat, 2: Meds, 3: History
    const buttons = document.querySelectorAll('.nav-item');
    if (viewId === 'dashboard') buttons[0].classList.add('active');
    if (viewId === 'medical-chat') buttons[1].classList.add('active');
    if (viewId === 'medications') buttons[2].classList.add('active');
    if (viewId === 'history') buttons[3].classList.add('active');

    // 2. Hide all sections
    document.querySelectorAll('.view-section').forEach(el => el.style.display = 'none');

    // 3. Show target section
    const targetSection = document.getElementById(`view-${viewId}`);
    if (targetSection) targetSection.style.display = 'block';

    // 4. Update Header
    const titles = {
        'dashboard': ['Dashboard', 'AI-Powered Symptom Checker'],
        'medical-chat': ['Health Assistant', 'Ask general medical questions'],
        'medications': ['Medication Manager', 'Track your active prescriptions'],
        'history': ['Medical History', 'Your past consultations log'],
        'profile': ['User Profile', 'Manage your personal details']
    };
    if (titles[viewId]) {
        document.getElementById('page-title').innerText = titles[viewId][0];
        document.getElementById('page-subtitle').innerText = titles[viewId][1];
    }

    // 5. Special Loads
    if (viewId === 'history') loadFullHistory();
    if (viewId === 'medications') loadMedications();
}

// --- 1. SYMPTOM CHECKER ---
async function analyzeSymptoms() {
    const input = document.getElementById('symptoms');
    const resultsContainer = document.getElementById('results-container');
    const loader = document.getElementById('loader');

    if (!input.value.trim()) {
        alert("Please describe your symptoms.");
        return;
    }

    resultsContainer.innerHTML = '';
    loader.style.display = 'flex'; // Changed to flex for centering

    try {
        const response = await fetch(`${API_BASE}/analyze`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ symptoms: input.value })
        });

        const data = await response.json();
        loader.style.display = 'none';

        if (!data.results || data.results.length === 0) {
            resultsContainer.innerHTML = `<div style="grid-column:1/-1; text-align:center; padding:40px; color:var(--text-secondary);">No matches found. Try more specific symptoms.</div>`;
            return;
        }

        saveHistory(input.value);

        data.results.slice(0, 3).forEach((item) => {
            const card = document.createElement('div');
            card.className = 'glass-panel result-card';
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
                        <span><i class="fas fa-carrot"></i> ${item.diet.length} Diet Tips</span>
                    </div>
                </div>
                <div class="details-view">
                    <div class="details-padding">
                        <div class="detail-block">
                            <div class="detail-title">Medication</div>
                            <div>${(item.medication || []).map(m => `<span class="chip chip-med">${m}</span>`).join('')}</div>
                        </div>
                        <div class="detail-block">
                            <div class="detail-title">Diet</div>
                            <div>${(item.diet || []).map(d => `<span class="chip chip-diet">${d}</span>`).join('')}</div>
                        </div>
                        <div class="detail-block">
                            <div class="detail-title">Precautions</div>
                            <ul style="padding-left:20px; font-size:0.9rem; color:var(--text-secondary);">
                                ${(item.precautions || []).map(p => `<li>${p}</li>`).join('')}
                            </ul>
                        </div>
                    </div>
                </div>
            `;
            resultsContainer.appendChild(card);
        });

    } catch (e) {
        loader.style.display = 'none';
        alert("Server Error. Ensure backend is running.");
        console.error(e);
    }
}

function toggleCard(header) {
    const card = header.parentElement;
    document.querySelectorAll('.result-card.expanded').forEach(c => {
        if (c !== card) c.classList.remove('expanded');
    });
    card.classList.toggle('expanded');
}

// --- 2. AI HEALTH CHAT ---
let chatHistory = [];

async function sendChatMessage() {
    const input = document.getElementById('chat-input');
    const windowDiv = document.getElementById('chat-window');
    const msg = input.value.trim();

    if (!msg) return;

    // Add User Message
    appendMessage('user', msg);
    input.value = '';

    // Loading State
    const loadingId = appendMessage('ai', '...', true);

    try {
        const response = await fetch(`${API_BASE}/chat`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message: msg, history: chatHistory })
        });
        const data = await response.json();

        // Remove loading
        const loadingEl = document.getElementById(loadingId);
        if (loadingEl) loadingEl.remove();

        // Add AI Response
        appendMessage('ai', data.response);

        // Update History
        chatHistory.push({ role: 'user', content: msg });
        chatHistory.push({ role: 'assistant', content: data.response });
        if (chatHistory.length > 10) chatHistory = chatHistory.slice(-10);

    } catch (e) {
        console.error(e);
        const loadingEl = document.getElementById(loadingId);
        if (loadingEl) loadingEl.innerText = "Error connecting to AI.";
    }
}

function appendMessage(role, text, isLoading = false) {
    const windowDiv = document.getElementById('chat-window');
    const div = document.createElement('div');
    div.className = `message ${role}-message`;
    const id = 'msg-' + Date.now();
    if (isLoading) div.id = id;

    const icon = role === 'ai' ? '<i class="fas fa-robot"></i>' : '<i class="fas fa-user"></i>';

    div.innerHTML = `
        <div class="msg-avatar">${icon}</div>
        <div class="msg-content">${text}</div>
    `;
    windowDiv.appendChild(div);
    windowDiv.scrollTop = windowDiv.scrollHeight;
    return id;
}

function handleChatEnter(e) {
    if (e.key === 'Enter') sendChatMessage();
}

// --- 3. MEDICATION MANAGER ---
async function loadMedications() {
    const list = document.getElementById('medications-list');
    list.innerHTML = '<div style="color:var(--text-secondary); padding:20px;">Loading...</div>';

    try {
        const res = await fetch(`${API_BASE}/medications`);
        const meds = await res.json();

        if (meds.length === 0) {
            list.innerHTML = '<div style="grid-column:1/-1; padding:20px; text-align:center; color:var(--text-secondary);">No active medications.</div>';
            return;
        }

        list.innerHTML = meds.map(m => `
            <div class="glass-panel med-card">
                <div class="med-header">
                    <span class="med-name">${m.name}</span>
                    <button class="btn-delete" onclick="deleteMedication('${m.id}')"><i class="fas fa-trash"></i></button>
                </div>
                <div class="med-info"><i class="fas fa-prescription-bottle"></i> ${m.dosage}</div>
                <div class="med-info"><i class="fas fa-clock"></i> ${m.frequency}</div>
            </div>
        `).join('');
    } catch (e) {
        list.innerHTML = 'Error loading medications.';
    }
}

async function addMedication() {
    const name = document.getElementById('med-name').value;
    const dosage = document.getElementById('med-dosage').value;
    const freq = document.getElementById('med-freq').value;

    if (!name || !dosage) { alert("Name and Dosage are required."); return; }

    await fetch(`${API_BASE}/medications`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, dosage, frequency: freq })
    });

    // Clear form
    document.getElementById('med-name').value = '';
    document.getElementById('med-dosage').value = '';
    document.getElementById('med-freq').value = '';

    loadMedications();
}

async function deleteMedication(id) {
    if (!confirm("Remove this medication?")) return;
    await fetch(`${API_BASE}/medications/${id}`, { method: 'DELETE' });
    loadMedications();
}


// --- UTILS: VOICE & HISTORY ---
let recognition;
function setupVoiceInput() {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
        const btn = document.getElementById('btn-mic');
        if (btn) btn.style.display = 'none';
        return;
    }
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    recognition = new SpeechRecognition();
    recognition.continuous = false;
    recognition.interimResults = true;
    recognition.lang = 'en-US';

    const btn = document.getElementById('btn-mic');
    const input = document.getElementById('symptoms');

    recognition.onstart = () => btn.classList.add('listening');
    recognition.onend = () => btn.classList.remove('listening');
    recognition.onresult = (event) => {
        const transcript = Array.from(event.results).map(r => r[0].transcript).join('');
        if (event.results[0].isFinal) input.value = transcript;
        else input.placeholder = transcript + "...";
    };
}

function toggleVoiceInput() {
    if (!recognition) return;
    const btn = document.getElementById('btn-mic');
    if (btn.classList.contains('listening')) recognition.stop();
    else recognition.start();
}

function saveHistory(text) {
    let history = JSON.parse(localStorage.getItem('mediHistory') || '[]');
    if (history.length > 0 && history[0].text === text) return;
    history.unshift({ text: text, date: new Date().toLocaleDateString() });
    if (history.length > 20) history.pop();
    localStorage.setItem('mediHistory', JSON.stringify(history));
    loadSidebarHistory();
}

function loadSidebarHistory() {
    const list = document.getElementById('sidebar-history');
    if (!list) return;
    const history = JSON.parse(localStorage.getItem('mediHistory') || '[]');
    if (history.length === 0) {
        list.innerHTML = '<div class="empty-history">No recent scans</div>';
        return;
    }
    list.innerHTML = history.slice(0, 5).map(item => `
        <div class="history-item" onclick="restoreSearch('${item.text}')">
            <i class="fas fa-search"></i> ${item.text}
        </div>
    `).join('');
}

function loadFullHistory() {
    const container = document.getElementById('full-history-list');
    if (!container) return;
    const history = JSON.parse(localStorage.getItem('mediHistory') || '[]');
    container.innerHTML = history.length ? history.map(item => `
        <div class="glass-panel full-history-item">
            <div>
                <div class="h-text">${item.text}</div>
                <div class="h-date">${item.date}</div>
            </div>
            <button class="btn-redo" onclick="restoreSearch('${item.text}')">Redo</button>
        </div>
    `).join('') : '<div style="text-align:center; padding:20px;">No history.</div>';
}

function clearHistory() {
    if (confirm("Clear all history?")) {
        localStorage.removeItem('mediHistory');
        loadSidebarHistory();
        loadFullHistory();
    }
}

function restoreSearch(text) {
    switchView('dashboard');
    const input = document.getElementById('symptoms');
    if (input) input.value = text;
    analyzeSymptoms();
}

function triggerSOS() { document.getElementById('sos-overlay').style.display = 'flex'; }
function closeSOS() { document.getElementById('sos-overlay').style.display = 'none'; }