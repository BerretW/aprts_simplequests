# editor/ui/main_window.py

from PyQt6.QtWidgets import QMainWindow, QWidget, QHBoxLayout, QSplitter, QMessageBox
from PyQt6.QtCore import Qt

from .panels.left_panel import QuestListPanel
from .panels.right_panel import QuestDetailsPanel

class QuestEditor(QMainWindow):
    def __init__(self, db_handler):
        super().__init__()
        self.db = db_handler
        self.current_quest_id = None
        self._is_dirty = False

        self.setWindowTitle("APRTS SimpleQuest Editor V2.0 - Modular") 
        self.setGeometry(100, 100, 1250, 850)

        self.init_ui()
        self.load_initial_data()

    def init_ui(self):
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QHBoxLayout(main_widget)
        
        splitter = QSplitter(Qt.Orientation.Horizontal)
        layout.addWidget(splitter)

        # 1. Levý panel (Seznam)
        # Předáváme 'self' jako referenci pro SafeTreeWidget (aby mohl volat _check_unsaved_changes)
        self.left_panel = QuestListPanel(self.db, self)
        
        # 2. Pravý panel (Detail)
        self.right_panel = QuestDetailsPanel(self.db)

        # Propojení signálů
        self.left_panel.quest_selected.connect(self.on_quest_selected)
        self.left_panel.new_quest_requested.connect(self.on_new_quest)
        self.left_panel.copy_quest_requested.connect(self.on_copy_quest)
        self.left_panel.group_changed.connect(self.on_groups_changed)
        self.left_panel.show_tree_viz_requested.connect(self.show_quest_tree_window)

        self.right_panel.data_changed.connect(self._mark_as_dirty)
        self.right_panel.save_requested.connect(lambda: self.save_quest(confirmed=False))
        self.right_panel.delete_requested.connect(self.delete_quest)

        splitter.addWidget(self.left_panel)
        splitter.addWidget(self.right_panel)
        splitter.setSizes([350, 850])

    def load_initial_data(self):
        # Načíst skupiny pro combo box v pravém panelu
        groups = self.db.get_quest_groups()
        self.right_panel.load_groups(groups)
        # Načíst strom
        self.left_panel.reload_tree()

    # --- Logika výběru ---
    def on_quest_selected(self, current_item, previous_item):
        self._mark_as_clean()
        
        if not current_item:
            self.right_panel.clear()
            self.right_panel.set_enabled(False)
            return

        quest_id = current_item.data(0, Qt.ItemDataRole.UserRole)
        
        if quest_id is None: # Je to skupina
            self.right_panel.clear()
            self.right_panel.set_enabled(False)
            self.right_panel.title_label.setText(f"Skupina: {current_item.text(0)}")
            return

        # Je to quest - načteme detaily
        self.current_quest_id = quest_id
        details = self.db.get_quest_details(quest_id)
        if details:
            self.right_panel.title_label.setText(f"Úprava: {details.get('name', '')} (ID: {quest_id})")
            self.right_panel.set_data(details)
            self.right_panel.set_enabled(True)

    def on_new_quest(self):
        if not self._check_unsaved_changes(): return
        
        self.left_panel.quest_tree.clearSelection()
        self._mark_as_clean()
        
        self.right_panel.clear()
        self.right_panel.title_label.setText("Tvorba nového questu *")
        self.right_panel.id.setText("<Automaticky>")
        self.current_quest_id = None
        
        self.right_panel.set_enabled(True)
        self.right_panel.delete_btn.setEnabled(False) # Nový quest nelze smazat (ještě neexistuje)
        self.right_panel.name.setFocus()

    def on_copy_quest(self):
        if not self._check_unsaved_changes(): return
        if not self.current_quest_id: return

        # Získáme data ze stávajícího formuláře (ne z DB, abychom zkopírovali i neuložené změny, pokud chceme)
        # Ale bezpečnější je často zkopírovat jen to co je v DB nebo ve formuláři.
        data = self.right_panel.get_data()
        if not data: return

        original_name = data.get('name', 'Quest')
        data['id'] = "<Automaticky>"
        data['name'] = f"{original_name} - KOPIE"

        self.left_panel.quest_tree.clearSelection()
        self.current_quest_id = None
        self._mark_as_clean()

        self.right_panel.set_data(data)
        self.right_panel.title_label.setText(f"Tvorba kopie: {original_name}")
        self.right_panel.set_enabled(True)
        self.right_panel.delete_btn.setEnabled(False)

    # --- Logika ukládání a DB ---
    def save_quest(self, confirmed=False):
        if not confirmed:
            name = self.right_panel.name.text() or "<bez názvu>"
            reply = QMessageBox.question(self, "Potvrzení", f"Opravdu uložit quest '{name}'?", 
                                         QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
            if reply == QMessageBox.StandardButton.No: return False

        data = self.right_panel.get_data()
        if not data: return False

        success, message, saved_id = self.db.save_quest(data, self.current_quest_id)
        if success:
            if not confirmed: QMessageBox.information(self, "Úspěch", message)
            self.current_quest_id = saved_id
            self._mark_as_clean()
            # Reload tree ale zachovat výběr?
            self.left_panel.reload_tree(current_quest_id=saved_id)
            return True
        else:
            if not confirmed: QMessageBox.critical(self, "Chyba", message)
            return False

    def delete_quest(self):
        if not self.current_quest_id: return
        if QMessageBox.question(self, "Potvrzení", f"Opravdu smazat quest ID {self.current_quest_id}?") == QMessageBox.StandardButton.Yes:
            if self.db.delete_quest(self.current_quest_id):
                self._mark_as_clean()
                self.right_panel.clear()
                self.right_panel.set_enabled(False)
                self.left_panel.reload_tree()

    def on_groups_changed(self):
        # Reload tree i combo boxu
        self.left_panel.reload_tree()
        self.right_panel.load_groups(self.db.get_quest_groups())

    # --- Dirty Logic ---
    def _mark_as_dirty(self):
        if self._is_dirty: return
        self._is_dirty = True
        
        # Obarvení stromu
        item = self.left_panel.quest_tree.currentItem()
        if item and item.data(0, Qt.ItemDataRole.UserRole) is not None:
            if not item.text(0).endswith("*"):
                item.setText(0, item.text(0) + " *")
                item.setForeground(0, Qt.GlobalColor.red)
        
        # Obarvení nadpisu
        txt = self.right_panel.title_label.text()
        if not txt.endswith("*"):
            self.right_panel.title_label.setText(txt + " *")
            self.right_panel.title_label.setStyleSheet("font-size: 22pt; font-weight: bold; color: #e74c3c; margin-bottom: 10px;")

    def _mark_as_clean(self):
        self._is_dirty = False
        
        # Obarvení stromu
        item = self.left_panel.quest_tree.currentItem()
        if item and item.data(0, Qt.ItemDataRole.UserRole) is not None:
            txt = item.text(0).rstrip(" *")
            item.setText(0, txt)
            item.setForeground(0, Qt.GlobalColor.white)
            
        # Obarvení nadpisu
        txt = self.right_panel.title_label.text().rstrip(" *")
        self.right_panel.title_label.setText(txt)
        self.right_panel.title_label.setStyleSheet("font-size: 22pt; font-weight: bold; color: #3498db; margin-bottom: 10px;")

    def _check_unsaved_changes(self):
        """Voláno z SafeTreeWidget (skrz referenci self) nebo při akcích."""
        if not self._is_dirty: return True
        reply = QMessageBox.question(self, "Neuložené změny", "Máte neuložené změny. Chcete je uložit?",
                                     QMessageBox.StandardButton.Save | QMessageBox.StandardButton.Discard | QMessageBox.StandardButton.Cancel)
        if reply == QMessageBox.StandardButton.Save: return self.save_quest(confirmed=True)
        elif reply == QMessageBox.StandardButton.Cancel: return False
        else: return True

    def show_quest_tree_window(self):
        # Lazy import aby se zabránilo circular importu pokud by tam byl
        from .quest_tree_widget import QuestTreeWidget
        self.quest_tree_window = QuestTreeWidget(self.db)
        self.quest_tree_window.generate_tree()
        self.quest_tree_window.show()