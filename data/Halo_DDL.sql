-- halo_chat.users definition

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- halo_chat.refresh_tokens definition

CREATE TABLE `refresh_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `token` varchar(800) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_refresh_tokens_id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- halo_chat.customers definition

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


-- halo_chat.chat_messages definition

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

-- halo_chat.blacklisted_tokens definition

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

-- halo_chat.advisor_match_data definition

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

-- halo_chat.transaction_aggregate_data definition

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


-- halo_chat.alembic_version definition

CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE document_summary (
  id char(32) NOT NULL,
  filename varchar(100) NOT NULL,
  summary text NOT NULL,
  created_at datetime NOT NULL,
  nodes_json mediumtext,
  source text,
  error text,
  PRIMARY KEY (id),
  UNIQUE KEY filename (filename)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
