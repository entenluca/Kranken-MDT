const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'nm_ktjobs';

const state = {
    missions: [],
    jobs: [],
    displayTitle: 'Krankentransport-Jobs',
    vehicleTypeOptions: ['RTW', 'KTW'],
    defaultNpcModel: '',
    search: '',
    open: false,
    placing: false,
    placementKeyLabel: 'E',
    collapsed: new Set(),
};

const refs = {};

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
        job: state.jobs[0]?.name || '',
        text: '',
        start: { x: '', y: '', z: '' },
        target: { x: '', y: '', z: '' },
        reward: { enabled: false, min: '', max: '' },
        npcModel: '',
        vehicles: [],
        items: [],
    };
}

function filteredMissions() {
    const q = state.search.trim().toLowerCase();
    if (!q) return state.missions;
    return state.missions.filter((m) => (m.text || '').toLowerCase().includes(q));
}

function formatCoord(value) {
    return value === '' || value === undefined || value === null ? '' : String(value);
}

function buildShell() {
    const root = document.getElementById('root');
    root.replaceChildren();

    const app = UI.el('div', 'app hidden', { id: 'app' });
    app.appendChild(UI.el('div', 'overlay'));

    const modal = UI.el('div', 'modal');

    const header = UI.el('header', 'modal-header');
    const titleWrap = UI.el('div', 'title-wrap');
    titleWrap.appendChild(UI.el('span', 'status-dot'));
    titleWrap.appendChild(UI.el('h1', '', { text: `${state.displayTitle} · Einsatz-Konfigurator` }));
    header.appendChild(titleWrap);
    header.appendChild(UI.button('btn-ghost', {
        text: 'Schließen (ESC)',
        onClick: () => nui('close'),
    }));

    const intro = UI.el('p', 'intro', {
        text: 'Jeder Einsatz gehört zu einem Job und wird per Dispatch verschickt. Koordinaten kannst du vor Ort übernehmen. Änderungen werden erst nach dem Speichern übernommen.',
    });

    const toolbar = UI.el('div', 'toolbar');
    const searchWrap = UI.el('div', 'search-wrap');
    searchWrap.appendChild(Icons.create('search', 16));
    const searchInput = UI.input('search-input', {
        type: 'search',
        placeholder: 'Dispatch-Text durchsuchen…',
    });
    searchInput.addEventListener('input', (e) => {
        state.search = e.target.value;
        renderMissions();
    });
    searchWrap.appendChild(searchInput);

    const btnNew = UI.button('btn-primary btn-with-icon', {
        icon: 'plus',
        text: ' Neuer Einsatz',
        onClick: () => {
            syncFromDom();
            const mission = defaultMission();
            state.collapsed.delete(mission.id);
            state.missions.unshift(mission);
            renderMissions();
        },
    });

    toolbar.appendChild(searchWrap);
    toolbar.appendChild(btnNew);

    const missionsWrap = UI.el('div', 'missions-wrap');
    const missionsViewport = UI.el('div', 'missions-viewport');
    const missions = UI.el('div', 'missions-list');
    const scrollbarTrack = UI.el('div', 'custom-scrollbar hidden');
    const scrollbarThumb = UI.el('div', 'custom-scrollbar-thumb');
    scrollbarTrack.appendChild(scrollbarThumb);
    missionsViewport.appendChild(missions);
    missionsWrap.appendChild(missionsViewport);
    missionsWrap.appendChild(scrollbarTrack);

    const footer = UI.el('footer', 'modal-footer');
    footer.appendChild(UI.button('btn-secondary', {
        text: 'Abbrechen',
        onClick: () => nui('close'),
    }));
    footer.appendChild(UI.button('btn-primary', {
        text: 'Speichern',
        onClick: () => {
            syncFromDom();
            nui('save', { missions: state.missions });
        },
    }));

    modal.appendChild(header);
    modal.appendChild(intro);
    modal.appendChild(toolbar);
    modal.appendChild(missionsWrap);
    modal.appendChild(footer);
    app.appendChild(modal);
    root.appendChild(app);

    refs.app = app;
    refs.missions = missions;
    refs.missionsViewport = missionsViewport;
    refs.scrollbarTrack = scrollbarTrack;
    refs.scrollbarThumb = scrollbarThumb;
    refs.searchInput = searchInput;

    refs.scrollbar = CustomScrollbar.attach(missionsViewport, scrollbarTrack, scrollbarThumb);

    const placementOverlay = UI.el('div', 'placement-overlay hidden', { id: 'placement-overlay' });
    const placementHint = UI.el('div', 'placement-hint');
    placementHint.appendChild(UI.el('p', 'placement-hint-text', { id: 'placement-hint-text' }));
    placementHint.appendChild(UI.el('span', 'placement-hint-cancel', { text: 'ESC zum Abbrechen' }));
    placementOverlay.appendChild(placementHint);
    root.appendChild(placementOverlay);

    refs.placementOverlay = placementOverlay;
    refs.placementHintText = document.getElementById('placement-hint-text');
}

function enterPlacementMode(data) {
    state.placing = true;
    refs.app.classList.add('hidden');
    refs.placementOverlay.classList.remove('hidden');

    const label = data.field === 'target' ? 'Zielpunkt' : 'Startpunkt';
    const key = data.key || state.placementKeyLabel || 'E';
    refs.placementHintText.textContent = `Drücke [${key}], um den ${label} zu setzen.`;
}

function exitPlacementMode() {
    state.placing = false;
    refs.placementOverlay.classList.add('hidden');
    if (state.open) {
        refs.app.classList.remove('hidden');
    }
}

function applyPlacementResult(data) {
    const mission = state.missions.find((m) => m.id === data.missionId);
    if (!mission || !data.field) return;

    mission[data.field] = { x: data.x, y: data.y, z: data.z };
    renderMissions();
}

function createCoordBlock(title, prefix, mission, missionId) {
    const block = UI.el('div', 'coord-block');
    block.appendChild(UI.el('h3', '', { text: title }));

    const row = UI.el('div', 'coord-row');
    ['x', 'y', 'z'].forEach((axis) => {
        const input = UI.input(`coord-input ${prefix}-${axis}`, {
            type: 'number',
            step: '0.01',
            placeholder: axis.toUpperCase(),
        });
        const val = formatCoord(mission[prefix]?.[axis]);
        if (val !== '') input.value = val;
        row.appendChild(input);
    });

    block.appendChild(row);

    const placeLabel = prefix === 'target' ? 'Zielpunkt setzen' : 'Startpunkt setzen';
    block.appendChild(UI.button('btn-small btn-secondary btn-with-icon btn-place', {
        icon: 'pin',
        text: ` ${placeLabel}`,
        onClick: () => {
            syncFromDom();
            nui('beginPlacement', { field: prefix, missionId });
        },
    }));

    return block;
}

function createListRow(missionId, kind, index, data, onRemove) {
    const row = UI.el('div', `list-row${kind === 'item' ? ' items' : ''}`, {
        dataset: { [kind]: String(index) },
    });

    if (kind === 'vehicle') {
        const typeItems = state.vehicleTypeOptions.map((v) => ({ value: v, label: v }));
        const typeDropdown = UI.dropdown({
            className: 'vehicle-type-dd',
            items: typeItems,
            value: data.type || '',
            placeholder: 'Typ',
        });
        row._vehicleTypeDropdown = typeDropdown;
        row.appendChild(typeDropdown.el);

        const minInput = UI.input('vehicle-min', {
            type: 'number',
            min: '1',
            title: 'min. besetzt',
            placeholder: 'Min.',
        });
        if (data.min !== undefined && data.min !== '') minInput.value = String(data.min);
        row.appendChild(minInput);
        row.appendChild(UI.iconButton('btn-check-vehicle', 'play', {
            title: 'Status prüfen',
            onClick: () => {
                syncFromDom();
                nui('checkVehicles', { missionId });
            },
        }));
    } else {
        const nameInput = UI.input('item-name', { type: 'text', placeholder: 'Item-Name' });
        if (data.name) nameInput.value = data.name;
        row.appendChild(nameInput);

        const amountInput = UI.input('item-amount', {
            type: 'number',
            min: '1',
            title: 'Menge',
            placeholder: 'Menge',
        });
        if (data.amount !== undefined && data.amount !== '') amountInput.value = String(data.amount);
        row.appendChild(amountInput);
    }

    row.appendChild(UI.iconButton('btn-remove', 'close', {
        title: 'Entfernen',
        onClick: onRemove,
    }));

    return row;
}

function missionSummary(mission) {
    const text = (mission.text || '').trim() || 'Neuer Einsatz';
    const job = mission.job || '—';
    return `${mission.type || 'MTD'} · ${job} · ${text}`;
}

function toggleMissionCollapsed(missionId) {
    if (state.collapsed.has(missionId)) {
        state.collapsed.delete(missionId);
    } else {
        state.collapsed.add(missionId);
    }
}

function createMissionCard(mission) {
    const isCollapsed = state.collapsed.has(mission.id);
    const card = UI.el('article', `mission-card ${mission.type === 'KT' ? 'kt-only' : 'mtd-only'}${isCollapsed ? ' is-collapsed' : ''}`, {
        dataset: { id: mission.id },
    });

    const cardHeader = UI.el('div', 'mission-card-header');
    const collapseBtn = UI.iconButton('btn-collapse', 'chevronRight', {
        title: isCollapsed ? 'Einsatz aufklappen' : 'Einsatz einklappen',
    });
    collapseBtn.querySelector('.icon').classList.add('collapse-icon');

    const summary = UI.el('span', 'mission-summary', { text: missionSummary(mission) });
    const toggle = UI.toggle(mission.enabled, () => {});
    toggle.el.title = 'Aktiv';

    const deleteBtn = UI.iconButton('btn-delete-header', 'trash', {
        title: 'Einsatz löschen',
        onClick: (e) => {
            e.stopPropagation();
            syncFromDom();
            state.missions = state.missions.filter((m) => m.id !== mission.id);
            state.collapsed.delete(mission.id);
            renderMissions();
        },
    });

    cardHeader.appendChild(collapseBtn);
    cardHeader.appendChild(summary);
    cardHeader.appendChild(toggle.el);
    cardHeader.appendChild(deleteBtn);

    collapseBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        syncFromDom();
        toggleMissionCollapsed(mission.id);
        renderMissions();
    });

    cardHeader.addEventListener('click', () => {
        syncFromDom();
        toggleMissionCollapsed(mission.id);
        renderMissions();
    });

    [toggle.el, deleteBtn].forEach((el) => {
        el.addEventListener('click', (e) => e.stopPropagation());
    });

    card.appendChild(cardHeader);

    const body = UI.el('div', 'mission-card-body');

    const top = UI.el('div', 'mission-top');

    const typeDropdown = UI.dropdown({
        className: 'mission-type-dd',
        items: [
            { value: 'MTD', label: 'MTD' },
            { value: 'KT', label: 'KT' },
        ],
        value: mission.type,
        onChange: (val) => {
            card.classList.toggle('kt-only', val === 'KT');
            card.classList.toggle('mtd-only', val === 'MTD');
        },
    });
    top.appendChild(typeDropdown.el);

    const jobDropdown = UI.dropdown({
        className: 'mission-job-dd',
        items: state.jobs.map((j) => ({ value: j.name, label: j.label || j.name })),
        value: mission.job || state.jobs[0]?.name || '',
    });
    top.appendChild(jobDropdown.el);

    top.appendChild(UI.input('mission-text', {
        type: 'text',
        placeholder: 'Dispatch-Text',
    }));
    const textInput = top.querySelector('.mission-text');
    if (mission.text) textInput.value = mission.text;

    body.appendChild(top);

    const coords = UI.el('div', 'coords-grid');
    coords.appendChild(createCoordBlock('START', 'start', mission, mission.id));
    coords.appendChild(createCoordBlock('ZIEL', 'target', mission, mission.id));
    body.appendChild(coords);

    const rewardSection = UI.section(
        'BELOHNUNG',
        'Optional. Bei Aktivierung wird der Betrag auf das Geschäftskonto des eingestellten Jobs gutgeschrieben.',
    );

    const rewardEnableRow = UI.el('div', 'reward-enable-row');
    const rewardToggle = UI.toggle(mission.reward?.enabled === true, () => {});
    rewardEnableRow.appendChild(UI.el('span', 'reward-label', { text: 'Belohnung aktivieren' }));
    rewardEnableRow.appendChild(rewardToggle.el);
    rewardSection.appendChild(rewardEnableRow);

    const rewardRow = UI.el('div', 'reward-row reward-amount-row');
    const minInput = UI.input('reward-min', { type: 'number', min: '0', placeholder: 'Min' });
    const maxInput = UI.input('reward-max', { type: 'number', min: '0', placeholder: 'Max' });
    if (mission.reward?.min !== '' && mission.reward?.min !== undefined) minInput.value = String(mission.reward.min);
    if (mission.reward?.max !== '' && mission.reward?.max !== undefined) maxInput.value = String(mission.reward.max);

    const syncRewardFields = () => {
        const enabled = rewardToggle.getValue();
        minInput.disabled = !enabled;
        maxInput.disabled = !enabled;
        rewardRow.classList.toggle('is-disabled', !enabled);
    };

    rewardToggle.el.querySelector('input').addEventListener('change', syncRewardFields);
    syncRewardFields();

    rewardRow.appendChild(minInput);
    rewardRow.appendChild(maxInput);
    rewardSection.appendChild(rewardRow);
    body.appendChild(rewardSection);

    card._controls = { toggle, typeDropdown, jobDropdown, rewardToggle };

    const npcSection = UI.section('NPC (nur bei KT)');
    npcSection.classList.add('kt-only');
    const npcRow = UI.el('div', 'npc-row');
    const npcInput = UI.input('npc-model', { type: 'text', placeholder: 'NPC-Modell' });
    npcInput.style.flex = '1';
    if (mission.npcModel) npcInput.value = mission.npcModel;
    npcRow.appendChild(npcInput);
    npcSection.appendChild(npcRow);
    body.appendChild(npcSection);

    const vehicleSection = UI.section(
        'FAHRZEUG-VORAUSSETZUNGEN',
        'Alle Zeilen müssen erfüllt sein (mindestens so viele besetzte Fahrzeuge des Typs), damit die Mission automatisch ausgelöst wird.',
    );
    const vehicleList = UI.el('div', 'vehicle-list');
    (mission.vehicles || []).forEach((v, i) => {
        vehicleList.appendChild(createListRow(mission.id, 'vehicle', i, v, () => {
            syncFromDom();
            const m = state.missions.find((x) => x.id === mission.id);
            m.vehicles.splice(i, 1);
            renderMissions();
        }));
    });
    vehicleSection.appendChild(vehicleList);
    vehicleSection.appendChild(UI.button('btn-small btn-secondary btn-with-icon', {
        icon: 'plus',
        text: ' Fahrzeug',
        onClick: () => {
            syncFromDom();
            const m = state.missions.find((x) => x.id === mission.id);
            m.vehicles.push({ type: '', min: '' });
            renderMissions();
        },
    }));
    body.appendChild(vehicleSection);

    const itemSection = UI.section(
        'MTD-ITEMS',
        'Items werden bei Annahme vergeben und bei Abschluss oder Abbruch entfernt.',
    );
    itemSection.classList.add('mtd-only');
    const itemList = UI.el('div', 'item-list');
    (mission.items || []).forEach((item, i) => {
        itemList.appendChild(createListRow(mission.id, 'item', i, item, () => {
            syncFromDom();
            const m = state.missions.find((x) => x.id === mission.id);
            m.items.splice(i, 1);
            renderMissions();
        }));
    });
    itemSection.appendChild(itemList);
    itemSection.appendChild(UI.button('btn-small btn-secondary btn-with-icon', {
        icon: 'plus',
        text: ' Item',
        onClick: () => {
            syncFromDom();
            const m = state.missions.find((x) => x.id === mission.id);
            m.items.push({ name: '', amount: '' });
            renderMissions();
        },
    }));
    body.appendChild(itemSection);

    card.appendChild(body);
    return card;
}

function renderMissions() {
    const list = filteredMissions();
    refs.missions.replaceChildren();

    if (!list.length) {
        refs.missions.appendChild(UI.el('div', 'empty', {
            text: 'Keine Einsätze vorhanden. Lege einen neuen an.',
        }));
        refs.scrollbar?.update();
        return;
    }

    list.forEach((mission) => {
        refs.missions.appendChild(createMissionCard(mission));
    });

    requestAnimationFrame(() => refs.scrollbar?.update());
}

function readCoord(card, prefix) {
    const read = (axis) => {
        const el = card.querySelector(`.${prefix}-${axis}`);
        const raw = el?.value ?? '';
        if (raw === '') return '';
        const num = parseFloat(raw);
        return Number.isNaN(num) ? '' : num;
    };
    return { x: read('x'), y: read('y'), z: read('z') };
}

function getMissionFromCard(card) {
    const id = card.dataset.id;
    const mission = state.missions.find((m) => m.id === id) || defaultMission();
    const controls = card._controls;

    mission.enabled = controls?.toggle ? controls.toggle.getValue() : true;
    mission.type = controls?.typeDropdown ? controls.typeDropdown.getValue() : 'MTD';
    mission.job = controls?.jobDropdown ? controls.jobDropdown.getValue() : '';
    mission.text = card.querySelector('.mission-text')?.value ?? '';
    mission.start = readCoord(card, 'start');
    mission.target = readCoord(card, 'target');

    const minRaw = card.querySelector('.reward-min')?.value ?? '';
    const maxRaw = card.querySelector('.reward-max')?.value ?? '';
    const rewardEnabled = controls?.rewardToggle ? controls.rewardToggle.getValue() : false;
    mission.reward = {
        enabled: rewardEnabled,
        min: minRaw === '' ? '' : parseInt(minRaw, 10) || 0,
        max: maxRaw === '' ? '' : parseInt(maxRaw, 10) || 0,
    };

    const npcInput = card.querySelector('.npc-model');
    mission.npcModel = npcInput?.value ?? '';

    mission.vehicles = Array.from(card.querySelectorAll('.list-row[data-vehicle]')).map((row) => {
        const type = row._vehicleTypeDropdown?.getValue() ?? '';
        const minRaw = row.querySelector('.vehicle-min')?.value ?? '';
        return {
            type: type.trim(),
            min: minRaw === '' ? '' : parseInt(minRaw, 10) || 1,
        };
    }).filter((v) => v.type);

    mission.items = Array.from(card.querySelectorAll('.list-row[data-item]')).map((row) => {
        const name = row.querySelector('.item-name')?.value.trim() ?? '';
        const amountRaw = row.querySelector('.item-amount')?.value ?? '';
        return {
            name,
            amount: amountRaw === '' ? '' : parseInt(amountRaw, 10) || 1,
        };
    }).filter((i) => i.name);

    return mission;
}

function syncFromDom() {
    document.querySelectorAll('.mission-card').forEach((card) => {
        const mission = getMissionFromCard(card);
        const idx = state.missions.findIndex((m) => m.id === mission.id);
        if (idx >= 0) state.missions[idx] = mission;
    });
}

function openConfigurator(data) {
    state.missions = data.missions || [];
    state.jobs = data.jobs || [];
    state.vehicleTypeOptions = data.vehicleTypeOptions || ['RTW', 'KTW'];
    state.displayTitle = data.displayTitle || 'Krankentransport-Jobs';
    state.placementKeyLabel = data.placementKeyLabel || 'E';
    state.defaultNpcModel = data.defaultNpcModel || '';
    state.search = '';
    state.open = true;

    refs.searchInput.value = '';
    refs.app.classList.remove('hidden');
    renderMissions();
}

function closeConfigurator() {
    state.open = false;
    state.placing = false;
    refs.app.classList.add('hidden');
    refs.placementOverlay.classList.add('hidden');
    document.querySelectorAll('.dropdown.open').forEach((d) => d.classList.remove('open'));
}

function updateVehicleStatus(missionId, status) {
    const card = document.querySelector(`.mission-card[data-id="${missionId}"]`);
    if (!card) return;

    const heading = card.querySelector('.section h3');
    if (!heading) return;

    const iconName = (met) => (met ? 'check' : 'cross');
    let badge = card.querySelector('.vehicle-status');

    if (!badge) {
        badge = UI.el('span', 'vehicle-status');
        heading.appendChild(document.createTextNode(' '));
        heading.appendChild(badge);
    }

    badge.replaceChildren();
    badge.className = `status-badge vehicle-status ${status.every((s) => s.met) ? 'ok' : 'fail'}`;

    status.forEach((s, idx) => {
        if (idx > 0) badge.appendChild(document.createTextNode(' · '));
        const line = UI.el('span', 'status-line');
        line.appendChild(document.createTextNode(`${s.type}: ${s.current}/${s.min} `));
        line.appendChild(Icons.create(iconName(s.met), 12));
        badge.appendChild(line);
    });
}

buildShell();

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};

    if (action === 'open') openConfigurator(data);
    if (action === 'close') closeConfigurator();
    if (action === 'placementMode') enterPlacementMode(data);
    if (action === 'placementDone') {
        applyPlacementResult(data);
        exitPlacementMode();
    }
    if (action === 'placementCancel') exitPlacementMode();
    if (action === 'saved' && data?.missions) {
        state.missions = data.missions;
        renderMissions();
    }
    if (action === 'vehicleStatus' && data?.status) {
        updateVehicleStatus(data.missionId, data.status);
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && state.open && !state.placing) {
        nui('close');
    }
});
