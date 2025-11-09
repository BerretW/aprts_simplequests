# editor/ui/main_window.py

import json
from PyQt6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QListWidget, QFormLayout, QLineEdit, QTextEdit, QCheckBox,
    QPushButton, QTabWidget, QSplitter, QMessageBox,
    QSpinBox, QLabel, QListWidgetItem
)
from PyQt6.QtCore import Qt

import config
from .custom_widgets import (
    PromptWidget, ItemsWidget, CoordsLineEdit, EventsWidget,
    QuestSelectionDialog, SafeListWidget
)


class QuestEditor(QMainWindow):
    def __init__(self, db_handler):
        super().__init__()
        self.db = db_handler
        self.current_quest_id = None
        self.setWindowTitle("RedM Quest Editor V1.3")
        self.setGeometry(100, 100, 1200, 800)

        self._is_dirty = False
        self._dirty_widgets = []   # sem si později uložíme všechny sledované widgety
        self.quest_tree_window = None

        self.init_ui()
        self.load_quests()
        

    def init_ui(self):
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        main_layout = QHBoxLayout(main_widget)
        splitter = QSplitter(Qt.Orientation.Horizontal)
        main_layout.addWidget(splitter)

        # Levý panel
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)

        tree_button = QPushButton("Zobrazit strom questů")
        tree_button.clicked.connect(self.show_quest_tree)
        left_layout.addWidget(tree_button)

        left_layout.addWidget(QLabel("Seznam Questů"))

        self.quest_list = SafeListWidget(
            main_window=self)  # Použití vlastního widgetu
        self.quest_list.currentItemChanged.connect(self.display_quest_details)
        left_layout.addWidget(self.quest_list)

        left_button_layout = QHBoxLayout()
        new_quest_btn = QPushButton("Nový")
        new_quest_btn.clicked.connect(self.new_quest)
        self.copy_quest_btn = QPushButton("Kopírovat")
        self.copy_quest_btn.clicked.connect(self.copy_quest)
        self.copy_quest_btn.setEnabled(False)
        left_button_layout.addWidget(new_quest_btn)
        left_button_layout.addWidget(self.copy_quest_btn)
        left_layout.addLayout(left_button_layout)
        splitter.addWidget(left_panel)

        # Pravý panel
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)

        self.current_quest_title_label = QLabel("Vyberte quest z nabídky")
        self.current_quest_title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.current_quest_title_label.setStyleSheet(
            "font-size: 22pt; font-weight: bold; color: #3498db; margin-bottom: 10px;")
        right_layout.addWidget(self.current_quest_title_label)

        self.tabs = QTabWidget()

        # >>> NEJDŘÍV TABY DO LAYOUTU <<<
        right_layout.addWidget(self.tabs)

        # >>> TEĎ TEPRVE VYTVÁŘET OBSAH TABŮ A NAPOJOVAT SIGNÁLY <<<
        self.init_form_tabs()

        button_layout = QHBoxLayout()
        self.save_btn = QPushButton("Uložit Quest")
        self.save_btn.clicked.connect(self.save_quest)
        self.delete_btn = QPushButton("Smazat Quest")
        self.delete_btn.clicked.connect(self.delete_quest)
        button_layout.addWidget(self.save_btn)
        button_layout.addWidget(self.delete_btn)
        right_layout.addLayout(button_layout)

        splitter.addWidget(right_panel)
        splitter.setSizes([300, 900])
        self.set_form_enabled(False)

    def init_form_tabs(self):
        from PyQt6.QtWidgets import QComboBox
        tab_general = QWidget()
        form_general = QFormLayout(tab_general)
        self.id = QLineEdit()
        self.id.setReadOnly(True)
        self.name = QLineEdit()
        self.description = QTextEdit()
        self.active = QCheckBox()
        self.repeatable = QCheckBox()
        self.jobs = QTextEdit()
        self.jobs.setToolTip(
            "Zadejte jako JSON pole objektů, např.:\n[{\"job\": \"police\", \"grade\": 1}]")
        self.complete_quests_display = QLineEdit()
        self.complete_quests_display.setReadOnly(True)
        select_quests_btn = QPushButton("Vybrat...")
        select_quests_btn.clicked.connect(self.open_quest_selection_dialog)
        completed_quests_layout = QHBoxLayout()
        completed_quests_layout.addWidget(self.complete_quests_display)
        completed_quests_layout.addWidget(select_quests_btn)
        form_general.addRow("ID:", self.id)
        form_general.addRow("Název:", self.name)
        form_general.addRow("Popis:", self.description)
        form_general.addRow("Aktivní:", self.active)
        form_general.addRow("Opakovatelný:", self.repeatable)
        form_general.addRow("Požadované práce (JSON):", self.jobs)
        form_general.addRow("Vyžaduje splněné questy:",
                            completed_quests_layout)
        self.tabs.addTab(tab_general, "Obecné")
        activation_types = ["", "talktoNPC",
                            "distance", "useItem", "clientEvent"]
        tab_start = QWidget()
        form_start = QFormLayout(tab_start)
        self.start_activation = QComboBox()
        self.start_activation.addItems(activation_types)
        self.start_param = QLineEdit()
        self.start_npc = QLineEdit()
        self.start_coords = CoordsLineEdit()
        self.start_text = QTextEdit()
        self.start_sound = QLineEdit() # <<< NOVÉ
        self.start_anim_dict = QLineEdit() # <<< NOVÉ
        self.start_anim_name = QLineEdit() # <<< NOVÉ
        self.start_prompt = PromptWidget()
        self.start_items = ItemsWidget(self.db, config.IMAGE_BASE_URL)
        self.start_events = EventsWidget()
        form_start.addRow("Aktivace:", self.start_activation)
        form_start.addRow("Parametr:", self.start_param)
        form_start.addRow("NPC model:", self.start_npc)
        form_start.addRow("Souřadnice:", self.start_coords)
        form_start.addRow("Text:", self.start_text)
        form_start.addRow("Zvuk:", self.start_sound) # <<< NOVÉ
        form_start.addRow("Animace (slovník):", self.start_anim_dict) # <<< NOVÉ
        form_start.addRow("Animace (název):", self.start_anim_name) # <<< NOVÉ
        form_start.addRow("Prompt:", self.start_prompt)
        form_start.addRow("Předměty:", self.start_items)
        form_start.addRow("Eventy:", self.start_events)
        self.tabs.addTab(tab_start, "Start")
        tab_target = QWidget()
        form_target = QFormLayout(tab_target)
        self.target_activation = QComboBox()
        self.target_activation.addItems(activation_types)
        self.target_param = QLineEdit()
        self.target_npc = QLineEdit()
        self.target_blip = QLineEdit()
        self.target_coords = CoordsLineEdit()
        self.target_text = QTextEdit()
        self.target_sound = QLineEdit() # <<< NOVÉ
        self.target_anim_dict = QLineEdit() # <<< NOVÉ
        self.target_anim_name = QLineEdit() # <<< NOVÉ
        self.target_prompt = PromptWidget()
        self.target_items = ItemsWidget(self.db, config.IMAGE_BASE_URL)
        self.target_money = QSpinBox()
        self.target_money.setRange(0, 1000000)
        self.target_events = EventsWidget()
        form_target.addRow("Aktivace:", self.target_activation)
        form_target.addRow("Parametr:", self.target_param)
        form_target.addRow("NPC model:", self.target_npc)
        form_target.addRow("Blip:", self.target_blip)
        form_target.addRow("Souřadnice:", self.target_coords)
        form_target.addRow("Text:", self.target_text)
        form_target.addRow("Zvuk:", self.target_sound) # <<< NOVÉ
        form_target.addRow("Animace (slovník):", self.target_anim_dict) # <<< NOVÉ
        form_target.addRow("Animace (název):", self.target_anim_name) # <<< NOVÉ
        form_target.addRow("Prompt:", self.target_prompt)
        form_target.addRow("Předměty:", self.target_items)
        form_target.addRow("Peníze:", self.target_money)
        form_target.addRow("Eventy:", self.target_events)
        self.tabs.addTab(tab_target, "Cíl")

        self._dirty_widgets = []

        # Hledáme jen uvnitř tabů, ne v celém okně
        self._dirty_widgets.extend(self.tabs.findChildren(QLineEdit))
        self._dirty_widgets.extend(self.tabs.findChildren(QTextEdit))
        self._dirty_widgets.extend(self.tabs.findChildren(QCheckBox))
        self._dirty_widgets.extend(self.tabs.findChildren(QComboBox))
        self._dirty_widgets.extend(self.tabs.findChildren(QSpinBox))

        for w in self._dirty_widgets:
            if isinstance(w, QLineEdit):
                w.textChanged.connect(self._mark_as_dirty)
            elif isinstance(w, QTextEdit):
                w.textChanged.connect(self._mark_as_dirty)
            elif isinstance(w, QCheckBox):
                w.stateChanged.connect(self._mark_as_dirty)
            elif isinstance(w, QComboBox):
                w.currentIndexChanged.connect(self._mark_as_dirty)
            elif isinstance(w, QSpinBox):
                w.valueChanged.connect(self._mark_as_dirty)

    def _set_dirty_tracking_enabled(self, enabled: bool):
        """Zapne/vypne sledování změn u všech polí formuláře."""
        widgets = getattr(self, "_dirty_widgets", [])
        for w in widgets:
            w.blockSignals(not enabled)


    def _mark_as_dirty(self, *args, **kwargs):
        if getattr(self, "_is_dirty", False):
            return
        self._is_dirty = True

        # 1️⃣ hvězdička v seznamu
        current_item = self.quest_list.currentItem()
        if current_item and not current_item.text().endswith("*"):
            current_item.setText(current_item.text() + " *")
            # změna barvy textu v seznamu
            current_item.setForeground(Qt.GlobalColor.red)

        # 2️⃣ hvězdička a barva titulku
        title = self.current_quest_title_label.text()
        if not title.endswith("*"):
            self.current_quest_title_label.setText(title + " *")
        self.current_quest_title_label.setStyleSheet(
            "font-size: 22pt; font-weight: bold; color: #e74c3c; margin-bottom: 10px;"
        )

    def _mark_as_clean(self):
        self._is_dirty = False

        # 1️⃣ reset v seznamu
        current_item = self.quest_list.currentItem()
        if current_item:
            text = current_item.text().rstrip(" *")
            current_item.setText(text)
            # zpět na výchozí barvu
            current_item.setForeground(Qt.GlobalColor.black)

        # 2️⃣ reset labelu
        title = self.current_quest_title_label.text().rstrip(" *")
        self.current_quest_title_label.setText(title)
        self.current_quest_title_label.setStyleSheet(
            "font-size: 22pt; font-weight: bold; color: #3498db; margin-bottom: 10px;"
        )

    def _check_unsaved_changes(self):
        if not self._is_dirty:
            return True
        reply = QMessageBox.question(self, "Neuložené změny", "Máte neuložené změny. Chcete je uložit?",
                                     QMessageBox.StandardButton.Save | QMessageBox.StandardButton.Discard | QMessageBox.StandardButton.Cancel)
        if reply == QMessageBox.StandardButton.Save:
            return self.save_quest(confirmed=True)
        elif reply == QMessageBox.StandardButton.Cancel:
            return False
        else:
            return True

    def show_quest_tree(self):
        if self.quest_tree_window is None:
            from .quest_tree_widget import QuestTreeWidget
            self.quest_tree_window = QuestTreeWidget(self.db)
        self.quest_tree_window.generate_tree()
        self.quest_tree_window.show()
        self.quest_tree_window.activateWindow()

    def load_quests(self):
        current_id = self.current_quest_id
        self.quest_list.clear()
        item_to_select = None
        for quest in self.db.get_all_quests():
            item = QListWidgetItem(f"{quest['id']}: {quest['name']}")
            item.setData(Qt.ItemDataRole.UserRole, quest['id'])
            self.quest_list.addItem(item)
            if quest['id'] == current_id:
                item_to_select = item
        if item_to_select:
            self.quest_list.setCurrentItem(item_to_select)

    def display_quest_details(self, current_item, previous_item):
        self._mark_as_clean()
        self.copy_quest_btn.setEnabled(bool(current_item))
        if not current_item:
            self.clear_form()
            self.set_form_enabled(False)
            return
        self.current_quest_id = current_item.data(Qt.ItemDataRole.UserRole)
        details = self.db.get_quest_details(self.current_quest_id)
        if details:
            self.current_quest_title_label.setText(
                f"Úprava: {details.get('name', '')} (ID: {self.current_quest_id})")
            self.fill_form_with_data(details)
            self.set_form_enabled(True)
            self.delete_btn.setEnabled(True)

    def fill_form_with_data(self, data):
        self._set_dirty_tracking_enabled(False)
        try:
            self.id.setText(str(data.get('id', '')))
            self.name.setText(data.get('name', ''))
            self.description.setText(data.get('description', ''))

            self.active.setChecked(bool(data.get('active', 0)))
            self.repeatable.setChecked(bool(data.get('repeatable', 0)))

            completed_quests_json = data.get('complete_quests')
            if completed_quests_json:
                try:
                    self.complete_quests_display.setText(
                        ", ".join(map(str, json.loads(completed_quests_json)))
                    )
                except (json.JSONDecodeError, TypeError):
                    self.complete_quests_display.setText("")
            else:
                self.complete_quests_display.setText("")

            self.start_activation.setCurrentText(data.get('start_activation', ''))
            self.start_param.setText(data.get('start_param', ''))
            self.start_npc.setText(data.get('start_npc', ''))
            self.start_coords.setText(data.get('start_coords', ''))
            self.start_text.setText(data.get('start_text', ''))
            self.start_sound.setText(data.get('start_sound', '')) # <<< DOPLNĚNO
            self.start_anim_dict.setText(data.get('start_anim_dict', '')) # <<< DOPLNĚNO (pozor na překlep 'amin' z DB)
            self.start_anim_name.setText(data.get('start_anim_name', '')) # <<< DOPLNĚNO

            self.target_activation.setCurrentText(data.get('target_activation', ''))
            self.target_param.setText(data.get('target_param', ''))
            self.target_npc.setText(data.get('target_npc', ''))
            self.target_blip.setText(data.get('target_blip', ''))
            self.target_coords.setText(data.get('target_coords', ''))
            self.target_text.setText(data.get('target_text', ''))
            self.target_sound.setText(data.get('target_sound', '')) # <<< DOPLNĚNO
            self.target_anim_dict.setText(data.get('target_anim_dict', '')) # <<< DOPLNĚNO (pozor na překlep 'amin' z DB)
            self.target_anim_name.setText(data.get('target_anim_name', '')) # <<< DOPLNĚNO
            self.target_money.setValue(data.get('target_money', 0))

            self._populate_json_field(self.jobs, data.get('jobs'))

            self.start_prompt.setData(self._safe_json_decode(data.get('start_prompt')))
            self.target_prompt.setData(self._safe_json_decode(data.get('target_prompt')))
            self.start_items.setData(self._safe_json_decode(data.get('start_items')))
            self.target_items.setData(self._safe_json_decode(data.get('target_items')))
            self.start_events.setData(self._safe_json_decode(data.get('start_events')))
            self.target_events.setData(self._safe_json_decode(data.get('target_events')))
        finally:
            self._set_dirty_tracking_enabled(True)
            self._mark_as_clean()

    # --- ZDE JSOU VRÁCENÉ POMOCNÉ METODY ---
    def _safe_json_decode(self, json_string):
        if not json_string:
            return None
        try:
            return json.loads(json_string)
        except json.JSONDecodeError:
            return None

    def _populate_json_field(self, widget, data):
        if not data:
            widget.setText("")
            return
        try:
            widget.setText(json.dumps(json.loads(data),
                           indent=4, ensure_ascii=False))
        except (json.JSONDecodeError, TypeError):
            widget.setText(data)
    # ---------------------------------------------

    def clear_form(self):
        self._set_dirty_tracking_enabled(False)
        try:
            self.current_quest_title_label.setText("Vyberte quest z nabídky")
            self.complete_quests_display.clear()

            for widget in self.findChildren(QLineEdit):
                widget.clear()
            for widget in self.findChildren(QTextEdit):
                widget.clear()

            for widget in self.findChildren((PromptWidget, ItemsWidget, EventsWidget)):
                widget.clear()

            self.active.setChecked(True)
            self.repeatable.setChecked(False)
            self.target_money.setValue(0)
            self.start_activation.setCurrentIndex(0)
            self.target_activation.setCurrentIndex(0)
            self.current_quest_id = None
        finally:
            self._set_dirty_tracking_enabled(True)
            self._mark_as_clean()


    def new_quest(self):
        if not self._check_unsaved_changes():
            return
        self._mark_as_clean()
        self.quest_list.clearSelection()
        self.clear_form()
        self.current_quest_title_label.setText("Tvorba nového questu *")
        self.id.setText("<Automaticky>")
        self.current_quest_id = None
        self.set_form_enabled(True)
        self.delete_btn.setEnabled(False)
        self.name.setFocus()

    def open_quest_selection_dialog(self):
        current_ids = [int(q_id.strip()) for q_id in self.complete_quests_display.text(
        ).split(',') if q_id.strip()]
        dialog = QuestSelectionDialog(self.db, current_ids, self)
        if dialog.exec():
            self.complete_quests_display.setText(
                ", ".join(map(str, dialog.get_selected_ids())))
            self._mark_as_dirty()

    def copy_quest(self):
        if not self._check_unsaved_changes():
            return
        if not self.current_quest_id:
            QMessageBox.warning(self, "Chyba", "Nejprve vyberte quest.")
            return

        data = self.get_data_from_form()
        if not data:
            return

        original_name = data.get('name', 'Quest')
        data['id'] = "<Automaticky>"
        data['name'] = f"{original_name} - KOPIE"

        self.quest_list.clearSelection()

        self._set_dirty_tracking_enabled(False)
        try:
            self.fill_form_with_data(data)
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
            'active': 1 if self.active.isChecked() else 0, 
            'name': self.name.text() or None, 
            'description': self.description.toPlainText() or None, 
            'repeatable': 1 if self.repeatable.isChecked() else 0, 
            'start_activation': self.start_activation.currentText() or None, 
            'start_param': self.start_param.text() or None, 
            'start_npc': self.start_npc.text() or None, 
            'start_coords': self.start_coords.text().replace(" ", "") or None,
            'start_text': self.start_text.toPlainText() or None, 
            'start_sound': self.start_sound.text() or None, # <<< DOPLNĚNO
            'start_anim_dict': self.start_anim_dict.text() or None, # <<< DOPLNĚNO
            'start_anim_name': self.start_anim_name.text() or None, # <<< DOPLNĚNO
            'target_activation': self.target_activation.currentText() or None, 
            'target_param': self.target_param.text() or None, 
            'target_npc': self.target_npc.text() or None, 
            'target_blip': self.target_blip.text() or None, 
            'target_coords': self.target_coords.text().replace(" ", "") or None, 
            'target_text': self.target_text.toPlainText() or None, 
            'target_sound': self.target_sound.text() or None, # <<< DOPLNĚNO
            'target_anim_dict': self.target_anim_dict.text() or None, # <<< DOPLNĚNO
            'target_anim_name': self.target_anim_name.text() or None, # <<< DOPLNĚNO
            'target_money': self.target_money.value()
        }
        for key, widget in {'start_prompt': self.start_prompt, 'target_prompt': self.target_prompt, 'start_items': self.start_items, 'target_items': self.target_items, 'start_events': self.start_events, 'target_events': self.target_events}.items():
            data[key] = json.dumps(
                widget.getData(), ensure_ascii=False) if widget.getData() else None
        try:
            data['jobs'] = json.dumps(json.loads(self.jobs.toPlainText().strip(
            )), ensure_ascii=False) if self.jobs.toPlainText().strip() else None
        except json.JSONDecodeError as e:
            QMessageBox.warning(self, "Chyba ve formátu",
                                f"Pole 'jobs' neobsahuje validní JSON.\n{e}")
            return None
        completed_text = self.complete_quests_display.text().strip()
        if completed_text:
            data['complete_quests'] = json.dumps(
                [int(q_id.strip()) for q_id in completed_text.split(',') if q_id.strip()])
        else:
            data['complete_quests'] = None
        return data

    def save_quest(self, confirmed=False):
        if not confirmed:
            reply = QMessageBox.question(
                self, "Potvrzení", f"Opravdu uložit quest '{self.name.text() or '<bez názvu>'}'?", QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
            if reply == QMessageBox.StandardButton.No:
                return False
        data = self.get_data_from_form()
        if not data:
            return False
        success, message, saved_id = self.db.save_quest(
            data, self.current_quest_id)
        if success:
            if not confirmed:
                QMessageBox.information(self, "Úspěch", message)
            # Aktualizujeme ID pro případ, že jde o nový quest
            self.current_quest_id = saved_id
            self._mark_as_clean()
            self.load_quests()  # Znovu načte seznam a vybere aktuální quest
            return True
        else:
            if not confirmed:
                QMessageBox.critical(self, "Chyba", message)
            return False

    def set_form_enabled(self, enabled): self.tabs.setEnabled(
        enabled); self.save_btn.setEnabled(enabled); self.delete_btn.setEnabled(enabled)

    def delete_quest(self):
        if not self.current_quest_id:
            return
        if QMessageBox.question(self, "Potvrzení", f"Opravdu smazat quest ID {self.current_quest_id}?") == QMessageBox.StandardButton.Yes:
            if self.db.delete_quest(self.current_quest_id):
                self._mark_as_clean()
                self.load_quests()
                self.clear_form()
                self.set_form_enabled(False)