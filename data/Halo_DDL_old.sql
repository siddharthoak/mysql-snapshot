SET foreign_key_checks = 0;

CREATE TABLE `account_types` (
  `id` binary(16) NOT NULL,
  `key` varchar(50) NOT NULL,
  `display_label` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  `updated_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_account_types_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `accounts` (
  `id` binary(16) NOT NULL,
  `user_id` int NOT NULL,
  `customer_id` binary(16) NOT NULL,
  `name` varchar(255) NOT NULL,
  `account_origin` enum('MANUAL','AUTO') NOT NULL DEFAULT 'MANUAL',
  `current_value` decimal(15,2) NOT NULL DEFAULT '0.00',
  `created_at` datetime NOT NULL DEFAULT (now()),
  `updated_at` datetime NOT NULL DEFAULT (now()),
  `external_ref` varchar(255) DEFAULT NULL,
  `account_subtype` enum('401k','403b','ira','roth ira','pension','retirement','brokerage','mutual fund','stock','bond','etf','life insurance','fixed annuity','gic','lira','lrif','lrsp','checking','savings','money market','cd','cash management','hsa','student','mortgage','auto','business','consumer','home equity','construction','line of credit','overdraft','credit card','other') DEFAULT NULL,
  `account_type_id` binary(16) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_accounts_external_ref` (`external_ref`),
  KEY `ix_accounts_user_id` (`user_id`),
  KEY `ix_accounts_created_at` (`created_at`),
  KEY `ix_accounts_updated_at` (`updated_at`),
  KEY `idx_account_user_created` (`user_id`,`created_at`),
  KEY `idx_account_user_name` (`user_id`,`name`),
  KEY `idx_account_user_origin` (`user_id`,`account_origin`),
  KEY `idx_account_user_external_ref` (`user_id`,`external_ref`),
  KEY `idx_account_type_id` (`account_type_id`),
  KEY `idx_account_user_type_id` (`user_id`,`account_type_id`),
  CONSTRAINT `fk_accounts_account_type_id` FOREIGN KEY (`account_type_id`) REFERENCES `account_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_accounts_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `ck_accounts_current_value_positive` CHECK ((`current_value` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `advisor_match_data` (
  `id` binary(16) NOT NULL,
  `customer_id` binary(16) NOT NULL,
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
  KEY `idx_customer_id` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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

CREATE TABLE `chat_messages` (
  `id` binary(16) NOT NULL,
  `customer_id` binary(16) NOT NULL,
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
  `crew_type` enum('SmallTalkCrew','ExplainerCrew','ReframerCrew','UnclassifiedCrew') DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
  KEY `ix_customers_lead_id` (`lead_id`),
  KEY `idx_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `dynamic_ingress_prompts` (
  `id` binary(16) NOT NULL,
  `customer_id` binary(16) NOT NULL,
  `trace_id` binary(16) NOT NULL,
  `agent_response` json DEFAULT NULL,
  `growth_projections_trace_id` binary(16) NOT NULL,
  `client_timestamp` datetime DEFAULT (now()),
  `agent_timestamp` datetime DEFAULT (now()),
  `status` enum('pending','completed','failed') NOT NULL DEFAULT 'pending',
  `created_at` datetime DEFAULT (now()),
  `updated_at` datetime DEFAULT (now()),
  `processing_category` varchar(100) DEFAULT NULL COMMENT 'Asset category being processed or ''opportunity_areas''',
  `ingress_prompt_type` enum('TBD','asset','opportunity_areas') DEFAULT NULL COMMENT 'Type of ingress prompt: asset or opportunity_areas',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_trace_category_type` (`trace_id`,`processing_category`,`ingress_prompt_type`),
  KEY `idx_customer_growth_projection` (`customer_id`,`growth_projections_trace_id`),
  KEY `idx_trace_category` (`trace_id`,`processing_category`),
  KEY `idx_trace_id` (`trace_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `growth_projections` (
  `id` binary(16) NOT NULL,
  `customer_id` binary(16) NOT NULL,
  `trace_id` binary(16) NOT NULL,
  `time_to_retire` int DEFAULT NULL,
  `growth_rate` enum('CONSERVATIVE','MODERATE','AGGRESSIVE','CUSTOM') DEFAULT NULL,
  `historical_simulation` enum('COVID19','GLOBAL_CRISIS_2008','DOT_COM_BUBBLE_2000') DEFAULT NULL,
  `extra_retirement_contribution` decimal(15,2) DEFAULT (0.00),
  `agent_response` json DEFAULT NULL,
  `client_timestamp` datetime DEFAULT (now()),
  `agent_timestamp` datetime DEFAULT (now()),
  `status` enum('pending','completed','failed') NOT NULL DEFAULT 'pending',
  `created_at` datetime DEFAULT (now()),
  `updated_at` datetime DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_growth_projections_trace_id` (`trace_id`),
  UNIQUE KEY `trace_id` (`trace_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `lead_responses` (
  `id` binary(16) NOT NULL,
  `customer_id` binary(16) NOT NULL,
  `question_number` int NOT NULL,
  `question_label` varchar(255) DEFAULT NULL,
  `question_text` text NOT NULL,
  `answer_json` json NOT NULL,
  `response_type` varchar(100) DEFAULT NULL,
  `source` varchar(100) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_lead_responses_customer_id` (`customer_id`),
  KEY `ix_lead_responses_question_number` (`question_number`),
  CONSTRAINT `lead_responses_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `money_flow_data` (
  `id` int NOT NULL AUTO_INCREMENT,
  `category_type` varchar(20) NOT NULL,
  `account_id` varchar(100) NOT NULL,
  `account_owner` varchar(100) DEFAULT NULL,
  `amount` decimal(15,2) NOT NULL,
  `authorized_date` datetime DEFAULT NULL,
  `date` datetime NOT NULL,
  `iso_currency_code` varchar(3) NOT NULL DEFAULT 'USD',
  `personal_finance_category_primary` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_account_date` (`account_id`,`date`),
  KEY `ix_money_flow_data_category_type` (`category_type`),
  KEY `ix_money_flow_data_account_id` (`account_id`),
  KEY `ix_money_flow_data_date` (`date`),
  KEY `idx_user_id_category` (`user_id`,`category_type`),
  KEY `idx_user_id_date` (`user_id`,`date`),
  KEY `idx_user_id_category_date` (`user_id`,`category_type`,`date`),
  KEY `ix_money_flow_data_user_id` (`user_id`),
  CONSTRAINT `fk_money_flow_data_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_user_id_positive` CHECK ((`user_id` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `refresh_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `token` varchar(800) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_refresh_tokens_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `sessions` (
  `id` binary(16) NOT NULL,
  `customer_id` binary(16) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_sessions_customer_id` (`customer_id`),
  KEY `ix_sessions_is_active` (`is_active`),
  KEY `ix_sessions_created_at` (`created_at`),
  CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
  KEY `ix_transaction_aggregate_data_username` (`username`),
  KEY `idx_period_type` (`period_type`),
  KEY `idx_period_key` (`period_key`),
  KEY `idx_username_period` (`username`,`period_type`,`period_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SET foreign_key_checks = 1;