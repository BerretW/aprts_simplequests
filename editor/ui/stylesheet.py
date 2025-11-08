# /Váš_Projekt/ui/stylesheet.py

STYLESHEET = """
/* Základní styl okna */
QWidget {
    background-color: #2c3e50; /* Tmavě modro-šedá */
    color: #ecf0f1; /* Světle šedá */
    font-size: 10pt;
}

/* Tlačítka */
QPushButton {
    background-color: #3498db; /* Světle modrá */
    color: white;
    border: 1px solid #2980b9;
    padding: 8px 12px;
    border-radius: 4px;
    font-weight: bold;
}
QPushButton:hover {
    background-color: #2980b9; /* Tmavší modrá při najetí */
}
QPushButton:pressed {
    background-color: #1f618d;
}
QPushButton:disabled {
    background-color: #566573;
    color: #99A3A4;
    border-color: #424949;
}


/* Vstupní pole */
QLineEdit, QTextEdit, QSpinBox, QComboBox {
    background-color: #34495e; /* Tmavší modro-šedá */
    border: 1px solid #566573;
    border-radius: 4px;
    padding: 5px;
    color: #ecf0f1;
}
QLineEdit:focus, QTextEdit:focus, QSpinBox:focus, QComboBox:focus {
    border-color: #3498db; /* Zvýraznění při fokusu */
}

/* ComboBox rozbalovací šipka */
QComboBox::drop-down {
    border: 0px;
}
QComboBox::down-arrow {
    image: url(./ui/down_arrow.png); /* Ujistěte se, že máte tento obrázek, nebo řádek smažte */
    width: 14px;
    height: 14px;
}
QComboBox QAbstractItemView { /* Rozbalovací menu */
    background-color: #34495e;
    selection-background-color: #3498db;
    border: 1px solid #566573;
}


/* Seznam questů */
QListWidget {
    background-color: #34495e;
    border: 1px solid #566573;
    border-radius: 4px;
}
QListWidget::item {
    padding: 8px;
}
QListWidget::item:selected {
    background-color: #3498db;
    color: white;
}
QListWidget::item:hover {
    background-color: #4e6a85;
}


/* Tabulky */
QTableWidget {
    background-color: #34495e;
    border: 1px solid #566573;
    gridline-color: #566573;
}
QHeaderView::section {
    background-color: #2c3e50;
    padding: 4px;
    border: 1px solid #566573;
    font-weight: bold;
}
QTableWidget::item:selected {
    background-color: #3498db;
    color: white;
}


/* Záložky */
QTabWidget::pane {
    border: 1px solid #566573;
    border-top: none;
}
QTabBar::tab {
    background-color: #2c3e50;
    border: 1px solid #566573;
    border-bottom: none;
    padding: 8px 20px;
    border-top-left-radius: 4px;
    border-top-right-radius: 4px;
}
QTabBar::tab:selected {
    background-color: #34495e;
    margin-bottom: -1px; /* Posune tab, aby vypadal spojeně s panelem */
}
QTabBar::tab:hover {
    background-color: #4e6a85;
}

/* Scrollbary */
QScrollBar:vertical {
    border: none;
    background: #34495e;
    width: 12px;
    margin: 0px;
}
QScrollBar::handle:vertical {
    background: #566573;
    min-height: 20px;
    border-radius: 6px;
}
QScrollBar::handle:vertical:hover {
    background: #7F8C8D;
}
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
    height: 0px;
}
QScrollBar:horizontal {
    border: none;
    background: #34495e;
    height: 12px;
    margin: 0px;
}
QScrollBar::handle:horizontal {
    background: #566573;
    min-width: 20px;
    border-radius: 6px;
}
QScrollBar::handle:horizontal:hover {
    background: #7F8C8D;
}
QScrollBar::add-line:horizontal, QScrollBar::sub-line:horizontal {
    width: 0px;
}


/* Splitter */
QSplitter::handle {
    background: #566573;
}
QSplitter::handle:horizontal {
    width: 4px;
}
QSplitter::handle:vertical {
    height: 4px;
}
"""