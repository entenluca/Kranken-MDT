const app = document.getElementById('app');
const missionsEl = document.getElementById('missions');
const searchEl = document.getElementById('search');

let state = {
    missions: [],
    jobs: [],
    vehicleTypes: {},
    defaultNpcModel: 'a_m_y_business_02',
    search: '',
};

const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'nm_ktjobs';

function nui(event, data = {}) {
    return fetch(`https://${resourceName}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then((r) => r.json()).catch(() => ({}));
}

function newMissionId() {
    return `m_${Date.now()}_${Math.floor(Math.random() * 9000) + 1000}`;
}

function defaultMission() {
    return {
        id: newMissionId(),
        enabled: true,
        type: 'MTD',
        job: state.jobs[0]?.name || 'ambulance',
        text: '',
        start: { x: 0, y: 0, z: 0 },
        target: { x: 0, y: 0, z: 0 },
        reward: { min: 250, max: 500 },
        npcModel: state.defaultNpcModel,
        vehicles: [],
        items: [],
    };
}

function filteredMissions() {
    const q = state.search.trim().toLowerCase();
    if (!q) return state.missions;
    return state.missions.filter((m) => (m.text || '').toLowerCase().includes(q));
}

function render() {
    const list = filteredMissions();

    if (!list.length) {
        missionsEl.innerHTML = '<div class="empty">Keine Einsätze vorhanden. Lege einen neuen an.</div>';
        return;
    }

    missionsEl.innerHTML = list.map((mission) => renderMission(mission)).join('');
    bindMissionEvents();
}

function renderMission(mission) {
    const typeClass = mission.type === 'KT' ? 'kt-only' : 'mtd-only';
    const jobOptions = state.jobs.map((j) =>
        `<option value="${j.name}" ${j.name === mission.job ? 'selected' : ''}>${j.label || j.name}</option>`
    ).join('');

    const vehicles = (mission.vehicles || []).map((v, i) => `
        <div class="list-row" data-mission="${mission.id}" data-vehicle="${i}">
            <input type="text" class="vehicle-type" value="${escapeHtml(v.type || '')}" placeholder="RTW" />
            <input type="number" class="vehicle-min" min="1" value="${v.min || 1}" title="min. besetzt" />
            <button type="button" class="btn-icon btn-check-vehicle" title="Status prüfen">▶</button>
            <button type="button" class="btn-icon btn-remove-vehicle" title="Entfernen">✕</button>
        </div>
    `).join('');

    const items = (mission.items || []).map((item, i) => `
        <div class="list-row items" data-mission="${mission.id}" data-item="${i}">
            <input type="text" class="item-name" value="${escapeHtml(item.name || '')}" placeholder="medikit" />
            <input type="number" class="item-amount" min="1" value="${item.amount || 1}" title="Menge" />
            <button type="button" class="btn-icon btn-remove-item" title="Entfernen">✕</button>
        </div>
    `).join('');

    return `
        <article class="mission-card ${typeClass}" data-id="${mission.id}">
            <div class="mission-top">
                <label class="toggle" title="Aktiv">
                    <input type="checkbox" class="mission-enabled" ${mission.enabled ? 'checked' : ''} />
                    <span class="slider"></span>
                </label>
                <select class="mission-type">
                    <option value="MTD" ${mission.type === 'MTD' ? 'selected' : ''}>MTD</option>
                    <option value="KT" ${mission.type === 'KT' ? 'selected' : ''}>KT</option>
                </select>
                <select class="mission-job">${jobOptions}</select>
                <input type="text" class="mission-text" value="${escapeHtml(mission.text || '')}" placeholder="Dispatch-Text" />
                <button type="button" class="btn-danger btn-delete">Löschen</button>
            </div>

            <div class="coords-grid">
                <div class="coord-block">
                    <h3>START</h3>
                    <div class="coord-row">
                        <input type="number" step="0.01" class="start-x" value="${mission.start?.x ?? 0}" placeholder="X" />
                        <input type="number" step="0.01" class="start-y" value="${mission.start?.y ?? 0}" placeholder="Y" />
                        <input type="number" step="0.01" class="start-z" value="${mission.start?.z ?? 0}" placeholder="Z" />
                        <button type="button" class="btn-icon btn-pos" data-field="start" title="Position übernehmen">📍</button>
                    </div>
                </div>
                <div class="coord-block">
                    <h3>ZIEL</h3>
                    <div class="coord-row">
                        <input type="number" step="0.01" class="target-x" value="${mission.target?.x ?? 0}" placeholder="X" />
                        <input type="number" step="0.01" class="target-y" value="${mission.target?.y ?? 0}" placeholder="Y" />
                        <input type="number" step="0.01" class="target-z" value="${mission.target?.z ?? 0}" placeholder="Z" />
                        <button type="button" class="btn-icon btn-pos" data-field="target" title="Position übernehmen">📍</button>
                    </div>
                </div>
            </div>

            <div class="section">
                <h3>REWARD</h3>
                <div class="reward-row">
                    <input type="number" class="reward-min" min="0" value="${mission.reward?.min ?? 0}" placeholder="Min" />
                    <input type="number" class="reward-max" min="0" value="${mission.reward?.max ?? 0}" placeholder="Max" />
                </div>
            </div>

            <div class="section kt-only">
                <h3>NPC (nur bei KT)</h3>
                <div class="npc-row">
                    <input type="text" class="npc-model" value="${escapeHtml(mission.npcModel || state.defaultNpcModel)}" placeholder="a_m_y_business_02" style="flex:1" />
                </div>
            </div>

            <div class="section">
                <h3>FAHRZEUG-VORAUSSETZUNGEN</h3>
                <p class="hint">Alle Zeilen müssen erfüllt sein (mindestens so viele besetzte Fahrzeuge des Typs), damit die Mission automatisch ausgelöst wird.</p>
                <div class="vehicle-list">${vehicles}</div>
                <button type="button" class="btn-small btn-secondary btn-add-vehicle">+ Fahrzeug</button>
            </div>

            <div class="section mtd-only">
                <h3>MTD-ITEMS</h3>
                <p class="hint">Items werden bei Annahme vergeben und bei Abschluss oder Abbruch entfernt.</p>
                <div class="item-list">${items}</div>
                <button type="button" class="btn-small btn-secondary btn-add-item">+ Item</button>
            </div>
        </article>
    `;
}

function escapeHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function getMissionFromDom(card) {
    const id = card.dataset.id;
    const mission = state.missions.find((m) => m.id === id) || defaultMission();

    mission.enabled = card.querySelector('.mission-enabled').checked;
    mission.type = card.querySelector('.mission-type').value;
    mission.job = card.querySelector('.mission-job').value;
    mission.text = card.querySelector('.mission-text').value;
    mission.start = {
        x: parseFloat(card.querySelector('.start-x').value) || 0,
        y: parseFloat(card.querySelector('.start-y').value) || 0,
        z: parseFloat(card.querySelector('.start-z').value) || 0,
    };
    mission.target = {
        x: parseFloat(card.querySelector('.target-x').value) || 0,
        y: parseFloat(card.querySelector('.target-y').value) || 0,
        z: parseFloat(card.querySelector('.target-z').value) || 0,
    };
    mission.reward = {
        min: parseInt(card.querySelector('.reward-min').value, 10) || 0,
        max: parseInt(card.querySelector('.reward-max').value, 10) || 0,
    };

    const npcInput = card.querySelector('.npc-model');
    if (npcInput) mission.npcModel = npcInput.value;

    mission.vehicles = Array.from(card.querySelectorAll('.list-row[data-vehicle]')).map((row) => ({
        type: row.querySelector('.vehicle-type').value.trim(),
        min: parseInt(row.querySelector('.vehicle-min').value, 10) || 1,
    })).filter((v) => v.type);

    mission.items = Array.from(card.querySelectorAll('.list-row[data-item]')).map((row) => ({
        name: row.querySelector('.item-name').value.trim(),
        amount: parseInt(row.querySelector('.item-amount').value, 10) || 1,
    })).filter((i) => i.name);

    return mission;
}

function syncFromDom() {
    document.querySelectorAll('.mission-card').forEach((card) => {
        const mission = getMissionFromDom(card);
        const idx = state.missions.findIndex((m) => m.id === mission.id);
        if (idx >= 0) state.missions[idx] = mission;
    });
}

function bindMissionEvents() {
    document.querySelectorAll('.mission-card').forEach((card) => {
        const id = card.dataset.id;

        card.querySelector('.btn-delete')?.addEventListener('click', () => {
            syncFromDom();
            state.missions = state.missions.filter((m) => m.id !== id);
            render();
        });

        card.querySelector('.mission-type')?.addEventListener('change', (e) => {
            card.classList.toggle('kt-only', e.target.value === 'KT');
            card.classList.toggle('mtd-only', e.target.value === 'MTD');
        });

        card.querySelectorAll('.btn-pos').forEach((btn) => {
            btn.addEventListener('click', async () => {
                syncFromDom();
                const result = await nui('getPosition', { field: btn.dataset.field, missionId: id });
                const mission = state.missions.find((m) => m.id === id);
                if (!mission || !result) return;

                if (result.field === 'start') {
                    mission.start = { x: result.x, y: result.y, z: result.z };
                } else {
                    mission.target = { x: result.x, y: result.y, z: result.z };
                }
                render();
            });
        });

        card.querySelector('.btn-add-vehicle')?.addEventListener('click', () => {
            syncFromDom();
            const mission = state.missions.find((m) => m.id === id);
            if (!mission) return;
            mission.vehicles.push({ type: 'RTW', min: 1 });
            render();
        });

        card.querySelector('.btn-add-item')?.addEventListener('click', () => {
            syncFromDom();
            const mission = state.missions.find((m) => m.id === id);
            if (!mission) return;
            mission.items.push({ name: 'medikit', amount: 1 });
            render();
        });

        card.querySelectorAll('.btn-remove-vehicle').forEach((btn) => {
            btn.addEventListener('click', () => {
                syncFromDom();
                const mission = state.missions.find((m) => m.id === id);
                const index = parseInt(btn.closest('.list-row').dataset.vehicle, 10);
                mission.vehicles.splice(index, 1);
                render();
            });
        });

        card.querySelectorAll('.btn-remove-item').forEach((btn) => {
            btn.addEventListener('click', () => {
                syncFromDom();
                const mission = state.missions.find((m) => m.id === id);
                const index = parseInt(btn.closest('.list-row').dataset.item, 10);
                mission.items.splice(index, 1);
                render();
            });
        });

        card.querySelectorAll('.btn-check-vehicle').forEach((btn) => {
            btn.addEventListener('click', () => {
                syncFromDom();
                nui('checkVehicles', { missionId: id });
            });
        });
    });
}

function openConfigurator(data) {
    state.missions = data.missions || [];
    state.jobs = data.jobs || [{ name: 'ambulance', label: 'ambulance' }];
    state.vehicleTypes = data.vehicleTypes || {};
    state.defaultNpcModel = data.defaultNpcModel || 'a_m_y_business_02';
    state.search = '';
    searchEl.value = '';
    app.classList.remove('hidden');
    render();
}

function closeConfigurator() {
    app.classList.add('hidden');
}

document.getElementById('btn-close').addEventListener('click', () => nui('close'));
document.getElementById('btn-cancel').addEventListener('click', () => nui('close'));
document.getElementById('btn-save').addEventListener('click', () => {
    syncFromDom();
    nui('save', { missions: state.missions });
});

document.getElementById('btn-new').addEventListener('click', () => {
    syncFromDom();
    state.missions.unshift(defaultMission());
    render();
});

searchEl.addEventListener('input', (e) => {
    state.search = e.target.value;
    render();
});

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};

    if (action === 'open') openConfigurator(data);
    if (action === 'close') closeConfigurator();
    if (action === 'saved' && data?.missions) {
        state.missions = data.missions;
        render();
    }
    if (action === 'vehicleStatus' && data?.status) {
        const card = document.querySelector(`.mission-card[data-id="${data.missionId}"]`);
        if (!card) return;

        const hint = card.querySelector('.section h3');
        const lines = data.status.map((s) =>
            `${s.type}: ${s.current}/${s.min} ${s.met ? '✓' : '✗'}`
        ).join(' · ');

        let badge = card.querySelector('.vehicle-status');
        if (!badge) {
            badge = document.createElement('span');
            badge.className = 'status-badge vehicle-status';
            hint.appendChild(document.createTextNode(' '));
            hint.appendChild(badge);
        }
        badge.textContent = lines;
        badge.className = `status-badge vehicle-status ${data.status.every((s) => s.met) ? 'ok' : 'fail'}`;
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') nui('close');
});
