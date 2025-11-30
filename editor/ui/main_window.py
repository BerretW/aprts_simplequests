# editor/ui/main_window.py

import json
from PyQt6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QListWidget, QFormLayout, QLineEdit, QTextEdit, QCheckBox,
    QPushButton, QTabWidget, QSplitter, QMessageBox,
    QSpinBox, QLabel, QListWidgetItem, QComboBox, 
    QTreeWidgetItem, QTreeWidget, QInputDialog # <-- Přidán QInputDialog
)
from PyQt6.QtCore import Qt

import config
from .custom_widgets import (
    PromptWidget, ItemsWidget, CoordsLineEdit, EventsWidget,
    QuestSelectionDialog, HoursWidget, SafeTreeWidget
)

class QuestEditor(QMainWindow):
    def __init__(self, db_handler):
        super().__init__()
        self.db = db_handler
        self.current_quest_id = None
        self.setWindowTitle("APRTS SimpleQuest Editor V1.6 - Group Management") 
        self.setGeometry(100, 100, 1200, 800)

        self._is_dirty = False
        self._dirty_widgets = []
        self.quest_tree_window = None

        self.quest_groups = [] 

        self.init_ui()
        self.load_quests()

    def init_ui(self):
        self.quest_groups = self.db.get_quest_groups()

        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        main_layout = QHBoxLayout(main_widget)
        splitter = QSplitter(Qt.Orientation.Horizontal)
        main_layout.addWidget(splitter)

        # --- LEVÝ PANEL ---
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)

        tree_button = QPushButton("Zobrazit graf posloupnosti")
        tree_button.clicked.connect(self.show_quest_tree)
        left_layout.addWidget(tree_button)

        left_layout.addWidget(QLabel("Seznam Questů"))

        self.quest_tree = SafeTreeWidget(main_window=self)
        self.quest_tree.currentItemChanged.connect(self.display_quest_details)
        left_layout.addWidget(self.quest_tree)

        # Tlačítka pro Questy
        quest_btns_layout = QHBoxLayout()
        new_quest_btn = QPushButton("Nový Quest")
        new_quest_btn.clicked.connect(self.new_quest)
        self.copy_quest_btn = QPushButton("Kopírovat")
        self.copy_quest_btn.clicked.connect(self.copy_quest)
        self.copy_quest_btn.setEnabled(False)
        quest_btns_layout.addWidget(new_quest_btn)
        quest_btns_layout.addWidget(self.copy_quest_btn)
        left_layout.addLayout(quest_btns_layout)

        # Tlačítka pro Skupiny (Oddělená sekce)
        left_layout.addWidget(QLabel("Správa skupin:"))
        group_btns_layout = QHBoxLayout()
        
        self.new_group_btn = QPushButton("Nová")
        self.new_group_btn.clicked.connect(self.create_group)
        self.new_group_btn.setToolTip("Vytvořit novou skupinu")
        
        self.rename_group_btn = QPushButton("Přejmenovat")
        self.rename_group_btn.clicked.connect(self.rename_group)
        self.rename_group_btn.setEnabled(False) # Defaultně vypnuto
        
        self.del_group_btn = QPushButton("Smazat")
        self.del_group_btn.clicked.connect(self.delete_group)
        self.del_group_btn.setStyleSheet("background-color: #c0392b;") # Červená pro smazat
        self.del_group_btn.setEnabled(False) # Defaultně vypnuto

        group_btns_layout.addWidget(self.new_group_btn)
        group_btns_layout.addWidget(self.rename_group_btn)
        group_btns_layout.addWidget(self.del_group_btn)
        left_layout.addLayout(group_btns_layout)

        splitter.addWidget(left_panel)

        # --- PRAVÝ PANEL ---
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)

        self.current_quest_title_label = QLabel("Vyberte quest z nabídky")
        self.current_quest_title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.current_quest_title_label.setStyleSheet(
            "font-size: 22pt; font-weight: bold; color: #3498db; margin-bottom: 10px;")
        right_layout.addWidget(self.current_quest_title_label)

        self.tabs = QTabWidget()
        right_layout.addWidget(self.tabs)

        self.init_form_tabs()

        button_layout = QHBoxLayout()
        self.save_btn = QPushButton("Uložit Quest")
        self.save_btn.clicked.connect(self.save_quest)
        self.delete_btn = QPushButton("Smazat Quest")
        self.delete_btn.clicked.connect(self.delete_quest_action) # Přejmenováno metodu pro quest
        button_layout.addWidget(self.save_btn)
        button_layout.addWidget(self.delete_btn)
        right_layout.addLayout(button_layout)

        splitter.addWidget(right_panel)
        splitter.setSizes([350, 850])
        self.set_form_enabled(False)

    # ... (init_form_tabs zůstává stejný) ...
    def init_form_tabs(self):
        # --- TAB: OBECNÉ ---
        tab_general = QWidget()
        form_general = QFormLayout(tab_general)
        self.id = QLineEdit(); self.id.setReadOnly(True)
        self.group_combo = QComboBox()
        for grp in self.quest_groups: self.group_combo.addItem(grp['name'], grp['id'])
        if self.group_combo.count() == 0: self.group_combo.addItem("Default Group (ID 1)", 1)
        self.name = QLineEdit(); self.description = QTextEdit(); self.hours_widget = HoursWidget()
        self.active = QCheckBox(); self.repeatable = QCheckBox()
        self.jobs = QTextEdit(); self.jobs.setToolTip("Zadejte jako JSON pole objektů.")
        self.blacklistJobs = QTextEdit(); self.blacklistJobs.setToolTip("Zadejte jako JSON pole jobů.")
        self.complete_quests_display = QLineEdit(); self.complete_quests_display.setReadOnly(True)
        select_quests_btn = QPushButton("Vybrat..."); select_quests_btn.clicked.connect(self.open_quest_selection_dialog)
        completed_quests_layout = QHBoxLayout(); completed_quests_layout.addWidget(self.complete_quests_display); completed_quests_layout.addWidget(select_quests_btn)
        form_general.addRow("ID:", self.id); form_general.addRow("Skupina:", self.group_combo)
        form_general.addRow("Název:", self.name); form_general.addRow("Popis:", self.description)
        form_general.addRow("Otevírací hodiny:", self.hours_widget); form_general.addRow("Aktivní:", self.active)
        form_general.addRow("Opakovatelný:", self.repeatable); form_general.addRow("Požadované práce (JSON):", self.jobs)
        form_general.addRow("Zakázané práce (JSON):", self.blacklistJobs); form_general.addRow("Vyžaduje splněné questy:", completed_quests_layout)
        self.tabs.addTab(tab_general, "Obecné")

        # --- TAB: START ---
        start_activation_types = ["", "talktoNPC", "distance", "useItem", "clientEvent", "prop"]
        target_activation_types = ["", "talktoNPC", "distance", "useItem", "clientEvent", "prop","delivery","kill"]
        tab_start = QWidget(); form_start = QFormLayout(tab_start)
        self.start_activation = QComboBox(); self.start_activation.addItems(start_activation_types)
        self.start_param = QLineEdit(); self.start_npc = QLineEdit(); self.start_coords = CoordsLineEdit()
        self.start_text = QTextEdit(); self.start_sound = QLineEdit()
        self.start_anim_dict = QLineEdit(); self.start_anim_name = QLineEdit()
        self.start_prompt = PromptWidget(); self.start_items = ItemsWidget(self.db, config.IMAGE_BASE_URL)
        self.start_events = EventsWidget()
        form_start.addRow("Aktivace:", self.start_activation); form_start.addRow("Parametr:", self.start_param)
        form_start.addRow("Model:", self.start_npc); form_start.addRow("Souřadnice:", self.start_coords)
        form_start.addRow("Text:", self.start_text); form_start.addRow("Zvuk:", self.start_sound)
        form_start.addRow("Animace (slovník):", self.start_anim_dict); form_start.addRow("Animace (název):", self.start_anim_name)
        form_start.addRow("Prompt:", self.start_prompt); form_start.addRow("Předměty:", self.start_items)
        form_start.addRow("Eventy:", self.start_events)
        self.tabs.addTab(tab_start, "Start")

        # --- TAB: CÍL ---
        tab_target = QWidget(); form_target = QFormLayout(tab_target)
        self.target_activation = QComboBox(); self.target_activation.addItems(target_activation_types)
        # pokud je target activation delivery, přejmenuje "Předměty" na "Dodávka předmětů"

        self.target_param = QLineEdit(); self.target_npc = QLineEdit(); self.target_blip = QLineEdit()
        self.target_coords = CoordsLineEdit(); self.target_text = QTextEdit(); self.target_sound = QLineEdit()
        self.target_anim_dict = QLineEdit(); self.target_anim_name = QLineEdit()
        self.target_prompt = PromptWidget(); self.target_items = ItemsWidget(self.db, config.IMAGE_BASE_URL)
        self.target_money = QSpinBox(); self.target_money.setRange(0, 1000000); self.target_events = EventsWidget()
        form_target.addRow("Aktivace:", self.target_activation); form_target.addRow("Parametr:", self.target_param)
        form_target.addRow("Model:", self.target_npc); form_target.addRow("Blip:", self.target_blip)
        form_target.addRow("Souřadnice:", self.target_coords); form_target.addRow("Text:", self.target_text)
        form_target.addRow("Zvuk:", self.target_sound); form_target.addRow("Animace (slovník):", self.target_anim_dict)
        form_target.addRow("Animace (název):", self.target_anim_name); form_target.addRow("Prompt:", self.target_prompt)
        form_target.addRow("Předměty:", self.target_items)
        form_target.addRow("Peníze:", self.target_money)
        form_target.addRow("Eventy:", self.target_events)
        self.tabs.addTab(tab_target, "Cíl")

        # --- DIRTY TRACKING ---
        self._dirty_widgets = []
        self._dirty_widgets.extend(self.tabs.findChildren(QLineEdit))
        self._dirty_widgets.extend(self.tabs.findChildren(QTextEdit))
        self._dirty_widgets.extend(self.tabs.findChildren(QCheckBox))
        self._dirty_widgets.extend(self.tabs.findChildren(QComboBox))
        self._dirty_widgets.extend(self.tabs.findChildren(QSpinBox))

        for w in self._dirty_widgets:
            if isinstance(w, QLineEdit): w.textChanged.connect(self._mark_as_dirty)
            elif isinstance(w, QTextEdit): w.textChanged.connect(self._mark_as_dirty)
            elif isinstance(w, QCheckBox): w.stateChanged.connect(self._mark_as_dirty)
            elif isinstance(w, QComboBox): w.currentIndexChanged.connect(self._mark_as_dirty)
            elif isinstance(w, QSpinBox): w.valueChanged.connect(self._mark_as_dirty)

    # ... (_set_dirty_tracking_enabled, _mark_as_dirty, _mark_as_clean, _check_unsaved_changes zůstávají stejné) ...
    def _set_dirty_tracking_enabled(self, enabled: bool):
        widgets = getattr(self, "_dirty_widgets", [])
        for w in widgets: w.blockSignals(not enabled)

    def _mark_as_dirty(self, *args, **kwargs):
        if getattr(self, "_is_dirty", False): return
        self._is_dirty = True
        current_item = self.quest_tree.currentItem()
        if current_item and current_item.data(0, Qt.ItemDataRole.UserRole) is not None and not current_item.text(0).endswith("*"):
            current_item.setText(0, current_item.text(0) + " *")
            current_item.setForeground(0, Qt.GlobalColor.red)
        title = self.current_quest_title_label.text()
        if not title.endswith("*"): self.current_quest_title_label.setText(title + " *")
        self.current_quest_title_label.setStyleSheet("font-size: 22pt; font-weight: bold; color: #e74c3c; margin-bottom: 10px;")

    def _mark_as_clean(self):
        self._is_dirty = False
        current_item = self.quest_tree.currentItem()
        if current_item and current_item.data(0, Qt.ItemDataRole.UserRole) is not None:
            text = current_item.text(0).rstrip(" *")
            current_item.setText(0, text)
            current_item.setForeground(0, Qt.GlobalColor.white)
        title = self.current_quest_title_label.text().rstrip(" *")
        self.current_quest_title_label.setText(title)
        self.current_quest_title_label.setStyleSheet("font-size: 22pt; font-weight: bold; color: #3498db; margin-bottom: 10px;")

    def _check_unsaved_changes(self):
        if not self._is_dirty: return True
        reply = QMessageBox.question(self, "Neuložené změny", "Máte neuložené změny. Chcete je uložit?",
                                     QMessageBox.StandardButton.Save | QMessageBox.StandardButton.Discard | QMessageBox.StandardButton.Cancel)
        if reply == QMessageBox.StandardButton.Save: return self.save_quest(confirmed=True)
        elif reply == QMessageBox.StandardButton.Cancel: return False
        else: return True

    def show_quest_tree(self):
        if self.quest_tree_window is None:
            from .quest_tree_widget import QuestTreeWidget
            self.quest_tree_window = QuestTreeWidget(self.db)
        self.quest_tree_window.generate_tree()
        self.quest_tree_window.show()
        self.quest_tree_window.activateWindow()

    # --- LOGIKA SKUPIN ---

    def create_group(self):
        """Vytvoří novou skupinu. Dostupné kdykoliv."""
        text, ok = QInputDialog.getText(self, "Nová skupina", "Zadejte název nové skupiny:")
        if ok and text:
            success, result = self.db.add_group(text.strip())
            if success:
                self.load_quests() # Přenačíst strom
                # Aktualizovat ComboBox ve formuláři
                self.quest_groups = self.db.get_quest_groups()
                self._reload_group_combo()
            else:
                QMessageBox.critical(self, "Chyba", f"Nepodařilo se vytvořit skupinu: {result}")

    def rename_group(self):
        """Přejmenuje vybranou skupinu."""
        current_item = self.quest_tree.currentItem()
        if not current_item or current_item.parent() is not None:
            return # Není vybrána skupina
            
        # Získání ID skupiny z prvního potomka nebo mapy? 
        # Ve funkci load_quests musíme uložit ID skupiny do TopLevelItem
        # Momentálně v load_quests: grp_item.setData(0, Qt.ItemDataRole.UserRole, None) -> To je špatně pro identifikaci.
        # Opravíme load_quests, aby ukládal ID skupiny jinam nebo použijeme UserRole s příznakem.
        
        # V load_quests níže jsem to upravil:
        # UserRole = Quest ID (pro questy)
        # UserRole + 100000 nebo jiná role = Group ID (pro skupiny)
        # Jednodušší: UserRole = ID. Pokud item má childy nebo je TopLevel, je to skupina? Ne, quest může být bez childů.
        # Řešení: Použijeme UserRole pro QuestID a UserRole+1 pro GroupID.
        
        group_id = current_item.data(0, Qt.ItemDataRole.UserRole + 1)
        old_name = current_item.text(0).split(' (')[0] # Odstranění počtu
        
        text, ok = QInputDialog.getText(self, "Přejmenovat skupinu", "Nový název:", text=old_name)
        if ok and text:
            success, msg = self.db.rename_group(group_id, text.strip())
            if success:
                self.load_quests()
                self.quest_groups = self.db.get_quest_groups()
                self._reload_group_combo()
            else:
                QMessageBox.critical(self, "Chyba", f"Nepodařilo se přejmenovat skupinu: {msg}")

    def delete_group(self):
        """Smaže vybranou skupinu."""
        current_item = self.quest_tree.currentItem()
        if not current_item or current_item.parent() is not None: return

        group_id = current_item.data(0, Qt.ItemDataRole.UserRole + 1)
        group_name = current_item.text(0)
        
        if group_id == 1:
            QMessageBox.warning(self, "Nelze smazat", "Výchozí skupinu nelze smazat.")
            return

        res = QMessageBox.question(self, "Smazat skupinu", 
                                   f"Opravdu smazat skupinu '{group_name}'?\nQuesty v ní budou přesunuty do výchozí skupiny.",
                                   QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
        if res == QMessageBox.StandardButton.Yes:
            success, msg = self.db.delete_group(group_id)
            if success:
                self.load_quests()
                self.quest_groups = self.db.get_quest_groups()
                self._reload_group_combo()
            else:
                QMessageBox.critical(self, "Chyba", f"Nepodařilo se smazat skupinu: {msg}")

    def _reload_group_combo(self):
        """Pomocná metoda pro obnovení obsahu ComboBoxu ve formuláři."""
        current_data = self.group_combo.currentData()
        self.group_combo.clear()
        for grp in self.quest_groups:
            self.group_combo.addItem(grp['name'], grp['id'])
        
        # Obnovení výběru
        idx = self.group_combo.findData(current_data)
        if idx >= 0: self.group_combo.setCurrentIndex(idx)
        elif self.group_combo.count() > 0: self.group_combo.setCurrentIndex(0)


    def load_quests(self):
        current_id = self.current_quest_id
        
        # Uložení stavu expanze skupin
        expanded_groups = set()
        for i in range(self.quest_tree.topLevelItemCount()):
            item = self.quest_tree.topLevelItem(i)
            if item.isExpanded():
                # Identifikujeme skupinu podle názvu (protože ID ještě nemáme uložené konzistentně v minulé verzi)
                # V nové verzi použijeme ID
                group_id = item.data(0, Qt.ItemDataRole.UserRole + 1)
                if group_id: expanded_groups.add(group_id)

        self.quest_tree.clear()
        self.quest_groups = self.db.get_quest_groups()
        group_items = {}
        
        # 1. Vytvoření skupin
        for grp in self.quest_groups:
            # Ukládám čistý název, počet přidám až na konci
            grp_item = QTreeWidgetItem([grp['name']])
            grp_item.setData(0, Qt.ItemDataRole.UserRole, None) # Quest ID je None
            grp_item.setData(0, Qt.ItemDataRole.UserRole + 1, grp['id']) # Group ID
            
            font = grp_item.font(0); font.setBold(True); grp_item.setFont(0, font)
            
            # Obnovení expanze
            if grp['id'] in expanded_groups: grp_item.setExpanded(True)
            else: grp_item.setExpanded(True) # Defaultně rozbaleno
            
            self.quest_tree.addTopLevelItem(grp_item)
            group_items[grp['id']] = grp_item
            
        unknown_group_item = None 
        item_to_select = None
        
        # 2. Načtení questů
        quests = self.db.get_all_quests()
        for quest in quests:
            grp_id = quest.get('groupid')
            parent_item = group_items.get(grp_id)
            
            if not parent_item:
                if not unknown_group_item:
                    unknown_group_item = QTreeWidgetItem(["Nezařazeno"])
                    unknown_group_item.setData(0, Qt.ItemDataRole.UserRole, None)
                    unknown_group_item.setData(0, Qt.ItemDataRole.UserRole + 1, 0) # Fake ID
                    unknown_group_item.setExpanded(True)
                    self.quest_tree.addTopLevelItem(unknown_group_item)
                parent_item = unknown_group_item
            
            quest_item = QTreeWidgetItem([f"{quest['id']}: {quest['name']}"])
            quest_item.setData(0, Qt.ItemDataRole.UserRole, quest['id'])
            parent_item.addChild(quest_item)
            
            if quest['id'] == current_id:
                item_to_select = quest_item
        
        # 3. Aktualizace názvů skupin s počty
        for grp_item in group_items.values():
            count = grp_item.childCount()
            grp_item.setText(0, f"{grp_item.text(0)} ({count})")
            
        if unknown_group_item:
            unknown_group_item.setText(0, f"{unknown_group_item.text(0)} ({unknown_group_item.childCount()})")

        if item_to_select: self.quest_tree.setCurrentItem(item_to_select)
        else: self.quest_tree.clearSelection()

    def display_quest_details(self, current_item, previous_item):
        self._mark_as_clean()
        
        # Reset tlačítek skupin
        self.rename_group_btn.setEnabled(False)
        self.del_group_btn.setEnabled(False)
        # Nová skupina je vždy povolena, ale tlačítko je statické
        self.new_group_btn.setEnabled(True) 

        # Detekce, co je vybráno
        if not current_item:
            self.copy_quest_btn.setEnabled(False)
            self.clear_form()
            self.set_form_enabled(False)
            return

        quest_id = current_item.data(0, Qt.ItemDataRole.UserRole)
        group_id = current_item.data(0, Qt.ItemDataRole.UserRole + 1)

        if quest_id is None:
            # --- VYBRÁNA SKUPINA ---
            # Povolíme tlačítka pro úpravu skupiny
            # (Pouze pokud to není "Nezařazeno" s fake ID 0, ale to v DB groups nebude)
            if group_id and group_id > 0:
                self.rename_group_btn.setEnabled(True)
                self.del_group_btn.setEnabled(True)
            
            # Formulář questu vyčistíme a zakážeme
            self.copy_quest_btn.setEnabled(False)
            self.clear_form()
            self.set_form_enabled(False)
            self.current_quest_title_label.setText(f"Skupina: {current_item.text(0)}")
            return
            
        # --- VYBRÁN QUEST ---
        self.copy_quest_btn.setEnabled(True)
        self.current_quest_id = quest_id
        
        details = self.db.get_quest_details(self.current_quest_id)
        if details:
            self.current_quest_title_label.setText(
                f"Úprava: {details.get('name', '')} (ID: {self.current_quest_id})")
            self.fill_form_with_data(details)
            self.set_form_enabled(True)
            self.delete_btn.setEnabled(True)

    # ... fill_form_with_data, _safe_json_decode, _populate_json_field, clear_form, new_quest, open_quest_selection_dialog, copy_quest, get_data_from_form, save_quest, set_form_enabled beze změn ...

    def fill_form_with_data(self, data):
        self._set_dirty_tracking_enabled(False)
        try:
            self.id.setText(str(data.get('id', '')))
            
            group_id = data.get('groupid', 1)
            index = self.group_combo.findData(group_id)
            if index >= 0: self.group_combo.setCurrentIndex(index)
            else:
                if self.group_combo.count() > 0: self.group_combo.setCurrentIndex(0)

            self.name.setText(data.get('name', ''))
            self.description.setText(data.get('description', ''))
            self.hours_widget.setData(data.get('hoursOpen'))
            self.active.setChecked(bool(data.get('active', 0)))
            self.repeatable.setChecked(bool(data.get('repeatable', 0)))

            completed_quests_json = data.get('complete_quests')
            if completed_quests_json:
                try: self.complete_quests_display.setText(", ".join(map(str, json.loads(completed_quests_json))))
                except: self.complete_quests_display.setText("")
            else: self.complete_quests_display.setText("")

            self.start_activation.setCurrentText(data.get('start_activation', ''))
            self.start_param.setText(data.get('start_param', ''))
            self.start_npc.setText(data.get('start_npc', ''))
            self.start_coords.setText(data.get('start_coords', ''))
            self.start_text.setText(data.get('start_text', ''))
            self.start_sound.setText(data.get('start_sound', ''))
            self.start_anim_dict.setText(data.get('start_anim_dict', ''))
            self.start_anim_name.setText(data.get('start_anim_name', ''))

            self.target_activation.setCurrentText(data.get('target_activation', ''))
            self.target_param.setText(data.get('target_param', ''))
            self.target_npc.setText(data.get('target_npc', ''))
            self.target_blip.setText(data.get('target_blip', ''))
            self.target_coords.setText(data.get('target_coords', ''))
            self.target_text.setText(data.get('target_text', ''))
            self.target_sound.setText(data.get('target_sound', ''))
            self.target_anim_dict.setText(data.get('target_anim_dict', ''))
            self.target_anim_name.setText(data.get('target_anim_name', ''))
            self.target_money.setValue(data.get('target_money', 0))

            self._populate_json_field(self.jobs, data.get('jobs'))
            self._populate_json_field(self.blacklistJobs, data.get('bljobs'))

            self.start_prompt.setData(self._safe_json_decode(data.get('start_prompt')))
            self.target_prompt.setData(self._safe_json_decode(data.get('target_prompt')))
            self.start_items.setData(self._safe_json_decode(data.get('start_items')))
            self.target_items.setData(self._safe_json_decode(data.get('target_items')))
            self.start_events.setData(self._safe_json_decode(data.get('start_events')))
            self.target_events.setData(self._safe_json_decode(data.get('target_events')))
        finally:
            self._set_dirty_tracking_enabled(True)
            self._mark_as_clean()

    def _safe_json_decode(self, json_string):
        if not json_string: return None
        try: return json.loads(json_string)
        except: return None

    def _populate_json_field(self, widget, data):
        if not data: widget.setText(""); return
        try: widget.setText(json.dumps(json.loads(data), indent=4, ensure_ascii=False))
        except: widget.setText(data)

    def clear_form(self):
        self._set_dirty_tracking_enabled(False)
        try:
            self.current_quest_title_label.setText("Vyberte quest z nabídky")
            self.complete_quests_display.clear()
            for widget in self.findChildren(QLineEdit): widget.clear()
            for widget in self.findChildren(QTextEdit): widget.clear()
            for widget in self.findChildren((PromptWidget, ItemsWidget, EventsWidget)): widget.clear()
            if self.group_combo.count() > 0: self.group_combo.setCurrentIndex(0)
            self.hours_widget.setData(None) 
            self.active.setChecked(True); self.repeatable.setChecked(False)
            self.target_money.setValue(0); self.start_activation.setCurrentIndex(0); self.target_activation.setCurrentIndex(0)
            self.current_quest_id = None
        finally:
            self._set_dirty_tracking_enabled(True)
            self._mark_as_clean()

    def new_quest(self):
        if not self._check_unsaved_changes(): return
        self._mark_as_clean()
        self.quest_tree.clearSelection() 
        self.clear_form()
        self.current_quest_title_label.setText("Tvorba nového questu *")
        self.id.setText("<Automaticky>")
        self.current_quest_id = None
        self.set_form_enabled(True)
        self.delete_btn.setEnabled(False)
        self.name.setFocus()

    def open_quest_selection_dialog(self):
        current_ids = [int(q_id.strip()) for q_id in self.complete_quests_display.text().split(',') if q_id.strip()]
        dialog = QuestSelectionDialog(self.db, current_ids, self)
        if dialog.exec():
            self.complete_quests_display.setText(", ".join(map(str, dialog.get_selected_ids())))
            self._mark_as_dirty()

    def copy_quest(self):
        if not self._check_unsaved_changes(): return
        if not self.current_quest_id: QMessageBox.warning(self, "Chyba", "Nejprve vyberte quest."); return
        data = self.get_data_from_form()
        if not data: return
        original_name = data.get('name', 'Quest')
        data['id'] = "<Automaticky>"; data['name'] = f"{original_name} - KOPIE"
        self.quest_tree.clearSelection()
        self._set_dirty_tracking_enabled(False)
        try: self.fill_form_with_data(data)
        finally:
            self._set_dirty_tracking_enabled(True)
            self._mark_as_clean()
        self.current_quest_title_label.setText(f"Tvorba kopie: {original_name}")
        self.current_quest_id = None
        self.set_form_enabled(True)
        self.delete_btn.setEnabled(False)
        self.name.setFocus()
        self.name.selectAll()

    def get_data_from_form(self):
        data = {
            'groupid': self.group_combo.currentData(),
            'hoursOpen': json.dumps(self.hours_widget.getData()),
            'active': 1 if self.active.isChecked() else 0, 
            'name': self.name.text() or None, 
            'description': self.description.toPlainText() or None, 
            'repeatable': 1 if self.repeatable.isChecked() else 0, 
            'start_activation': self.start_activation.currentText() or None, 
            'start_param': self.start_param.text() or None, 
            'start_npc': self.start_npc.text() or None, 
            'start_coords': self.start_coords.text().replace(" ", "") or None,
            'start_text': self.start_text.toPlainText() or None, 
            'start_sound': self.start_sound.text() or None,
            'start_anim_dict': self.start_anim_dict.text() or None,
            'start_anim_name': self.start_anim_name.text() or None,
            'target_activation': self.target_activation.currentText() or None, 
            'target_param': self.target_param.text() or None, 
            'target_npc': self.target_npc.text() or None, 
            'target_blip': self.target_blip.text() or None, 
            'target_coords': self.target_coords.text().replace(" ", "") or None, 
            'target_text': self.target_text.toPlainText() or None, 
            'target_sound': self.target_sound.text() or None,
            'target_anim_dict': self.target_anim_dict.text() or None,
            'target_anim_name': self.target_anim_name.text() or None,
            'target_money': self.target_money.value()
        }
        for key, widget in {'start_prompt': self.start_prompt, 'target_prompt': self.target_prompt, 'start_items': self.start_items, 'target_items': self.target_items, 'start_events': self.start_events, 'target_events': self.target_events}.items():
            data[key] = json.dumps(widget.getData(), ensure_ascii=False) if widget.getData() else None
        try: data['jobs'] = json.dumps(json.loads(self.jobs.toPlainText().strip()), ensure_ascii=False) if self.jobs.toPlainText().strip() else None
        except json.JSONDecodeError as e: QMessageBox.warning(self, "Chyba ve formátu", f"Pole 'jobs' neobsahuje validní JSON.\n{e}"); return None
        try: data['bljobs'] = json.dumps(json.loads(self.blacklistJobs.toPlainText().strip()), ensure_ascii=False) if self.blacklistJobs.toPlainText().strip() else None
        except json.JSONDecodeError as e: QMessageBox.warning(self, "Chyba ve formátu", f"Pole 'blacklistJobs' neobsahuje validní JSON.\n{e}"); return None
        completed_text = self.complete_quests_display.text().strip()
        if completed_text: data['complete_quests'] = json.dumps([int(q_id.strip()) for q_id in completed_text.split(',') if q_id.strip()])
        else: data['complete_quests'] = None
        return data

    def save_quest(self, confirmed=False):
        if not confirmed:
            reply = QMessageBox.question(self, "Potvrzení", f"Opravdu uložit quest '{self.name.text() or '<bez názvu>'}'?", QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
            if reply == QMessageBox.StandardButton.No: return False
        data = self.get_data_from_form()
        if not data: return False
        success, message, saved_id = self.db.save_quest(data, self.current_quest_id)
        if success:
            if not confirmed: QMessageBox.information(self, "Úspěch", message)
            self.current_quest_id = saved_id
            self._mark_as_clean()
            self.load_quests() 
            return True
        else:
            if not confirmed: QMessageBox.critical(self, "Chyba", message)
            return False

    def set_form_enabled(self, enabled):
        self.tabs.setEnabled(enabled)
        self.save_btn.setEnabled(enabled)
        self.delete_btn.setEnabled(enabled)

    def delete_quest_action(self):
        if not self.current_quest_id: return
        if QMessageBox.question(self, "Potvrzení", f"Opravdu smazat quest ID {self.current_quest_id}?") == QMessageBox.StandardButton.Yes:
            if self.db.delete_quest(self.current_quest_id):
                self._mark_as_clean()
                self.load_quests()
                self.clear_form()
                self.set_form_enabled(False)