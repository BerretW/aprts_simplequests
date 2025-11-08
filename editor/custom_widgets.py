# custom_widgets.py
import re
import requests
import json
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLineEdit,
    QTableWidget, QTableWidgetItem, QPushButton, QSpinBox,
    QLabel, QHeaderView, QMessageBox, QDialog, QDialogButtonBox,
    QFormLayout, QComboBox
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QObject
from PyQt6.QtGui import QPixmap

# --- Worker pro asynchronní načítání obrázků ---
class ImageLoader(QObject):
    image_loaded = pyqtSignal(int, QPixmap)
    def __init__(self, url, row, parent=None):
        super().__init__(parent)
        self.url = url
        self.row = row
    def run(self):
        pixmap = QPixmap()
        try:
            response = requests.get(self.url, timeout=5)
            if response.status_code == 200:
                pixmap.loadFromData(response.content)
        except requests.exceptions.RequestException:
            pass
        self.image_loaded.emit(self.row, pixmap)

# --- Dialog pro výběr Itemu ---
class ItemSelectionDialog(QDialog):
    def __init__(self, all_items, parent=None):
        super().__init__(parent)
        self.all_items = all_items
        self.setWindowTitle("Vybrat předmět")
        self.setMinimumSize(400, 500)
        layout = QVBoxLayout(self)
        self.search_bar = QLineEdit()
        self.search_bar.setPlaceholderText("Hledat podle názvu nebo ID...")
        self.search_bar.textChanged.connect(self.filter_table)
        layout.addWidget(self.search_bar)
        self.table = QTableWidget()
        self.table.setColumnCount(2)
        self.table.setHorizontalHeaderLabels(["Název", "ID"])
        self.table.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.setSelectionMode(QTableWidget.SelectionMode.SingleSelection)
        self.table.itemDoubleClicked.connect(self.accept)
        layout.addWidget(self.table)
        btns = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
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
            label_text = self.table.item(row, 0).text().lower()
            name_text = self.table.item(row, 1).text().lower()
            if search_text in label_text or search_text in name_text:
                self.table.setRowHidden(row, False)
            else:
                self.table.setRowHidden(row, True)
    def get_selected_item(self):
        selected_rows = self.table.selectionModel().selectedRows()
        if not selected_rows: return None
        selected_item_widget = self.table.item(selected_rows[0].row(), 0)
        return selected_item_widget.data(Qt.ItemDataRole.UserRole)

# --- Widget pro editaci Promptu ---
class PromptWidget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QFormLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        self.text_edit = QLineEdit(); self.group_text_edit = QLineEdit()
        layout.addRow("Text nápovědy:", self.text_edit)
        layout.addRow("Skupina nápovědy:", self.group_text_edit)
    def setData(self, data):
        self.clear()
        if data and isinstance(data, dict):
            self.text_edit.setText(data.get('text', ''))
            self.group_text_edit.setText(data.get('groupText', ''))
    def getData(self):
        text = self.text_edit.text(); group_text = self.group_text_edit.text()
        if not text and not group_text: return None
        return {'text': text, 'groupText': group_text}
    def clear(self):
        self.text_edit.clear(); self.group_text_edit.clear()

# --- Widget pro editaci Itemů ---
class ItemsWidget(QWidget):
    def __init__(self, db_handler, image_base_url, parent=None):
        super().__init__(parent)
        self.db = db_handler; self.image_base_url = image_base_url
        self.all_items_list = []; self.active_threads = {}
        main_layout = QVBoxLayout(self); main_layout.setContentsMargins(0, 0, 0, 0)
        controls_layout = QHBoxLayout()
        add_btn = QPushButton("Přidat předmět..."); add_btn.clicked.connect(self.open_item_selection_dialog)
        remove_btn = QPushButton("Odebrat vybraný"); remove_btn.clicked.connect(self.remove_item)
        controls_layout.addWidget(add_btn); controls_layout.addWidget(remove_btn); controls_layout.addStretch()
        main_layout.addLayout(controls_layout)
        self.table = QTableWidget(); self.table.setColumnCount(4)
        self.table.setHorizontalHeaderLabels(["Obrázek", "Název", "ID", "Počet"])
        self.table.horizontalHeader().setSectionResizeMode(1, QHeaderView.ResizeMode.Stretch)
        self.table.verticalHeader().setDefaultSectionSize(68); self.table.setColumnWidth(0, 68)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        main_layout.addWidget(self.table)
        self.load_available_items()
    def load_available_items(self): self.all_items_list = self.db.get_available_items()
    def open_item_selection_dialog(self):
        dialog = ItemSelectionDialog(self.all_items_list, self)
        if dialog.exec():
            selected_item = dialog.get_selected_item()
            if selected_item: self.add_item_to_table(selected_item)
    def add_item_to_table(self, item_data, count=1):
        item_name = item_data['item']
        for row in range(self.table.rowCount()):
            if self.table.item(row, 2).text() == item_name:
                QMessageBox.warning(self, "Duplikát", "Tento předmět je již v seznamu."); return
        row_position = self.table.rowCount(); self.table.insertRow(row_position)
        image_label = QLabel("..."); image_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.table.setCellWidget(row_position, 0, image_label)
        self.table.setItem(row_position, 1, QTableWidgetItem(item_data['label']))
        self.table.setItem(row_position, 2, QTableWidgetItem(item_name))
        count_spinbox = QSpinBox(); count_spinbox.setRange(1, 1000); count_spinbox.setValue(count)
        self.table.setCellWidget(row_position, 3, count_spinbox)
        self.load_image_for_row(row_position, item_name)
    def load_image_for_row(self, row, item_name):
        if row in self.active_threads and self.active_threads[row].isRunning():
            self.active_threads[row].quit(); self.active_threads[row].wait()
        url = f"{self.image_base_url}{item_name}.png"; thread = QThread()
        worker = ImageLoader(url, row); worker.moveToThread(thread)
        thread.started.connect(worker.run); worker.image_loaded.connect(self.set_image_in_table)
        worker.image_loaded.connect(thread.quit); worker.image_loaded.connect(worker.deleteLater)
        thread.finished.connect(thread.deleteLater); thread.start(); self.active_threads[row] = thread
    def set_image_in_table(self, row, pixmap):
        widget = self.table.cellWidget(row, 0)
        if isinstance(widget, QLabel):
            if not pixmap.isNull(): widget.setPixmap(pixmap.scaled(64, 64, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation))
            else: widget.setText("N/A")
    def remove_item(self):
        current_row = self.table.currentRow()
        if current_row >= 0: self.table.removeRow(current_row)
    def setData(self, data):
        self.clear()
        if data and isinstance(data, list):
            item_map = {item['item']: item for item in self.all_items_list}
            for item in data:
                item_name = item.get('name'); count = item.get('count', 1)
                item_data = item_map.get(item_name, {'item': item_name, 'label': f"{item_name} (nenalezen)"})
                self.add_item_to_table(item_data, count)
    def getData(self):
        items = []
        for row in range(self.table.rowCount()):
            items.append({'name': self.table.item(row, 2).text(), 'count': self.table.cellWidget(row, 3).value()})
        return items if items else None
    def clear(self): self.table.setRowCount(0)

# --- Widget pro souřadnice ---
class CoordsLineEdit(QLineEdit):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setPlaceholderText("např. vector4(x, y, z, w)")
        self.editingFinished.connect(self.format_text)
    def format_text(self):
        current_text = super().text().strip()
        if not current_text: return
        match = re.search(r'vector[34]\((.*)\)', current_text, re.IGNORECASE)
        if match:
            coords_part = match.group(1)
            numbers = re.findall(r'-?\d+\.?\d*', coords_part)
            formatted_coords = ", ".join(numbers)
            self.setText(formatted_coords)
    def text(self):
        self.format_text()
        return super().text()

# --- NOVÉ WIDGETY PRO EDITACI EVENTŮ ---

class SingleEventDialog(QDialog):
    """Dialog pro editaci JEDNOHO eventu a jeho argumentů."""
    def __init__(self, event_data=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Upravit Event")
        
        layout = QVBoxLayout(self)
        form_layout = QFormLayout()
        
        self.type_combo = QComboBox(); self.type_combo.addItems(["server", "client"])
        self.name_edit = QLineEdit()
        form_layout.addRow("Typ:", self.type_combo)
        form_layout.addRow("Název:", self.name_edit)
        layout.addLayout(form_layout)
        
        layout.addWidget(QLabel("Argumenty:"))
        self.args_table = QTableWidget(0, 2)
        self.args_table.setHorizontalHeaderLabels(["Klíč", "Hodnota"])
        self.args_table.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
        self.args_table.horizontalHeader().setSectionResizeMode(1, QHeaderView.ResizeMode.Stretch)
        layout.addWidget(self.args_table)

        args_btns_layout = QHBoxLayout()
        add_arg_btn = QPushButton("Přidat argument"); add_arg_btn.clicked.connect(self.add_arg_row)
        remove_arg_btn = QPushButton("Smazat argument"); remove_arg_btn.clicked.connect(self.remove_arg_row)
        args_btns_layout.addWidget(add_arg_btn); args_btns_layout.addWidget(remove_arg_btn)
        layout.addLayout(args_btns_layout)

        dialog_btns = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        dialog_btns.accepted.connect(self.accept); dialog_btns.rejected.connect(self.reject)
        layout.addWidget(dialog_btns)
        
        if event_data: self.setData(event_data)

    def setData(self, data):
        self.type_combo.setCurrentText(data.get("type", "server"))
        self.name_edit.setText(data.get("name", ""))
        args = data.get("args", {})
        if isinstance(args, dict):
            for key, value in args.items():
                self.add_arg_row(key, str(value))

    def add_arg_row(self, key="", value=""):
        row = self.args_table.rowCount()
        self.args_table.insertRow(row)
        self.args_table.setItem(row, 0, QTableWidgetItem(key))
        self.args_table.setItem(row, 1, QTableWidgetItem(value))

    def remove_arg_row(self):
        current_row = self.args_table.currentRow()
        if current_row >= 0: self.args_table.removeRow(current_row)
        
    def getData(self):
        if not self.name_edit.text().strip():
            QMessageBox.warning(self, "Chyba", "Název eventu nesmí být prázdný.")
            return None
        
        args_dict = {}
        for row in range(self.args_table.rowCount()):
            key_item = self.args_table.item(row, 0)
            value_item = self.args_table.item(row, 1)
            if key_item and value_item and key_item.text().strip():
                args_dict[key_item.text().strip()] = value_item.text()

        return {
            "type": self.type_combo.currentText(),
            "name": self.name_edit.text().strip(),
            "args": args_dict
        }

class EventsEditorDialog(QDialog):
    """Hlavní dialog pro správu seznamu eventů."""
    def __init__(self, events_data, parent=None):
        super().__init__(parent)
        # Pracujeme s kopií, abychom mohli zrušit změny
        self.events_data = json.loads(json.dumps(events_data)) if events_data else {"server": [], "client": []}
        
        self.setWindowTitle("Editor Eventů")
        self.setMinimumSize(500, 400)
        layout = QVBoxLayout(self)

        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(["Typ", "Název"])
        self.table.horizontalHeader().setSectionResizeMode(1, QHeaderView.ResizeMode.Stretch)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.itemDoubleClicked.connect(self.edit_event)
        layout.addWidget(self.table)
        
        btns_layout = QHBoxLayout()
        add_btn = QPushButton("Přidat..."); add_btn.clicked.connect(self.add_event)
        edit_btn = QPushButton("Upravit..."); edit_btn.clicked.connect(self.edit_event)
        remove_btn = QPushButton("Smazat"); remove_btn.clicked.connect(self.remove_event)
        btns_layout.addWidget(add_btn); btns_layout.addWidget(edit_btn); btns_layout.addWidget(remove_btn)
        layout.addLayout(btns_layout)

        dialog_btns = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        dialog_btns.accepted.connect(self.accept); dialog_btns.rejected.connect(self.reject)
        layout.addWidget(dialog_btns)
        
        self.populate_table()

    def populate_table(self):
        self.table.setRowCount(0)
        for event_type in ["server", "client"]:
            if event_type in self.events_data:
                for event in self.events_data[event_type]:
                    row = self.table.rowCount()
                    self.table.insertRow(row)
                    type_item = QTableWidgetItem(event_type)
                    name_item = QTableWidgetItem(event.get("name"))
                    # Uložíme si celý event a jeho typ pro snadnou editaci
                    name_item.setData(Qt.ItemDataRole.UserRole, (event_type, event))
                    self.table.setItem(row, 0, type_item)
                    self.table.setItem(row, 1, name_item)

    def add_event(self):
        dialog = SingleEventDialog(parent=self)
        if dialog.exec():
            new_data = dialog.getData()
            if new_data:
                event_type = new_data.pop("type")
                if event_type not in self.events_data:
                    self.events_data[event_type] = []
                self.events_data[event_type].append(new_data)
                self.populate_table()

    def edit_event(self):
        current_row = self.table.currentRow()
        if current_row < 0: return
        
        item = self.table.item(current_row, 1)
        event_type, event_data = item.data(Qt.ItemDataRole.UserRole)
        # Přidáme typ zpět do dat pro dialog
        event_data_with_type = event_data.copy()
        event_data_with_type["type"] = event_type
        
        dialog = SingleEventDialog(event_data_with_type, self)
        if dialog.exec():
            updated_data = dialog.getData()
            if updated_data:
                new_type = updated_data.pop("type")
                # Pokud se změnil typ, musíme ho přesunout
                if new_type != event_type:
                    self.events_data[event_type].remove(event_data)
                    if new_type not in self.events_data: self.events_data[new_type] = []
                    self.events_data[new_type].append(updated_data)
                else: # Jinak jen aktualizujeme data na místě
                    event_data.update(updated_data)
                self.populate_table()

    def remove_event(self):
        current_row = self.table.currentRow()
        if current_row < 0: return
        
        reply = QMessageBox.question(self, "Smazat event", "Opravdu chcete smazat tento event?", QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No, QMessageBox.StandardButton.No)
        if reply == QMessageBox.StandardButton.Yes:
            item = self.table.item(current_row, 1)
            event_type, event_data = item.data(Qt.ItemDataRole.UserRole)
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
        self.events_data = data if data and isinstance(data, dict) else {"server": [], "client": []}
        if "server" not in self.events_data: self.events_data["server"] = []
        if "client" not in self.events_data: self.events_data["client"] = []
        self.update_summary()

    def getData(self):
        # Pokud nejsou žádné eventy, vrátíme None, aby se do DB neukládal prázdný objekt
        if not self.events_data.get("server") and not self.events_data.get("client"):
            return None
        return self.events_data

    def clear(self):
        self.setData(None)

    def update_summary(self):
        server_count = len(self.events_data.get("server", []))
        client_count = len(self.events_data.get("client", []))
        total = server_count + client_count
        if total == 0:
            self.summary_label.setText("Žádné eventy")
        else:
            self.summary_label.setText(f"Počet eventů: {total} (Server: {server_count}, Client: {client_count})")