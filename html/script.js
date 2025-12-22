// =======================================================
// SCRIPT.JS - Hlavní logika Questbook UI
// =======================================================

// Globální proměnné
let currentQuests = { active: [], completed: [], all: [] };
let currentTab = 'active'; // 'active', 'completed', 'all'
let selectedQuestId = null;
let isAdminUser = false;
let currentEditingQuestId = null;

// Audio přehrávače
const gameAudioPlayer = document.getElementById('game-player');
const journalAudioPlayer = document.getElementById('journal-player');

// -------------------------------------------------------
// EVENT LISTENER - Příjem zpráv z Lua
// -------------------------------------------------------
window.addEventListener('message', function(event) {
    const data = event.data;

    // 1. Přehrání zvuku (přímo ze hry, ne z deníku)
    if (data.action === 'playSound') {
        gameAudioPlayer.src = data.soundFile;
        gameAudioPlayer.volume = data.volume || 1.0;
        gameAudioPlayer.play();
    }

    // 2. Otevření knihy
    if (data.action === 'openBook') {
        currentQuests = data.quests;
        isAdminUser = data.isAdmin;
        
        setupAdminView(); // Skrýt/Zobrazit admin prvky
        
        document.getElementById('quest-book').style.display = 'flex';
        
        // Pokud admin nebyl v admin tabu, resetujeme na active
        if (currentTab === 'all' && !isAdminUser) {
            currentTab = 'active';
        }
        
        renderList(); // Vykreslit seznam
        
        // Pokud bylo něco vybráno, pokusíme se obnovit detail (např. po editaci)
        if (selectedQuestId) {
            const quest = findQuestById(selectedQuestId);
            if (quest) {
                selectQuest(quest);
            } else {
                hideDetails();
            }
        } else {
            hideDetails();
        }
    }

    // 3. Zavření knihy
    if (data.action === 'closeBook') {
        document.getElementById('quest-book').style.display = 'none';
        journalAudioPlayer.pause();
        journalAudioPlayer.currentTime = 0;
        closeEditModal(); // Zavřít modal, pokud byl otevřený
    }

    // 4. Update sledování (Tracking)
    if (data.action === 'updateTracking') {
        updateTrackingState(data.activeId);
        renderList(); // Překreslit hvězdičky v seznamu
        
        // Pokud je zrovna otevřený detail sledovaného questu, aktualizujeme tlačítko
        if (selectedQuestId) {
            const quest = findQuestById(selectedQuestId);
            if(quest) selectQuest(quest);
        }
    }
});

// Zavírání přes ESC
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        // Pokud je otevřený modal, zavřeme jen modal
        if (!document.getElementById('edit-modal').classList.contains('hidden')) {
            closeEditModal();
        } else {
            // Jinak zavřeme knihu
            fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: JSON.stringify({}) });
        }
    }
});

// -------------------------------------------------------
// POMOCNÉ FUNKCE
// -------------------------------------------------------

function findQuestById(id) {
    // Prohledá všechny seznamy
    return [...currentQuests.active, ...currentQuests.completed, ...currentQuests.all].find(q => q.id === id);
}

function hideDetails() {
    document.getElementById('quest-details').classList.add('hidden');
    document.getElementById('empty-state').classList.remove('hidden');
}

function setupAdminView() {
    const adminTabBtn = document.getElementById('admin-tab-btn');
    const adminControls = document.getElementById('admin-controls');
    const adminInfo = document.getElementById('admin-status-info');

    if (isAdminUser) {
        adminTabBtn.classList.remove('admin-hidden');
    } else {
        adminTabBtn.classList.add('admin-hidden');
        if (adminControls) adminControls.classList.add('admin-hidden');
        if (adminInfo) adminInfo.classList.add('admin-hidden');
    }
}

// -------------------------------------------------------
// RENDER LOGIKA (Seznam a Detaily)
// -------------------------------------------------------

function switchTab(tab) {
    currentTab = tab;
    
    // Update active class na tlačítkách
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');
    
    // Reset výběru
    selectedQuestId = null;
    hideDetails();
    
    renderList();
}

function renderList() {
    const list = document.getElementById('quest-list');
    list.innerHTML = '';
    
    const questsToShow = currentQuests[currentTab] || [];
    
    if (questsToShow.length === 0) {
        list.innerHTML = '<li style="text-align:center; margin-top:20px; font-style:italic; opacity:0.6;">Žádné záznamy...</li>';
        return;
    }

    let lastGroupId = -1; // Pro sledování změny skupiny (Admin View)

    questsToShow.forEach(quest => {
        // --- LOGIKA SESKUPOVÁNÍ (Pouze pro Admin Tab) ---
        if (currentTab === 'all' && isAdminUser) {
            if (quest.groupId !== lastGroupId) {
                const header = document.createElement('div');
                header.className = 'group-header';
                header.innerText = quest.groupName || `Skupina ${quest.groupId}`;
                list.appendChild(header);
                lastGroupId = quest.groupId;
            }
        }

        // --- VYTVOŘENÍ POLOŽKY ---
        const li = document.createElement('li');
        li.className = 'quest-item';
        if (quest.id === selectedQuestId) li.classList.add('selected');
        if (quest.isTracking) li.classList.add('tracking');
        
        let htmlContent = `<span class="quest-name">${quest.name}</span>`;
        
        // Admin štítky stavu
        if (currentTab === 'all' && isAdminUser) {
            let colorClass = 'tag-0';
            if (quest.state === 1) colorClass = 'tag-1';
            if (quest.state === 100) colorClass = 'tag-100';
            
            htmlContent += `<span class="quest-state-tag ${colorClass}">${quest.stateLabel}</span>`;
        }
        
        li.innerHTML = htmlContent;
        li.onclick = () => selectQuest(quest);
        
        list.appendChild(li);
    });
}

function selectQuest(quest) {
    selectedQuestId = quest.id;
    renderList(); // Překreslit pro zvýraznění vybraného

    const details = document.getElementById('quest-details');
    const empty = document.getElementById('empty-state');
    
    // 1. Základní info
    const title = document.getElementById('detail-title');
    title.innerText = quest.name;
    if (isAdminUser) title.innerText += ` (ID: ${quest.id})`;
    
    document.getElementById('detail-desc').innerText = quest.description || "Bez popisu.";
    
    // 2. Admin Info (Stav)
    const adminInfo = document.getElementById('admin-status-info');
    if (isAdminUser) {
        adminInfo.classList.remove('admin-hidden');
        adminInfo.innerText = `Stav: ${quest.stateLabel} (${quest.state})`;
    } else {
        adminInfo.classList.add('admin-hidden');
    }

    // 3. Audio Tlačítka
    const audioContainer = document.getElementById('audio-list');
    audioContainer.innerHTML = '';
    
    if (quest.sounds && quest.sounds.length > 0) {
        quest.sounds.forEach(sound => {
            const btn = document.createElement('button');
            btn.className = 'action-btn audio-btn';
            btn.innerHTML = '<span>🔊</span> ' + sound.label;
            btn.onclick = () => playJournalSound(sound.file);
            audioContainer.appendChild(btn);
        });
        audioContainer.style.display = 'flex';
    } else {
        audioContainer.style.display = 'none';
    }

    // 4. Tlačítko Sledovat (Track)
    const trackBtn = document.getElementById('btn-track');
    // Zobrazíme vždy, aby admin mohl testovat trasu, nebo jen u aktivních pro hráče
    trackBtn.style.display = 'block';
    
    if (quest.isTracking) {
        trackBtn.innerText = "Přestat sledovat";
        trackBtn.className = "action-btn btn-danger";
        trackBtn.onclick = stopTracking;
    } else {
        trackBtn.innerText = "Sledovat úkol";
        trackBtn.className = "action-btn";
        trackBtn.onclick = trackQuest;
    }

    // 5. Admin Controls (Panel akcí)
    const adminControls = document.getElementById('admin-controls');
    if (isAdminUser) {
        adminControls.classList.remove('admin-hidden');
    } else {
        adminControls.classList.add('admin-hidden');
    }

    // Zobrazit detail
    details.classList.remove('hidden');
    empty.classList.add('hidden');
}

// -------------------------------------------------------
// INTERAKCE (Audio, Tracking, Admin)
// -------------------------------------------------------

function playJournalSound(file) {
    journalAudioPlayer.src = file;
    journalAudioPlayer.volume = 0.5;
    journalAudioPlayer.play();
}

function trackQuest() {
    if (!selectedQuestId) return;
    fetch(`https://${GetParentResourceName()}/setActive`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ questId: selectedQuestId })
    });
}

function stopTracking() {
    fetch(`https://${GetParentResourceName()}/stopTracking`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function updateTrackingState(newActiveId) {
    // Reset u všech questů ve všech listech
    [...currentQuests.active, ...currentQuests.completed, ...currentQuests.all].forEach(q => q.isTracking = false);
    
    // Nastavit nový
    if (newActiveId > 0) {
        // Musíme najít všechny výskyty tohoto ID (v active i v all) a nastavit jim true
        const lists = [currentQuests.active, currentQuests.completed, currentQuests.all];
        lists.forEach(list => {
            const q = list.find(q => q.id === newActiveId);
            if (q) q.isTracking = true;
        });
    }
}

function adminSetState(newState) {
    if (!selectedQuestId) return;
    fetch(`https://${GetParentResourceName()}/adminSetState`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ questId: selectedQuestId, state: newState })
    });
}

// -------------------------------------------------------
// EDITACE TEXTŮ (Modal)
// -------------------------------------------------------

function openEditModal() {
    if (!selectedQuestId) return;
    
    // Najít data questu (hledáme v 'all', protože tam je vše)
    const quest = currentQuests.all.find(q => q.id === selectedQuestId);
    if (!quest) return;

    currentEditingQuestId = quest.id;
    
    // Naplnit inputy
    document.getElementById('edit-quest-id').innerText = "#" + quest.id;
    document.getElementById('edit-name').value = quest.name;
    document.getElementById('edit-desc').value = quest.description || "";
    // Pozor: Tyto vlastnosti (start_text, target_text) musí Lua poslat v 'GetQuestDataForUI'
    document.getElementById('edit-start-text').value = quest.start_text || "";
    document.getElementById('edit-target-text').value = quest.target_text || "";
    
    // Zobrazit
    document.getElementById('edit-modal').classList.remove('hidden');
}

function closeEditModal() {
    document.getElementById('edit-modal').classList.add('hidden');
    currentEditingQuestId = null;
}

function saveEditQuest() {
    if (!currentEditingQuestId) return;
    
    const data = {
        id: currentEditingQuestId,
        name: document.getElementById('edit-name').value,
        description: document.getElementById('edit-desc').value,
        start_text: document.getElementById('edit-start-text').value,
        target_text: document.getElementById('edit-target-text').value
    };

    fetch(`https://${GetParentResourceName()}/adminSaveQuest`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    
    closeEditModal();
    // Poznámka: UI se refreshne, až přijde event 'syncQuestData' z Lua
}