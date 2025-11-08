# quest_editor.py
import sys
import json
import pymysql
import config
from passlib.hash import scrypt
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QListWidget, QFormLayout, QLineEdit, QTextEdit, QCheckBox,
    QPushButton, QTabWidget, QSplitter, QMessageBox, QDialog,
    QSpinBox, QDialogButtonBox, QLabel, QListWidgetItem, QComboBox
)
from PyQt6.QtCore import Qt
from custom_widgets import PromptWidget, ItemsWidget, CoordsLineEdit, EventsWidget # Přidán import EventsWidget

# --- Třídy RegisterDialog a LoginDialog (beze změny) ---
class RegisterDialog(QDialog):
    def __init__(self, connection, parent=None):
        super().__init__(parent)
        self.connection = connection
        self.setWindowTitle("Registrace nového uživatele")
        self.setModal(True)
        self.init_ui()
    def init_ui(self):
        layout = QVBoxLayout(self); form_layout = QFormLayout()
        self.username_edit = QLineEdit(); self.email_edit = QLineEdit()
        self.password_edit = QLineEdit(); self.password_edit.setEchoMode(QLineEdit.EchoMode.Password)
        form_layout.addRow("Uživatelské jméno:", self.username_edit); form_layout.addRow("Email:", self.email_edit); form_layout.addRow("Heslo:", self.password_edit)
        layout.addLayout(form_layout)
        btns = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel, Qt.Orientation.Horizontal, self)
        btns.accepted.connect(self.register_user); btns.rejected.connect(self.reject); layout.addWidget(btns)
    def register_user(self):
        user = self.username_edit.text().strip(); email = self.email_edit.text().strip(); password_plain = self.password_edit.text()
        if not user or not password_plain: QMessageBox.warning(self, "Chyba", "Musíš vyplnit jméno i heslo."); return
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT id FROM web_users WHERE user=%s", (user,))
                if cursor.fetchone(): QMessageBox.warning(self, "Chyba", f"Uživatel '{user}' už existuje!"); return
                hashed = scrypt.hash(password_plain)
                sql = "INSERT INTO web_users (user, password, email, perm) VALUES (%s, %s, %s, %s)"
                cursor.execute(sql, (user, hashed, email, '0'))
            QMessageBox.information(self, "Hotovo", "Registrace proběhla. Pro přihlášení musí administrátor ručně nastavit vaše oprávnění (perm) na hodnotu vyšší než '0'."); self.accept()
        except pymysql.Error as e: QMessageBox.critical(self, "Chyba DB", f"Nepodařilo se uložit uživatele: {e}")

class LoginDialog(QDialog):
    current_user_name = None
    def __init__(self, connection, parent=None):
        super().__init__(parent)
        self.connection = connection; self.setWindowTitle("Přihlášení do editoru"); self.setModal(True); self.init_ui()
    def init_ui(self):
        layout = QVBoxLayout(self); form_layout = QFormLayout()
        self.username_edit = QLineEdit(); self.password_edit = QLineEdit()
        self.password_edit.setEchoMode(QLineEdit.EchoMode.Password); self.password_edit.returnPressed.connect(self.login_user)
        form_layout.addRow("Uživatelské jméno:", self.username_edit); form_layout.addRow("Heslo:", self.password_edit); layout.addLayout(form_layout)
        btns_layout = QHBoxLayout(); login_btn = QPushButton("Přihlásit se"); login_btn.clicked.connect(self.login_user); btns_layout.addWidget(login_btn)
        cancel_btn = QPushButton("Zrušit"); cancel_btn.clicked.connect(self.reject); btns_layout.addWidget(cancel_btn); layout.addLayout(btns_layout)
        register_btn = QPushButton("Registrace"); register_btn.clicked.connect(self.open_register_dialog); layout.addWidget(register_btn)
    def open_register_dialog(self): dlg = RegisterDialog(self.connection, self); dlg.exec()
    def login_user(self):
        user = self.username_edit.text().strip(); pass_plain = self.password_edit.text()
        if not user or not pass_plain: QMessageBox.warning(self, "Chyba", "Musíš vyplnit jméno i heslo."); return
        try:
            with self.connection.cursor() as cursor: cursor.execute("SELECT * FROM web_users WHERE user=%s", (user,)); row = cursor.fetchone()
        except pymysql.Error as e: QMessageBox.critical(self, "Chyba DB", f"Došlo k chybě při dotazu na databázi: {e}"); return
        if not row: QMessageBox.warning(self, "Chyba", "Takový uživatel neexistuje."); return
        if str(row.get('perm', '0')) == '0': QMessageBox.warning(self, "Přístup odepřen", "Nemáš oprávnění pro přístup do editoru (perm=0)."); return
        db_hash = row['password']
        try:
            if not scrypt.verify(pass_plain, db_hash): QMessageBox.warning(self, "Chyba", "Heslo nesouhlasí."); return
        except Exception: QMessageBox.critical(self, "Chyba", "Nepodařilo se ověřit heslo."); return
        LoginDialog.current_user_name = row["user"]; self.accept()

# --- Třída pro správu databáze (beze změny) ---
class Database:
    def __init__(self):
        self.config = config.DB_CONFIG; self.connection = None
    def connect(self):
        try:
            self.connection = pymysql.connect(**self.config, cursorclass=pymysql.cursors.DictCursor, autocommit=True); return True
        except pymysql.Error as e: QMessageBox.critical(None, "Kritická chyba", f"Nepodařilo se připojit k databázi:\n{e}\nAplikace bude ukončena."); return False
    def get_available_items(self):
        try:
            with self.connection.cursor() as cursor: cursor.execute("SELECT item, label FROM items ORDER BY label"); return cursor.fetchall()
        except pymysql.Error as e: QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se načíst seznam předmětů:\n{e}"); return []
    def get_all_quests(self):
        try:
            with self.connection.cursor() as cursor: cursor.execute("SELECT id, name FROM aprts_simplequests_quests ORDER BY id"); return cursor.fetchall()
        except pymysql.Error as e: QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se načíst questy:\n{e}"); return []
    def get_quest_details(self, quest_id):
        try:
            with self.connection.cursor() as cursor: cursor.execute("SELECT * FROM aprts_simplequests_quests WHERE id = %s", (quest_id,)); return cursor.fetchone()
        except pymysql.Error as e: QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se načíst detail questu:\n{e}"); return None
    def delete_quest(self, quest_id):
        try:
            with self.connection.cursor() as cursor: cursor.execute("DELETE FROM aprts_simplequests_quests WHERE id = %s", (quest_id,)); return True
        except pymysql.Error as e: QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se smazat quest:\n{e}"); return False
    def save_quest(self, data):
        is_update = False
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT id FROM aprts_simplequests_quests WHERE id = %s", (data['id'],)); is_update = bool(cursor.fetchone())
        except pymysql.Error as e: return False, f"Chyba při kontrole existence questu: {e}"
        if is_update:
            sql = "UPDATE aprts_simplequests_quests SET " + ", ".join([f"`{k}`=%s" for k in data if k != 'id']) + " WHERE id=%s"
            params = list(data.values())[1:] + [data['id']]
        else:
            columns = ", ".join(f"`{k}`" for k in data.keys()); placeholders = ", ".join(["%s"] * len(data))
            sql = f"INSERT INTO aprts_simplequests_quests ({columns}) VALUES ({placeholders})"; params = list(data.values())
        try:
            with self.connection.cursor() as cursor: cursor.execute(sql, params); return True, "Quest úspěšně uložen."
        except pymysql.Error as e: return False, f"Chyba při ukládání questu:\n{e}"

# --- Hlavní okno editoru ---
class QuestEditor(QMainWindow):
    def __init__(self, db_handler):
        super().__init__(); self.db = db_handler; self.current_quest_id = None
        self.setWindowTitle("RedM Quest Editor"); self.setGeometry(100, 100, 1200, 800)
        self.init_ui()
        self.statusBar().showMessage(f"Přihlášen jako: {LoginDialog.current_user_name}"); self.load_quests()

    def init_ui(self):
        main_widget = QWidget(); self.setCentralWidget(main_widget); main_layout = QHBoxLayout(main_widget)
        splitter = QSplitter(Qt.Orientation.Horizontal); main_layout.addWidget(splitter)
        left_panel = QWidget(); left_layout = QVBoxLayout(left_panel); self.quest_list = QListWidget()
        self.quest_list.currentItemChanged.connect(self.display_quest_details)
        new_quest_btn = QPushButton("Nový Quest"); new_quest_btn.clicked.connect(self.new_quest)
        left_layout.addWidget(QLabel("Seznam Questů")); left_layout.addWidget(self.quest_list); left_layout.addWidget(new_quest_btn); splitter.addWidget(left_panel)
        right_panel = QWidget(); right_layout = QVBoxLayout(right_panel); self.tabs = QTabWidget(); self.init_form_tabs()
        right_layout.addWidget(self.tabs); button_layout = QHBoxLayout(); self.save_btn = QPushButton("Uložit Quest")
        self.save_btn.clicked.connect(self.save_quest); self.delete_btn = QPushButton("Smazat Quest"); self.delete_btn.clicked.connect(self.delete_quest)
        button_layout.addWidget(self.save_btn); button_layout.addWidget(self.delete_btn); right_layout.addLayout(button_layout)
        splitter.addWidget(right_panel); splitter.setSizes([300, 900]); self.set_form_enabled(False)

    def init_form_tabs(self):
        tab_general = QWidget(); form_general = QFormLayout(tab_general)
        self.id = QLineEdit(); self.name = QLineEdit(); self.description = QTextEdit()
        self.active = QCheckBox(); self.repeatable = QCheckBox(); self.jobs = QTextEdit()
        self.jobs.setToolTip("Zadejte jako JSON pole objektů, např.:\n[{\"job\": \"police\", \"grade\": 1}]")
        form_general.addRow("ID:", self.id); form_general.addRow("Název:", self.name); form_general.addRow("Popis:", self.description)
        form_general.addRow("Aktivní:", self.active); form_general.addRow("Opakovatelný:", self.repeatable); form_general.addRow("Požadované práce (JSON):", self.jobs)
        self.tabs.addTab(tab_general, "Obecné")
        
        activation_types = ["", "talktoNPC", "distance", "useItem", "clientEvent"]
        tab_start = QWidget(); form_start = QFormLayout(tab_start)
        self.start_activation = QComboBox(); self.start_activation.addItems(activation_types)
        self.start_param = QLineEdit(); self.start_npc = QLineEdit(); self.start_coords = CoordsLineEdit(); self.start_text = QTextEdit()
        self.start_prompt = PromptWidget(); self.start_items = ItemsWidget(self.db, config.IMAGE_BASE_URL)
        self.start_events = EventsWidget() # ZMĚNA
        form_start.addRow("Aktivace:", self.start_activation); form_start.addRow("Parametr:", self.start_param); form_start.addRow("NPC model:", self.start_npc)
        form_start.addRow("Souřadnice:", self.start_coords); form_start.addRow("Text:", self.start_text); form_start.addRow("Prompt:", self.start_prompt)
        form_start.addRow("Předměty:", self.start_items); form_start.addRow("Eventy:", self.start_events); self.tabs.addTab(tab_start, "Start")
        
        tab_target = QWidget(); form_target = QFormLayout(tab_target)
        self.target_activation = QComboBox(); self.target_activation.addItems(activation_types)
        self.target_param = QLineEdit(); self.target_npc = QLineEdit(); self.target_blip = QLineEdit(); self.target_coords = CoordsLineEdit(); self.target_text = QTextEdit()
        self.target_prompt = PromptWidget(); self.target_items = ItemsWidget(self.db, config.IMAGE_BASE_URL)
        self.target_money = QSpinBox(); self.target_money.setRange(0, 1000000); self.target_events = EventsWidget() # ZMĚNA
        form_target.addRow("Aktivace:", self.target_activation); form_target.addRow("Parametr:", self.target_param); form_target.addRow("NPC model:", self.target_npc)
        form_target.addRow("Blip:", self.target_blip); form_target.addRow("Souřadnice:", self.target_coords); form_target.addRow("Text:", self.target_text)
        form_target.addRow("Prompt:", self.target_prompt); form_target.addRow("Předměty:", self.target_items); form_target.addRow("Peníze:", self.target_money)
        form_target.addRow("Eventy:", self.target_events); self.tabs.addTab(tab_target, "Cíl")

    def load_quests(self):
        self.quest_list.clear()
        for quest in self.db.get_all_quests():
            item = QListWidgetItem(f"{quest['id']}: {quest['name']}"); item.setData(Qt.ItemDataRole.UserRole, quest['id']); self.quest_list.addItem(item)
    
    def display_quest_details(self, current_item, _):
        if not current_item: self.clear_form(); self.set_form_enabled(False); return
        quest_id = current_item.data(Qt.ItemDataRole.UserRole); self.current_quest_id = quest_id
        details = self.db.get_quest_details(quest_id)
        if details:
            self.id.setText(str(details.get('id', ''))); self.id.setReadOnly(True); self.name.setText(details.get('name', '')); self.description.setText(details.get('description', ''))
            self.active.setChecked(bool(details.get('active', 0))); self.repeatable.setChecked(bool(details.get('repeatable', 0)))
            self.start_activation.setCurrentText(details.get('start_activation', '')); self.start_param.setText(details.get('start_param', ''))
            self.start_npc.setText(details.get('start_npc', '')); self.start_coords.setText(details.get('start_coords', '')); self.start_text.setText(details.get('start_text', ''))
            self.target_activation.setCurrentText(details.get('target_activation', '')); self.target_param.setText(details.get('target_param', ''))
            self.target_npc.setText(details.get('target_npc', '')); self.target_blip.setText(details.get('target_blip', ''))
            self.target_coords.setText(details.get('target_coords', '')); self.target_text.setText(details.get('target_text', '')); self.target_money.setValue(details.get('target_money', 0))

            self.populate_field(self.jobs, details.get('jobs'))
            self.start_prompt.setData(self.safe_json_decode(details.get('start_prompt'))); self.target_prompt.setData(self.safe_json_decode(details.get('target_prompt')))
            self.start_items.setData(self.safe_json_decode(details.get('start_items'))); self.target_items.setData(self.safe_json_decode(details.get('target_items')))
            self.start_events.setData(self.safe_json_decode(details.get('start_events'))); self.target_events.setData(self.safe_json_decode(details.get('target_events')))
            
            self.set_form_enabled(True); self.delete_btn.setEnabled(True)

    def safe_json_decode(self, json_string):
        if not json_string: return None
        try: return json.loads(json_string)
        except json.JSONDecodeError: return None

    def populate_field(self, widget, data):
        if not data: widget.setText(""); return
        try: widget.setText(json.dumps(json.loads(data), indent=4, ensure_ascii=False))
        except json.JSONDecodeError: widget.setText(data)

    def clear_form(self):
        for widget in self.findChildren((QLineEdit, QTextEdit)): widget.clear()
        self.active.setChecked(True); self.repeatable.setChecked(False); self.target_money.setValue(0); self.start_activation.setCurrentIndex(0); self.target_activation.setCurrentIndex(0)
        self.start_prompt.clear(); self.target_prompt.clear(); self.start_items.clear(); self.target_items.clear(); self.start_events.clear(); self.target_events.clear()
        self.id.setReadOnly(False); self.current_quest_id = None

    def new_quest(self):
        self.quest_list.clearSelection(); self.clear_form(); self.set_form_enabled(True)
        self.delete_btn.setEnabled(False); self.id.setFocus(); self.statusBar().showMessage("Připraven pro vytvoření nového questu.", 3000)

    def set_form_enabled(self, enabled):
        self.tabs.setEnabled(enabled); self.save_btn.setEnabled(enabled); self.delete_btn.setEnabled(enabled)

    def save_quest(self):
        if not self.id.text().isdigit(): QMessageBox.warning(self, "Chyba", "ID musí být číslo."); return
        data = {
            'id': int(self.id.text()), 'active': 1 if self.active.isChecked() else 0, 'name': self.name.text() or None, 'description': self.description.toPlainText() or None,
            'repeatable': 1 if self.repeatable.isChecked() else 0, 'start_activation': self.start_activation.currentText() or None, 'start_param': self.start_param.text() or None,
            'start_npc': self.start_npc.text() or None, 'start_coords': self.start_coords.text().replace(" ", "") or None, 'start_text': self.start_text.toPlainText() or None,
            'target_activation': self.target_activation.currentText() or None, 'target_param': self.target_param.text() or None, 'target_npc': self.target_npc.text() or None,
            'target_blip': self.target_blip.text() or None, 'target_coords': self.target_coords.text().replace(" ", "") or None, 'target_text': self.target_text.toPlainText() or None,
            'target_money': self.target_money.value()
        }
        
        # Získání dat z vlastních widgetů
        data['start_prompt'] = json.dumps(self.start_prompt.getData(), ensure_ascii=False) if self.start_prompt.getData() else None
        data['target_prompt'] = json.dumps(self.target_prompt.getData(), ensure_ascii=False) if self.target_prompt.getData() else None
        data['start_items'] = json.dumps(self.start_items.getData(), ensure_ascii=False) if self.start_items.getData() else None
        data['target_items'] = json.dumps(self.target_items.getData(), ensure_ascii=False) if self.target_items.getData() else None
        data['start_events'] = json.dumps(self.start_events.getData(), ensure_ascii=False) if self.start_events.getData() else None
        data['target_events'] = json.dumps(self.target_events.getData(), ensure_ascii=False) if self.target_events.getData() else None

        text = self.jobs.toPlainText().strip()
        if not text: data['jobs'] = None
        else:
            try: data['jobs'] = json.dumps(json.loads(text), ensure_ascii=False)
            except json.JSONDecodeError as e: QMessageBox.warning(self, "Chyba ve formátu", f"Pole 'jobs' neobsahuje validní JSON.\n{e}"); return

        success, message = self.db.save_quest(data)
        if success: QMessageBox.information(self, "Úspěch", message); self.load_quests()
        else: QMessageBox.critical(self, "Chyba při ukládání", message)

    def delete_quest(self):
        if not self.current_quest_id: return
        reply = QMessageBox.question(self, "Potvrzení smazání", f"Opravdu chcete smazat quest s ID {self.current_quest_id}?", QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No, QMessageBox.StandardButton.No)
        if reply == QMessageBox.StandardButton.Yes:
            if self.db.delete_quest(self.current_quest_id):
                QMessageBox.information(self, "Smazáno", "Quest byl úspěšně smazán.")
                self.load_quests(); self.clear_form(); self.set_form_enabled(False)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    db_handler = Database()
    if not db_handler.connect(): sys.exit(1)
    login_dialog = LoginDialog(db_handler.connection)
    if login_dialog.exec():
        editor = QuestEditor(db_handler); editor.show(); sys.exit(app.exec())
    else: sys.exit(0)