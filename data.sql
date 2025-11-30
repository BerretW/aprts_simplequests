-- --------------------------------------------------------
-- Hostitel:                     192.168.88.21
-- Verze serveru:                11.7.2-MariaDB-ubu2404 - mariadb.org binary distribution
-- OS serveru:                   debian-linux-gnu
-- HeidiSQL Verze:               12.11.0.7065
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Exportování struktury pro tabulka database.aprts_simplequests_char
CREATE TABLE IF NOT EXISTS `aprts_simplequests_char` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `charId` mediumint(8) unsigned NOT NULL,
  `questID` smallint(5) unsigned NOT NULL,
  UNIQUE KEY `Index 1` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Exportování dat pro tabulku database.aprts_simplequests_char: ~5 rows (přibližně)
INSERT INTO `aprts_simplequests_char` (`id`, `charId`, `questID`) VALUES
	(5, 10084, 3),
	(6, 10084, 4),
	(8, 10447, 3),
	(11, 10447, 4),
	(12, 10447, 5);

-- Exportování struktury pro tabulka database.aprts_simplequests_groups
CREATE TABLE IF NOT EXISTS `aprts_simplequests_groups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT 'Questová linka',
  KEY `Index 1` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Exportování dat pro tabulku database.aprts_simplequests_groups: ~0 rows (přibližně)

-- Exportování struktury pro tabulka database.aprts_simplequests_quests
CREATE TABLE IF NOT EXISTS `aprts_simplequests_quests` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `groupid` int(10) unsigned NOT NULL DEFAULT 1,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `jobs` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`jobs`)),
  `bljobs` longtext DEFAULT NULL,
  `hoursOpen` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]' CHECK (json_valid(`hoursOpen`)),
  `repeatable` tinyint(1) NOT NULL DEFAULT 0,
  `start_activation` enum('talktoNPC','distance','useItem','clientEvent','prop') DEFAULT NULL,
  `start_param` varchar(100) DEFAULT NULL,
  `start_npc` varchar(50) DEFAULT NULL,
  `start_coords` varchar(100) DEFAULT NULL,
  `start_text` text DEFAULT NULL,
  `start_sound` varchar(255) DEFAULT NULL,
  `start_anim_dict` varchar(255) DEFAULT NULL,
  `start_anim_name` varchar(255) DEFAULT NULL,
  `start_prompt` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_prompt`)),
  `start_items` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_items`)),
  `start_events` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_events`)),
  `target_activation` enum('talktoNPC','distance','useItem','clientEvent','prop') DEFAULT NULL,
  `target_param` varchar(100) DEFAULT NULL,
  `target_npc` varchar(50) DEFAULT NULL,
  `target_blip` varchar(50) DEFAULT NULL,
  `target_coords` varchar(100) DEFAULT NULL,
  `target_text` text DEFAULT NULL,
  `target_sound` varchar(255) DEFAULT NULL,
  `target_anim_dict` varchar(255) DEFAULT NULL,
  `target_anim_name` varchar(255) DEFAULT NULL,
  `target_prompt` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_prompt`)),
  `target_items` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_items`)),
  `target_money` int(11) NOT NULL DEFAULT 0,
  `target_events` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_events`)),
  `complete_quests` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Exportování dat pro tabulku database.aprts_simplequests_quests: ~9 rows (přibližně)
INSERT INTO `aprts_simplequests_quests` (`id`, `groupid`, `active`, `name`, `description`, `jobs`, `bljobs`, `hoursOpen`, `repeatable`, `start_activation`, `start_param`, `start_npc`, `start_coords`, `start_text`, `start_sound`, `start_anim_dict`, `start_anim_name`, `start_prompt`, `start_items`, `start_events`, `target_activation`, `target_param`, `target_npc`, `target_blip`, `target_coords`, `target_text`, `target_sound`, `target_anim_dict`, `target_anim_name`, `target_prompt`, `target_items`, `target_money`, `target_events`, `complete_quests`) VALUES
	(1, 1, 0, 'DEMO Doručovací úkol', 'Doruč balíček na určené místo.', NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 0, 'talktoNPC', NULL, 'a_m_m_middlesdtownfolk_01', '2858.225342,-1354.093994,44.557438,152.488403', 'Tady máš gulášek dej si do nosu!', NULL, NULL, NULL, '{"text": "Přijmout", "groupText": "Ukoly od Karla"}', '[{"name": "food_muschgulas", "count": 1}]', '{"server": [{"name": "aprts_simplequests:server:startDeliveryQuest", "args": {}}], "client": [{"name": "notifications:notify", "args": ["Hladový quest", "Začal jsi něco nového", 5000]}]}', 'distance', NULL, 'a_m_m_middlesdtownfolk_01', 'blip_bag_capture', '2822.979736,-1377.657349,44.507278,290.667084', 'Snad ti chutnal pane. Tady máš ještě jeden gulášek.', NULL, NULL, NULL, '{"text": "Přinést balíček sem.", "groupText": "Ukoly od Karla"}', '[{"name": "food_muschgulas", "count": 1}]', 0, '{"server": [{"name": "aprts_simplequests:server:completeDeliveryQuest", "args": {}}], "client": [{"name": "aprts_simplequests:client:onDeliveryQuestComplete", "args": {}}]}', '[]'),
	(2, 1, 0, 'DEMO Nášup u Karla', 'Snědl jsi výborný guláš. Zajdi za Karlem a poděkuj mu.', NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 0, 'useItem', 'food_muschgulas', NULL, NULL, 'Mmm, to byl ale guláš! Měl bych zajít za Karlem a říct mu, jak mi chutnalo.', NULL, NULL, NULL, NULL, NULL, '{"server": [], "client": [{"name": "aprts_consumable:Client:setEffect", "args": [10, 20]}]}', 'talktoNPC', NULL, 's_m_m_valcowpoke_01', 'blip_bag_capture', '-222.500259,663.965332,113.324120,107.736641', 'Rád slyším, že ti chutnalo! Tady máš, přidej si. Čerstvá várka!', NULL, NULL, NULL, '{"text": "Poděkovat za guláš", "groupText": "Úkol od Karla"}', '[{"name": "food_sausage_with_eggs_n_bread", "count": 3}]', 5, NULL, '[]'),
	(3, 1, 1, 'Jsem tu nový #1', 'Prozkoumej město, je tu pár zajímavých míst a prodejců o kterých by jsi měl vědět.', NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 0, 'talktoNPC', '5', 'a_m_m_sddockforeman_01', '2858.255371,-1354.112061,44.557449,131.013397', 'No nazdar cizinče, starám se o to aby takový jako seš ty tu nepotkal úplně špatnej osud. Ale nebudu ti lhát už sem viděl i hezčí individua. Skoč si za Frankem, ukážu ti na mapě kde to je a něco se sebou udělej.', 'https://api.whrp.cz/storage/files/1762690998_4b0e944de96a3863fd5a5ccc5acadbf8.ogg', 'script_re@stalking_shadows', 'run_v1', '{"text": "Pokecat si", "groupText": "Náhodný občan"}', '[{"name": "food_carrot_cake", "count": 1}]', NULL, 'talktoNPC', NULL, 'cs_didsbury', '639638961', '2660.438477,-1176.828003,52.955887,275.613586', 'Tak přece si dorazil. Menuju se Frank, ale to už víš. Za těmahle dveřma je kadeřník, až budeš hotovej skoč za mnou, probereme trochu tvojí vizáž.', 'https://api.whrp.cz/storage/files/1762691025_da63325181694cb92fa5145153b05d4b.ogg', NULL, NULL, '{"text": "Vizáž", "groupText": "Frank Wuschon"}', NULL, 5, NULL, '[1, 2]'),
	(4, 1, 1, 'Jsem tu nový #2', 'Prozkoumej město, je tu pár zajímavých míst a prodejců o kterých by jsi měl vědět.', NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 0, 'talktoNPC', NULL, 'cs_didsbury', '2660.403809,-1177.144653,52.973949,273.152344', 'Tak tohle bychom měli. Pošlu tě teď za Thomasem, ten udělá něco s tím tvým oblečením.', 'https://api.whrp.cz/storage/files/1762691051_74fd10725964c814dbeb7ef803a0c3cf.ogg', NULL, NULL, '{"text": "Pokecat si", "groupText": "Frank Wuschon"}', NULL, NULL, 'talktoNPC', NULL, 'cs_exoticcollector', '639638961', '2555.113037,-1174.124390,53.482361,153.870178', 'A vy musíte bejt od pana Franka. Teď jděte prosím dovnitř monsieur a trochu líp se oblečte, na tohle se nedá koukat. Tady máte nějaké drobné a něco se sebou udělejte. Pak se vraťte prosím.', 'https://api.whrp.cz/storage/files/1762698304_be339e7bbbcae921c0aa8e12fd0f7d35.ogg', NULL, NULL, '{"text": "Frank mě za Váma posílá", "groupText": "Thomas DeGuier"}', NULL, 10, NULL, '[3]'),
	(5, 1, 1, 'Jsem tu nový #3', 'Prozkoumej město, je tu pár zajímavých míst a prodejců o kterých by jsi měl vědět.', NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 0, 'talktoNPC', NULL, 'cs_exoticcollector', '2555.113037,-1174.124390,53.482361,153.870178', 'No prosím, sice no... Ale tak monsieur mohlo to být i horší. Skočte si ke stájím, ukážu Vám cestu. Čeká tam na Vás pan Fussar, jen mu řekněte, že Vás posílám já.', 'https://api.whrp.cz/storage/files/1762698337_dc001101744aa8422278e5824d51cf0b.ogg', NULL, NULL, '{"text": "Pokecat si", "groupText": "Thomas DeGuier"}', NULL, NULL, 'talktoNPC', NULL, 'cs_fussar', '639638961', '2499.114502,-1434.547119,46.311893,83.276901', 'Ale, aleee koho si to Thomas vybral za "oblíbence", musels na něm zanechat dojem když tě posílá za mnou. Nechal pro tebe připravit koně. Neni to nic extra, ale pořád lepčí než chodit pěšky ne? Stájník ti ho zrovna připravuje, ale těkžo říct kdy s tím bude hotovej, klidně se prospi, chvíli to zabere.', 'https://api.whrp.cz/storage/files/1762698470_ddbb5b5768057365323e9f5f210cdf61.ogg', NULL, NULL, '{"text": "Jsem od Thomase", "groupText": "Fussar"}', '[{"name": "horse_treat", "count": 3}]', 0, '{"server": [{"name": "ss-stable-bettertraining:server:addHorse", "args": ["a_c_horse_winter02_01", "Grey", "Tury"]}], "client": []}', '[4]'),
	(7, 1, 1, 'Dno láhve a dno kufru #2', 'Získaj kontakt, ktorý ti predstaví alternatívny spôsob zarabania', NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 1, 'talktoNPC', NULL, 'mes_marston6_males_01', '2619.721680,-1357.928833,49.044025,130.287064', 'Teba posiela Kennedy? Konečne si tu. Potrebujem, aby si skočil do Van Hornu. Náš kontakt nám dal echo. Nejaký ital si sem nechal poslať loď s chlastom. Údajne chce ovládnuť trh alkoholom v Lemoyne. Hádam ti nemusím vysvetľovať, čo by to pre nás znamenalo. Tie bedne schováva v starej sheriffarni. Zbav sa ich, potom sa za mnou zastav a pobavíme sa o tvojej odmene. ', NULL, NULL, NULL, '{"text": "Hej ty, poď sem!", "groupText": "Dno láhve a dno kufru"}', NULL, NULL, 'talktoNPC', NULL, 're_darkalleyambush_males_01', NULL, '2966.766357,489.780823,46.238155,192.255280', 'Tak si tady, ty bedny sou v horním patře. Asi budeš potřebovat něco, čím to zničíš. Tady, vem si tohle. Až skončíš, ja zdržím stráže, ty se vrať za panem Goldsteinem. ', NULL, NULL, NULL, '{"text": "Ty jsi od Kennedyho?", "groupText": ""}', '[{"name": "tool_hammer", "count": 1}]', 0, NULL, NULL),
	(8, 1, 1, 'Dno láhve a dno kufru #3', NULL, NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 1, 'distance', '5', NULL, '2966.766357,489.780823,46.238155,192.255280', NULL, NULL, NULL, NULL, '{"text": "", "groupText": "Dno láhve a dno kufru"}', NULL, NULL, 'useItem', 'tool_hammer', NULL, NULL, '2972.394531,500.149628,48.452915,11.887978', NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, '[7]'),
	(9, 1, 1, 'Dno láhve a dno kufru #1', 'Získaj kontakt, ktorý ti predstaví alternatívny spôsob zarabania', NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL),
	(10, 1, 1, 'Dno láhve a dno kufru #3', NULL, NULL, NULL, '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]', 1, 'distance', '5', NULL, '2972.394531,500.149628,48.452915,11.887978', 'Vrať sa za Goldsteinem', NULL, NULL, NULL, NULL, NULL, NULL, 'talktoNPC', NULL, 'mes_marston6_males_01', NULL, '2619.721680,-1357.928833,49.044025,130.287064', 'Takže od Kennedyho?! Maš šťastie a dneska ťa nezastrelím. Ale čo s tebou... Hmmm... Nemam rád, keď ma niekto ojebáva. Ale potrebujem niekoho, kto sa nebojí riskovať svoju prdel. Dneska to však bolo zadarmo. Aspoň sa naučíš, že ma nemaš vodiť za nos. Každopádne mal by som pre teba nejakú prácu. Zastav sa za mnou po zotmení. Budem ťa čakať na nádraží. ', NULL, NULL, NULL, '{"text": "Promluvit s Goldsteinem", "groupText": ""}', NULL, 0, NULL, '[8]');

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
