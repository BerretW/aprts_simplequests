# /Váš_Projekt/main.py

import sys
from PyQt6.QtWidgets import QApplication

from database_manager import Database
from ui.auth_dialogs import LoginDialog
from ui.main_window import QuestEditor
from ui.stylesheet import STYLESHEET # <-- NOVÝ IMPORT

def main():
    """Hlavní funkce aplikace."""
    app = QApplication(sys.argv)
    
    # --- NOVÝ ŘÁDEK: Aplikace stylesheetu ---
    app.setStyleSheet(STYLESHEET)
    
    # 1. Vytvoříme a otestujeme připojení k databázi
    db_handler = Database()
    if not db_handler.connect():
        return 1
    
    # 2. Zobrazíme přihlašovací dialog
    login_dialog = LoginDialog(db_handler.connection)
    
    # 3. Pokud je přihlášení úspěšné, zobrazíme hlavní okno editoru
    if login_dialog.exec():
        editor = QuestEditor(db_handler)
        editor.statusBar().showMessage(f"Přihlášen jako: {login_dialog.current_user_name}")
        editor.show()
        return app.exec()
    else:
        return 0

if __name__ == '__main__':
    sys.exit(main())