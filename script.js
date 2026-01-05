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
        'profile': ['User Profile', 'Manage your personal details'],
        'bmi': ['BMI Calculator', 'Body Mass Index Assessment'],
        'hydration': ['Hydration Tracker', 'Daily Water Intake Goal'],
        'mood': ['Mood Tracker', 'Emotional Well-being Journal'],
        'appointments': ['Find Doctors', 'Book Medical Consultations'],
        'diet': ['AI Nutritionist', 'Personalized Meal Plans'],
        'workout': ['Workout Coach', 'Fitness Routines'],
        'wearables': ['Wearables', 'Device Synchronization']
    };
    if (titles[viewId]) {
        document.getElementById('page-title').innerText = titles[viewId][0];
        document.getElementById('page-subtitle').innerText = titles[viewId][1];
    }

    // 5. Special Loads
    if (viewId === 'history') loadFullHistory();
    if (viewId === 'medications') loadMedications();
    if (viewId === 'hydration') loadHydration();
    if (viewId === 'mood') loadMoodHistory();
    if (viewId === 'wearables') startWearableSimulation();
    else stopWearableSimulation();
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
                </div>
                <div class="med-info"><i class="fas fa-prescription-bottle"></i> ${m.dosage}</div>
                <div class="med-info"><i class="fas fa-clock"></i> ${m.frequency} ${m.time ? '<span class="badge-pro" style="margin-left:5px; font-size:0.8rem;">' + m.time + '</span>' : ''}</div>
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
    const time = document.getElementById('med-time').value;

    if (!name || !dosage) { alert("Name and Dosage are required."); return; }

    await fetch(`${API_BASE}/medications`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, dosage, frequency: freq, time })
    });

    // Clear form
    document.getElementById('med-name').value = '';
    document.getElementById('med-dosage').value = '';
    document.getElementById('med-freq').value = '';
    document.getElementById('med-time').value = '';

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

// --- 4. NEW TOOLS LOGIC ---

// BMI CALCULATOR
function calculateBMI() {
    const height = parseFloat(document.getElementById('bmi-height').value);
    const weight = parseFloat(document.getElementById('bmi-weight').value);

    if (!height || !weight) { alert("Please enter valid height and weight."); return; }

    const bmi = (weight / ((height / 100) ** 2)).toFixed(1);
    const resultBox = document.getElementById('bmi-result');
    const valueEl = document.getElementById('bmi-value');
    const catEl = document.getElementById('bmi-category');

    valueEl.innerText = bmi;
    resultBox.style.display = 'flex';

    let category = '';
    let color = '';

    if (bmi < 18.5) { category = 'Underweight'; color = '#3b82f6'; }
    else if (bmi < 25) { category = 'Normal Weight'; color = '#10b981'; } // Green
    else if (bmi < 30) { category = 'Overweight'; color = '#f59e0b'; } // Orange
    else { category = 'Obese'; color = '#ef4444'; } // Red

    catEl.innerText = category;
    catEl.style.color = color;
    catEl.style.background = color + '20'; // 20 hex = 12% opacity roughly
}

// HYDRATION TRACKER
let waterCount = 0;
function loadHydration() {
    const date = new Date().toLocaleDateString();
    const saved = JSON.parse(localStorage.getItem('mediHydration') || '{}');

    // Reset if new day
    if (saved.date !== date) {
        waterCount = 0;
    } else {
        waterCount = saved.count || 0;
    }
    updateWaterUI();
}

function updateWater(change) {
    waterCount += change;
    if (waterCount < 0) waterCount = 0;
    // Cap at reasonable amount (e.g. 20) to prevent UI break
    if (waterCount > 20) waterCount = 20;

    localStorage.setItem('mediHydration', JSON.stringify({
        date: new Date().toLocaleDateString(),
        count: waterCount
    }));
    updateWaterUI();
    updateDashboardWidgets();
}

function updateWaterUI() {
    document.getElementById('water-count').innerText = waterCount;
    const percentage = Math.min((waterCount / 8) * 100, 100);
    const wave = document.querySelector('.wave');
    if (wave) wave.style.height = `${percentage}%`;
}

// MOOD TRACKER
function loadMoodHistory() {
    const history = JSON.parse(localStorage.getItem('mediMood') || '[]');
    const container = document.getElementById('mood-history');

    // Always render chart
    renderMoodChart(history);

    if (!container) return; // Guard clause

    if (history.length === 0) {
        container.innerHTML = '<div style="text-align:center; color:var(--text-secondary); padding:20px;">No mood logs yet.</div>';
        return;
    }

    const emojis = { 'great': '🤩', 'good': '🙂', 'okay': '😐', 'bad': '😔', 'awful': '😫' };

    container.innerHTML = history.slice(0, 7).map(item => `
        <div class="history-entry">
            <div class="h-mood"><span style="font-size:1.5rem;">${emojis[item.mood] || '❓'}</span> ${item.mood.charAt(0).toUpperCase() + item.mood.slice(1)}</div>
            <div class="h-time">${item.date} <br> <span style="font-size:0.8rem">${item.time}</span></div>
        </div>
    `).join('');
}

function logMood(mood) {
    const history = JSON.parse(localStorage.getItem('mediMood') || '[]');
    const now = new Date();

    history.unshift({
        mood: mood,
        date: now.toLocaleDateString(),
        time: now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    });

    if (history.length > 50) history.pop(); // Keep last 50
    localStorage.setItem('mediMood', JSON.stringify(history));

    // Visual Feedback (Selection state)
    document.querySelectorAll('.mood-btn').forEach(btn => btn.classList.remove('selected'));
    // Ideally we'd select the button that was clicked, but simple alert or reload is fine for now
    loadMoodHistory();
    updateDashboardWidgets(); // Update dashboard if mood changes
}

function renderMoodChart(history) {
    const counts = { 'great': 0, 'good': 0, 'okay': 0, 'bad': 0, 'awful': 0 };
    history.forEach(h => {
        if (counts[h.mood] !== undefined) counts[h.mood]++;
    });

    const max = Math.max(...Object.values(counts)) || 1; // Avoid divide by zero
    const colors = { 'great': 'bar-great', 'good': 'bar-good', 'okay': 'bar-okay', 'bad': 'bar-bad', 'awful': 'bar-awful' };
    const labels = { 'great': 'Great', 'good': 'Good', 'okay': 'Okay', 'bad': 'Bad', 'awful': 'Awful' };

    const chart = document.getElementById('mood-chart');
    if (chart) {
        chart.innerHTML = Object.keys(counts).map(key => {
            const height = (counts[key] / max) * 100; // Percentage of max
            return `
                <div class="chart-bar-group">
                    <div class="chart-bar ${colors[key]}" style="height:${height}%" data-count="${counts[key]}"></div>
                    <span class="chart-label">${labels[key]}</span>
                </div>
            `;
        }).join('');
    }
}

function renderMoodChart(history) {
    const counts = { 'great': 0, 'good': 0, 'okay': 0, 'bad': 0, 'awful': 0 };
    history.forEach(h => {
        if (counts[h.mood] !== undefined) counts[h.mood]++;
    });

    const max = Math.max(...Object.values(counts)) || 1; // Avoid divide by zero
    const colors = { 'great': 'bar-great', 'good': 'bar-good', 'okay': 'bar-okay', 'bad': 'bar-bad', 'awful': 'bar-awful' };
    const labels = { 'great': 'Great', 'good': 'Good', 'okay': 'Okay', 'bad': 'Bad', 'awful': 'Awful' };

    const chart = document.getElementById('mood-chart');
    if (chart) {
        chart.innerHTML = Object.keys(counts).map(key => {
            const height = (counts[key] / max) * 100; // Percentage of max
            return `
                <div class="chart-bar-group">
                    <div class="chart-bar ${colors[key]}" style="height:${height}%" data-count="${counts[key]}"></div>
                    <span class="chart-label">${labels[key]}</span>
                </div>
            `;
        }).join('');
    }
}

// --- 5. DASHBOARD 2.0 AGGREGATION ---
function updateDashboardWidgets() {
    // 1. Water
    const waterData = JSON.parse(localStorage.getItem('mediHydration') || '{}');
    const today = new Date().toLocaleDateString();
    const count = (waterData.date === today) ? (waterData.count || 0) : 0;
    const waterEl = document.getElementById('dash-water');
    if (waterEl) waterEl.innerText = `${count} / 8`;

    // 2. Meds
    // We need to fetch meds count. Since loadMedications is async and updates DOM, 
    // we should ideally fetch data directly. 
    // For simplicity, we'll trigger a background fetch or just use a stored count if we had one.
    // Better: Fetch meds just for count.
    fetch(`${API_BASE}/medications`)
        .then(res => res.json())
        .then(data => {
            const medEl = document.getElementById('dash-meds');
            if (medEl) medEl.innerText = data.length || 0;
        })
        .catch(() => { });

    // 3. Mood
    const moodData = JSON.parse(localStorage.getItem('mediMood') || '[]');
    const moodEl = document.getElementById('dash-mood');
    if (moodEl) {
        if (moodData.length > 0) {
            const latest = moodData[0].mood;
            moodEl.innerText = latest.charAt(0).toUpperCase() + latest.slice(1);
        } else {
            moodEl.innerText = "-";
        }
    }
}

// --- 6. PROFILE SYSTEM ---
function loadProfile() {
    const profile = JSON.parse(localStorage.getItem('mediProfile') || '{}');

    // Update Display
    const name = profile.name || 'Guest User';
    document.getElementById('profile-name-display').innerText = name;

    // Update Form
    if (document.getElementById('p-name')) document.getElementById('p-name').value = profile.name || '';
    if (document.getElementById('p-age')) document.getElementById('p-age').value = profile.age || '';
    if (document.getElementById('p-blood')) document.getElementById('p-blood').value = profile.blood || '';
    if (document.getElementById('p-email')) document.getElementById('p-email').value = profile.email || '';
    if (document.getElementById('p-notes')) document.getElementById('p-notes').value = profile.notes || '';

    // Update Greeting on Dashboard
    // Use try-catch or check existence
    const subtitle = document.getElementById('page-subtitle');
    if (subtitle) subtitle.innerText = `Welcome back, ${name.split(' ')[0]}`;
}

function saveProfile() {
    const profile = {
        name: document.getElementById('p-name').value,
        age: document.getElementById('p-age').value,
        blood: document.getElementById('p-blood').value,
        email: document.getElementById('p-email').value,
        notes: document.getElementById('p-notes').value
    };

    localStorage.setItem('mediProfile', JSON.stringify(profile));
    localStorage.setItem('mediProfile', JSON.stringify(profile));
    showToast("Profile changes saved successfully!");
    loadProfile(); // Refresh UI
    loadProfile(); // Refresh UI
}

// --- 7. APPOINTMENTS SYSTEM ---
// --- 7. APPOINTMENTS SYSTEM ---
const mockDoctors = [
    { id: 1, name: "Dr. Sarah Smith", specialty: "Cardiologist", image: "https://ui-avatars.com/api/?name=Sarah+Smith&background=random" },
    { id: 2, name: "Dr. James Wilson", specialty: "Dermatologist", image: "https://ui-avatars.com/api/?name=James+Wilson&background=random" },
    { id: 3, name: "Dr. Emily Chen", specialty: "Pediatrician", image: "https://ui-avatars.com/api/?name=Emily+Chen&background=random" },
    { id: 4, name: "Dr. Michael Ross", specialty: "General Physician", image: "https://ui-avatars.com/api/?name=Michael+Ross&background=random" },
    { id: 5, name: "Dr. Linda Brown", specialty: "Neurologist", image: "https://ui-avatars.com/api/?name=Linda+Brown&background=random" }
];

function loadDoctors() {
    const list = document.getElementById('doctor-list');
    if (!list) return;
    list.innerHTML = mockDoctors.map(doc => `
        <div class="doctor-row">
            <img src="${doc.image}" class="doc-img-sm">
            <div class="doc-info-list">
                <div class="doc-name-list">${doc.name}</div>
                <div class="doc-spec-list">${doc.specialty}</div>
            </div>
            <button class="btn-book-sm" onclick="bookAppointment('${doc.name}')">Book</button>
        </div>
    `).join('');
}

function filterDoctors() {
    const query = document.getElementById('doc-search').value.toLowerCase();
    const cards = document.querySelectorAll('.doctor-card');
    cards.forEach(card => {
        const text = card.innerText.toLowerCase();
        card.style.display = text.includes(query) ? 'block' : 'none';
    });
}

// --- REFACTORED APPOINTMENT LOGIC ---
let selectedDoctor = null;

function bookAppointment(docName) {
    try {
        console.log("Booking for:", docName);
        selectedDoctor = docName;
        const nameEl = document.getElementById('modal-doc-name');
        const inputEl = document.getElementById('appt-date-input');
        const modalEl = document.getElementById('date-modal');

        if (nameEl) nameEl.innerText = docName;
        if (inputEl) inputEl.value = "Tomorrow at 10 AM";
        if (modalEl) modalEl.style.display = 'flex';
    } catch (e) {
        console.error(e);
        alert("Error opening booking modal. See console.");
    }
}

function closeDateModal() {
    const modal = document.getElementById('date-modal');
    if (modal) modal.style.display = 'none';
    selectedDoctor = null;
}

function confirmAppointment() {
    const dateInput = document.getElementById('appt-date-input');
    const date = dateInput ? dateInput.value : null;

    if (!date || !selectedDoctor) {
        alert("Please confirm the doctor and date.");
        return;
    }

    closeDateModal();

    const appointments = JSON.parse(localStorage.getItem('mediAppointments') || '[]');
    appointments.unshift({ doctor: selectedDoctor, date: date, id: Date.now() });
    localStorage.setItem('mediAppointments', JSON.stringify(appointments));

    // Show App Popup (Success Modal)
    showSuccessModal('Request Sent', `Your request to see <strong>${selectedDoctor}</strong> on <strong>${date}</strong> has been sent!`);
    loadAppointments();
}

function showSuccessModal(title, message) {
    const modal = document.getElementById('success-modal');
    if (modal) {
        document.getElementById('success-title').innerText = title;
        document.getElementById('success-message').innerHTML = message;
        modal.style.display = 'flex';
    }
}

function closeSuccessModal() {
    const modal = document.getElementById('success-modal');
    if (modal) modal.style.display = 'none';
}

function showToast(message) {
    // Keep this for profile saves, but appointments now use Success Modal
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `<i class="fas fa-check-circle" style="color:#4ade80"></i> <span>${message}</span>`;

    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(20px)';
        toast.style.transition = '0.3s';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}



function loadAppointments() {
    const list = document.getElementById('appointment-list');
    if (!list) return;
    const appointments = JSON.parse(localStorage.getItem('mediAppointments') || '[]');

    if (appointments.length === 0) {
        list.innerHTML = '<div style="color:var(--text-secondary); text-align:center;">No upcoming appointments.</div>';
        return;
    }

    list.innerHTML = appointments.map(appt => `
        <div class="appt-card">
            <div>
                <div style="font-weight:700;">${appt.doctor}</div>
                <div style="font-size:0.9rem; color:var(--text-secondary);"><i class="far fa-calendar-alt"></i> ${appt.date}</div>
            </div>
            <span class="badge-pro" style="background:#dcfce7; color:#166534;">Confirmed</span>
        </div>
    `).join('');
}

// --- 8. REPORT EXPORT ---
function exportHealthReport() {
    const profile = JSON.parse(localStorage.getItem('mediProfile') || '{}');
    const meds = loadMedications_Data(); // Need to extract this logic or just fetch again
    const history = JSON.parse(localStorage.getItem('mediHistory') || '[]');

    // We'll just fetch meds from API for now in the background or assume we have them locally? 
    // Let's just use what we can get synchronously or await.
    // Making this async to be clean.
    generateReportContent(profile, history);
}

async function generateReportContent(profile, history) {
    let meds = [];
    try {
        const res = await fetch(`${API_BASE}/medications`);
        meds = await res.json();
    } catch (e) { }

    const report = `
MEDICAL HEALTH REPORT - MediMind
Generated: ${new Date().toLocaleString()}
------------------------------------------------
PATIENT PROFILE
Name: ${profile.name || 'N/A'}
Age: ${profile.age || 'N/A'}
Blood Group: ${profile.blood || 'N/A'}
Emails: ${profile.email || 'N/A'}
Notes: ${profile.notes || 'None'}

------------------------------------------------
ACTIVE MEDICATIONS
${meds.length ? meds.map(m => `- ${m.name} (${m.dosage}, ${m.frequency})`).join('\n') : "No active medications."}

------------------------------------------------
RECENT CONSULTATION HISTORY
${history.slice(0, 10).map(h => `- [${h.date}] ${h.text}`).join('\n')}

------------------------------------------------
DISCLAIMER: This report is generated by an AI tool and should be verified by a doctor.
    `;

    // Download Logic
    const blob = new Blob([report], { type: 'text/plain' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `MediMind_Report_${Date.now()}.txt`;
    a.click();
    window.URL.revokeObjectURL(url);
}

// --- 9. DISCLAIMER ---
function checkDisclaimer() {
    if (!localStorage.getItem('mediDisclaimerAccepted')) {
        document.getElementById('disclaimer-overlay').style.display = 'flex';
    }
}

function acceptDisclaimer() {
    localStorage.setItem('mediDisclaimerAccepted', 'true');
    document.getElementById('disclaimer-overlay').style.display = 'none';
}

// Update Init
document.addEventListener('DOMContentLoaded', () => {
    updateDashboardWidgets();
    loadProfile();
    loadDoctors();
    loadAppointments();
    loadAppointments();
    checkDisclaimer();

    // Start Reminder Loop
    setInterval(checkMedicationReminders, 60000);
});

// --- REMINDER SYSTEM ---
function checkMedicationReminders() {
    const now = new Date();
    // Format HH:MM
    const current = String(now.getHours()).padStart(2, '0') + ":" + String(now.getMinutes()).padStart(2, '0');

    fetch(`${API_BASE}/medications`)
        .then(res => res.json())
        .then(meds => {
            meds.forEach(m => {
                if (m.time === current) {
                    showSuccessModal("Medication Reminder", `It's time to take your <strong>${m.name}</strong> (${m.dosage})!`);
                }
            });
        })
        .catch(e => console.error("Reminder check failed", e));
}

// --- NEW FEATURES LOGIC ---

// 1. DIET PLAN
async function generateDiet() {
    const goal = document.getElementById('diet-goal').value;
    const pref = document.getElementById('diet-pref').value || "No specific preferences";
    const container = document.getElementById('diet-result');

    container.innerHTML = '<div class="loader" style="display:flex; grid-column:1/-1;">Generating nutritional plan...</div>';

    try {
        const res = await fetch(`${API_BASE}/generate/diet`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ goal, preferences: pref })
        });
        const plan = await res.json();

        container.innerHTML = plan.map(day => `
            <div class="glass-panel plan-card">
                <h3 style="color:var(--primary); margin-bottom:15px; border-bottom:1px solid #f1f5f9; padding-bottom:10px;">${day.day || "Day"}</h3>
                <div>
                    ${(day.meals || []).map(m => {
            let tag = "Meal";
            if (m.includes("Breakfast")) tag = "Breakfast";
            if (m.includes("Lunch")) tag = "Lunch";
            if (m.includes("Dinner")) tag = "Dinner";
            if (m.includes("Snack")) tag = "Snack";

            const cleanText = m.replace(tag, '').replace(':', '').trim();
            return `<div class="plan-item"><span class="plan-tag">${tag}</span> ${cleanText || m}</div>`;
        }).join('')}
                </div>
            </div>
        `).join('');
    } catch (e) {
        container.innerHTML = "Error generating plan. Try again.";
    }
}

// 2. WORKOUT PLAN
async function generateWorkout() {
    const level = document.getElementById('work-level').value;
    const equip = document.getElementById('work-equip').value;
    const goal = "General Fitness"; // Simplified for UI
    const container = document.getElementById('workout-result');

    container.innerHTML = '<div class="loader" style="display:flex; grid-column:1/-1;">Building workout routine...</div>';

    try {
        const res = await fetch(`${API_BASE}/generate/workout`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ level, equipment: equip, goal })
        });
        const plan = await res.json();

        container.innerHTML = plan.map(day => `
            <div class="glass-panel plan-card">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px; border-bottom:1px solid #f1f5f9; padding-bottom:10px;">
                    <h3 style="color:var(--secondary); margin:0;">${day.day || "Day"}</h3>
                    <div class="badge-pro">${day.focus || "Training"}</div>
                </div>
                <div>
                    ${(day.exercises || []).map(e => `<div class="plan-item"><i class="fas fa-check-circle" style="color:#d1fae5; margin-right:8px;"></i> ${e}</div>`).join('')}
                </div>
            </div>
        `).join('');
    } catch (e) {
        container.innerHTML = "Error generating workout. Try again.";
    }
}

// 3. WEARABLE SIMULATION
let wearInterval;
let hrChart = null;

function initHRChart() {
    const ctx = document.getElementById('hrChart').getContext('2d');
    hrChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Heart Rate (BPM)',
                data: [],
                borderColor: '#ef4444',
                backgroundColor: 'rgba(239, 68, 68, 0.2)',
                borderWidth: 3,
                tension: 0.4,
                fill: false,
                pointRadius: 4,
                pointBackgroundColor: '#fff',
                pointBorderColor: '#ef4444',
                pointBorderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: { duration: 800, easing: 'linear' }, // Smooth slide
            scales: {
                x: {
                    title: { display: true, text: 'Time' },
                    grid: { display: false }
                },
                y: {
                    title: { display: true, text: 'BPM' },
                    min: 50,
                    max: 130
                }
            },
            plugins: {
                legend: { display: false }
            }
        }
    });
}

function startWearableSimulation() {
    if (!hrChart) initHRChart();

    // Clear old interval if exists
    if (wearInterval) clearInterval(wearInterval);

    wearInterval = setInterval(() => {
        const now = new Date();
        const timeStr = now.toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });

        // Random BPM between 70 and 100
        const hr = 70 + Math.floor(Math.random() * 30);

        // Update Chart Data
        hrChart.data.labels.push(timeStr);
        hrChart.data.datasets[0].data.push(hr);

        // Keep last 15 points
        if (hrChart.data.labels.length > 15) {
            hrChart.data.labels.shift();
            hrChart.data.datasets[0].data.shift();
        }

        hrChart.update();

        // Update Big Number
        const hrEl = document.getElementById('wear-hr');
        if (hrEl) {
            hrEl.innerText = hr;
            hrEl.style.transform = "scale(1.1)";
            setTimeout(() => hrEl.style.transform = "scale(1)", 200);
        }

    }, 2000);
}

function stopWearableSimulation() {
    if (wearInterval) clearInterval(wearInterval);
}