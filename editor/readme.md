### 🐍 Manuál k Editoru Questů (Python aplikace)

**Tento editor je desktopová aplikace pro snadnou a přehlednou správu questů v databázi, aniž byste museli psát SQL dotazy nebo editovat Lua soubory.**

---

#### 💻 **1. Požadavky a Instalace**

* **Nainstalujte Python:** **Pokud nemáte, stáhněte si a nainstalujte Python (doporučená verze 3.8 nebo novější).**
* **Nainstalujte potřebné knihovny:** **Otevřete příkazový řádek (CMD, PowerShell, Terminál) a spusťte následující příkaz:**

  **code**Code

  ```
  pip install PyQt6 pymysql passlib
  ```

---

#### 🔑 **2. První Spuštění a Nastavení**

* **Spuštění Editoru:**
* * **Spusťte soubor** **main.exe.**
* **Registrace a Přihlášení:**

  * **Při prvním spuštění se zobrazí přihlašovací okno. Klikněte na** **"Registrace"**.
  * **Vytvořte si účet.**
  * > **DŮLEŽITÉ:** **Po registraci musí administrátor databáze ručně nastavit vaše oprávnění. V tabulce** **web_users** **najděte svůj účet a změňte hodnotu ve sloupci** **perm** **z** **0** **na** **1** **(nebo vyšší). Bez toho se nepřihlásíte!**
    >
  * **Nyní se můžete přihlásit se svým účtem.**

---

#### 🎨 **3. Používání Editoru**

**Editor je rozdělen na dvě hlavní části:**

**Levý Panel - Seznam Questů:**

* **Zobrazuje všechny questy z databáze.**
* **Kliknutím na quest se jeho detaily načtou do pravého panelu.**
* **Tlačítko "Nový"**: Vyčistí formulář a připraví editor pro vytvoření nového questu.
* **Tlačítko "Kopírovat"**: Vytvoří kopii aktuálně vybraného questu. Ideální, pokud děláte podobné úkoly.

**Pravý Panel - Editace Questu:**
Obsahuje tři záložky pro přehlednou editaci:

* **Záložka "Obecné":**

  * **ID**: Zobrazeno, ale nelze měnit (přiřazuje se automaticky).
  * **Název**: Jméno questu.
  * **Popis**: Delší text s popisem.
  * **Aktivní**: Zaškrtávací políčko pro zapnutí/vypnutí questu.
  * **Opakovatelný**: Pokud je zaškrtnuto, hráč může quest dělat znovu.
  * **Požadované práce (JSON)**: Zde můžete omezit quest pro práce. Formát je pole objektů, např.: **[{"job": "police", "grade": 1}]**. Nechte prázdné pro všechny.
* **Záložka "Start":**

  * **Zde definujete, jak quest začíná. Pole odpovídají struktuře popsané v manuálu ke scriptu (Aktivace, Parametr, NPC model, Souřadnice, Text atd.).**
  * **Předměty a Eventy:** **Mají vlastní vizuální editory pro snadné přidávání/odebírání.**
* **Záložka "Cíl":**

  * **Zde definujete cíl a odměny. Pole opět odpovídají struktuře ze scriptu.**
  * **Navíc zde najdete pole** **Blip** **(ikona na mapě) a** **Peníze** **(finanční odměna).**

**Tlačítka dole:**

* **"Uložit Quest"**: Uloží aktuální změny (nebo vytvoří nový quest) do databáze.
* **"Smazat Quest"**: Trvale odstraní vybraný quest z databáze (požaduje potvrzení).

> **Tip:** **Po uložení změn v editoru je potřeba restartovat script** **aprts_simplequests** **na serveru, aby se změny projevily ve hře. Můžete si na to případně vytvořit admin příkaz, který zavolá funkci** **LoadQuests()** **na serveru.**

---


### ⚙️ Manuál k Editoru Questů - Detailní pohled na EVENTY

 **Tato část se zaměřuje na jednu z nejmocnějších funkcí quest systému:** **eventy**. Umožňují vám propojit questy s jakýmkoliv jiným scriptem na vašem serveru.

---

#### 🤔 **1. Co jsou Eventy a Proč je Používat?**

**Představte si eventy jako "dálkové ovladače". Když quest dosáhne určitého bodu (start nebo cíl), může "zmáčknout tlačítko" na ovladači. Jakýkoliv jiný script, který je naladěný na signál z tohoto tlačítka, provede nějakou akci.**

**K čemu je to dobré?**

* **Propojení s jinými scripty:** **Můžete spustit notifikaci, přehrát zvuk, zobrazit efekt na obrazovce, spustit animaci nebo třeba aktivovat cutscénu z úplně jiného scriptu.**
* **Vlastní herní logika:** **Můžete vytvořit vlastní, unikátní mechaniky. Například po dokončení questu se může změnit počasí, objevit se skupina nepřátel nebo se odemknout nová lokace.**
* **Modularita:** **Nemusíte psát veškerou logiku přímo do quest scriptu. Udržujete tak kód čistý a přehledný.**

---

#### 🛠️ **2. Jak funguje Editor Eventů?**

 **V editoru, v záložkách** **"Start"** **i** **"Cíl"**, najdete sekci "Eventy". Když kliknete na "Upravit", otevře se okno se třemi sloupci:

* **Typ**:
* **Server**: Event se spustí na straně serveru (**TriggerServerEvent**). Vhodné pro akce, které mají ovlivnit všechny hráče, zapisovat do databáze, nebo pracovat s chráněnými daty.
* **Client**: Event se spustí pouze u klienta (hráče), který quest plní (**TriggerEvent**). Ideální pro vizuální efekty, notifikace, zvuky a cokoliv, co má vidět jen daný hráč.
* **Název Eventu**:

  * **Přesný název eventu, který chcete spustit. Například** **notifications:notify**.
* **Argumenty**:

  * **Nejdůležitější část!** **Zde definujete, jaká data se eventu předají.**
* **Data musí být zapsána ve formátu** **JSON pole (listu)**. To znamená, že musí začínat **[** **a končit** **]**.
* **Jednotlivé argumenty se oddělují čárkou** **,**.
* **Text (string) musí být v uvozovkách** **" "**. Čísla a booleovské hodnoty (**true**, **false**) se píší bez uvozovek.

---

#### ✨ **3. Praktické Příklady z Vaší Databáze**

**Pojďme se podívat, jak jsou eventy použity ve vašich existujících questech a jak by to vypadalo v editoru.**

* **Cíl:** **Při přijetí úkolu se hráči ukáže vlastní notifikace ze scriptu** **notifications**.
* **Jak to funguje:** **Ve** **start_events** **máte nastavený klientský event.**

**Nastavení v editoru by vypadalo takto:**

| Typ                 | Název Eventu                       | Argumenty                                                           |
| :------------------ | :---------------------------------- | :------------------------------------------------------------------ |
| **Client** ** | ****notifications:notify** ** | ****["Hladový quest", "Začal jsi něco nového", 5000]** ** |

**Vysvětlení argumentů:**

* **"Hladový quest"**: První argument, který script pro notifikace použije jako nadpis.
* **"Začal jsi něco nového"**: Druhý argument, samotný text notifikace.
* **5000**: Třetí argument, doba zobrazení v milisekundách (5 sekund).

---

* **Cíl:** **Když hráč sní guláš (čímž spustí quest), dostane nějaký status efekt (např. "dobře najedený") ze scriptu** **aprts_consumable**.
* **Jak to funguje:** **Při startu questu (po použití itemu) se spustí klientský event.**

**Nastavení v editoru by vypadalo takto:**

| Typ                 | Název Eventu                                    | Argumenty               |
| :------------------ | :----------------------------------------------- | :---------------------- |
| **Client** ** | ****aprts_consumable:Client:setEffect** ** | ****[10, 20]** ** |

**Vysvětlení argumentů:**

* **10** **a** **20**: Toto jsou číselné argumenty. U **aprts_consumable** nastavuje **první číslo (**10**) je typ efektu a druhé (**20**) je jeho délka v sekundách. Toto ukazuje, jak můžete předávat i jiná data než jen text.**

---

* **Cíl:** **Chcete si zaznamenat do logu na serveru nebo spustit nějakou specifickou serverovou logiku, když hráč začne doručovací úkol.**
* **Jak to funguje:** **Ve** **start_events** **máte nastavený serverový event** **aprts_simplequests:server:startDeliveryQuest**.

**Nastavení v editoru by vypadalo takto:**

| Typ                 | Název Eventu                                               | Argumenty         |
| :------------------ | :---------------------------------------------------------- | :---------------- |
| **Server** ** | ****aprts_simplequests:server:startDeliveryQuest** ** | ****[]** ** |

**Vysvětlení:**
Tento event sám o sobě nic nedělá. Je to signál, na který můžete "napojit" jiný script. Někde jinde na serveru byste mohli mít kód, který na tento signál čeká:

**code**Lua

```
-- Vloženo v nějakém jiném serverovém scriptu
AddEventHandler('aprts_simplequests:server:startDeliveryQuest', function(source)
    local playerName = GetPlayerName(source)
    print(('[LOGS] Hráč %s právě přijal doručovací quest!'):format(playerName))
    -- Zde může být jakákoliv další logika...
end)
```

**Tímto způsobem jste propojili váš quest s úplně jinou částí serveru, aniž byste museli upravovat samotný quest script.**

> **Shrnutí:** **Systém eventů je extrémně flexibilní. Umožňuje vám spouštět téměř jakoukoliv akci, kterou váš server a jeho scripty podporují, a to vše pohodlně z jednoho místa v editoru. Stačí znát název eventu a argumenty, které očekává.**
>
