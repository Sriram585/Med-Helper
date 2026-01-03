async function analyzeSymptoms() {
    const input = document.getElementById('symptoms');
    const resultsArea = document.getElementById('results-area');
    const loader = document.getElementById('loader');

    // Validation animation
    if (!input.value.trim()) {
        const card = document.querySelector('.search-card');
        card.style.borderColor = "#ef4444";
        card.style.transform = "translateX(5px)";
        setTimeout(() => {
            card.style.borderColor = "#e2e8f0";
            card.style.transform = "none";
        }, 300);
        return;
    }

    resultsArea.innerHTML = '';
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
            resultsArea.innerHTML = `
                <div style="grid-column: 1/-1; text-align: center; color: #64748b; padding: 40px;">
                    <i class="fas fa-search fa-2x mb-3"></i>
                    <h4>No specific conditions found</h4>
                    <p>Try describing your symptoms with more specific details.</p>
                </div>`;
            return;
        }

        // Render Cards
        data.results.forEach((item, index) => {
            const card = document.createElement('div');
            card.className = 'result-card';
            card.style.animationDelay = `${index * 0.1}s`;

            // Confidence Color Logic
            let confColor = 'var(--primary)';
            if(item.confidence > 80) confColor = '#10b981'; // Green
            else if(item.confidence < 50) confColor = '#f59e0b'; // Orange

            card.innerHTML = `
                <div class="card-header">
                    <div>
                        <h3 class="condition-title">${item.disease}</h3>
                        <div style="font-size:0.85rem; color:#64748b;">Clinical Match</div>
                    </div>
                    <div class="confidence-badge" style="color: ${confColor}; background: ${confColor}15">
                        ${item.confidence}%
                    </div>
                </div>

                <div class="card-body">
                    <p class="description">${item.description}</p>
                    
                    <div class="meta-tags">
                        <div class="meta-tag tag-blue"><i class="fas fa-capsules"></i> ${item.medication.length} Meds</div>
                        <div class="meta-tag tag-green"><i class="fas fa-utensils"></i> Diet</div>
                        <div class="meta-tag tag-orange"><i class="fas fa-running"></i> Lifestyle</div>
                    </div>

                    <button class="expand-btn" onclick="toggleDetails(this)">
                        <span>View Treatment Protocol</span>
                        <i class="fas fa-chevron-down"></i>
                    </button>
                </div>

                <div class="details-content">
                    <div class="details-inner">
                        <div class="detail-block">
                            <div class="detail-heading">Recommended Medication</div>
                            <ul class="item-list">
                                ${(item.medication || []).map(m => `<li>${m}</li>`).join('')}
                            </ul>
                        </div>
                        
                        <div class="detail-block">
                            <div class="detail-heading">Dietary Adjustments</div>
                            <ul class="item-list">
                                ${(item.diet || []).map(d => `<li>${d}</li>`).join('')}
                            </ul>
                        </div>

                        <div class="detail-block">
                            <div class="detail-heading">Lifestyle & Recovery</div>
                            <ul class="item-list">
                                ${(item.workout || []).map(w => `<li>${w}</li>`).join('')}
                            </ul>
                        </div>

                        <div class="detail-block">
                            <div class="detail-heading" style="color:#ef4444;">Precautions</div>
                            <ul class="item-list">
                                ${(item.precautions || []).map(p => `<li>${p}</li>`).join('')}
                            </ul>
                        </div>
                    </div>
                </div>
            `;
            resultsArea.appendChild(card);
        });

    } catch (e) {
        loader.style.display = 'none';
        resultsArea.innerHTML = `<div style="text-align:center; color:red; grid-column:1/-1;">Error: ${e.message}</div>`;
    }
}

function toggleDetails(btn) {
    const content = btn.parentElement.nextElementSibling;
    const icon = btn.querySelector('.fa-chevron-down');
    
    if (content.style.maxHeight) {
        content.style.maxHeight = null;
        icon.style.transform = 'rotate(0deg)';
        btn.querySelector('span').textContent = 'View Treatment Protocol';
    } else {
        content.style.maxHeight = content.scrollHeight + "px";
        icon.style.transform = 'rotate(180deg)';
        btn.querySelector('span').textContent = 'Hide Details';
    }
}