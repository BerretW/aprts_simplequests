# editor/ui/quest_tree_widget.py

import json
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QPushButton, QGraphicsView, QGraphicsScene, 
    QGraphicsTextItem, QGraphicsRectItem, QGraphicsLineItem
)
from PyQt6.QtCore import Qt, QRectF, QPointF
from PyQt6.QtGui import QPen, QBrush, QColor

class QuestTreeWidget(QWidget):
    def __init__(self, db_handler, parent=None):
        super().__init__(parent)
        self.db = db_handler
        self.setWindowTitle("Strom posloupnosti questů")
        self.setGeometry(200, 200, 800, 600)

        layout = QVBoxLayout(self)

        # Tlačítko pro obnovení
        self.refresh_btn = QPushButton("Obnovit data")
        self.refresh_btn.clicked.connect(self.generate_tree)
        layout.addWidget(self.refresh_btn)

        # Plocha pro kreslení
        self.scene = QGraphicsScene()
        self.view = QGraphicsView(self.scene)
        self.view.setDragMode(QGraphicsView.DragMode.ScrollHandDrag) # Umožní posouvat pohled myší
        layout.addWidget(self.view)
    
    def generate_tree(self):
        self.scene.clear()
        
        # 1. Načteme všechna data
        quests = self.db.get_all_quests()
        if not quests:
            text = self.scene.addText("Žádné questy k zobrazení.")
            text.setDefaultTextColor(QColor("#ecf0f1"))
            return

        quest_data = {q['id']: {'name': q['name'], 'req': []} for q in quests}
        
        # 2. Vytvoříme závislosti
        all_quest_details = [self.db.get_quest_details(q['id']) for q in quests]
        for details in all_quest_details:
            if not details or not details.get('complete_quests'):
                continue
            try:
                req_ids = json.loads(details['complete_quests'])
                quest_data[details['id']]['req'] = req_ids
            except (json.JSONDecodeError, TypeError):
                continue

        # 3. Rozmístíme uzly (jednoduchý hierarchický layout)
        nodes = {}
        levels = {}
        
        # Najdeme úroveň každého uzlu
        def get_level(quest_id):
            if quest_id in levels:
                return levels[quest_id]
            
            reqs = quest_data[quest_id]['req']
            if not reqs:
                level = 0
            else:
                level = 1 + max(get_level(req_id) for req_id in reqs if req_id in quest_data)
            
            levels[quest_id] = level
            return level

        for q_id in quest_data:
            get_level(q_id)

        # Uspořádáme uzly do sloupců podle úrovně
        level_counts = {}
        for q_id, level in levels.items():
            x = level * 250  # Vzdálenost mezi sloupci
            y = level_counts.get(level, 0) * 100 # Vzdálenost mezi řádky
            nodes[q_id] = QPointF(x, y)
            level_counts[level] = level_counts.get(level, 0) + 1

        # 4. Vykreslíme uzly a hrany
        node_items = {}
        for q_id, pos in nodes.items():
            # Obdélník
            rect = QGraphicsRectItem(0, 0, 200, 50)
            rect.setPos(pos)
            rect.setBrush(QBrush(QColor("#34495e")))
            rect.setPen(QPen(QColor("#3498db"), 2))
            self.scene.addItem(rect)
            
            # Text
            text = QGraphicsTextItem(f"ID: {q_id}\n{quest_data[q_id]['name']}", rect)
            text.setDefaultTextColor(QColor("#ecf0f1"))
            text.setPos(5, 5)
            
            node_items[q_id] = rect

        # Hrany (šipky)
        for q_id, data in quest_data.items():
            for req_id in data['req']:
                if req_id not in node_items: continue
                
                start_item = node_items[req_id]
                end_item = node_items[q_id]
                
                start_pos = start_item.pos() + QPointF(start_item.rect().width(), start_item.rect().height() / 2)
                end_pos = end_item.pos() + QPointF(0, end_item.rect().height() / 2)
                
                line = QGraphicsLineItem(start_pos.x(), start_pos.y(), end_pos.x(), end_pos.y())
                line.setPen(QPen(QColor("#bdc3c7"), 1.5))
                self.scene.addItem(line)