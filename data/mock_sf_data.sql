DELIMITER $$

DROP PROCEDURE IF EXISTS generate_advisor_customer_data$$

CREATE PROCEDURE generate_advisor_customer_data()
BEGIN
    DECLARE v_customer_counter INT DEFAULT 0;
    DECLARE v_max_customer INT DEFAULT 0;
    DECLARE v_customer_id BINARY(16);
    DECLARE v_advisor_match_id BINARY(16);
    DECLARE v_response_id BINARY(16);
    DECLARE v_trace_id BINARY(16);
    DECLARE v_response_counter INT;
    DECLARE v_advisor_id VARCHAR(50);
    DECLARE v_firm_name VARCHAR(255);
    DECLARE v_advisor_photo VARCHAR(255);
    DECLARE v_portfolios_managed INT;
    DECLARE v_pricing_type VARCHAR(50);
    DECLARE v_matched_traits JSON;
    DECLARE v_match_rationale JSON;
    DECLARE v_match_score DECIMAL(3,2);
    DECLARE v_existing_responses INT;
    DECLARE v_existing_advisor_match INT;
    DECLARE v_existing_customer INT;
    DECLARE v_customer_name VARCHAR(255);
    DECLARE v_customer_email VARCHAR(255);
    DECLARE v_customer_phone VARCHAR(50);
    DECLARE v_customer_city VARCHAR(100);
    DECLARE v_customer_state VARCHAR(10);
    DECLARE v_customer_zip VARCHAR(20);
    DECLARE v_customer_age INT;
    DECLARE v_customer_profession VARCHAR(255);
    DECLARE v_current_advisor VARCHAR(50);
    DECLARE v_lead_id INT;
    DECLARE v_current_customer_index INT DEFAULT 0;
    DECLARE v_advisor_counter INT DEFAULT 0;
    DECLARE v_base_offset INT DEFAULT 0;
    DECLARE v_first_names TEXT;
    DECLARE v_last_names TEXT;
    DECLARE v_random_first INT;
    DECLARE v_random_last INT;
    DECLARE v_first_name VARCHAR(100);
    DECLARE v_last_name VARCHAR(100);
    DECLARE v_original_email VARCHAR(255);
    DECLARE v_email_counter INT;
    DECLARE v_email_exists INT;
    
    -- Question configurations for lead_responses
    DECLARE v_question_labels TEXT;
    DECLARE v_question_answers TEXT;
    DECLARE v_question_texts TEXT;
    
    -- Initialize question data (20 questions)
    SET v_question_labels = 'contact_preference,investment_experience,risk_tolerance,investment_goals,time_horizon,income_level,net_worth,age_range,employment_status,retirement_planning,tax_optimization,estate_planning,education_funding,business_succession,real_estate_investing,charitable_giving,debt_management,insurance_needs,healthcare_planning,advisor_preference';
    
    SET v_question_answers = '["Text","Email"]|["Beginner"]|["Moderate"]|["Retirement","Growth","Income"]|["10-20 years"]|["$100k-$250k"]|["$500k-$1M"]|["45-54"]|["Employed Full-time"]|["Yes"]|["Interested","Very Interested"]|["Yes"]|["Future Need","Planning Now"]|["Not Applicable"]|["Interested"]|["Yes","Sometimes"]|["Manageable"]|["Adequate Coverage","Reviewing Options"]|["Medicare Planning","Long-term Care"]|["Fee-only","AUM-based"]';
    
    SET v_question_texts = 'What is your preferred contact method?,What is your investment experience level?,What is your risk tolerance?,What are your primary investment goals?,What is your investment time horizon?,What is your annual income level?,What is your current net worth?,What is your age range?,What is your current employment status?,Are you planning for retirement?,Are you interested in tax optimization strategies?,Do you have an estate plan in place?,Do you need to plan for education funding?,Do you need business succession planning?,Are you interested in real estate investing?,Do you engage in charitable giving?,How would you describe your debt situation?,How would you rate your insurance coverage?,What are your healthcare planning needs?,What type of financial advisor do you prefer?';

    -- Initialize name lists for random generation
    SET v_first_names = 'James,Mary,John,Patricia,Robert,Jennifer,Michael,Linda,William,Elizabeth,David,Barbara,Richard,Susan,Joseph,Jessica,Thomas,Sarah,Charles,Karen,Christopher,Nancy,Daniel,Lisa,Matthew,Betty,Anthony,Margaret,Mark,Sandra,Donald,Ashley,Steven,Kimberly,Paul,Emily,Andrew,Donna,Joshua,Michelle,Kenneth,Carol,Kevin,Amanda,Brian,Dorothy,George,Melissa,Edward,Deborah';
    SET v_last_names = 'Smith,Johnson,Williams,Brown,Jones,Garcia,Miller,Davis,Rodriguez,Martinez,Hernandez,Lopez,Gonzalez,Wilson,Anderson,Thomas,Taylor,Moore,Jackson,Martin,Lee,Perez,Thompson,White,Harris,Sanchez,Clark,Ramirez,Lewis,Robinson,Walker,Young,Allen,King,Wright,Scott,Torres,Nguyen,Hill,Flores,Green,Adams,Nelson,Baker,Hall,Rivera,Campbell,Mitchell,Carter,Roberts';

    -- ==============================================
    -- PART 1: Create 18 real customers (indices 0-17)
    -- ==============================================
    WHILE v_current_customer_index < 18 DO
        -- Generate customer UUID
        SET v_customer_id = UNHEX(CONCAT(
            '123e4567e89b12d3a456426614174',
            LPAD(HEX(v_current_customer_index), 3, '0')
        ));
        
        -- Map customer index to real data from CSV and determine advisor
        CASE v_current_customer_index
            WHEN 0 THEN
                SET v_customer_name = 'Kimberly Woodward';
                SET v_customer_email = 'kimberly.woodward@gmail.com';
                SET v_customer_phone = '(215) 345-7864';
                SET v_customer_city = 'Philadelphia';
                SET v_customer_state = 'PA';
                SET v_customer_zip = '19152';
                SET v_customer_age = 54;
                SET v_customer_profession = 'real estate income';
                SET v_lead_id = NULL;
                SET v_current_advisor = '1';
            WHEN 1 THEN
                SET v_customer_name = 'James Williams';
                SET v_customer_email = 'james.williams@yahoo.com';
                SET v_customer_phone = '(212) 598-3021';
                SET v_customer_city = 'Denver';
                SET v_customer_state = 'CO';
                SET v_customer_zip = '80207';
                SET v_customer_age = 68;
                SET v_customer_profession = 'Hospital';
                SET v_lead_id = NULL;
                SET v_current_advisor = '2';
            WHEN 2 THEN
                SET v_customer_name = 'Joshua Phillips';
                SET v_customer_email = 'joshua.phillips@hotmail.com';
                SET v_customer_phone = '(978) 862-1543';
                SET v_customer_city = 'Boxborough';
                SET v_customer_state = 'MA';
                SET v_customer_zip = '02026';
                SET v_customer_age = 38;
                SET v_customer_profession = 'Nurse Practitioner';
                SET v_lead_id = NULL;
                SET v_current_advisor = '3';
            WHEN 3 THEN
                SET v_customer_name = 'Linda Black';
                SET v_customer_email = 'linda.black@outlook.com';
                SET v_customer_phone = '(616) 721-4390';
                SET v_customer_city = 'Grand Rapids';
                SET v_customer_state = 'MI';
                SET v_customer_zip = '49508';
                SET v_customer_age = 67;
                SET v_customer_profession = 'Retired';
                SET v_lead_id = 1001;
                SET v_current_advisor = '1';
            WHEN 4 THEN
                SET v_customer_name = 'Michael Davis';
                SET v_customer_email = 'michael.davis@gmail.com';
                SET v_customer_phone = '(617) 238-5906';
                SET v_customer_city = 'Boston';
                SET v_customer_state = 'MA';
                SET v_customer_zip = '02120';
                SET v_customer_age = 51;
                SET v_customer_profession = 'Sr. Director Operations';
                SET v_lead_id = 1002;
                SET v_current_advisor = '1';
            WHEN 5 THEN
                SET v_customer_name = 'Robert Pope';
                SET v_customer_email = 'r.pope@yahoo.com';
                SET v_customer_phone = '(310) 527-4632';
                SET v_customer_city = 'Beverly Hills';
                SET v_customer_state = 'CA';
                SET v_customer_zip = '90215';
                SET v_customer_age = 75;
                SET v_customer_profession = 'Publishing';
                SET v_lead_id = 1003;
                SET v_current_advisor = '1';
            WHEN 6 THEN
                SET v_customer_name = 'Patricia Solis';
                SET v_customer_email = 'patricia.solis@outlook.com';
                SET v_customer_phone = '(773) 414-2859';
                SET v_customer_city = 'Chicago';
                SET v_customer_state = 'IL';
                SET v_customer_zip = '60619';
                SET v_customer_age = 63;
                SET v_customer_profession = 'Writer';
                SET v_lead_id = 1004;
                SET v_current_advisor = '2';
            WHEN 7 THEN
                SET v_customer_name = 'David Fletcher';
                SET v_customer_email = 'david.fletcher@gmail.com';
                SET v_customer_phone = '(404) 653-1902';
                SET v_customer_city = 'Boston';
                SET v_customer_state = 'MA';
                SET v_customer_zip = '02120';
                SET v_customer_age = 54;
                SET v_customer_profession = 'N/A';
                SET v_lead_id = 1005;
                SET v_current_advisor = '2';
            WHEN 8 THEN
                SET v_customer_name = 'John Myers';
                SET v_customer_email = 'john.myers@hotmail.com';
                SET v_customer_phone = '(973) 657-8491';
                SET v_customer_city = 'Wayne';
                SET v_customer_state = 'NJ';
                SET v_customer_zip = '07078';
                SET v_customer_age = 69;
                SET v_customer_profession = 'Prefer not to say';
                SET v_lead_id = 1006;
                SET v_current_advisor = '2';
            WHEN 9 THEN
                SET v_customer_name = 'Christopher Smith';
                SET v_customer_email = 'csmith@yahoo.com';
                SET v_customer_phone = '(503) 291-7486';
                SET v_customer_city = 'Portland';
                SET v_customer_state = 'OR';
                SET v_customer_zip = '97214';
                SET v_customer_age = 34;
                SET v_customer_profession = 'Construction worker';
                SET v_lead_id = 1007;
                SET v_current_advisor = '3';
            WHEN 10 THEN
                SET v_customer_name = 'Barbara Rodriguez';
                SET v_customer_email = 'barbara.rodriguez@gmail.com';
                SET v_customer_phone = '(415) 782-6354';
                SET v_customer_city = 'Seattle';
                SET v_customer_state = 'WA';
                SET v_customer_zip = '98106';
                SET v_customer_age = 71;
                SET v_customer_profession = 'retired';
                SET v_lead_id = 1008;
                SET v_current_advisor = NULL;
            WHEN 11 THEN
                SET v_customer_name = 'Mary Russell';
                SET v_customer_email = 'mary.russell@outlook.com';
                SET v_customer_phone = '(720) 813-5592';
                SET v_customer_city = 'Aurora';
                SET v_customer_state = 'CO';
                SET v_customer_zip = '80020';
                SET v_customer_age = 75;
                SET v_customer_profession = 'project specialist';
                SET v_lead_id = 1009;
                SET v_current_advisor = NULL;
            WHEN 12 THEN
                SET v_customer_name = 'Lisa Riley';
                SET v_customer_email = 'lisa.riley@yahoo.com';
                SET v_customer_phone = '(512) 494-2167';
                SET v_customer_city = 'Austin';
                SET v_customer_state = 'TX';
                SET v_customer_zip = '73306';
                SET v_customer_age = 54;
                SET v_customer_profession = 'Prefer not to say';
                SET v_lead_id = 1010;
                SET v_current_advisor = NULL;
            WHEN 13 THEN
                SET v_customer_name = 'Michele Chapman';
                SET v_customer_email = 'michele.chapman@gmail.com';
                SET v_customer_phone = '(267) 910-2348';
                SET v_customer_city = 'Philadelphia';
                SET v_customer_state = 'PA';
                SET v_customer_zip = '19152';
                SET v_customer_age = 64;
                SET v_customer_profession = 'Optician';
                SET v_lead_id = 1011;
                SET v_current_advisor = NULL;
            WHEN 14 THEN
                SET v_customer_name = 'Amanda Fisher';
                SET v_customer_email = 'amanda.fisher@hotmail.com';
                SET v_customer_phone = '(323) 742-5891';
                SET v_customer_city = 'Los Angeles';
                SET v_customer_state = 'CA';
                SET v_customer_zip = '90018';
                SET v_customer_age = 39;
                SET v_customer_profession = 'Bar Manager';
                SET v_lead_id = 1012;
                SET v_current_advisor = NULL;
            WHEN 15 THEN
                SET v_customer_name = 'Jason Kramer';
                SET v_customer_email = 'jason.kramer@outlook.com';
                SET v_customer_phone = '(206) 385-9207';
                SET v_customer_city = 'Seattle';
                SET v_customer_state = 'WA';
                SET v_customer_zip = '98106';
                SET v_customer_age = 57;
                SET v_customer_profession = 'Prefer not to say';
                SET v_lead_id = 1013;
                SET v_current_advisor = NULL;
            WHEN 16 THEN
                SET v_customer_name = 'Carlos Walter';
                SET v_customer_email = 'carlos.walter@gmail.com';
                SET v_customer_phone = '(713) 597-3248';
                SET v_customer_city = 'Los Angeles';
                SET v_customer_state = 'CA';
                SET v_customer_zip = '90031';
                SET v_customer_age = 60;
                SET v_customer_profession = 'medical doctor';
                SET v_lead_id = 1014;
                SET v_current_advisor = NULL;
            WHEN 17 THEN
                SET v_customer_name = 'Ryan Barajas';
                SET v_customer_email = 'ryan.barajas@yahoo.com';
                SET v_customer_phone = '(445) 672-1839';
                SET v_customer_city = 'Philadelphia';
                SET v_customer_state = 'PA';
                SET v_customer_zip = '19152';
                SET v_customer_age = 56;
                SET v_customer_profession = 'Construction Supervisor';
                SET v_lead_id = 1015;
                SET v_current_advisor = NULL;
        END CASE;
                
        SET v_original_email = v_customer_email;
        SET v_email_counter = 0;

        SELECT COUNT(*) INTO v_email_exists
        FROM customers
        WHERE email = v_customer_email;

        WHILE v_email_exists > 0 DO
            SET v_email_counter = v_email_counter + 1;
            SET v_customer_email = CONCAT(
                SUBSTRING_INDEX(v_original_email, '@', 1),
                '+',
                v_email_counter,
                '@',
                SUBSTRING_INDEX(v_original_email, '@', -1)
            );
            
            SELECT COUNT(*) INTO v_email_exists
            FROM customers
            WHERE email = v_customer_email;
        END WHILE;

        -- Check if customer already exists
        SELECT COUNT(*) INTO v_existing_customer
        FROM customers
        WHERE id = v_customer_id;
        
        -- Insert customer if doesn't exist
        IF v_existing_customer = 0 THEN
            INSERT INTO customers (
                id, name, email, created_at, updated_at, phone, 
                preferred_contact_method, primary_city, primary_state, zip_code_extended,
                age, profession, is_married, is_homeowner, income_source, publisher, 
                advertiser, customer_segment, estimated_aum, income, cash_allocation,
                investments_allocation, retirement_allocation, home_value_allocation,
                other_investments_allocation, time_to_retirement, investment_obj,
                market_drop, long_term_plan_conf, open_to_remote, prev_paid_advice,
                lead_id, portfolio_management_json, preferred_relationships_json, 
                speciality_interests_json, verifications_json, tag_metadata_json, basic_data_json
            ) VALUES (
                v_customer_id,
                v_customer_name,
                v_customer_email,
                NOW(),
                NOW(),
                v_customer_phone,
                'Email',
                v_customer_city,
                v_customer_state,
                v_customer_zip,
                v_customer_age,
                v_customer_profession,
                IF(RAND() > 0.5, 1, 0),
                IF(RAND() > 0.3, 1, 0),
                CASE FLOOR(RAND() * 3)
                    WHEN 0 THEN 'self-employed'
                    WHEN 1 THEN 'other'
                    ELSE 'employed'
                END,
                'WealthWise',
                v_current_advisor,
                'Mass Affluent',
                FLOOR(400000 + RAND() * 800000),
                FLOOR(50000 + RAND() * 200000),
                FLOOR(100000 + RAND() * 600000),
                FLOOR(0 + RAND() * 300000),
                FLOOR(0 + RAND() * 600000),
                FLOOR(0 + RAND() * 700000),
                0,
                CASE FLOOR(RAND() * 4)
                    WHEN 0 THEN '2-5 years'
                    WHEN 1 THEN '6-10 years'
                    WHEN 2 THEN '11-15 years'
                    ELSE '16+ years'
                END,
                CASE FLOOR(RAND() * 3)
                    WHEN 0 THEN 'Growth'
                    WHEN 1 THEN 'Income'
                    ELSE 'Balanced'
                END,
                CASE FLOOR(RAND() * 3)
                    WHEN 0 THEN 'Unsure'
                    WHEN 1 THEN 'Hold'
                    ELSE 'Buy more'
                END,
                FLOOR(1 + RAND() * 5),
                IF(RAND() > 0.5, 1, 0),
                IF(RAND() > 0.5, 1, 0),
                v_lead_id,
                JSON_ARRAY(IF(RAND() > 0.5, 'Professional managed', 'Self-directed')),
                JSON_ARRAY(IF(RAND() > 0.5, 'Comprehensive planning', 'Flexible approach')),
                JSON_ARRAY('tax-aware-investing', 'retirement-planning', 'estate-planning'),
                JSON_OBJECT(
                    'sources', JSON_ARRAY('Phone verified', 'Email verified', 'Income not verified', 'Address verified'),
                    'verifications', JSON_ARRAY(true, true, false, true)
                ),
                JSON_OBJECT(
                    'persona_tags', JSON_ARRAY('Retirement Focused', 'Tax-Aware investor')
                ),
                JSON_OBJECT(
                    'id', v_current_customer_index,
                    'age', v_customer_age,
                    'name', v_customer_name,
                    'email', v_customer_email,
                    'phone', v_customer_phone,
                    'income', FLOOR(50000 + RAND() * 200000),
                    'publisher', 'WealthWise',
                    'advertiser', v_current_advisor,
                    'is_married', IF(RAND() > 0.5, true, false),
                    'profession', v_customer_profession,
                    'market_drop', 'Unsure',
                    'is_homeowner', true,
                    'primary_city', v_customer_city,
                    'estimated_aum', FLOOR(400000 + RAND() * 800000),
                    'income_source', 'self-employed',
                    'primary_state', v_customer_state,
                    'investment_obj', 'Growth',
                    'open_to_remote', true,
                    'cash_allocation', FLOOR(100000 + RAND() * 600000),
                    'customer_segment', 'Mass Affluent',
                    'prev_paid_advice', true,
                    'zip_code_extended', v_customer_zip,
                    'time_to_retirement', '6-10 years',
                    'long_term_plan_conf', FLOOR(1 + RAND() * 5),
                    'portfolio_management', JSON_ARRAY('Professional managed'),
                    'speciality_interests', JSON_ARRAY('tax-aware-investing', 'retirement-planning', 'estate-planning'),
                    'home_value_allocation', FLOOR(0 + RAND() * 700000),
                    'retirement_allocation', 0,
                    'investments_allocation', 0,
                    'preferred_relationships', JSON_ARRAY('Comprehensive planning'),
                    'preferred_contact_method', 'Email',
                    'other_investments_allocation', 0
                )
            );
        ELSE
            -- Update existing customer with correct lead_id
            UPDATE customers 
            SET 
                name = v_customer_name,
                email = v_customer_email,
                phone = v_customer_phone,
                primary_city = v_customer_city,
                primary_state = v_customer_state,
                zip_code_extended = v_customer_zip,
                age = v_customer_age,
                profession = v_customer_profession,
                lead_id = v_lead_id,
                advertiser = v_current_advisor,
                updated_at = NOW()
            WHERE id = v_customer_id;

        END IF;
        
        -- Only create advisor_match_data for customers with advisors (indices 3-9)
        IF v_current_customer_index BETWEEN 3 AND 9 THEN
            SELECT COUNT(*) INTO v_existing_advisor_match
            FROM advisor_match_data
            WHERE customer_id = v_customer_id
            AND advisor_id = v_current_advisor;
            
            IF v_existing_advisor_match = 0 THEN
                CASE (v_current_customer_index % 10)
                    WHEN 3 THEN
                        SET v_advisor_id = v_current_advisor;
                        SET v_advisor_photo = 'https://example.com/photos/advisor-john-smith.jpg';
                        SET v_portfolios_managed = 125;
                        SET v_pricing_type = 'AUM-based';
                        SET v_matched_traits = JSON_ARRAY('retirement planning', 'tax optimization', 'estate planning');
                        SET v_match_score = 0.92;
                        SET v_match_rationale = JSON_OBJECT('score', v_match_score, 'reason', 'Strong match for retirement and estate planning needs');
                    WHEN 4 THEN
                        SET v_advisor_id = v_current_advisor;
                        SET v_advisor_photo = 'https://example.com/photos/advisor-sarah-johnson.jpg';
                        SET v_portfolios_managed = 132;
                        SET v_pricing_type = 'Fee-only';
                        SET v_matched_traits = JSON_ARRAY('investment management', 'college planning', 'risk assessment');
                        SET v_match_score = 0.88;
                        SET v_match_rationale = JSON_OBJECT('score', v_match_score, 'reason', 'Excellent fit for education planning and investment strategy');
                    WHEN 5 THEN
                        SET v_advisor_id = v_current_advisor;
                        SET v_advisor_photo = 'https://example.com/photos/advisor-michael-chen.jpg';
                        SET v_portfolios_managed = 148;
                        SET v_pricing_type = 'Hybrid';
                        SET v_matched_traits = JSON_ARRAY('business succession', 'wealth transfer', 'charitable giving');
                        SET v_match_score = 0.95;
                        SET v_match_rationale = JSON_OBJECT('score', v_match_score, 'reason', 'Perfect match for business owners and succession planning');
                    ELSE
                        SET v_advisor_id = v_current_advisor;
                        SET v_advisor_photo = 'https://example.com/photos/advisor-patricia-garcia.jpg';
                        SET v_portfolios_managed = 134;
                        SET v_pricing_type = 'AUM-based';
                        SET v_matched_traits = JSON_ARRAY('women in wealth', 'career transitions', 'financial independence');
                        SET v_match_score = 0.88;
                        SET v_match_rationale = JSON_OBJECT('score', v_match_score, 'reason', 'Specialized in empowering financial independence');
                END CASE;
                
                SET v_advisor_match_id = UNHEX(REPLACE(UUID(), '-', ''));
                SET v_trace_id = UNHEX(REPLACE(UUID(), '-', ''));
                
                INSERT INTO advisor_match_data (
                    id, customer_id, advisor_id, trace_id, firm_name, firm_logo_url, 
                    advisor_photo_url, established_date, sec_number, assets_value, 
                    portfolios_managed, pricing_type, matched_traits, match_rationale,
                    client_timestamp, agent_timestamp, status, agent_failure_response,
                    created_at, updated_at
                ) VALUES (
                    v_advisor_match_id,
                    v_customer_id,
                    v_advisor_id,
                    v_trace_id,
                    'Horizon Wealth Management LLC',
                    'https://example.com/logos/horizon-wealth.png',
                    v_advisor_photo,
                    '2010-03-15',
                    'SEC-801-12345',
                    '$50M - $100M',
                    v_portfolios_managed,
                    v_pricing_type,
                    v_matched_traits,
                    v_match_rationale,
                    NOW(),
                    NOW(),
                    'completed',
                    NULL,
                    NOW(),
                    NOW()
                );
            END IF;
        END IF;
        
        -- Only create lead_responses for customers with advisors (indices 3-9)
        IF v_current_customer_index BETWEEN 3 AND 9 THEN
            SELECT COUNT(*) INTO v_existing_responses
            FROM lead_responses
            WHERE customer_id = v_customer_id;
            
            SET v_response_counter = v_existing_responses + 1;
            
            WHILE v_response_counter <= 20 DO
                SET v_response_id = UNHEX(REPLACE(UUID(), '-', ''));
                
                INSERT INTO lead_responses (
                    id, customer_id, question_number, question_label, 
                    question_text, answer_json, response_type, source, 
                    status, created_at, updated_at
                ) VALUES (
                    v_response_id,
                    v_customer_id,
                    v_response_counter,
                    SUBSTRING_INDEX(SUBSTRING_INDEX(v_question_labels, ',', v_response_counter), ',', -1),
                    SUBSTRING_INDEX(SUBSTRING_INDEX(v_question_texts, ',', v_response_counter), ',', -1),
                    CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(v_question_answers, '|', v_response_counter), '|', -1) AS JSON),
                    'lead',
                    IF(v_response_counter % 2 = 0, 'mobile_app', 'email_survey'),
                    'active',
                    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 90) DAY),
                    NOW()
                );
                
                SET v_response_counter = v_response_counter + 1;
            END WHILE;
        END IF;
        
        SET v_current_customer_index = v_current_customer_index + 1;
    END WHILE;
    
    -- ==============================================
    -- PART 2: Generate bulk dummy data for 3 advisors
    -- ==============================================
    
    -- Loop through 3 advisors (1, 2, 3)
    WHILE v_advisor_counter < 3 DO
        -- Set the current advisor_id, base offset, and customer count
        CASE v_advisor_counter
            WHEN 0 THEN 
                SET v_current_advisor = '1';
                SET v_base_offset = 1000;  -- Start at 1000
            WHEN 1 THEN 
                SET v_current_advisor = '2';
                SET v_base_offset = 2000;  -- Start at 2000
            ELSE 
                SET v_current_advisor = '3';
                SET v_base_offset = 3000;  -- Start at 3000
        END CASE;
        
        -- Reset customer counter for each advisor
        SET v_customer_counter = 0;
        
        -- Generate random number of customers between 250-300 for each advisor
        SET v_max_customer = FLOOR(250 + RAND() * 51);
        
        -- Loop through all customers for this advisor
        WHILE v_customer_counter < v_max_customer DO
            -- Generate customer UUID with non-overlapping ranges
            SET v_customer_id = UNHEX(CONCAT(
                '123e4567e89b12d3a456426614174',
                LPAD(HEX(v_base_offset + v_customer_counter), 3, '0')
            ));
            
            -- Generate random name and unique email
            SET v_random_first = FLOOR(1 + RAND() * 50);
            SET v_random_last = FLOOR(1 + RAND() * 50);
            SET v_first_name = SUBSTRING_INDEX(SUBSTRING_INDEX(v_first_names, ',', v_random_first), ',', -1);
            SET v_last_name = SUBSTRING_INDEX(SUBSTRING_INDEX(v_last_names, ',', v_random_last), ',', -1);
            SET v_customer_name = CONCAT(v_first_name, ' ', v_last_name);
            SET v_customer_email = CONCAT(
                LOWER(v_first_name), '.', LOWER(v_last_name), 
                '+', v_base_offset + v_customer_counter,
                '@', 
                CASE FLOOR(RAND() * 5)
                    WHEN 0 THEN 'gmail.com'
                    WHEN 1 THEN 'yahoo.com'
                    WHEN 2 THEN 'hotmail.com'
                    WHEN 3 THEN 'outlook.com'
                    ELSE 'email.com'
                END
            );
            
            -- Check if customer already exists
            SELECT COUNT(*) INTO v_existing_customer
            FROM customers
            WHERE id = v_customer_id;
            
            -- Insert customer if doesn't exist
            IF v_existing_customer = 0 THEN
                INSERT INTO customers (
                    id, name, email, created_at, updated_at, phone, 
                    preferred_contact_method, primary_city, primary_state, zip_code_extended,
                    age, profession, is_married, is_homeowner, income_source, publisher, 
                    advertiser, customer_segment, estimated_aum, income, cash_allocation,
                    investments_allocation, retirement_allocation, home_value_allocation,
                    other_investments_allocation, time_to_retirement, investment_obj,
                    market_drop, long_term_plan_conf, open_to_remote, prev_paid_advice,
                    lead_id, portfolio_management_json, preferred_relationships_json, 
                    speciality_interests_json, verifications_json, tag_metadata_json, basic_data_json
                ) VALUES (
                    v_customer_id,
                    v_customer_name,
                    v_customer_email,
                    NOW(),
                    NOW(),
                    CONCAT('(', LPAD(FLOOR(200 + RAND() * 799), 3, '0'), ') ', 
                           LPAD(FLOOR(RAND() * 1000), 3, '0'), '-',
                           LPAD(FLOOR(RAND() * 10000), 4, '0')),
                    'Email',
                    CASE FLOOR(RAND() * 10)
                        WHEN 0 THEN 'Philadelphia'
                        WHEN 1 THEN 'Denver'
                        WHEN 2 THEN 'New York'
                        WHEN 3 THEN 'Los Angeles'
                        WHEN 4 THEN 'Chicago'
                        WHEN 5 THEN 'Houston'
                        WHEN 6 THEN 'Phoenix'
                        WHEN 7 THEN 'San Antonio'
                        WHEN 8 THEN 'San Diego'
                        ELSE 'Dallas'
                    END,
                    CASE FLOOR(RAND() * 10)
                        WHEN 0 THEN 'PA'
                        WHEN 1 THEN 'CO'
                        WHEN 2 THEN 'NY'
                        WHEN 3 THEN 'CA'
                        WHEN 4 THEN 'IL'
                        WHEN 5 THEN 'TX'
                        WHEN 6 THEN 'AZ'
                        WHEN 7 THEN 'TX'
                        WHEN 8 THEN 'CA'
                        ELSE 'TX'
                    END,
                    CONCAT(LPAD(FLOOR(10000 + RAND() * 90000), 5, '0')),
                    FLOOR(45 + RAND() * 30),
                    CASE FLOOR(RAND() * 5)
                        WHEN 0 THEN 'real estate income'
                        WHEN 1 THEN 'Hospital'
                        WHEN 2 THEN 'Technology'
                        WHEN 3 THEN 'Finance'
                        ELSE 'Healthcare'
                    END,
                    IF(RAND() > 0.5, 1, 0),
                    IF(RAND() > 0.3, 1, 0),
                    CASE FLOOR(RAND() * 3)
                        WHEN 0 THEN 'self-employed'
                        WHEN 1 THEN 'other'
                        ELSE 'employed'
                    END,
                    'WealthWise',
                    v_current_advisor,
                    'Mass Affluent',
                    FLOOR(400000 + RAND() * 800000),
                    FLOOR(50000 + RAND() * 200000),
                    FLOOR(100000 + RAND() * 600000),
                    FLOOR(0 + RAND() * 300000),
                    FLOOR(0 + RAND() * 600000),
                    FLOOR(0 + RAND() * 700000),
                    0,
                    CASE FLOOR(RAND() * 4)
                        WHEN 0 THEN '2-5 years'
                        WHEN 1 THEN '6-10 years'
                        WHEN 2 THEN '11-15 years'
                        ELSE '16+ years'
                    END,
                    CASE FLOOR(RAND() * 3)
                        WHEN 0 THEN 'Growth'
                        WHEN 1 THEN 'Income'
                        ELSE 'Balanced'
                    END,
                    CASE FLOOR(RAND() * 3)
                        WHEN 0 THEN 'Unsure'
                        WHEN 1 THEN 'Hold'
                        ELSE 'Buy more'
                    END,
                    FLOOR(1 + RAND() * 5),
                    IF(RAND() > 0.5, 1, 0),
                    IF(RAND() > 0.5, 1, 0),
                    10000 + v_base_offset + v_customer_counter,
                    JSON_ARRAY(IF(RAND() > 0.5, 'Professional managed', 'Self-directed')),
                    JSON_ARRAY(IF(RAND() > 0.5, 'Comprehensive planning', 'Flexible approach')),
                    JSON_ARRAY('tax-aware-investing', 'retirement-planning', 'estate-planning'),
                    JSON_OBJECT(
                        'sources', JSON_ARRAY('Phone verified', 'Email verified', 'Income not verified', 'Address verified'),
                        'verifications', JSON_ARRAY(true, true, false, true)
                    ),
                    JSON_OBJECT(
                        'persona_tags', JSON_ARRAY('Retirement Focused', 'Tax-Aware investor')
                    ),
                    JSON_OBJECT(
                        'id', 10000 + v_base_offset + v_customer_counter,
                        'age', FLOOR(45 + RAND() * 30),
                        'name', v_customer_name,
                        'email', v_customer_email,
                        'phone', CONCAT('(', LPAD(FLOOR(200 + RAND() * 799), 3, '0'), ') ', 
                               LPAD(FLOOR(RAND() * 1000), 3, '0'), '-',
                               LPAD(FLOOR(RAND() * 10000), 4, '0')),
                        'income', FLOOR(50000 + RAND() * 200000),
                        'publisher', 'WealthWise',
                        'advertiser', v_current_advisor,
                        'is_married', IF(RAND() > 0.5, true, false),
                        'profession', 'real estate income',
                        'market_drop', 'Unsure',
                        'is_homeowner', true,
                        'primary_city', 'Philadelphia',
                        'estimated_aum', FLOOR(400000 + RAND() * 800000),
                        'income_source', 'self-employed',
                        'primary_state', 'PA',
                        'investment_obj', 'Growth',
                        'open_to_remote', true,
                        'cash_allocation', FLOOR(100000 + RAND() * 600000),
                        'customer_segment', 'Mass Affluent',
                        'prev_paid_advice', true,
                        'zip_code_extended', CONCAT(LPAD(FLOOR(10000 + RAND() * 90000), 5, '0')),
                        'time_to_retirement', '6-10 years',
                        'long_term_plan_conf', FLOOR(1 + RAND() * 5),
                        'portfolio_management', JSON_ARRAY('Professional managed'),
                        'speciality_interests', JSON_ARRAY('tax-aware-investing', 'retirement-planning', 'estate-planning'),
                        'home_value_allocation', FLOOR(0 + RAND() * 700000),
                        'retirement_allocation', 0,
                        'investments_allocation', 0,
                        'preferred_relationships', JSON_ARRAY('Comprehensive planning'),
                        'preferred_contact_method', 'Email',
                        'other_investments_allocation', 0
                    )
                );
            END IF;
            
            -- Check if advisor_match_data already exists for this customer
            SELECT COUNT(*) INTO v_existing_advisor_match
            FROM advisor_match_data
            WHERE customer_id = v_customer_id
            AND advisor_id = v_current_advisor;
            
            -- Only insert advisor_match_data if it doesn't exist
            IF v_existing_advisor_match = 0 THEN
                -- Rotate through different advisor configurations
                CASE (v_customer_counter % 10)
                    WHEN 0 THEN
                        SET v_advisor_id = v_current_advisor;
                        SET v_advisor_photo = 'https://example.com/photos/advisor-john-smith.jpg';
                        SET v_portfolios_managed = 125 + (v_customer_counter % 30);
                        SET v_pricing_type = 'AUM-based';
                        SET v_matched_traits = JSON_ARRAY('retirement planning', 'tax optimization', 'estate planning');
                        SET v_match_score = 0.92;
                        SET v_match_rationale = JSON_OBJECT('score', v_match_score, 'reason', 'Strong match for retirement and estate planning needs');
                    WHEN 1 THEN
                        SET v_advisor_id = v_current_advisor;
                        SET v_advisor_photo = 'https://example.com/photos/advisor-sarah-johnson.jpg';
                        SET v_portfolios_managed = 132 + (v_customer_counter % 30);
                        SET v_pricing_type = 'Fee-only';
                        SET v_matched_traits = JSON_ARRAY('investment management', 'college planning', 'risk assessment');
                        SET v_match_score = 0.88;
                        SET v_match_rationale = JSON_OBJECT('score', v_match_score, 'reason', 'Excellent fit for education planning and investment strategy');
                    WHEN 2 THEN
                        SET v_advisor_id = v_current_advisor;
                        SET v_advisor_photo = 'https://example.com/photos/advisor-michael-chen.jpg';
                        SET v_portfolios_managed = 148 + (v_customer_counter % 30);
                        SET v_pricing_type = 'Hybrid';
                        SET v_matched_traits = JSON_ARRAY('business succession', 'wealth transfer', 'charitable giving');
                        SET v_match_score = 0.95;
                        SET v_match_rationale = JSON_OBJECT('score', v_match_score, 'reason', 'Perfect match for business owners and succession planning');
                    ELSE
                        SET v_advisor_id = v_current_advisor;
                        SET v_advisor_photo = 'https://example.com/photos/advisor-patricia-garcia.jpg';
                        SET v_portfolios_managed = 134 + (v_customer_counter % 30);
                        SET v_pricing_type = 'AUM-based';
                        SET v_matched_traits = JSON_ARRAY('women in wealth', 'career transitions', 'financial independence');
                        SET v_match_score = 0.88;
                        SET v_match_rationale = JSON_OBJECT('score', v_match_score, 'reason', 'Specialized in empowering financial independence');
                END CASE;
                
                -- Insert advisor_match_data record
                SET v_advisor_match_id = UNHEX(REPLACE(UUID(), '-', ''));
                SET v_trace_id = UNHEX(REPLACE(UUID(), '-', ''));
                
                INSERT INTO advisor_match_data (
                    id, customer_id, advisor_id, trace_id, firm_name, firm_logo_url, 
                    advisor_photo_url, established_date, sec_number, assets_value, 
                    portfolios_managed, pricing_type, matched_traits, match_rationale,
                    client_timestamp, agent_timestamp, status, agent_failure_response,
                    created_at, updated_at
                ) VALUES (
                    v_advisor_match_id,
                    v_customer_id,
                    v_advisor_id,
                    v_trace_id,
                    'Horizon Wealth Management LLC',
                    'https://example.com/logos/horizon-wealth.png',
                    v_advisor_photo,
                    '2010-03-15',
                    'SEC-801-12345',
                    '$50M - $100M',
                    v_portfolios_managed,
                    v_pricing_type,
                    v_matched_traits,
                    v_match_rationale,
                    NOW(),
                    NOW(),
                    'completed',
                    NULL,
                    NOW(),
                    NOW()
                );
            END IF;
            
            -- Check how many lead_responses already exist for this customer
            SELECT COUNT(*) INTO v_existing_responses
            FROM lead_responses
            WHERE customer_id = v_customer_id;
            
            -- Calculate how many more responses we need (target is 20)
            SET v_response_counter = v_existing_responses + 1;
            
            -- Insert remaining lead_responses to reach 20 total
            WHILE v_response_counter <= 20 DO
                SET v_response_id = UNHEX(REPLACE(UUID(), '-', ''));
                
                INSERT INTO lead_responses (
                    id, customer_id, question_number, question_label, 
                    question_text, answer_json, response_type, source, 
                    status, created_at, updated_at
                ) VALUES (
                    v_response_id,
                    v_customer_id,
                    v_response_counter,
                    SUBSTRING_INDEX(SUBSTRING_INDEX(v_question_labels, ',', v_response_counter), ',', -1),
                    SUBSTRING_INDEX(SUBSTRING_INDEX(v_question_texts, ',', v_response_counter), ',', -1),
                    CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(v_question_answers, '|', v_response_counter), '|', -1) AS JSON),                    
                    'lead',
                    IF(v_response_counter % 2 = 0, 'mobile_app', 'email_survey'),
                    'active',
                    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 90) DAY),
                    NOW()
                );
                
                SET v_response_counter = v_response_counter + 1;
            END WHILE;
            
            SET v_customer_counter = v_customer_counter + 1;
            
            -- Commit every 10 customers to avoid long transactions
            IF v_customer_counter % 10 = 0 THEN
                COMMIT;
            END IF;
        END WHILE;
        
        -- Move to next advisor
        SET v_advisor_counter = v_advisor_counter + 1;
    END WHILE;
    
    -- Final commit
    COMMIT;

END$$


DELIMITER ;