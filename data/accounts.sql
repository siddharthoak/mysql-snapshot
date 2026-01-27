-- MySQL dump 10.13  Distrib 8.0.42, for macos15 (arm64)
--
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `accounts`
--
/*!40101 SET character_set_client = @OLD_CHARACTER_SET_CLIENT */;

--
-- Dumping data for table `accounts`
--

LOCK TABLES `accounts` WRITE;
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
-- INSERT INTO `accounts` VALUES (_binary '\0�}k�M��\�\�\�*���',4,_binary '>Eg\�ӤVBf@','Everyday Checking','depository','AUTO',13240.00,'2025-10-17 06:21:09','2025-10-17 06:21:09','mvEQawk6neHB9GeEoQQkiPQyWAeje9cgQe383','checking'),(_binary '@\�lG�\�~燆*\�',4,_binary '>Eg\�ӤVBf@','High Yield Savings','depository','AUTO',61250.00,'2025-10-17 06:21:09','2025-10-17 06:21:09','ywBGDRe6nacgkaJ9Exx3UL9XKg1r1lf48PvpL','savings'),(_binary '	-|ڪK-��\�<[t',2,_binary '>Eg\�ӤVBf@\0','Mortgage','loan','AUTO',368828.00,'2025-10-17 06:15:34','2025-10-17 06:15:34','wdnpBajjJ1uQ1MNv66EdFp8mVAxj64FPXznEL','mortgage'),(_binary '_`�h�^H��8�\�m|q�',4,_binary '>Eg\�ӤVBf@','Student Loan','loan','AUTO',25000.00,'2025-10-17 06:21:09','2025-10-17 06:21:09','RqbWZA5lDeuLlvyQKbbATrBV7eDmDJcaoN15e','student'),(_binary '|\nDaeD\�\\\�*�f�',3,_binary '>Eg\�ӤVBf@','Rewards Credit Card','credit_card','AUTO',1350.00,'2025-10-17 06:19:50','2025-10-17 06:19:50','g1lmnJoXlbfejy6ykLMoUXkL5MDLZeuE7g7Wv','credit card'),(_binary '��\�bA\�C.�r��\�',2,_binary '>Eg\�ӤVBf@\0','Rewards Credit Card','credit_card','AUTO',1260.00,'2025-10-17 06:15:34','2025-10-17 06:15:34','VdRQ8P55rmunepEqNNd4tKg9rvnBbQF9MQGqn','credit card'),(_binary '��֊�JG�\�t\�\�&\�',4,_binary '>Eg\�ӤVBf@','Chase Sapphire Preferred','credit_card','AUTO',1425.00,'2025-10-17 06:21:09','2025-10-17 06:21:09','9JBq5jAoEvhWQvXN7jjoTK3okG6N6lS49oJM7','credit card'),(_binary '���vC���\�p\�A',4,_binary '>Eg\�ӤVBf@','Mortgage','loan','AUTO',384500.00,'2025-10-17 06:21:09','2025-10-17 06:21:09','vvKE3JP6nrHwB56E1zzPHLpkWVm3mafqZb7V9','mortgage'),(_binary '���\�\�cL��\�Te�',3,_binary '>Eg\�ӤVBf@','Mortgage','loan','AUTO',145000.00,'2025-10-17 06:19:50','2025-10-17 06:19:50','8zy9MRgmypfd7L5Le6kDioD6zgQ6KXiWJwJqD','mortgage'),(_binary '�0\���H��7q����',2,_binary '>Eg\�ӤVBf@\0','High Yield Savings','depository','AUTO',11968.07,'2025-10-17 06:15:34','2025-10-17 06:15:34','DgZW3b55VGhPevy4aampiL9yrR6NBgf3qNj4E','savings'),(_binary '\�q�}wM;���\�\�J8',3,_binary '>Eg\�ӤVBf@','Primary Checking','depository','AUTO',21500.00,'2025-10-17 06:19:50','2025-10-17 06:19:50','pGkWKXvDk5CzogmgdyM5iwNeJ81eKXtpQLQay','checking'),(_binary '\�\��B�F������\�\�',3,_binary '>Eg\�ӤVBf@','High Yield Savings','depository','AUTO',177269.42,'2025-10-17 06:19:50','2025-10-17 06:19:50','oAdwqLvDd5Trp979wvPNsQnWzqaWB9hoVRVEJ','savings'),(_binary '\�A�\��vAx��j����(',2,_binary '>Eg\�ӤVBf@\0','Primary Checking','depository','AUTO',7911.00,'2025-10-17 06:15:34','2025-10-17 06:15:34','X4XMl755BRfmZJyGKK46tv9raE4BN8ibAko11','checking');
INSERT INTO `accounts` (
  `id`,
  `user_id`,
  `customer_id`,
  `name`,
  `account_type`,
  `account_origin`,
  `current_value`,
  `equity`,
  `created_at`,
  `updated_at`,
  `external_ref`,
  `account_subtype`
) VALUES
(
  _binary '\0�}k�M��\�\�\�*���',
  4,
  _binary '>Eg\�ӤVBf@',
  'Everyday Checking',
  'depository',
  'AUTO',
  13240.00,
  NULL,
  '2025-10-17 06:21:09',
  '2025-10-17 06:21:09',
  'mvEQawk6neHB9GeEoQQkiPQyWAeje9cgQe383',
  'checking'
),
(
  _binary '@\�lG�\�~燆*\�',
  4,
  _binary '>Eg\�ӤVBf@',
  'High Yield Savings',
  'depository',
  'AUTO',
  61250.00,
  NULL,
  '2025-10-17 06:21:09',
  '2025-10-17 06:21:09',
  'ywBGDRe6nacgkaJ9Exx3UL9XKg1r1lf48PvpL',
  'savings'
),
(
  _binary '	-|ڪK-��\�<[t',
  2,
  _binary '>Eg\�ӤVBf@\0',
  'Mortgage',
  'loan',
  'AUTO',
  368828.00,
  NULL,
  '2025-10-17 06:15:34',
  '2025-10-17 06:15:34',
  'wdnpBajjJ1uQ1MNv66EdFp8mVAxj64FPXznEL',
  'mortgage'
),
(
  _binary '_`�h�^H��8�\�m|q�',
  4,
  _binary '>Eg\�ӤVBf@',
  'Student Loan',
  'loan',
  'AUTO',
  25000.00,
  NULL,
  '2025-10-17 06:21:09',
  '2025-10-17 06:21:09',
  'RqbWZA5lDeuLlvyQKbbATrBV7eDmDJcaoN15e',
  'student'
),
(
  _binary '|\nDaeD\�\\\�*�f�',
  3,
  _binary '>Eg\�ӤVBf@',
  'Rewards Credit Card',
  'credit_card',
  'AUTO',
  1350.00,
  NULL,
  '2025-10-17 06:19:50',
  '2025-10-17 06:19:50',
  'g1lmnJoXlbfejy6ykLMoUXkL5MDLZeuE7g7Wv',
  'credit card'
),
(
  _binary '��\�bA\�C.�r��\�',
  2,
  _binary '>Eg\�ӤVBf@\0',
  'Rewards Credit Card',
  'credit_card',
  'AUTO',
  1260.00,
  NULL,
  '2025-10-17 06:15:34',
  '2025-10-17 06:15:34',
  'VdRQ8P55rmunepEqNNd4tKg9rvnBbQF9MQGqn',
  'credit card'
),
(
  _binary '��֊�JG�\�t\�\�&\�',
  4,
  _binary '>Eg\�ӤVBf@',
  'Chase Sapphire Preferred',
  'credit_card',
  'AUTO',
  1425.00,
  NULL,
  '2025-10-17 06:21:09',
  '2025-10-17 06:21:09',
  '9JBq5jAoEvhWQvXN7jjoTK3okG6N6lS49oJM7',
  'credit card'
),
(
  _binary '���vC���\�p\�A',
  4,
  _binary '>Eg\�ӤVBf@',
  'Mortgage',
  'loan',
  'AUTO',
  384500.00,
  NULL,
  '2025-10-17 06:21:09',
  '2025-10-17 06:21:09',
  'vvKE3JP6nrHwB56E1zzPHLpkWVm3mafqZb7V9',
  'mortgage'
),
(
  _binary '���\�\�cL��\�Te�',
  3,
  _binary '>Eg\�ӤVBf@',
  'Mortgage',
  'loan',
  'AUTO',
  145000.00,
  NULL,
  '2025-10-17 06:19:50',
  '2025-10-17 06:19:50',
  '8zy9MRgmypfd7L5Le6kDioD6zgQ6KXiWJwJqD',
  'mortgage'
),
(
  _binary '�0\���H��7q����',
  2,
  _binary '>Eg\�ӤVBf@\0',
  'High Yield Savings',
  'depository',
  'AUTO',
  11968.07,
  NULL,
  '2025-10-17 06:15:34',
  '2025-10-17 06:15:34',
  'DgZW3b55VGhPevy4aampiL9yrR6NBgf3qNj4E',
  'savings'
),
(
  _binary '\�q�}wM;���\�\�J8',
  3,
  _binary '>Eg\�ӤVBf@',
  'Primary Checking',
  'depository',
  'AUTO',
  21500.00,
  NULL,
  '2025-10-17 06:19:50',
  '2025-10-17 06:19:50',
  'pGkWKXvDk5CzogmgdyM5iwNeJ81eKXtpQLQay',
  'checking'
),
(
  _binary '\�\��B�F������\�\�',
  3,
  _binary '>Eg\�ӤVBf@',
  'High Yield Savings',
  'depository',
  'AUTO',
  177269.42,
  NULL,
  '2025-10-17 06:19:50',
  '2025-10-17 06:19:50',
  'oAdwqLvDd5Trp979wvPNsQnWzqaWB9hoVRVEJ',
  'savings'
),
(
  _binary '\�A�\��vAx��j����(',
  2,
  _binary '>Eg\�ӤVBf@\0',
  'Primary Checking',
  'depository',
  'AUTO',
  7911.00,
  NULL,
  '2025-10-17 06:15:34',
  '2025-10-17 06:15:34',
  'X4XMl755BRfmZJyGKK46tv9raE4BN8ibAko11',
  'checking'
);

/*!40000 ALTER TABLE `accounts` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-10-17 11:53:46
