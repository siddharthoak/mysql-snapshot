-- MySQL dump 10.13  Distrib 8.0.42, for Linux (aarch64)
--
-- Host: localhost    Database: halo_new
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `advisor_match_data`
--

DROP TABLE IF EXISTS `advisor_match_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `advisor_match_data` (
  `id` binary(16) NOT NULL,
  `client_id` binary(16) NOT NULL,
  `advisor_id` text,
  `trace_id` binary(16) NOT NULL,
  `firm_name` text,
  `firm_logo_url` text,
  `advisor_photo_url` text,
  `established_date` text,
  `sec_number` text,
  `assets_value` text,
  `portfolios_managed` int DEFAULT NULL,
  `pricing_type` text,
  `matched_traits` json DEFAULT NULL,
  `match_rationale` json DEFAULT NULL,
  `client_timestamp` datetime DEFAULT NULL,
  `agent_timestamp` datetime DEFAULT NULL,
  `status` enum('pending','completed','failed') NOT NULL DEFAULT 'pending',
  `agent_failure_response` json DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_client_id` (`client_id`),
  KEY `idx_status` (`status`),
  KEY `idx_trace_id` (`trace_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `advisor_match_data`
--

LOCK TABLES `advisor_match_data` WRITE;
/*!40000 ALTER TABLE `advisor_match_data` DISABLE KEYS */;
/*!40000 ALTER TABLE `advisor_match_data` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alembic_version`
--

DROP TABLE IF EXISTS `alembic_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alembic_version`
--

LOCK TABLES `alembic_version` WRITE;
/*!40000 ALTER TABLE `alembic_version` DISABLE KEYS */;
/*!40000 ALTER TABLE `alembic_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `blacklisted_tokens`
--

DROP TABLE IF EXISTS `blacklisted_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blacklisted_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `token_type` varchar(20) NOT NULL,
  `blacklisted_at` datetime NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `jti` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_blacklisted_tokens_jti` (`jti`),
  KEY `ix_blacklisted_tokens_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blacklisted_tokens`
--

LOCK TABLES `blacklisted_tokens` WRITE;
/*!40000 ALTER TABLE `blacklisted_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `blacklisted_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chat_messages`
--

DROP TABLE IF EXISTS `chat_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chat_messages` (
  `id` binary(16) NOT NULL,
  `client_id` binary(16) NOT NULL,
  `session_id` binary(16) NOT NULL,
  `trace_id` binary(16) NOT NULL,
  `client_message` text,
  `agent_response` json DEFAULT NULL,
  `client_timestamp` datetime DEFAULT NULL,
  `agent_timestamp` datetime DEFAULT NULL,
  `is_valid` tinyint(1) DEFAULT NULL,
  `status` enum('pending','completed','failed') NOT NULL DEFAULT 'pending',
  `validated_output` json DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chat_messages`
--

LOCK TABLES `chat_messages` WRITE;
/*!40000 ALTER TABLE `chat_messages` DISABLE KEYS */;
/*!40000 ALTER TABLE `chat_messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customers` (
  `id` binary(16) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `tag_metadata` json DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `preferred_contact_method` varchar(100) DEFAULT NULL,
  `primary_city` varchar(255) DEFAULT NULL,
  `primary_state` varchar(50) DEFAULT NULL,
  `zip_code_extended` varchar(20) DEFAULT NULL,
  `age` int DEFAULT NULL,
  `profession` varchar(255) DEFAULT NULL,
  `is_married` tinyint(1) DEFAULT NULL,
  `is_homeowner` tinyint(1) DEFAULT NULL,
  `income_source` varchar(255) DEFAULT NULL,
  `publisher` varchar(255) DEFAULT NULL,
  `advertiser` varchar(255) DEFAULT NULL,
  `customer_segment` varchar(100) DEFAULT NULL,
  `estimated_aum` int DEFAULT NULL,
  `income` int DEFAULT NULL,
  `cash_allocation` int DEFAULT NULL,
  `investments_allocation` int DEFAULT NULL,
  `retirement_allocation` int DEFAULT NULL,
  `home_value_allocation` int DEFAULT NULL,
  `other_investments_allocation` int DEFAULT NULL,
  `time_to_retirement` varchar(50) DEFAULT NULL,
  `investment_obj` varchar(255) DEFAULT NULL,
  `market_drop` varchar(255) DEFAULT NULL,
  `long_term_plan_conf` int DEFAULT NULL,
  `open_to_remote` tinyint(1) DEFAULT NULL,
  `prev_paid_advice` tinyint(1) DEFAULT NULL,
  `lead_id` int DEFAULT NULL,
  `portfolio_management_json` json DEFAULT NULL,
  `preferred_relationships_json` json DEFAULT NULL,
  `speciality_interests_json` json DEFAULT NULL,
  `verifications_json` json DEFAULT NULL,
  `tag_metadata_json` json DEFAULT NULL,
  `basic_data_json` json DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_clients_email` (`email`),
  KEY `ix_clients_name` (`name`),
  KEY `ix_customers_phone` (`phone`),
  KEY `ix_customers_primary_state` (`primary_state`),
  KEY `ix_customers_zip_code_extended` (`zip_code_extended`),
  KEY `ix_customers_profession` (`profession`),
  KEY `ix_customers_publisher` (`publisher`),
  KEY `ix_customers_advertiser` (`advertiser`),
  KEY `ix_customers_customer_segment` (`customer_segment`),
  KEY `ix_customers_lead_id` (`lead_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customers`
--

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document_summary`
--

DROP TABLE IF EXISTS `document_summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_summary` (
  `id` char(32) NOT NULL,
  `filename` varchar(100) NOT NULL,
  `summary` text NOT NULL,
  `created_at` datetime NOT NULL,
  `nodes_json` mediumtext,
  `source` text,
  `error` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `filename` (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_summary`
--

LOCK TABLES `document_summary` WRITE;
/*!40000 ALTER TABLE `document_summary` DISABLE KEYS */;
/*!40000 ALTER TABLE `document_summary` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refresh_tokens`
--

DROP TABLE IF EXISTS `refresh_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `token` varchar(800) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_refresh_tokens_id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refresh_tokens`
--

LOCK TABLES `refresh_tokens` WRITE;
/*!40000 ALTER TABLE `refresh_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `refresh_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transaction_aggregate_data`
--

DROP TABLE IF EXISTS `transaction_aggregate_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaction_aggregate_data` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `period_type` varchar(20) NOT NULL,
  `period_key` varchar(20) NOT NULL,
  `inflow` decimal(15,2) NOT NULL,
  `expense` decimal(15,2) NOT NULL,
  `next_cursor` varchar(500) NOT NULL,
  `inflow_by_category` json NOT NULL,
  `expense_by_category` json NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_transaction_aggregate_data_id` (`id`),
  KEY `ix_transaction_aggregate_data_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transaction_aggregate_data`
--

LOCK TABLES `transaction_aggregate_data` WRITE;
/*!40000 ALTER TABLE `transaction_aggregate_data` DISABLE KEYS */;
/*!40000 ALTER TABLE `transaction_aggregate_data` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `hashed_password` varchar(255) NOT NULL,
  `advisor_id` varchar(100) DEFAULT NULL,
  `advisor_secret` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `customer_id` binary(16) NOT NULL,
  `lead_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_users_username` (`username`),
  UNIQUE KEY `ix_users_advisor_id` (`advisor_id`),
  KEY `ix_users_id` (`id`),
  KEY `ix_users_customer_id` (`customer_id`),
  KEY `ix_users_lead_id` (`lead_id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` (`id`, `username`, `hashed_password`, `advisor_id`, `advisor_secret`, `created_at`, `updated_at`, `version`, `customer_id`, `lead_id`) VALUES (1,'admin','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_001','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x75303031323E4567EFBFBD7530303132,1000),(2,'kimberly_woodward','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_002','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174000,1001),(3,'james_williams','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_003','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174001,1002),(4,'joshua_phillips','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_004','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174002,1003),(5,'linda_black','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_005','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174003,1004),(6,'michael_davis','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_006','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174004,1005),(7,'robert_pope','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_007','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174005,1006),(8,'patricia_solis','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_008','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174006,1007),(9,'david_fletcher','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_009','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174007,1008),(10,'john_myers','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_010','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174008,1009),(11,'christopher_smith','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_011','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174009,1010),(12,'barbara_rodriguez','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_012','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174010,1011),(13,'mary_russell','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_013','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174011,1012),(14,'lisa_riley','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_014','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174012,1013),(15,'michele_chapman','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_015','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174013,1014),(16,'amanda_fisher','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_016','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174014,1015),(17,'jason_kramer','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_017','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174015,1016),(18,'carlos_walter','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_018','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174016,1017),(19,'ryan_barajas','$2b$12$tjmcSh2KnePHr8h0Yh4cIubPJ2edysIxCUqtfgVvs3UIlsPpoNjSK','admin_client_019','$2b$12$Jlr59dkFw64BoVlvVF0ZDeymEuEJxcKOVDpY251u.kh1AJSA.ge7e','2025-08-06 18:46:02','2025-08-06 18:46:02',1,0x123E4567E89B12D3A456426614174017,1018);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'halo_new'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-08-17 14:15:18
