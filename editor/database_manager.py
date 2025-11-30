# editor/database_manager.py

import pymysql
import config
from PyQt6.QtWidgets import QMessageBox

class Database:
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
            
    # --- NOVÁ METODA PRO SKUPINY ---
    def get_quest_groups(self):
        """Načte seznam dostupných skupin questů."""
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT id, name FROM aprts_simplequests_groups ORDER BY name")
                return cursor.fetchall()
        except pymysql.Error as e:
            QMessageBox.critical(None, "Chyba DB", f"Nepodařilo se načíst skupiny questů:\n{e}")
            return []

    def get_all_quests(self):
        try:
            with self.connection.cursor() as cursor:
                # Přidáno groupid do výběru
                cursor.execute("SELECT id, name, groupid FROM aprts_simplequests_quests ORDER BY groupid, id")
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

    def save_quest(self, data, quest_id=None):
        if quest_id:
            set_clause = ", ".join([f"`{k}`=%s" for k in data])
            sql = f"UPDATE aprts_simplequests_quests SET {set_clause} WHERE id=%s"
            params = list(data.values()) + [quest_id]
            message = "Quest úspěšně aktualizován."
            saved_id = quest_id
        else:
            columns = ", ".join(f"`{k}`" for k in data.keys())
            placeholders = ", ".join(["%s"] * len(data))
            sql = f"INSERT INTO aprts_simplequests_quests ({columns}) VALUES ({placeholders})"
            params = list(data.values())
            message = "Nový quest úspěšně vytvořen."
            saved_id = None

        try:
            with self.connection.cursor() as cursor:
                cursor.execute(sql, params)
                if not quest_id:
                    saved_id = cursor.lastrowid
            return True, message, saved_id
        except pymysql.Error as e:
            return False, f"Chyba při ukládání questu:\n{e}", None
    def add_group(self, name):
        """Vytvoří novou skupinu."""
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("INSERT INTO aprts_simplequests_groups (name) VALUES (%s)", (name,))
            return True, cursor.lastrowid
        except pymysql.Error as e:
            return False, str(e)

    def rename_group(self, group_id, new_name):
        """Přejmenuje existující skupinu."""
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("UPDATE aprts_simplequests_groups SET name = %s WHERE id = %s", (new_name, group_id))
            return True, ""
        except pymysql.Error as e:
            return False, str(e)

    def delete_group(self, group_id):
        """Smaže skupinu. Questy v ní přesune do defaultní skupiny (ID 1) nebo nastaví na NULL."""
        try:
            with self.connection.cursor() as cursor:
                # 1. Přesuneme questy do "Nezařazeno" (nebo ID 1, pokud existuje)
                # Zde předpokládám, že ID 1 je default. Pokud ne, questy se stanou sirotky, což GUI vyřeší jako "Nezařazeno".
                cursor.execute("UPDATE aprts_simplequests_quests SET groupid = 1 WHERE groupid = %s", (group_id,))
                
                # 2. Smažeme skupinu
                cursor.execute("DELETE FROM aprts_simplequests_groups WHERE id = %s", (group_id,))
            return True, ""
        except pymysql.Error as e:
            return False, str(e)

    # ... (zbytek třídy: get_all_quests, save_quest, delete_quest atd. zůstává stejný) ...
    def get_all_quests(self):
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT id, name, groupid FROM aprts_simplequests_quests ORDER BY groupid, id")
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

    def save_quest(self, data, quest_id=None):
        # ... (kód save_quest beze změny) ...
        if quest_id:
            set_clause = ", ".join([f"`{k}`=%s" for k in data])
            sql = f"UPDATE aprts_simplequests_quests SET {set_clause} WHERE id=%s"
            params = list(data.values()) + [quest_id]
            message = "Quest úspěšně aktualizován."
            saved_id = quest_id
        else:
            columns = ", ".join(f"`{k}`" for k in data.keys())
            placeholders = ", ".join(["%s"] * len(data))
            sql = f"INSERT INTO aprts_simplequests_quests ({columns}) VALUES ({placeholders})"
            params = list(data.values())
            message = "Nový quest úspěšně vytvořen."
            saved_id = None

        try:
            with self.connection.cursor() as cursor:
                cursor.execute(sql, params)
                if not quest_id:
                    saved_id = cursor.lastrowid
            return True, message, saved_id
        except pymysql.Error as e:
            return False, f"Chyba při ukládání questu:\n{e}", None