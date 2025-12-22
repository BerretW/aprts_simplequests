# editor/ui/panels/left_panel.py

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLabel, 
    QTreeWidgetItem, QInputDialog, QMessageBox
)
from PyQt6.QtCore import Qt, pyqtSignal

from ..custom_widgets import SafeTreeWidget

class QuestListPanel(QWidget):
    # Signály pro komunikaci s hlavním oknem
    quest_selected = pyqtSignal(object, object) # current_item, previous_item
    new_quest_requested = pyqtSignal()
    copy_quest_requested = pyqtSignal()
    show_tree_viz_requested = pyqtSignal()
    
    # Signály pro změny v DB, které musí řešit hlavní okno (reload)
    group_changed = pyqtSignal() 

    def __init__(self, db_handler, main_window_ref, parent=None):
        super().__init__(parent)
        self.db = db_handler
        self.main_window = main_window_ref # Reference pro SafeTreeWidget
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout(self)

        # Vizualizace stromu
        tree_btn = QPushButton("Zobrazit graf posloupnosti")
        tree_btn.clicked.connect(self.show_tree_viz_requested.emit)
        layout.addWidget(tree_btn)

        layout.addWidget(QLabel("Seznam Questů"))

        # Strom questů
        self.quest_tree = SafeTreeWidget(main_window=self.main_window)
        self.quest_tree.currentItemChanged.connect(self.on_item_changed)
        layout.addWidget(self.quest_tree)

        # Tlačítka Questy
        q_btns = QHBoxLayout()
        self.new_quest_btn = QPushButton("Nový Quest")
        self.new_quest_btn.clicked.connect(self.new_quest_requested.emit)
        
        self.copy_quest_btn = QPushButton("Kopírovat")
        self.copy_quest_btn.clicked.connect(self.copy_quest_requested.emit)
        self.copy_quest_btn.setEnabled(False)
        
        q_btns.addWidget(self.new_quest_btn)
        q_btns.addWidget(self.copy_quest_btn)
        layout.addLayout(q_btns)

        # Tlačítka Skupiny
        layout.addWidget(QLabel("Správa skupin:"))
        g_btns = QHBoxLayout()
        
        self.new_group_btn = QPushButton("Nová")
        self.new_group_btn.clicked.connect(self.create_group)
        
        self.rename_group_btn = QPushButton("Přejmenovat")
        self.rename_group_btn.clicked.connect(self.rename_group)
        self.rename_group_btn.setEnabled(False)
        
        self.del_group_btn = QPushButton("Smazat")
        self.del_group_btn.clicked.connect(self.delete_group)
        self.del_group_btn.setStyleSheet("background-color: #c0392b;")
        self.del_group_btn.setEnabled(False)

        g_btns.addWidget(self.new_group_btn)
        g_btns.addWidget(self.rename_group_btn)
        g_btns.addWidget(self.del_group_btn)
        layout.addLayout(g_btns)

    def on_item_changed(self, current, previous):
        # Logika tlačítek
        if not current:
            self.copy_quest_btn.setEnabled(False)
            self.rename_group_btn.setEnabled(False)
            self.del_group_btn.setEnabled(False)
        else:
            quest_id = current.data(0, Qt.ItemDataRole.UserRole)
            group_id = current.data(0, Qt.ItemDataRole.UserRole + 1)
            
            # Je to quest?
            if quest_id is not None:
                self.copy_quest_btn.setEnabled(True)
                self.rename_group_btn.setEnabled(False)
                self.del_group_btn.setEnabled(False)
            # Je to skupina?
            elif group_id and group_id > 0:
                self.copy_quest_btn.setEnabled(False)
                self.rename_group_btn.setEnabled(True)
                self.del_group_btn.setEnabled(True)
            else:
                self.copy_quest_btn.setEnabled(False)
        
        # Předání výš
        self.quest_selected.emit(current, previous)

    def reload_tree(self, current_quest_id=None):
        """Načte data z DB a překreslí strom."""
        # Uložení stavu expanded
        expanded_groups = set()
        for i in range(self.quest_tree.topLevelItemCount()):
            item = self.quest_tree.topLevelItem(i)
            if item.isExpanded():
                group_id = item.data(0, Qt.ItemDataRole.UserRole + 1)
                if group_id: expanded_groups.add(group_id)

        self.quest_tree.clear()
        quest_groups = self.db.get_quest_groups()
        group_items = {}

        # 1. Vytvoření skupin
        for grp in quest_groups:
            grp_item = QTreeWidgetItem([grp['name']])
            grp_item.setData(0, Qt.ItemDataRole.UserRole, None)
            grp_item.setData(0, Qt.ItemDataRole.UserRole + 1, grp['id'])
            font = grp_item.font(0); font.setBold(True); grp_item.setFont(0, font)
            
            if grp['id'] in expanded_groups: grp_item.setExpanded(True)
            else: grp_item.setExpanded(True)
            
            self.quest_tree.addTopLevelItem(grp_item)
            group_items[grp['id']] = grp_item

        # 2. Vytvoření questů
        unknown_group_item = None
        item_to_select = None
        quests = self.db.get_all_quests()

        for quest in quests:
            grp_id = quest.get('groupid')
            parent_item = group_items.get(grp_id)

            if not parent_item:
                if not unknown_group_item:
                    unknown_group_item = QTreeWidgetItem(["Nezařazeno"])
                    unknown_group_item.setData(0, Qt.ItemDataRole.UserRole, None)
                    unknown_group_item.setData(0, Qt.ItemDataRole.UserRole + 1, 0)
                    unknown_group_item.setExpanded(True)
                    self.quest_tree.addTopLevelItem(unknown_group_item)
                parent_item = unknown_group_item

            quest_item = QTreeWidgetItem([f"{quest['id']}: {quest['name']}"])
            quest_item.setData(0, Qt.ItemDataRole.UserRole, quest['id'])
            parent_item.addChild(quest_item)
            
            if quest['id'] == current_quest_id:
                item_to_select = quest_item

        # 3. Aktualizace počtů
        for grp_item in group_items.values():
            grp_item.setText(0, f"{grp_item.text(0)} ({grp_item.childCount()})")
        if unknown_group_item:
            unknown_group_item.setText(0, f"{unknown_group_item.text(0)} ({unknown_group_item.childCount()})")

        # 4. Výběr
        if item_to_select:
            self.quest_tree.setCurrentItem(item_to_select)
        else:
            self.quest_tree.clearSelection()

    # --- Group Logic ---
    def create_group(self):
        text, ok = QInputDialog.getText(self, "Nová skupina", "Zadejte název nové skupiny:")
        if ok and text:
            success, result = self.db.add_group(text.strip())
            if success:
                self.group_changed.emit()
            else:
                QMessageBox.critical(self, "Chyba", f"Nepodařilo se vytvořit skupinu: {result}")

    def rename_group(self):
        item = self.quest_tree.currentItem()
        if not item: return
        group_id = item.data(0, Qt.ItemDataRole.UserRole + 1)
        old_name = item.text(0).split(' (')[0]
        text, ok = QInputDialog.getText(self, "Přejmenovat skupinu", "Nový název:", text=old_name)
        if ok and text:
            success, msg = self.db.rename_group(group_id, text.strip())
            if success: self.group_changed.emit()
            else: QMessageBox.critical(self, "Chyba", msg)

    def delete_group(self):
        item = self.quest_tree.currentItem()
        if not item: return
        group_id = item.data(0, Qt.ItemDataRole.UserRole + 1)
        if group_id == 1: 
            QMessageBox.warning(self, "Chyba", "Nelze smazat defaultní skupinu.")
            return
        
        if QMessageBox.question(self, "Smazat", f"Opravdu smazat skupinu?") == QMessageBox.StandardButton.Yes:
            success, msg = self.db.delete_group(group_id)
            if success: self.group_changed.emit()
            else: QMessageBox.critical(self, "Chyba", msg)