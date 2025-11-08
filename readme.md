### 📜 Manuál k **aprts_simplequests** **(In-Game Script)**

**Tento manuál popisuje, jak nastavit a pochopit herní script pro systém úkolů (questů) ve vašem RedM serveru.**

---

#### 🚀 **1. Instalace a Závislosti**

**Než začnete, ujistěte se, že máte na serveru nainstalované a spuštěné následující scripty, protože** **aprts_simplequests** **na nich závisí:**

* **@oxmysql**: Pro komunikaci s databází.
* **vorp_core**: Základní framework serveru.
* **vorp_inventory**: Pro práci s inventářem (dávání odměn).
* **notifications** **(nebo jiný script, který handle'uje event** **notifications:notify**).

**Postup:**

* **Vložte složku** **aprts_simplequests** **do vaší složky** **resources**.
* **Přidejte** **ensure aprts_simplequests** **do vašeho** **server.cfg** **(ujistěte se, že je** **za** **všemi výše uvedenými závislostmi).**

---

#### 💾 **2. Nastavení Databáze**

**Script potřebuje v databázi dvě tabulky. Spusťte následující SQL kód ve vaší databázi (např. přes HeidiSQL nebo Adminer), aby se vytvořily.**

**code**SQL

```
CREATE TABLE IF NOT EXISTS `aprts_simplequests_quests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `jobs` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`jobs`)),
  `repeatable` tinyint(1) NOT NULL DEFAULT 0,
  `start_activation` enum('talktoNPC','distance','useItem','clientEvent') DEFAULT NULL,
  `start_param` varchar(100) DEFAULT NULL,
  `start_npc` varchar(50) DEFAULT NULL,
  `start_coords` varchar(100) DEFAULT NULL,
  `start_text` varchar(255) DEFAULT NULL,
  `start_prompt` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_prompt`)),
  `start_items` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_items`)),
  `start_events` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_events`)),
  `target_activation` enum('talktoNPC','distance','useItem','clientEvent') DEFAULT NULL,
  `target_param` varchar(100) DEFAULT NULL,
  `target_npc` varchar(50) DEFAULT NULL,
  `target_blip` varchar(50) DEFAULT NULL,
  `target_coords` varchar(100) DEFAULT NULL,
  `target_text` varchar(255) DEFAULT NULL,
  `target_prompt` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_prompt`)),
  `target_items` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_items`)),
  `target_money` int(11) NOT NULL DEFAULT 0,
  `target_events` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_events`)),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `aprts_simplequests_char` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `charId` mediumint(8) unsigned NOT NULL,
  `questID` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```

---

#### 🔧 **3. Konfigurace (**config.lua**)**

**Tento soubor je srdcem nastavení. Zde je vysvětlení jednotlivých voleb:**

* **Config.Debug**: **true** **/** **false** **- Zapíná/vypíná výpisy do konzole pro ladění.**
* **Config.DST**: **1** **nebo** **2** **- Nastavení letního času (posun hodin).**
* **Config.GreenTimeStart** **/** **End**: **16** **/** **23** **- Hodina, od/do které platí "Green Time" (může být použito pro speciální logiku, momentálně se ve scriptu nepoužívá pro omezení questů).**
* **Config.ActiveTimeStart** **/** **End**: **23** **/** **3** **- Hodina, od/do které jsou některé herní mechaniky aktivní (opět se nepoužívá pro omezení questů, ale je k dispozici).**
* **Config.WebHook**: "" - URL adresa Discord webhooku pro posílání logů.
* **Config.Quests**: **{}** **-** **TUTO TABULKU NEUPRAVUJTE RUČNĚ!** **Script si ji načítá z databáze. Pro editaci questů použijte přiložený Python editor.**

---

#### 🧩 **4. Struktura Questu (pro pochopení)**

**Každý quest, načtený z databáze, má následující strukturu:**

**Základní Vlastnosti:**

* **id**: Unikátní číslo questu.
* **active**: **true**/**false** **- Zda je quest globálně aktivní.**
* **name**: Název questu.
* **description**: Popis, který může být zobrazen hráči.
* **jobs**: **nil** **nebo JSON pole. Omezuje quest jen pro určité práce. Příklad:** **[{ "job": "police", "grade": 1 }]**. **nil** **znamená, že je pro všechny.**
* **repeatable**: **true**/**false** **- Zda může hráč quest opakovat i po jeho dokončení.**

**Blok** **start** **(Jak quest začíná):**

* **activation**: Určuje, jak se quest spustí.

  * **talktoNPC**: Hráč musí přijít k NPC a interagovat s ním.
  * **distance**: Quest se spustí, jakmile hráč vstoupí do určité vzdálenosti.
  * **useItem**: Quest se spustí po použití specifického předmětu.
  * **clientEvent**: Quest se spustí po zavolání specifického eventu.
* **param**: Doplňující parametr pro aktivaci (název itemu, název eventu, vzdálenost v metrech).
* **NPC**: Model NPC, který se na místě spawne (např. **"a_m_m_middlesdtownfolk_01"**).
* **coords**: **vector4** **souřadnice (x, y, z, heading) pro NPC nebo pro aktivační zónu.**
* **text**: Text, který se hráči zobrazí v notifikaci při startu.
* **prompt**: Texty pro interakci (**text** **= co se ukáže u NPC,** **groupText** **= nadpis interakce).**
* **items**: Pole předmětů, které hráč dostane na začátku. Formát: **{ {name = "item_name", count = 1} }**.
* **events**: Eventy, které se spustí na startu (mohou být **server** **i** **client**).

**Blok** **target** **(Jak se quest dokončuje):**

* **activation**, **param**, **NPC**, **coords**, **text**, **prompt**: Fungují stejně jako v bloku **start**, ale definují cíl questu.
* **blip**: Název blipu (ikony) na mapě, která ukazuje na cíl (např. **"blip_bag_capture"**).
* **items**: Předměty, které hráč dostane jako odměnu.
* **money**: Finanční odměna.
* **events**: Eventy, které se spustí po dokončení.
