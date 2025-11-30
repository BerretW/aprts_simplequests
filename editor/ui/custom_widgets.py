# /Váš_Projekt/ui/custom_widgets.py

import re
import requests
import json
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLineEdit,
    QTableWidget, QTableWidgetItem, QPushButton, QSpinBox,
    QLabel, QHeaderView, QMessageBox, QDialog, QDialogButtonBox,
    QFormLayout, QComboBox, QListWidget, QListWidgetItem, QAbstractItemView,QTreeWidget
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QObject
from PyQt6.QtGui import QPixmap


class SafeListWidget(QListWidget):
    """
    QListWidget, který před změnou výběru zkontroluje neuložené změny
    v hlavním okně.
    """

    def __init__(self, main_window, parent=None):
        super().__init__(parent)
        self.main_window = main_window

    def mousePressEvent(self, event):
        # Než zpracujeme kliknutí myši, které by mohlo změnit položku...
        if not self.main_window._check_unsaved_changes():
            # ...pokud uživatel akci zrušil, ignorujeme toto kliknutí.
            return
        # Pokud je vše v pořádku, pokračujeme v normálním chování.
        super().mousePressEvent(event)

class SafeTreeWidget(QTreeWidget):
    """
    QTreeWidget, který před změnou výběru zkontroluje neuložené změny
    v hlavním okně.
    """
    def __init__(self, main_window, parent=None):
        super().__init__(parent)
        self.main_window = main_window
        self.setHeaderHidden(True) # Skryjeme hlavičku (sloupce)

    def mousePressEvent(self, event):
        # Získáme položku pod myší
        item = self.itemAt(event.position().toPoint())
        
        # Pokud klikáme do prázdna nebo na stejnou položku, chováme se standardně
        if not item:
            super().mousePressEvent(event)
            return

        # Pokud se pokoušíme změnit výběr na jinou položku
        if item != self.currentItem():
            # Zkontrolujeme neuložené změny
            if not self.main_window._check_unsaved_changes():
                # Uživatel dal "Cancel", ignorujeme kliknutí
                return
        
        # Vše ok, provedeme standardní akci
        super().mousePressEvent(event)

# --- Worker pro asynchronní načítání obrázků (beze změny) ---
class ImageLoader(QObject):
    image_loaded = pyqtSignal(int, QPixmap)

    def __init__(self, url, row, parent=None): super().__init__(
        parent); self.url = url; self.row = row

    def run(self):
        pixmap = QPixmap()
        try:
            response = requests.get(self.url, timeout=5)
            if response.status_code == 200:
                pixmap.loadFromData(response.content)
        except requests.exceptions.RequestException:
            pass
        self.image_loaded.emit(self.row, pixmap)

# --- Dialog pro výběr Itemu (beze změny) ---


class ItemSelectionDialog(QDialog):
    def __init__(self, all_items, parent=None):
        super().__init__(parent)
        self.all_items = all_items
        self.setWindowTitle("Vybrat předmět")
        self.setMinimumSize(400, 500)
        layout = QVBoxLayout(self)
        self.search_bar = QLineEdit()
        self.search_bar.setPlaceholderText("Hledat...")
        self.search_bar.textChanged.connect(self.filter_table)
        layout.addWidget(self.search_bar)
        self.table = QTableWidget()
        self.table.setColumnCount(2)
        self.table.setHorizontalHeaderLabels(["Název", "ID"])
        self.table.horizontalHeader().setSectionResizeMode(
            0, QHeaderView.ResizeMode.Stretch)
        self.table.setSelectionBehavior(
            QTableWidget.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.setSelectionMode(QTableWidget.SelectionMode.SingleSelection)
        self.table.itemDoubleClicked.connect(self.accept)
        layout.addWidget(self.table)
        btns = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        btns.accepted.connect(self.accept)
        btns.rejected.connect(self.reject)
        layout.addWidget(btns)
        self.populate_table()

    def populate_table(self):
        self.table.setRowCount(len(self.all_items))
        for row, item_data in enumerate(self.all_items):
            label_item = QTableWidgetItem(item_data['label'])
            name_item = QTableWidgetItem(item_data['item'])
            label_item.setData(Qt.ItemDataRole.UserRole, item_data)
            self.table.setItem(row, 0, label_item)
            self.table.setItem(row, 1, name_item)

    def filter_table(self, text):
        search_text = text.lower()
        for row in range(self.table.rowCount()):
            if search_text in self.table.item(row, 0).text().lower() or search_text in self.table.item(row, 1).text().lower():
                self.table.setRowHidden(row, False)
            else:
                self.table.setRowHidden(row, True)

    def get_selected_item(self):
        selected_rows = self.table.selectionModel().selectedRows()
        if not selected_rows:
            return None
        return self.table.item(selected_rows[0].row(), 0).data(Qt.ItemDataRole.UserRole)

# --- Widget pro editaci Promptu (beze změny) ---


class PromptWidget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QFormLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        self.text_edit = QLineEdit()
        self.group_text_edit = QLineEdit()
        layout.addRow("Text nápovědy:", self.text_edit)
        layout.addRow("Skupina nápovědy:", self.group_text_edit)

    def setData(self, data):
        self.clear()
        if data and isinstance(data, dict):
            self.text_edit.setText(data.get('text', ''))
            self.group_text_edit.setText(data.get('groupText', ''))

    def getData(self):
        text = self.text_edit.text()
        group_text = self.group_text_edit.text()
        if not text and not group_text:
            return None
        return {'text': text, 'groupText': group_text}

    def clear(self): self.text_edit.clear(); self.group_text_edit.clear()

# --- Widget pro editaci Itemů (beze změny) ---


class ItemsWidget(QWidget):
    def __init__(self, db_handler, image_base_url, parent=None):
        super().__init__(parent)
        self.db = db_handler
        self.image_base_url = image_base_url
        self.all_items_list = []
        self.active_threads = {}
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        controls_layout = QHBoxLayout()
        add_btn = QPushButton("Přidat předmět...")
        add_btn.clicked.connect(self.open_item_selection_dialog)
        remove_btn = QPushButton("Odebrat vybraný")
        remove_btn.clicked.connect(self.remove_item)
        controls_layout.addWidget(add_btn)
        controls_layout.addWidget(remove_btn)
        controls_layout.addStretch()
        main_layout.addLayout(controls_layout)
        self.table = QTableWidget()
        self.table.setColumnCount(4)
        self.table.setHorizontalHeaderLabels(
            ["Obrázek", "Název", "ID", "Počet"])
        self.table.horizontalHeader().setSectionResizeMode(
            1, QHeaderView.ResizeMode.Stretch)
        self.table.verticalHeader().setDefaultSectionSize(68)
        self.table.setColumnWidth(0, 68)
        self.table.setSelectionBehavior(
            QTableWidget.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        main_layout.addWidget(self.table)
        self.load_available_items()

    def load_available_items(
        self): self.all_items_list = self.db.get_available_items()

    def open_item_selection_dialog(self):
        dialog = ItemSelectionDialog(self.all_items_list, self)
        if dialog.exec():
            selected_item = dialog.get_selected_item()
            if selected_item:
                self.add_item_to_table(selected_item)

    def add_item_to_table(self, item_data, count=1):
        item_name = item_data['item']
        for row in range(self.table.rowCount()):
            if self.table.item(row, 2).text() == item_name:
                QMessageBox.warning(
                    self, "Duplikát", "Tento předmět je již v seznamu.")
                return
        row_pos = self.table.rowCount()
        self.table.insertRow(row_pos)
        image_label = QLabel("...")
        image_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.table.setCellWidget(row_pos, 0, image_label)
        self.table.setItem(row_pos, 1, QTableWidgetItem(item_data['label']))
        self.table.setItem(row_pos, 2, QTableWidgetItem(item_name))
        count_spinbox = QSpinBox()
        count_spinbox.setRange(1, 1000)
        count_spinbox.setValue(count)
        self.table.setCellWidget(row_pos, 3, count_spinbox)
        self.load_image_for_row(row_pos, item_name)

    def load_image_for_row(self, row, item_name):
        if row in self.active_threads and self.active_threads[row].isRunning():
            self.active_threads[row].quit()
            self.active_threads[row].wait()
        url = f"{self.image_base_url}{item_name}.png"
        thread = QThread()
        worker = ImageLoader(url, row)
        worker.moveToThread(thread)
        thread.started.connect(worker.run)
        worker.image_loaded.connect(self.set_image_in_table)
        worker.image_loaded.connect(thread.quit)
        worker.image_loaded.connect(worker.deleteLater)
        thread.finished.connect(thread.deleteLater)
        thread.start()
        self.active_threads[row] = thread

    def set_image_in_table(self, row, pixmap):
        widget = self.table.cellWidget(row, 0)
        if isinstance(widget, QLabel):
            if not pixmap.isNull():
                widget.setPixmap(pixmap.scaled(
                    64, 64, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation))
            else:
                widget.setText("N/A")

    def remove_item(self):
        current_row = self.table.currentRow()
        if current_row >= 0:
            self.table.removeRow(current_row)

    def setData(self, data):
        self.clear()
        if data and isinstance(data, list):
            item_map = {item['item']: item for item in self.all_items_list}
            for item in data:
                self.add_item_to_table(item_map.get(item.get('name'), {'item': item.get(
                    'name'), 'label': f"{item.get('name')} (nenalezen)"}), item.get('count', 1))

    def getData(self):
        items = [{'name': self.table.item(row, 2).text(), 'count': self.table.cellWidget(
            row, 3).value()} for row in range(self.table.rowCount())]
        return items if items else None

    def clear(self): self.table.setRowCount(0)

# --- Widget pro souřadnice (beze změny) ---


class CoordsLineEdit(QLineEdit):
    def __init__(self, parent=None): super().__init__(parent); self.setPlaceholderText(
        "např. vector4(x, y, z, w)"); self.editingFinished.connect(self.format_text)

    def format_text(self):
        current_text = super().text().strip()
        if not current_text:
            return
        match = re.search(r'vector[34]\((.*)\)', current_text, re.IGNORECASE)
        if match:
            self.setText(", ".join(re.findall(r'-?\d+\.?\d*', match.group(1))))

    def text(self): self.format_text(); return super().text()

# --- WIDGETY PRO EDITACI EVENTŮ (VÝRAZNĚ ZMĚNĚNO) ---


class SingleEventDialog(QDialog):
    """Dialog pro editaci JEDNOHO eventu a jeho argumentů (seznamu)."""

    def __init__(self, event_data=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Upravit Event")

        main_layout = QVBoxLayout(self)
        form_layout = QFormLayout()

        self.type_combo = QComboBox()
        self.type_combo.addItems(["server", "client"])
        self.name_edit = QLineEdit()
        form_layout.addRow("Typ:", self.type_combo)
        form_layout.addRow("Název:", self.name_edit)
        main_layout.addLayout(form_layout)

        main_layout.addWidget(QLabel("Argumenty (hodnoty v pořadí):"))

        # Argumenty a jejich tlačítka
        args_layout = QHBoxLayout()
        self.args_list = QListWidget()
        self.args_list.setAlternatingRowColors(True)
        args_layout.addWidget(self.args_list)

        args_btns_layout = QVBoxLayout()
        move_up_btn = QPushButton("↑ Nahoru")
        move_up_btn.clicked.connect(self.move_arg_up)
        move_down_btn = QPushButton("↓ Dolů")
        move_down_btn.clicked.connect(self.move_arg_down)
        args_btns_layout.addWidget(move_up_btn)
        args_btns_layout.addWidget(move_down_btn)
        args_btns_layout.addStretch()
        args_layout.addLayout(args_btns_layout)
        main_layout.addLayout(args_layout)

        # Přidání a úprava argumentů
        add_arg_layout = QHBoxLayout()
        self.new_arg_edit = QLineEdit()
        self.new_arg_edit.setPlaceholderText("Nová hodnota argumentu")
        add_arg_btn = QPushButton("Přidat")
        add_arg_btn.clicked.connect(self.add_arg)
        add_arg_layout.addWidget(self.new_arg_edit, 1)
        add_arg_layout.addWidget(add_arg_btn)
        main_layout.addLayout(add_arg_layout)

        control_btns_layout = QHBoxLayout()
        edit_arg_btn = QPushButton("Upravit vybraný")
        edit_arg_btn.clicked.connect(self.edit_arg)
        remove_arg_btn = QPushButton("Smazat vybraný")
        remove_arg_btn.clicked.connect(self.remove_arg)
        control_btns_layout.addStretch()
        control_btns_layout.addWidget(edit_arg_btn)
        control_btns_layout.addWidget(remove_arg_btn)
        main_layout.addLayout(control_btns_layout)

        # OK / Cancel
        dialog_btns = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        dialog_btns.accepted.connect(self.accept)
        dialog_btns.rejected.connect(self.reject)
        main_layout.addWidget(dialog_btns)

        if event_data:
            self.setData(event_data)

    def setData(self, data):
        self.type_combo.setCurrentText(data.get("type", "server"))
        self.name_edit.setText(data.get("name", ""))
        args = data.get("args", [])
        if isinstance(args, list):
            for value in args:
                # Snažíme se převést na string, aby to šlo zobrazit
                self.args_list.addItem(str(value))

    def add_arg(self):
        value = self.new_arg_edit.text()
        if value:
            self.args_list.addItem(value)
            self.new_arg_edit.clear()

    def edit_arg(self):
        selected_item = self.args_list.currentItem()
        if selected_item:
            selected_item.setFlags(selected_item.flags()
                                   | Qt.ItemFlag.ItemIsEditable)
            self.args_list.editItem(selected_item)

    def remove_arg(self):
        current_row = self.args_list.currentRow()
        if current_row >= 0:
            self.args_list.takeItem(current_row)

    def move_arg_up(self):
        current_row = self.args_list.currentRow()
        if current_row > 0:
            item = self.args_list.takeItem(current_row)
            self.args_list.insertItem(current_row - 1, item)
            self.args_list.setCurrentRow(current_row - 1)

    def move_arg_down(self):
        current_row = self.args_list.currentRow()
        if 0 <= current_row < self.args_list.count() - 1:
            item = self.args_list.takeItem(current_row)
            self.args_list.insertItem(current_row + 1, item)
            self.args_list.setCurrentRow(current_row + 1)

    def _try_convert_type(self, value_str):
        """Pokusí se převést string na číslo nebo boolean, pokud to jde."""
        value_str = value_str.strip()
        # Zkusíme int
        try:
            return int(value_str)
        except ValueError:
            pass
        # Zkusíme float
        try:
            return float(value_str)
        except ValueError:
            pass
        # Zkusíme boolean
        if value_str.lower() == 'true':
            return True
        if value_str.lower() == 'false':
            return False
        # Pokud nic, vrátíme string
        return value_str

    def getData(self):
        if not self.name_edit.text().strip():
            QMessageBox.warning(
                self, "Chyba", "Název eventu nesmí být prázdný.")
            return None

        args_list = []
        for i in range(self.args_list.count()):
            item_text = self.args_list.item(i).text()
            converted_value = self._try_convert_type(item_text)
            args_list.append(converted_value)

        return {
            "type": self.type_combo.currentText(),
            "name": self.name_edit.text().strip(),
            "args": args_list
        }

# --- Ostatní widgety pro eventy zůstávají stejné, ale nyní budou pracovat se seznamy ---


class EventsEditorDialog(QDialog):
    """Hlavní dialog pro správu seznamu eventů."""

    def __init__(self, events_data, parent=None):
        super().__init__(parent)
        self.events_data = json.loads(json.dumps(events_data)) if events_data else {
            "server": [], "client": []}
        self.setWindowTitle("Editor Eventů")
        self.setMinimumSize(500, 400)
        layout = QVBoxLayout(self)
        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(["Typ", "Název"])
        self.table.horizontalHeader().setSectionResizeMode(
            1, QHeaderView.ResizeMode.Stretch)
        self.table.setSelectionBehavior(
            QTableWidget.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.itemDoubleClicked.connect(self.edit_event)
        layout.addWidget(self.table)
        btns_layout = QHBoxLayout()
        add_btn = QPushButton("Přidat...")
        add_btn.clicked.connect(self.add_event)
        edit_btn = QPushButton("Upravit...")
        edit_btn.clicked.connect(self.edit_event)
        remove_btn = QPushButton("Smazat")
        remove_btn.clicked.connect(self.remove_event)
        btns_layout.addWidget(add_btn)
        btns_layout.addWidget(edit_btn)
        btns_layout.addWidget(remove_btn)
        layout.addLayout(btns_layout)
        dialog_btns = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        dialog_btns.accepted.connect(self.accept)
        dialog_btns.rejected.connect(self.reject)
        layout.addWidget(dialog_btns)
        self.populate_table()

    def populate_table(self):
        self.table.setRowCount(0)
        for event_type in ["server", "client"]:
            for event in self.events_data.get(event_type, []):
                row = self.table.rowCount()
                self.table.insertRow(row)
                name_item = QTableWidgetItem(event.get("name"))
                name_item.setData(Qt.ItemDataRole.UserRole,
                                  (event_type, event))
                self.table.setItem(row, 0, QTableWidgetItem(event_type))
                self.table.setItem(row, 1, name_item)

    def add_event(self):
        dialog = SingleEventDialog(parent=self)
        if dialog.exec():
            if new_data := dialog.getData():
                event_type = new_data.pop("type")
                self.events_data.setdefault(event_type, []).append(new_data)
                self.populate_table()

    def edit_event(self):
        if self.table.currentRow() < 0:
            return
        event_type, event_data = self.table.item(
            self.table.currentRow(), 1).data(Qt.ItemDataRole.UserRole)
        dialog = SingleEventDialog({**event_data, "type": event_type}, self)
        if dialog.exec():
            if updated_data := dialog.getData():
                new_type = updated_data.pop("type")
                if new_type != event_type:
                    self.events_data[event_type].remove(event_data)
                    self.events_data.setdefault(
                        new_type, []).append(updated_data)
                else:
                    event_data.update(updated_data)
                self.populate_table()

    def remove_event(self):
        if self.table.currentRow() < 0:
            return
        if QMessageBox.question(self, "Smazat event", "Opravdu chcete smazat tento event?") == QMessageBox.StandardButton.Yes:
            event_type, event_data = self.table.item(
                self.table.currentRow(), 1).data(Qt.ItemDataRole.UserRole)
            self.events_data[event_type].remove(event_data)
            self.populate_table()

    def getData(self): return self.events_data


class EventsWidget(QWidget):
    """Widget, který bude zobrazen na hlavním formuláři."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.events_data = {"server": [], "client": []}
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        self.summary_label = QLabel("Žádné eventy")
        edit_btn = QPushButton("Upravit eventy...")
        edit_btn.clicked.connect(self.open_editor)
        layout.addWidget(self.summary_label, 1)
        layout.addWidget(edit_btn)

    def open_editor(self):
        dialog = EventsEditorDialog(self.events_data, self)
        if dialog.exec():
            self.events_data = dialog.getData()
            self.update_summary()

    def setData(self, data):
        self.events_data = data if isinstance(data, dict) else {
            "server": [], "client": []}
        self.events_data.setdefault("server", [])
        self.events_data.setdefault("client", [])
        self.update_summary()

    def getData(self): return self.events_data if any(
        self.events_data.values()) else None

    def clear(self): self.setData(None)

    def update_summary(self):
        server_count = len(self.events_data.get("server", []))
        client_count = len(self.events_data.get("client", []))
        total = server_count + client_count
        self.summary_label.setText(
            f"Počet eventů: {total} (Server: {server_count}, Client: {client_count})" if total > 0 else "Žádné eventy")


class QuestSelectionDialog(QDialog):
    """
    Dialogové okno pro výběr předcházejících questů ze seznamu.
    """

    def __init__(self, db_handler, preselected_ids=None, parent=None):
        super().__init__(parent)
        self.db = db_handler
        if preselected_ids is None:
            preselected_ids = []

        self.setWindowTitle("Vyberte požadované splněné questy")
        self.setMinimumSize(400, 500)
        self.setModal(True)

        layout = QVBoxLayout(self)

        # Seznam pro zobrazení questů
        self.quest_list = QListWidget()
        # Povolíme výběr více položek pomocí Ctrl nebo Shift
        self.quest_list.setSelectionMode(
            QAbstractItemView.SelectionMode.MultiSelection)
        layout.addWidget(self.quest_list)

        # Tlačítka OK a Zrušit
        buttons = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

        # Naplníme seznam questy
        self.populate_quests()
        # Předvybereme již nastavené questy
        self.preselect_items(preselected_ids)

    def populate_quests(self):
        """Načte všechny questy z databáze a zobrazí je v seznamu."""
        all_quests = self.db.get_all_quests()
        for quest in all_quests:
            item = QListWidgetItem(f"{quest['id']}: {quest['name']}")
            item.setData(Qt.ItemDataRole.UserRole, quest['id'])
            self.quest_list.addItem(item)

    def preselect_items(self, ids_to_select):
        """Označí v seznamu questy, jejichž ID jsou v 'ids_to_select'."""
        id_set = set(ids_to_select)  # Použití setu pro rychlejší vyhledávání
        for i in range(self.quest_list.count()):
            item = self.quest_list.item(i)
            quest_id = item.data(Qt.ItemDataRole.UserRole)
            if quest_id in id_set:
                item.setSelected(True)

    def get_selected_ids(self):
        """Vrátí seznam ID všech vybraných questů."""
        selected_ids = []
        for item in self.quest_list.selectedItems():
            selected_ids.append(item.data(Qt.ItemDataRole.UserRole))
        return sorted(selected_ids)


class HoursSelectionDialog(QDialog):
    """Dialog pro výběr hodin (0-23)."""
    def __init__(self, selected_hours=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Vybrat otevírací hodiny")
        self.setModal(True)
        self.selected_hours = selected_hours if selected_hours is not None else list(range(24))
        
        layout = QVBoxLayout(self)
        
        # Grid pro checkboxy 0-23
        from PyQt6.QtWidgets import QGridLayout, QCheckBox
        grid = QGridLayout()
        self.checkboxes = []
        
        for hour in range(24):
            cb = QCheckBox(f"{hour:02d}:00")
            if hour in self.selected_hours:
                cb.setChecked(True)
            self.checkboxes.append(cb)
            # Rozložení: 4 řádky po 6 sloupcích
            row = hour // 6
            col = hour % 6
            grid.addWidget(cb, row, col)
            
        layout.addLayout(grid)
        
        # Rychlé volby
        quick_layout = QHBoxLayout()
        btn_all = QPushButton("Vše (0-23)")
        btn_all.clicked.connect(lambda: self.set_all(True))
        btn_none = QPushButton("Nic")
        btn_none.clicked.connect(lambda: self.set_all(False))
        btn_day = QPushButton("Den (6-22)")
        btn_day.clicked.connect(self.set_day)
        
        quick_layout.addWidget(btn_all)
        quick_layout.addWidget(btn_none)
        quick_layout.addWidget(btn_day)
        layout.addLayout(quick_layout)
        
        # Dialog tlačítka
        btns = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        btns.accepted.connect(self.accept)
        btns.rejected.connect(self.reject)
        layout.addWidget(btns)

    def set_all(self, state):
        for cb in self.checkboxes:
            cb.setChecked(state)

    def set_day(self):
        for i, cb in enumerate(self.checkboxes):
            # 6:00 až 21:59 (tedy hodiny 6..21, 22 už je "po") nebo 22 včetně? 
            # Obvykle Day je 6-22
            is_day = 6 <= i < 22
            cb.setChecked(is_day)

    def get_hours(self):
        hours = []
        for i, cb in enumerate(self.checkboxes):
            if cb.isChecked():
                hours.append(i)
        return hours

class HoursWidget(QWidget):
    """Widget pro zobrazení a editaci hodin v hlavním okně."""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.hours = list(range(24)) # Defaultně vše
        
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0,0,0,0)
        
        self.display = QLineEdit()
        self.display.setReadOnly(True)
        self.update_display()
        
        btn = QPushButton("Upravit...")
        btn.clicked.connect(self.open_dialog)
        
        layout.addWidget(self.display)
        layout.addWidget(btn)
        
    def open_dialog(self):
        dlg = HoursSelectionDialog(self.hours, self)
        if dlg.exec():
            self.hours = dlg.get_hours()
            self.update_display()
            # Emit changes for dirty tracker? 
            # QLineEdit change triggers dirty manually in main_window via display text change
            
    def update_display(self):
        if len(self.hours) == 24:
            self.display.setText("Nonstop (0-23)")
        elif len(self.hours) == 0:
            self.display.setText("Zavřeno")
        else:
            # Zjednodušený výpis
            self.display.setText(f"{len(self.hours)} hodin aktivní ({self.hours})")

    def setData(self, data):
        """Očekává seznam intů nebo JSON string."""
        if isinstance(data, str):
            try:
                data = json.loads(data)
            except:
                data = []
        
        if isinstance(data, list):
            self.hours = [int(h) for h in data]
        else:
            self.hours = list(range(24))
        self.update_display()

    def getData(self):
        return self.hours