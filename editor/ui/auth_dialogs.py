# /Váš_Projekt/ui/auth_dialogs.py

from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QFormLayout, QLineEdit,
    QPushButton, QDialogButtonBox, QHBoxLayout, QMessageBox
)
from PyQt6.QtCore import Qt
from passlib.hash import scrypt
import pymysql

class RegisterDialog(QDialog):
    def __init__(self, connection, parent=None):
        super().__init__(parent)
        self.connection = connection
        self.setWindowTitle("Registrace nového uživatele"); self.setModal(True)
        layout = QVBoxLayout(self); form_layout = QFormLayout()
        self.username_edit = QLineEdit(); self.email_edit = QLineEdit()
        self.password_edit = QLineEdit(); self.password_edit.setEchoMode(QLineEdit.EchoMode.Password)
        form_layout.addRow("Uživatelské jméno:", self.username_edit); form_layout.addRow("Email:", self.email_edit); form_layout.addRow("Heslo:", self.password_edit)
        layout.addLayout(form_layout)
        btns = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel, Qt.Orientation.Horizontal, self)
        btns.accepted.connect(self.register_user); btns.rejected.connect(self.reject); layout.addWidget(btns)

    def register_user(self):
        user = self.username_edit.text().strip(); password_plain = self.password_edit.text()
        if not user or not password_plain: QMessageBox.warning(self, "Chyba", "Musíš vyplnit jméno i heslo."); return
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT id FROM web_users WHERE user=%s", (user,))
                if cursor.fetchone(): QMessageBox.warning(self, "Chyba", f"Uživatel '{user}' už existuje!"); return
                hashed = scrypt.hash(password_plain)
                sql = "INSERT INTO web_users (user, password, email, perm) VALUES (%s, %s, %s, %s)"
                cursor.execute(sql, (user, hashed, self.email_edit.text().strip(), '0'))
            QMessageBox.information(self, "Hotovo", "Registrace proběhla. Administrátor musí ručně nastavit vaše oprávnění."); self.accept()
        except pymysql.Error as e: QMessageBox.critical(self, "Chyba DB", f"Nepodařilo se uložit uživatele: {e}")

class LoginDialog(QDialog):
    current_user_name = None
    def __init__(self, connection, parent=None):
        super().__init__(parent)
        self.connection = connection; self.setWindowTitle("Přihlášení do editoru"); self.setModal(True)
        layout = QVBoxLayout(self); form_layout = QFormLayout()
        self.username_edit = QLineEdit(); self.password_edit = QLineEdit()
        self.password_edit.setEchoMode(QLineEdit.EchoMode.Password); self.password_edit.returnPressed.connect(self.login_user)
        form_layout.addRow("Uživatelské jméno:", self.username_edit); form_layout.addRow("Heslo:", self.password_edit); layout.addLayout(form_layout)
        btns_layout = QHBoxLayout(); login_btn = QPushButton("Přihlásit se"); login_btn.clicked.connect(self.login_user); btns_layout.addWidget(login_btn)
        cancel_btn = QPushButton("Zrušit"); cancel_btn.clicked.connect(self.reject); btns_layout.addWidget(cancel_btn); layout.addLayout(btns_layout)
        register_btn = QPushButton("Registrace"); register_btn.clicked.connect(self.open_register_dialog); layout.addWidget(register_btn)

    def open_register_dialog(self): RegisterDialog(self.connection, self).exec()
    def login_user(self):
        user = self.username_edit.text().strip(); pass_plain = self.password_edit.text()
        if not user or not pass_plain: QMessageBox.warning(self, "Chyba", "Musíš vyplnit jméno i heslo."); return
        try:
            with self.connection.cursor() as cursor: cursor.execute("SELECT * FROM web_users WHERE user=%s", (user,)); row = cursor.fetchone()
        except pymysql.Error as e: QMessageBox.critical(self, "Chyba DB", f"Došlo k chybě při dotazu na databázi: {e}"); return
        if not row: QMessageBox.warning(self, "Chyba", "Takový uživatel neexistuje."); return
        if str(row.get('perm', '0')) == '0': QMessageBox.warning(self, "Přístup odepřen", "Nemáš oprávnění (perm=0)."); return
        try:
            if not scrypt.verify(pass_plain, row['password']): QMessageBox.warning(self, "Chyba", "Heslo nesouhlasí."); return
        except Exception: QMessageBox.critical(self, "Chyba", "Nepodařilo se ověřit heslo."); return
        LoginDialog.current_user_name = row["user"]; self.accept()