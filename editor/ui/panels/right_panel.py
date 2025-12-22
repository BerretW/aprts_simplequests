# editor/ui/panels/right_panel.py

import json
import config
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QTabWidget, QFormLayout, 
    QLineEdit, QTextEdit, QCheckBox, QComboBox, QPushButton, 
    QSpinBox, QLabel, QMessageBox
)
from PyQt6.QtCore import pyqtSignal

from ..custom_widgets import (
    PromptWidget, ItemsWidget, CoordsLineEdit, EventsWidget,
    QuestSelectionDialog, HoursWidget, ParamEditorWidget
)

class QuestDetailsPanel(QWidget):
    # Signál při změně jakéhokoli pole (pro dirty tracking)
    data_changed = pyqtSignal()
    save_requested = pyqtSignal()
    delete_requested = pyqtSignal()

    def __init__(self, db_handler, parent=None):
        super().__init__(parent)
        self.db = db_handler
        self.quest_groups = []
        self._dirty_widgets = []
        
        self.init_ui()
        self.connect_dirty_signals()

    def init_ui(self):
        layout = QVBoxLayout(self)

        # Nadpis
        self.title_label = QLabel("Vyberte quest z nabídky")
        self.title_label.setStyleSheet("font-size: 22pt; font-weight: bold; color: #3498db; margin-bottom: 10px;")
        layout.addWidget(self.title_label)

        # Taby
        self.tabs = QTabWidget()
        layout.addWidget(self.tabs)
        self.init_tabs()

        # Tlačítka dole
        btns = QHBoxLayout()
        self.save_btn = QPushButton("Uložit Quest")
        self.save_btn.clicked.connect(self.save_requested.emit)
        
        self.delete_btn = QPushButton("Smazat Quest")
        self.delete_btn.clicked.connect(self.delete_requested.emit)
        
        btns.addWidget(self.save_btn)
        btns.addWidget(self.delete_btn)
        layout.addLayout(btns)

        # Default state
        self.set_enabled(False)

    def init_tabs(self):
        # --- TAB: OBECNÉ ---
        tab_gen = QWidget(); form_gen = QFormLayout(tab_gen)
        self.id = QLineEdit(); self.id.setReadOnly(True)
        self.group_combo = QComboBox()
        self.name = QLineEdit(); self.description = QTextEdit()
        self.hours = HoursWidget(); self.active = QCheckBox()
        self.repeatable = QCheckBox()
        self.jobs = QTextEdit(); self.jobs.setToolTip("JSON: [{\"job\": \"police\", \"grade\": 0}]")
        self.bljobs = QTextEdit(); self.bljobs.setToolTip("JSON seznam jobů")
        
        # Complete quests logic
        self.comp_quests = QLineEdit(); self.comp_quests.setReadOnly(True)
        sel_q_btn = QPushButton("Vybrat..."); sel_q_btn.clicked.connect(self.open_quest_selection)
        comp_lo = QHBoxLayout(); comp_lo.addWidget(self.comp_quests); comp_lo.addWidget(sel_q_btn)

        form_gen.addRow("ID:", self.id); form_gen.addRow("Skupina:", self.group_combo)
        form_gen.addRow("Název:", self.name); form_gen.addRow("Popis:", self.description)
        form_gen.addRow("Hodiny:", self.hours); form_gen.addRow("Aktivní:", self.active)
        form_gen.addRow("Opakovatelný:", self.repeatable)
        form_gen.addRow("Povolené práce:", self.jobs); form_gen.addRow("Zakázané práce:", self.bljobs)
        form_gen.addRow("Vyžaduje questy:", comp_lo)
        self.tabs.addTab(tab_gen, "Obecné")

        # --- TAB: START ---
        tab_start = QWidget(); form_start = QFormLayout(tab_start)
        self.start_act = QComboBox(); self.start_act.addItems(["", "talktoNPC", "distance", "useItem", "clientEvent", "prop"])
        self.start_blip = QCheckBox(); self.start_blip.setToolTip("Zobrazit blip na začátku?")
        
        # ZMĚNA: Předáváme self.db pro Item Picker
        self.start_param = ParamEditorWidget(db_handler=self.db)
        
        # Propojení změny typu aktivace
        self.start_act.currentTextChanged.connect(lambda t: self.start_param.set_activation_type(t))

        self.start_npc = QLineEdit(); self.start_coords = CoordsLineEdit()
        self.start_text = QTextEdit(); self.start_sound = QLineEdit()
        self.start_anim_d = QLineEdit(); self.start_anim_n = QLineEdit()
        self.start_prompt = PromptWidget(); self.start_items = ItemsWidget(self.db, config.IMAGE_BASE_URL)
        self.start_events = EventsWidget()

        form_start.addRow("Aktivace:", self.start_act); form_start.addRow("Parametr:", self.start_param)
        form_start.addRow("Start Blip:", self.start_blip)
        form_start.addRow("Model:", self.start_npc); form_start.addRow("Souřadnice:", self.start_coords)
        form_start.addRow("Text:", self.start_text); form_start.addRow("Zvuk:", self.start_sound)
        form_start.addRow("Anim Dic:", self.start_anim_d); form_start.addRow("Anim Name:", self.start_anim_n)
        form_start.addRow("Prompt:", self.start_prompt); form_start.addRow("Předměty:", self.start_items)
        form_start.addRow("Eventy:", self.start_events)
        self.tabs.addTab(tab_start, "Start")

        # --- TAB: CÍL ---
        tab_target = QWidget(); form_target = QFormLayout(tab_target)
        self.target_act = QComboBox(); self.target_act.addItems(["", "talktoNPC", "distance", "useItem", "clientEvent", "prop", "delivery", "kill"])
        
        # ZMĚNA: Předáváme self.db pro Item Picker
        self.target_param = ParamEditorWidget(db_handler=self.db)
        
        # Propojení změny typu aktivace
        self.target_act.currentTextChanged.connect(lambda t: self.target_param.set_activation_type(t))

        self.target_npc = QLineEdit(); self.target_blip = QLineEdit()
        self.target_coords = CoordsLineEdit(); self.target_text = QTextEdit(); self.target_sound = QLineEdit()
        self.target_anim_d = QLineEdit(); self.target_anim_n = QLineEdit()
        self.target_prompt = PromptWidget(); self.target_items = ItemsWidget(self.db, config.IMAGE_BASE_URL)
        self.target_money = QSpinBox(); self.target_money.setRange(0, 1000000)
        self.target_events = EventsWidget()

        form_target.addRow("Aktivace:", self.target_act); form_target.addRow("Parametr:", self.target_param)
        form_target.addRow("Model:", self.target_npc); form_target.addRow("Blip:", self.target_blip)
        form_target.addRow("Souřadnice:", self.target_coords); form_target.addRow("Text:", self.target_text)
        form_target.addRow("Zvuk:", self.target_sound)
        form_target.addRow("Anim Dic:", self.target_anim_d); form_target.addRow("Anim Name:", self.target_anim_n)
        form_target.addRow("Prompt:", self.target_prompt); form_target.addRow("Předměty:", self.target_items)
        form_target.addRow("Peníze:", self.target_money); form_target.addRow("Eventy:", self.target_events)
        self.tabs.addTab(tab_target, "Cíl")

    def connect_dirty_signals(self):
        # Najdeme všechny widgety a napojíme je na data_changed signal
        self._dirty_widgets.extend(self.tabs.findChildren(QLineEdit))
        self._dirty_widgets.extend(self.tabs.findChildren(QTextEdit))
        self._dirty_widgets.extend(self.tabs.findChildren(QCheckBox))
        self._dirty_widgets.extend(self.tabs.findChildren(QComboBox))
        self._dirty_widgets.extend(self.tabs.findChildren(QSpinBox))
        
        # Přidání custom Param widgetů
        self._dirty_widgets.append(self.start_param)
        self._dirty_widgets.append(self.target_param)

        for w in self._dirty_widgets:
            if isinstance(w, QLineEdit): w.textChanged.connect(self.data_changed.emit)
            elif isinstance(w, QTextEdit): w.textChanged.connect(self.data_changed.emit)
            elif isinstance(w, QCheckBox): w.stateChanged.connect(self.data_changed.emit)
            elif isinstance(w, QComboBox): w.currentIndexChanged.connect(self.data_changed.emit)
            elif isinstance(w, QSpinBox): w.valueChanged.connect(self.data_changed.emit)
            elif isinstance(w, ParamEditorWidget): w.dataChanged.connect(self.data_changed.emit)

    def set_enabled(self, enabled):
        self.tabs.setEnabled(enabled)
        self.save_btn.setEnabled(enabled)
        self.delete_btn.setEnabled(enabled)

    def block_signals_recursive(self, blocked):
        for w in self._dirty_widgets:
            w.blockSignals(blocked)

    def load_groups(self, groups):
        self.quest_groups = groups
        curr = self.group_combo.currentData()
        self.group_combo.clear()
        for g in groups: self.group_combo.addItem(g['name'], g['id'])
        if self.group_combo.count() == 0: self.group_combo.addItem("Default (1)", 1)
        
        idx = self.group_combo.findData(curr)
        if idx >= 0: self.group_combo.setCurrentIndex(idx)
        else: self.group_combo.setCurrentIndex(0)

    def set_data(self, data):
        self.block_signals_recursive(True)
        try:
            self.id.setText(str(data.get('id', '')))
            idx = self.group_combo.findData(data.get('groupid', 1))
            self.group_combo.setCurrentIndex(idx if idx >= 0 else 0)
            
            self.name.setText(data.get('name', ''))
            self.description.setText(data.get('description', ''))
            self.hours.setData(data.get('hoursOpen'))
            self.active.setChecked(bool(data.get('active', 0)))
            self.start_blip.setChecked(bool(data.get('start_blip', 0)))
            self.repeatable.setChecked(bool(data.get('repeatable', 0)))

            # JSONs
            self._set_json(self.jobs, data.get('jobs'))
            self._set_json(self.bljobs, data.get('bljobs'))
            self._set_comp_quests(data.get('complete_quests'))

            # Start
            act_start = data.get('start_activation', '')
            self.start_act.setCurrentText(act_start)
            
            # Nejdříve typ, pak data
            self.start_param.set_activation_type(act_start)
            self.start_param.set_data(data.get('start_param', ''))
            
            self.start_npc.setText(data.get('start_npc', ''))
            self.start_coords.setText(data.get('start_coords', ''))
            self.start_text.setText(data.get('start_text', ''))
            self.start_sound.setText(data.get('start_sound', ''))
            self.start_anim_d.setText(data.get('start_anim_dict', ''))
            self.start_anim_n.setText(data.get('start_anim_name', ''))
            self.start_prompt.setData(self._json_decode(data.get('start_prompt')))
            self.start_items.setData(self._json_decode(data.get('start_items')))
            self.start_events.setData(self._json_decode(data.get('start_events')))

            # Target
            act_target = data.get('target_activation', '')
            self.target_act.setCurrentText(act_target)
            
            # Nejdříve typ, pak data
            self.target_param.set_activation_type(act_target)
            self.target_param.set_data(data.get('target_param', ''))
            
            self.target_npc.setText(data.get('target_npc', ''))
            self.target_blip.setText(data.get('target_blip', ''))
            self.target_coords.setText(data.get('target_coords', ''))
            self.target_text.setText(data.get('target_text', ''))
            self.target_sound.setText(data.get('target_sound', ''))
            self.target_anim_d.setText(data.get('target_anim_dict', ''))
            self.target_anim_n.setText(data.get('target_anim_name', ''))
            self.target_money.setValue(data.get('target_money', 0))
            self.target_prompt.setData(self._json_decode(data.get('target_prompt')))
            self.target_items.setData(self._json_decode(data.get('target_items')))
            self.target_events.setData(self._json_decode(data.get('target_events')))

        finally:
            self.block_signals_recursive(False)

    def get_data(self):
        """Vrátí slovník dat připravený pro DB."""
        # Validace JSON polí
        try:
            j_jobs = json.dumps(json.loads(self.jobs.toPlainText().strip()), ensure_ascii=False) if self.jobs.toPlainText().strip() else None
            j_bljobs = json.dumps(json.loads(self.bljobs.toPlainText().strip()), ensure_ascii=False) if self.bljobs.toPlainText().strip() else None
        except Exception as e:
            QMessageBox.warning(self, "Chyba JSON", f"Neplatný formát JSON u prací:\n{e}")
            return None

        # Complete quests parse
        cq_str = self.comp_quests.text().strip()
        cq_data = json.dumps([int(x.strip()) for x in cq_str.split(',') if x.strip()]) if cq_str else None

        data = {
            'groupid': self.group_combo.currentData(),
            'name': self.name.text() or None,
            'description': self.description.toPlainText() or None,
            'hoursOpen': json.dumps(self.hours.getData()),
            'active': 1 if self.active.isChecked() else 0,
            'repeatable': 1 if self.repeatable.isChecked() else 0,
            'jobs': j_jobs,
            'bljobs': j_bljobs,
            'complete_quests': cq_data,

            # START
            'start_activation': self.start_act.currentText() or None,
            'start_blip': 1 if self.start_blip.isChecked() else 0,
            
            # Získání dat z ParamWidgetu
            'start_param': self.start_param.get_data() or None,
            
            'start_npc': self.start_npc.text() or None,
            'start_coords': self.start_coords.text().replace(" ", "") or None,
            'start_text': self.start_text.toPlainText() or None,
            'start_sound': self.start_sound.text() or None,
            'start_anim_dict': self.start_anim_d.text() or None,
            'start_anim_name': self.start_anim_n.text() or None,
            'start_prompt': self._json_encode(self.start_prompt.getData()),
            'start_items': self._json_encode(self.start_items.getData()),
            'start_events': self._json_encode(self.start_events.getData()),

            # TARGET
            'target_activation': self.target_act.currentText() or None,
            
            # Získání dat z ParamWidgetu
            'target_param': self.target_param.get_data() or None,
            
            'target_npc': self.target_npc.text() or None,
            'target_blip': self.target_blip.text() or None,
            'target_coords': self.target_coords.text().replace(" ", "") or None,
            'target_text': self.target_text.toPlainText() or None,
            'target_sound': self.target_sound.text() or None,
            'target_anim_dict': self.target_anim_d.text() or None,
            'target_anim_name': self.target_anim_n.text() or None,
            'target_money': self.target_money.value(),
            'target_prompt': self._json_encode(self.target_prompt.getData()),
            'target_items': self._json_encode(self.target_items.getData()),
            'target_events': self._json_encode(self.target_events.getData()),
        }
        return data

    def clear(self):
        self.block_signals_recursive(True)
        # Vymazání všech polí
        for w in self.findChildren((QLineEdit, QTextEdit)): w.clear()
        for w in self.findChildren((PromptWidget, ItemsWidget, EventsWidget)): w.clear()
        self.hours.setData(None)
        self.active.setChecked(True); self.repeatable.setChecked(False)
        self.start_blip.setChecked(False)
        self.target_money.setValue(0)
        self.start_act.setCurrentIndex(0); self.target_act.setCurrentIndex(0)
        
        # Reset Param Widgetů
        self.start_param.set_activation_type("")
        self.start_param.set_data("")
        self.target_param.set_activation_type("")
        self.target_param.set_data("")
        
        self.title_label.setText("Vyberte quest z nabídky")
        self.block_signals_recursive(False)

    # --- Helpers ---
    def open_quest_selection(self):
        current = [int(x.strip()) for x in self.comp_quests.text().split(',') if x.strip()]
        d = QuestSelectionDialog(self.db, current, self)
        if d.exec():
            self.comp_quests.setText(", ".join(map(str, d.get_selected_ids())))
            self.data_changed.emit()

    def _set_json(self, widget, data):
        if not data: widget.setText(""); return
        try: widget.setText(json.dumps(json.loads(data), indent=4, ensure_ascii=False))
        except: widget.setText(data)

    def _set_comp_quests(self, data):
        if not data: self.comp_quests.setText(""); return
        try: self.comp_quests.setText(", ".join(map(str, json.loads(data))))
        except: self.comp_quests.setText("")

    def _json_decode(self, val):
        if not val: return None
        try: return json.loads(val)
        except: return None
    
    def _json_encode(self, val):
        if not val: return None
        return json.dumps(val, ensure_ascii=False)