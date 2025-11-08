# /Váš_Projekt/database_manager.py

import pymysql
import config
from PyQt6.QtWidgets import QMessageBox

class Database:
    """Spravuje veškeré připojení a dotazy do databáze."""
    def __init__(self):
        self.config = config.DB_CONFIG
        self.connection = None

    def connect(self):
        try:
            self.connection = pymysql.connect(
                **self.config,
                cursorclass=pymysql.cursors.DictCursor,
                autocommit=True
            )
            return True
        except pymysql.Error as e:
            QMessageBox.critical(None, "Kritická chyba", f"Nepodařilo se připojit k databázi:\n{e}\nAplikace bude ukončena.")
            return False

    def get_available_items(self):
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT item, label FROM items ORDER BY label")
                return cursor.fetchall()
        except pymysql.Error as e:
            QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se načíst seznam předmětů:\n{e}")
            return []

    def get_all_quests(self):
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT id, name FROM aprts_simplequests_quests ORDER BY id")
                return cursor.fetchall()
        except pymysql.Error as e:
            QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se načíst questy:\n{e}")
            return []

    def get_quest_details(self, quest_id):
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT * FROM aprts_simplequests_quests WHERE id = %s", (quest_id,))
                return cursor.fetchone()
        except pymysql.Error as e:
            QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se načíst detail questu:\n{e}")
            return None

    def delete_quest(self, quest_id):
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("DELETE FROM aprts_simplequests_quests WHERE id = %s", (quest_id,))
            return True
        except pymysql.Error as e:
            QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se smazat quest:\n{e}")
            return False

    def save_quest(self, data):
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT id FROM aprts_simplequests_quests WHERE id = %s", (data['id'],))
                is_update = bool(cursor.fetchone())
        except pymysql.Error as e:
            return False, f"Chyba při kontrole existence questu: {e}"

        if is_update:
            # Sestavení pro UPDATE, vynechá ID z SET klauzule
            set_clause = ", ".join([f"`{k}`=%s" for k in data if k != 'id'])
            sql = f"UPDATE aprts_simplequests_quests SET {set_clause} WHERE id=%s"
            # Parametry: všechny hodnoty kromě ID, na konec přidáme ID pro WHERE
            params = [v for k, v in data.items() if k != 'id'] + [data['id']]
        else:
            columns = ", ".join(f"`{k}`" for k in data.keys())
            placeholders = ", ".join(["%s"] * len(data))
            sql = f"INSERT INTO aprts_simplequests_quests ({columns}) VALUES ({placeholders})"
            params = list(data.values())

        try:
            with self.connection.cursor() as cursor:
                cursor.execute(sql, params)
            return True, "Quest úspěšně uložen."
        except pymysql.Error as e:
            return False, f"Chyba při ukládání questu:\n{e}"