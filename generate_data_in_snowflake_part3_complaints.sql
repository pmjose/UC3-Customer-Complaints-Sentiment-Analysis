-- =====================================================================
-- UC3 - GENERATE SAMPLE DATA IN SNOWFLAKE - PART 3: COMPLAINT DATA
-- =====================================================================
-- Purpose: Generate multi-channel complaint data
-- Usage: Run AFTER Part 1 and Part 2
-- Time: ~10 minutes
-- =====================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE UC3_CUSTOMER_COMPLAINTS;
USE SCHEMA COMPLAINTS;

SELECT 'Starting Part 3: Complaint data generation...' as STATUS;
SELECT '================================================' as SEPARATOR;

-- =====================================================================
-- STEP 17: GENERATE VOICE TRANSCRIPTS (1,000 call center recordings)
-- =====================================================================

SELECT 'Step 17: Generating 1,000 voice transcripts...' as STATUS;

-- Create temp table for voice transcript templates
CREATE OR REPLACE TEMP TABLE VOICE_TRANSCRIPT_TEMPLATES AS
SELECT * FROM (VALUES
    (1, 'network_issue', 'Customer Service: Thank you for calling. How may I help you today?\nCustomer: Hi, I have been experiencing network connectivity issues for the past three days. My data is very slow and calls keep dropping.\nCustomer Service: I apologize for the inconvenience. Let me check your account and the network status in your area.\nCustomer: This is very frustrating. I need reliable service for my work.\nCustomer Service: I understand your frustration. I can see there was a network incident affecting your area. We are providing a credit to your account and the issue has been resolved.\nCustomer: Thank you, I appreciate that. When will I see the credit?\nCustomer Service: The credit will appear on your next bill within 2-3 business days.', -0.3, 'frustrated'),
    (2, 'billing_complaint', 'Customer Service: Good afternoon, how can I assist you?\nCustomer: I received my bill and the charges are much higher than expected. Can you explain why?\nCustomer Service: Certainly, let me review your account. I see here that you exceeded your data limit this month.\nCustomer: But I thought I had unlimited data?\nCustomer Service: You have the 50GB plan. Once you exceed 50GB, overage charges apply at €0.10 per MB.\nCustomer: This is ridiculous! Nobody explained that to me when I signed up.\nCustomer Service: I sincerely apologize for the confusion. Let me see what we can do to help with these charges.', -0.5, 'angry'),
    (3, 'technical_support', 'Customer Service: Technical support, how may I help you?\nCustomer: Hi, I cannot get my new phone to connect to your network properly.\nCustomer Service: I would be happy to help you with that. Can you tell me what kind of phone you have?\nCustomer: It is a Samsung Galaxy S23. I just got it yesterday.\nCustomer Service: Great choice! Let me walk you through the APN settings. First, go to Settings, then Connections.\nCustomer: Okay, I am there now.\nCustomer Service: Perfect. Now select Mobile Networks, then Access Point Names.\nCustomer: Got it. What should I enter here?\nCustomer Service: I will provide you with the correct settings. Please write these down.', 0.1, 'neutral'),
    (4, 'service_quality', 'Customer Service: Thank you for contacting us. What can I help you with today?\nCustomer: My internet has been extremely slow for the past week. I pay for 500Mbps but I am only getting about 50Mbps.\nCustomer Service: I am sorry to hear that. Let me run a diagnostic test on your connection.\nCustomer: I have already restarted the router multiple times. Nothing helps.\nCustomer Service: I understand. The diagnostic shows there may be an issue with the line. I will schedule a technician visit.\nCustomer: How soon can they come? I work from home and need reliable internet.\nCustomer Service: I have an appointment available tomorrow afternoon between 2-5 PM. Would that work?\nCustomer: Yes, that works. Please make sure they actually show up this time.', -0.2, 'frustrated'),
    (5, 'positive_feedback', 'Customer Service: Good morning, how may I assist you today?\nCustomer: Hi, I actually called to say thank you. Your technician came yesterday and fixed my internet issue.\nCustomer Service: That is wonderful to hear! I am so glad we could resolve that for you.\nCustomer: Yes, he was very professional and explained everything clearly. The service is working perfectly now.\nCustomer Service: That is excellent feedback. I will make sure to pass that along to the technician and his supervisor.\nCustomer: Please do. It is refreshing to have such good customer service. Thank you again.\nCustomer Service: You are very welcome. Is there anything else I can help you with today?\nCustomer: No, that is all. Have a great day!', 0.8, 'satisfied'),
    (6, 'account_inquiry', 'Customer Service: Customer service, how can I help?\nCustomer: I want to inquire about upgrading my plan. What options do I have?\nCustomer Service: I would be happy to review the available plans with you. Currently you are on our Standard 4G plan.\nCustomer: Yes, but I need more data and faster speeds.\nCustomer Service: We have several 5G plans that might interest you. Would you like to hear about those?\nCustomer: Yes please, what do they include?\nCustomer Service: Our 5G Premium plan includes unlimited data, 5G speeds, and international calling to 50 countries.\nCustomer: That sounds good. How much does it cost?\nCustomer Service: It is 49.99 euros per month. I can upgrade you right now if you would like.', 0.3, 'neutral')
) AS t(template_id, issue_type, transcript_text, sentiment_score, emotion);

INSERT INTO VOICE_TRANSCRIPT (
    TRANSCRIPT_ID,
    CALL_ID,
    CASE_ID,
    CUSTOMER_ID,
    ACCOUNT_ID,
    CALL_TIMESTAMP,
    DURATION_SECONDS,
    AGENT_ID,
    TRANSCRIPT_TEXT,
    CALL_OUTCOME,
    FIRST_CALL_RESOLUTION,
    CUSTOMER_SATISFACTION,
    NETWORK_INCIDENT_ID,
    CREATED_DATE
)
WITH CALL_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
),
ACCOUNTS_WITH_CASES AS (
    SELECT DISTINCT
        c.ACCOUNT_ID,
        cm.CUSTOMER_ID,
        c.CASE_ID,
        c.NETWORK_INCIDENT_ID,
        c.CATEGORY,
        c.CREATED_DATE,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM CUSTOMER_DATA.CASE c
    JOIN CUSTOMER_DATA.ACCOUNT a ON c.ACCOUNT_ID = a.ACCOUNT_ID
    LEFT JOIN BILLING_DATA.CUSTOMER_MASTER cm ON a.ACCOUNT_ID = cm.ACCOUNT_ID
    WHERE c.CHANNEL = 'Voice'
),
TEMPLATES_REPEATED AS (
    SELECT 
        template_id,
        issue_type,
        transcript_text,
        sentiment_score,
        emotion
    FROM VOICE_TRANSCRIPT_TEMPLATES
),
ACCOUNTS_COUNT AS (
    SELECT COUNT(*) as CNT FROM ACCOUNTS_WITH_CASES
)
SELECT 
    'TRANS-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as TRANSCRIPT_ID,
    'CALL-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as CALL_ID,
    awc.CASE_ID,
    awc.CUSTOMER_ID,
    awc.ACCOUNT_ID,
    DATEADD(minute, -UNIFORM(0, 43200, RANDOM()), CURRENT_TIMESTAMP()) as CALL_TIMESTAMP,
    UNIFORM(180, 1800, RANDOM()) as DURATION_SECONDS,
    'AGENT-' || LPAD(UNIFORM(1, 50, RANDOM())::VARCHAR, 3, '0') as AGENT_ID,
    tr.transcript_text as TRANSCRIPT_TEXT,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'resolved'
        WHEN 2 THEN 'escalated'
        WHEN 3 THEN 'callback_required'
        WHEN 4 THEN 'information_provided'
        ELSE 'ticket_created'
    END as CALL_OUTCOME,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 7 THEN TRUE ELSE FALSE END as FIRST_CALL_RESOLUTION,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 5
        WHEN 2 THEN 4
        WHEN 3 THEN 3
        WHEN 4 THEN 2
        ELSE 1
    END as CUSTOMER_SATISFACTION,
    awc.NETWORK_INCIDENT_ID,
    awc.CREATED_DATE as CREATED_DATE
FROM CALL_GENERATOR cg
CROSS JOIN ACCOUNTS_COUNT ac
LEFT JOIN ACCOUNTS_WITH_CASES awc ON ((cg.ROW_NUM - 1) % ac.CNT) + 1 = awc.RN
LEFT JOIN TEMPLATES_REPEATED tr ON ((cg.ROW_NUM - 1) % 6) + 1 = tr.template_id;

SELECT COUNT(*) || ' voice transcripts generated' as STATUS FROM VOICE_TRANSCRIPT;

-- =====================================================================
-- STEP 18: GENERATE EMAIL COMPLAINTS (5,000 emails)
-- =====================================================================

SELECT 'Step 18: Generating 5,000 email complaints...' as STATUS;

INSERT INTO EMAIL_COMPLAINT (
    EMAIL_ID,
    CASE_ID,
    CUSTOMER_ID,
    FROM_ADDRESS,
    TO_ADDRESS,
    SUBJECT,
    BODY_TEXT,
    RECEIVED_TIMESTAMP,
    CATEGORY,
    PRIORITY,
    IS_REPLIED,
    CREATED_DATE
)
WITH EMAIL_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
),
ACCOUNTS_FOR_EMAIL AS (
    SELECT 
        a.ACCOUNT_ID,
        cm.CUSTOMER_ID,
        c.EMAIL,
        a.TIER,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM CUSTOMER_DATA.ACCOUNT a
    JOIN BILLING_DATA.CUSTOMER_MASTER cm ON a.ACCOUNT_ID = cm.ACCOUNT_ID
    JOIN CUSTOMER_DATA.CONTACT c ON a.ACCOUNT_ID = c.ACCOUNT_ID AND c.IS_PRIMARY = TRUE
),
ACCOUNTS_COUNT_EMAIL AS (
    SELECT COUNT(*) as CNT FROM ACCOUNTS_FOR_EMAIL
)
SELECT 
    'EMAIL-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as EMAIL_ID,
    NULL as CASE_ID,
    afe.CUSTOMER_ID,
    afe.EMAIL as FROM_ADDRESS,
    'support@telecomcompany.pt' as TO_ADDRESS,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'URGENT: Network outage affecting my business'
        WHEN 2 THEN 'Billing issue - incorrect charges on invoice'
        WHEN 3 THEN 'Poor network quality in my area'
        WHEN 4 THEN 'Request for service credit'
        WHEN 5 THEN 'Complaint about customer service'
        WHEN 6 THEN 'Technical support needed'
        WHEN 7 THEN 'Data service not working properly'
        WHEN 8 THEN 'Request for plan upgrade information'
        WHEN 9 THEN 'Account access problems'
        ELSE 'General inquiry about services'
    END as SUBJECT,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'Dear Support Team,\n\nI am writing to express my frustration with the ongoing network issues I have been experiencing. For the past week, my service has been extremely unreliable with frequent disconnections and very slow data speeds. This is completely unacceptable for a premium customer like myself.\n\nI have called your support line three times already and each time I am given a different excuse. I need this resolved immediately or I will be forced to consider switching providers.\n\nPlease contact me as soon as possible to discuss compensation for this service disruption.\n\nRegards'
        WHEN 2 THEN 'Hello,\n\nI received my latest bill and I noticed several charges that I do not recognize. Can you please provide a detailed breakdown of these charges?\n\nSpecifically, I see charges for international roaming, but I have not left the country in months. There also appears to be duplicate charges for my monthly subscription.\n\nPlease investigate this matter urgently and credit my account accordingly.\n\nThank you'
        WHEN 3 THEN 'Good morning,\n\nI am experiencing very poor network quality at my home address. Calls are frequently dropping and data speeds are much slower than what I am paying for.\n\nCan you please check if there are any known issues in my area? If this is a ongoing problem, I would like to discuss my options including potentially canceling my service without penalty.\n\nLooking forward to your response.'
        WHEN 4 THEN 'Dear Customer Service,\n\nI recently spoke with your support team about a network outage that affected my area last week. I was told that I would receive a service credit, but I have not seen anything applied to my account yet.\n\nCan you please confirm when this credit will be processed? I lost several days of service and had to use alternative means to stay connected, which cost me additional money.\n\nThank you for your attention to this matter.'
        WHEN 5 THEN 'To whom it may concern,\n\nI am writing to file a formal complaint about the poor customer service I received from one of your representatives yesterday. I called regarding a billing issue and was met with rudeness and unhelpfulness.\n\nThe agent refused to escalate my call to a supervisor and basically told me there was nothing that could be done. This is not the level of service I expect from your company.\n\nI request that this matter be investigated and that I receive a proper response from a manager.\n\nThank you'
        WHEN 6 THEN 'Hi,\n\nI am having trouble configuring my new device to work with your network. I have tried following the setup instructions on your website but I keep getting error messages.\n\nCould someone please provide me with step-by-step instructions or perhaps schedule a call to help me get this working? I have been without service for two days now.\n\nYour assistance would be greatly appreciated.\n\nBest regards'
        WHEN 7 THEN 'Hello Support,\n\nMy mobile data has not been working properly for the past several days. I have tried restarting my phone and checking the settings, but nothing seems to help.\n\nWhen I try to use data, it either does not connect at all or is extremely slow. My phone shows full signal bars but no data connection.\n\nPlease help me resolve this issue as soon as possible.\n\nThanks'
        ELSE 'Dear Team,\n\nI am interested in learning more about your available service plans and potential upgrades. I currently have the standard package but I am considering moving to a higher tier.\n\nCould you please send me information about your premium plans including pricing and features? Also, are there any promotional offers currently available?\n\nThank you for your time.\n\nBest regards'
    END as BODY_TEXT,
    DATEADD(hour, -UNIFORM(1, 4320, RANDOM()), CURRENT_TIMESTAMP()) as RECEIVED_TIMESTAMP,
    CASE UNIFORM(1, 6, RANDOM())
        WHEN 1 THEN 'network_outage'
        WHEN 2 THEN 'billing_dispute'
        WHEN 3 THEN 'technical_support'
        WHEN 4 THEN 'service_quality'
        WHEN 5 THEN 'account_management'
        ELSE 'general_inquiry'
    END as CATEGORY,
    CASE 
        WHEN afe.TIER = 'Gold' AND UNIFORM(1, 100, RANDOM()) <= 40 THEN 'critical'
        WHEN UNIFORM(1, 100, RANDOM()) <= 20 THEN 'high'
        WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN 'medium'
        ELSE 'low'
    END as PRIORITY,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 6 THEN TRUE ELSE FALSE END as IS_REPLIED,
    DATEADD(hour, -UNIFORM(1, 4320, RANDOM()), CURRENT_TIMESTAMP()) as CREATED_DATE
FROM EMAIL_GENERATOR eg
CROSS JOIN ACCOUNTS_COUNT_EMAIL ace
LEFT JOIN ACCOUNTS_FOR_EMAIL afe ON ((eg.ROW_NUM - 1) % ace.CNT) + 1 = afe.RN;

SELECT COUNT(*) || ' email complaints generated' as STATUS FROM EMAIL_COMPLAINT;

-- =====================================================================
-- STEP 19: GENERATE SOCIAL MEDIA POSTS (3,000 posts)
-- =====================================================================

SELECT 'Step 19: Generating 3,000 social media posts...' as STATUS;

INSERT INTO SOCIAL_MEDIA_POST (
    POST_ID,
    CASE_ID,
    PLATFORM,
    CUSTOMER_ID,
    USERNAME,
    POST_TEXT,
    POST_TIMESTAMP,
    ENGAGEMENT_COUNT,
    RETWEET_COUNT,
    INFLUENCER_FLAG,
    FOLLOWER_COUNT,
    CREATED_DATE
)
WITH SOCIAL_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 3000))
),
ACCOUNTS_FOR_SOCIAL AS (
    SELECT 
        cm.CUSTOMER_ID,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM CUSTOMER_DATA.ACCOUNT a
    JOIN BILLING_DATA.CUSTOMER_MASTER cm ON a.ACCOUNT_ID = cm.ACCOUNT_ID
),
ACCOUNTS_COUNT_SOCIAL AS (
    SELECT COUNT(*) as CNT FROM ACCOUNTS_FOR_SOCIAL
)
SELECT 
    'SOCIAL-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as POST_ID,
    NULL as CASE_ID,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'twitter'
        WHEN 2 THEN 'facebook'
        WHEN 3 THEN 'instagram'
        ELSE 'linkedin'
    END as PLATFORM,
    afs.CUSTOMER_ID,
    'user' || UNIFORM(1000, 9999, RANDOM()) as USERNAME,
    CASE UNIFORM(1, 15, RANDOM())
        WHEN 1 THEN '@TelecomCompany Seriously?! 3 days without service and still no resolution! This is completely unacceptable! #NetworkDown #PoorService'
        WHEN 2 THEN 'Very disappointed with @TelecomCompany customer service today. Waited on hold for 45 minutes only to be disconnected. Not impressed.'
        WHEN 3 THEN '@TelecomCompany Why is my bill double this month?? I have not changed anything! Someone please explain!'
        WHEN 4 THEN 'Another day, another network outage. @TelecomCompany when will you fix the issues in my area? Getting really fed up with this.'
        WHEN 5 THEN 'Shoutout to @TelecomCompany support team! My issue was resolved quickly and professionally. Thank you!'
        WHEN 6 THEN '@TelecomCompany Internet speeds are terrible again. I pay for 500Mbps but only get 50. What gives?'
        WHEN 7 THEN 'Thinking about switching from @TelecomCompany after 5 years. Service quality has really declined lately.'
        WHEN 8 THEN '@TelecomCompany billing department charged me twice this month! Still waiting for refund after 2 weeks!'
        WHEN 9 THEN 'Best decision ever was switching to @TelecomCompany 5G! Lightning fast speeds and reliable service!'
        WHEN 10 THEN '@TelecomCompany mobile app keeps crashing. Cannot check my usage or pay my bill. Please fix!'
        WHEN 11 THEN 'Absolutely furious with @TelecomCompany! Hours of calls, no resolution, terrible service!'
        WHEN 12 THEN '@TelecomCompany Just upgraded to your premium plan and loving it so far! Great value for money!'
        WHEN 13 THEN 'Network down AGAIN in Porto? @TelecomCompany this is becoming ridiculous! Need better infrastructure!'
        WHEN 14 THEN '@TelecomCompany Why do you keep raising prices but service quality stays the same or gets worse??'
        ELSE 'Question for @TelecomCompany - what unlimited data plans do you offer? Need more details please.'
    END as POST_TEXT,
    DATEADD(hour, -UNIFORM(1, 2160, RANDOM()), CURRENT_TIMESTAMP()) as POST_TIMESTAMP,
    UNIFORM(0, 500, RANDOM()) as ENGAGEMENT_COUNT,
    UNIFORM(0, 100, RANDOM()) as RETWEET_COUNT,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 5 THEN TRUE ELSE FALSE END as INFLUENCER_FLAG,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 5 
        THEN UNIFORM(10000, 100000, RANDOM())
        ELSE UNIFORM(50, 5000, RANDOM())
    END as FOLLOWER_COUNT,
    DATEADD(hour, -UNIFORM(1, 2160, RANDOM()), CURRENT_TIMESTAMP()) as CREATED_DATE
FROM SOCIAL_GENERATOR sg
CROSS JOIN ACCOUNTS_COUNT_SOCIAL acs
LEFT JOIN ACCOUNTS_FOR_SOCIAL afs ON ((sg.ROW_NUM - 1) % acs.CNT) + 1 = afs.RN;

SELECT COUNT(*) || ' social media posts generated' as STATUS FROM SOCIAL_MEDIA_POST;

-- =====================================================================
-- STEP 20: GENERATE CHAT SESSIONS (8,000 chat sessions)
-- =====================================================================

SELECT 'Step 20: Generating 8,000 chat sessions...' as STATUS;

INSERT INTO CHAT_SESSION (
    SESSION_ID,
    CASE_ID,
    CUSTOMER_ID,
    AGENT_ID,
    AGENT_NAME,
    START_TIMESTAMP,
    END_TIMESTAMP,
    DURATION_SECONDS,
    TRANSCRIPT_TEXT,
    MESSAGES_COUNT,
    WAIT_TIME_SECONDS,
    SATISFACTION_RATING,
    ESCALATED,
    CREATED_DATE
)
WITH CHAT_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 8000))
),
ACCOUNTS_FOR_CHAT AS (
    SELECT 
        a.ACCOUNT_ID,
        cm.CUSTOMER_ID,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM CUSTOMER_DATA.ACCOUNT a
    JOIN BILLING_DATA.CUSTOMER_MASTER cm ON a.ACCOUNT_ID = cm.ACCOUNT_ID
),
ACCOUNTS_COUNT_CHAT AS (
    SELECT COUNT(*) as CNT FROM ACCOUNTS_FOR_CHAT
)
SELECT 
    'CHAT-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as SESSION_ID,
    NULL as CASE_ID,  -- No case linkage for most chats
    afc.CUSTOMER_ID,
    'AGENT-CHAT-' || LPAD(UNIFORM(1, 30, RANDOM())::VARCHAR, 3, '0') as AGENT_ID,
    'Chat Agent ' || LPAD(UNIFORM(1, 30, RANDOM())::VARCHAR, 3, '0') as AGENT_NAME,
    DATEADD(minute, -UNIFORM(1, 129600, RANDOM()), CURRENT_TIMESTAMP()) as START_TIMESTAMP,
    DATEADD(minute, UNIFORM(5, 60, RANDOM()), DATEADD(minute, -UNIFORM(1, 129600, RANDOM()), CURRENT_TIMESTAMP())) as END_TIMESTAMP,
    UNIFORM(5, 60, RANDOM()) * 60 as DURATION_SECONDS,  -- Convert minutes to seconds
    CASE UNIFORM(1, 6, RANDOM())
        WHEN 1 THEN '[Agent]: Hello! How can I help you today?\n[Customer]: Hi I am having issues with my mobile data\n[Agent]: I would be happy to help you with that. Can you describe the issue?\n[Customer]: Data is very slow and keeps disconnecting\n[Agent]: Let me check your account and run some diagnostics\n[Agent]: I can see there was a network issue in your area. It has been resolved now\n[Customer]: Okay thank you for checking'
        WHEN 2 THEN '[Agent]: Welcome to TelecomCompany chat support. How may I assist you?\n[Customer]: I need help understanding my bill\n[Agent]: Of course, I can help explain your charges\n[Customer]: Why is my bill higher this month?\n[Agent]: Let me review your account. I see you had additional data usage charges\n[Customer]: I thought I had unlimited?\n[Agent]: You have our 50GB plan. Additional usage is charged separately\n[Customer]: Can you upgrade me to unlimited?\n[Agent]: Absolutely, I can process that upgrade now'
        WHEN 3 THEN '[Agent]: Hi there! Thanks for contacting us. What brings you in today?\n[Customer]: Need technical support for my device setup\n[Agent]: I will be glad to walk you through the setup process\n[Customer]: I just got a new iPhone and cannot get it to work\n[Agent]: No problem! First, lets make sure your SIM card is properly installed\n[Customer]: Yes the SIM is in\n[Agent]: Great! Now go to Settings, then Cellular\n[Customer]: Okay found it\n[Agent]: Perfect! Now I will send you the configuration profile'
        WHEN 4 THEN '[Agent]: Hello! Welcome to TelecomCompany support. How can I help you today?\n[Customer]: I want to file a complaint about my service\n[Agent]: I am sorry to hear you are having issues. Can you tell me more?\n[Customer]: Service has been terrible for weeks now\n[Agent]: I sincerely apologize for that experience. Let me see how I can help\n[Customer]: I want compensation for all this downtime\n[Agent]: I understand. Let me review your account and see what credits we can apply'
        WHEN 5 THEN '[Agent]: Good afternoon! How may I assist you?\n[Customer]: Quick question about international roaming\n[Agent]: Of course! What would you like to know?\n[Customer]: Do you have any roaming packages for Europe?\n[Agent]: Yes we have several EU roaming options available\n[Customer]: What are the rates?\n[Agent]: Our EU Roaming Plus package is 9.99 euros for 7 days with 5GB data\n[Customer]: Perfect! Can you activate that for me?\n[Agent]: Absolutely! I will activate it right now'
        ELSE '[Agent]: Thanks for reaching out! What can I do for you?\n[Customer]: Just checking on my order status\n[Agent]: I can look that up for you. Can you provide your order number?\n[Customer]: Its ORDER-12345\n[Agent]: Thank you! Let me check that for you\n[Agent]: Your order is currently being processed and will ship tomorrow\n[Customer]: Great thanks for checking!\n[Agent]: You are welcome! Anything else I can help with today?\n[Customer]: No that is all thank you'
    END as TRANSCRIPT_TEXT,
    UNIFORM(5, 20, RANDOM()) as MESSAGES_COUNT,
    UNIFORM(0, 300, RANDOM()) as WAIT_TIME_SECONDS,
    UNIFORM(1, 5, RANDOM()) as SATISFACTION_RATING,
    CASE WHEN UNIFORM(1, 20, RANDOM()) = 1 THEN TRUE ELSE FALSE END as ESCALATED,  -- 5% escalated
    DATEADD(minute, -UNIFORM(1, 129600, RANDOM()), CURRENT_TIMESTAMP()) as CREATED_DATE
FROM CHAT_GENERATOR cg
CROSS JOIN ACCOUNTS_COUNT_CHAT acc
LEFT JOIN ACCOUNTS_FOR_CHAT afc ON (cg.ROW_NUM % acc.CNT) + 1 = afc.RN;

SELECT COUNT(*) || ' chat sessions generated' as STATUS FROM CHAT_SESSION;

-- =====================================================================
-- STEP 21: GENERATE SURVEY RESPONSES (12,000 surveys)
-- =====================================================================

SELECT 'Step 21: Generating 12,000 survey responses...' as STATUS;

INSERT INTO SURVEY_RESPONSE (
    RESPONSE_ID,
    SURVEY_TYPE,
    CUSTOMER_ID,
    CASE_ID,
    INTERACTION_ID,
    SURVEY_NAME,
    SCORE,
    COMMENT_TEXT,
    RESPONSE_TIMESTAMP,
    SURVEY_SENT_DATE,
    CHANNEL,
    PROMOTER_CATEGORY,
    CREATED_DATE
)
WITH SURVEY_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 12000))
),
ACCOUNTS_FOR_SURVEY AS (
    SELECT 
        a.ACCOUNT_ID,
        cm.CUSTOMER_ID,
        a.TIER,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM CUSTOMER_DATA.ACCOUNT a
    JOIN BILLING_DATA.CUSTOMER_MASTER cm ON a.ACCOUNT_ID = cm.ACCOUNT_ID
),
ACCOUNTS_COUNT_SURVEY AS (
    SELECT COUNT(*) as CNT FROM ACCOUNTS_FOR_SURVEY
),
SURVEY_WITH_TYPE AS (
    SELECT 
        sg.ROW_NUM,
        afs.CUSTOMER_ID,
        CASE UNIFORM(1, 4, RANDOM())
            WHEN 1 THEN 'nps'
            WHEN 2 THEN 'csat'
            WHEN 3 THEN 'ces'
            ELSE 'general_feedback'
        END as SURVEY_TYPE
    FROM SURVEY_GENERATOR sg
    CROSS JOIN ACCOUNTS_COUNT_SURVEY acs
    LEFT JOIN ACCOUNTS_FOR_SURVEY afs ON (sg.ROW_NUM % acs.CNT) + 1 = afs.RN
)
SELECT 
    'SURVEY-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as RESPONSE_ID,
    SURVEY_TYPE,
    CUSTOMER_ID,
    NULL as CASE_ID,  -- Most surveys not linked to cases
    NULL as INTERACTION_ID,  -- Optional reference to specific interaction
    CASE SURVEY_TYPE
        WHEN 'nps' THEN 'Net Promoter Score Survey'
        WHEN 'csat' THEN 'Customer Satisfaction Survey'
        WHEN 'ces' THEN 'Customer Effort Score Survey'
        ELSE 'General Feedback Survey'
    END as SURVEY_NAME,
    -- Score depends on survey type: NPS (0-10), CSAT (1-5), CES (1-7), General (1-5)
    CASE SURVEY_TYPE
        WHEN 'nps' THEN UNIFORM(0, 10, RANDOM())
        WHEN 'csat' THEN UNIFORM(1, 5, RANDOM())
        WHEN 'ces' THEN UNIFORM(1, 7, RANDOM())
        ELSE UNIFORM(1, 5, RANDOM())
    END as SCORE,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'Service has been excellent overall. Very satisfied with the network quality and customer support.'
        WHEN 2 THEN 'Recent network issues have been very frustrating. Hope they get resolved soon.'
        WHEN 3 THEN 'Billing is confusing and difficult to understand. Need clearer invoices.'
        WHEN 4 THEN 'Customer service agents are helpful but wait times are too long.'
        WHEN 5 THEN 'Good value for money. Happy with my plan and pricing.'
        WHEN 6 THEN 'Network coverage needs improvement in my area. Lots of dead zones.'
        WHEN 7 THEN 'Been a customer for years and generally satisfied. Keep up the good work.'
        WHEN 8 THEN 'Disappointed with recent price increases. Considering switching providers.'
        WHEN 9 THEN 'Technical support has been very helpful in resolving my issues.'
        ELSE 'No major complaints. Service is adequate for my needs.'
    END as COMMENT_TEXT,
    DATEADD(day, -UNIFORM(1, 180, RANDOM()), CURRENT_TIMESTAMP()) as RESPONSE_TIMESTAMP,
    DATEADD(day, -UNIFORM(1, 180, RANDOM()) - 1, CURRENT_DATE()) as SURVEY_SENT_DATE,  -- Sent day before response
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'email'
        WHEN 2 THEN 'sms'
        WHEN 3 THEN 'web'
        ELSE 'app'
    END as CHANNEL,
    -- NPS categories: 0-6=detractor, 7-8=passive, 9-10=promoter
    CASE 
        WHEN SURVEY_TYPE = 'nps' THEN
            CASE 
                WHEN UNIFORM(0, 10, RANDOM()) <= 6 THEN 'detractor'
                WHEN UNIFORM(0, 10, RANDOM()) <= 8 THEN 'passive'
                ELSE 'promoter'
            END
        ELSE NULL
    END as PROMOTER_CATEGORY,
    DATEADD(day, -UNIFORM(1, 180, RANDOM()), CURRENT_TIMESTAMP()) as CREATED_DATE
FROM SURVEY_WITH_TYPE;

SELECT COUNT(*) || ' survey responses generated' as STATUS FROM SURVEY_RESPONSE;

-- =====================================================================
-- STEP 22: GENERATE UNIFIED COMPLAINTS (30,000 unified records)
-- =====================================================================

SELECT 'Step 22: Generating unified complaint view...' as STATUS;

-- Combine all complaint sources into unified table
INSERT INTO UNIFIED_COMPLAINT (
    COMPLAINT_ID,
    CUSTOMER_ID,
    ACCOUNT_ID,
    CHANNEL,
    SOURCE_ID,
    COMPLAINT_TIMESTAMP,
    COMPLAINT_TEXT,
    CATEGORY,
    SUBCATEGORY,
    PRIORITY,
    STATUS,
    NETWORK_INCIDENT_ID,
    CREATED_DATE
)
-- Voice transcripts
SELECT 
    'COMP-V-' || LPAD(ROW_NUMBER() OVER (ORDER BY vt.CALL_ID)::VARCHAR, 8, '0'),
    vt.CUSTOMER_ID,
    vt.ACCOUNT_ID,
    'Voice',
    vt.CALL_ID,
    vt.CALL_TIMESTAMP,
    vt.TRANSCRIPT_TEXT,
    c.CATEGORY,
    NULL,
    CASE WHEN vt.CUSTOMER_SATISFACTION <= 2 THEN 'High' ELSE 'Medium' END,
    CASE WHEN vt.FIRST_CALL_RESOLUTION THEN 'Resolved' ELSE 'Open' END,
    vt.NETWORK_INCIDENT_ID,
    vt.CREATED_DATE
FROM VOICE_TRANSCRIPT vt
LEFT JOIN CUSTOMER_DATA.CASE c ON vt.CASE_ID = c.CASE_ID

UNION ALL

-- Email complaints
SELECT 
    'COMP-E-' || LPAD(ROW_NUMBER() OVER (ORDER BY EMAIL_ID)::VARCHAR, 8, '0'),
    CUSTOMER_ID,
    NULL as ACCOUNT_ID,
    'Email',
    EMAIL_ID,
    RECEIVED_TIMESTAMP,
    BODY_TEXT,
    CATEGORY,
    NULL,
    PRIORITY,
    CASE WHEN IS_REPLIED THEN 'Resolved' ELSE 'Open' END,
    NULL as NETWORK_INCIDENT_ID,
    CREATED_DATE
FROM EMAIL_COMPLAINT

UNION ALL

-- Social media posts (negative sentiment implied by content)
SELECT 
    'COMP-S-' || LPAD(ROW_NUMBER() OVER (ORDER BY POST_ID)::VARCHAR, 8, '0'),
    CUSTOMER_ID,
    NULL as ACCOUNT_ID,
    'Social',
    POST_ID,
    POST_TIMESTAMP,
    POST_TEXT,
    'social_media_complaint' as CATEGORY,
    NULL,
    CASE WHEN ENGAGEMENT_COUNT > 100 OR INFLUENCER_FLAG THEN 'Critical' ELSE 'Medium' END,
    'Open' as STATUS,
    NULL as NETWORK_INCIDENT_ID,
    CREATED_DATE
FROM SOCIAL_MEDIA_POST
WHERE POST_TEXT LIKE '%@TelecomCompany%' 
    AND (POST_TEXT LIKE '%furious%' OR POST_TEXT LIKE '%terrible%' OR POST_TEXT LIKE '%unacceptable%'
         OR POST_TEXT LIKE '%disappointed%' OR POST_TEXT LIKE '%fed up%' OR POST_TEXT LIKE '%ridiculous%')

UNION ALL

-- Chat sessions with complaints
SELECT 
    'COMP-C-' || LPAD(ROW_NUMBER() OVER (ORDER BY SESSION_ID)::VARCHAR, 8, '0'),
    CUSTOMER_ID,
    NULL as ACCOUNT_ID,
    'Chat',
    SESSION_ID,
    START_TIMESTAMP,
    TRANSCRIPT_TEXT,
    'chat_support' as CATEGORY,
    NULL,
    CASE WHEN SATISFACTION_RATING <= 2 THEN 'High' ELSE 'Low' END,
    CASE WHEN ESCALATED THEN 'Escalated' ELSE 'Resolved' END,
    NULL as NETWORK_INCIDENT_ID,
    CREATED_DATE
FROM CHAT_SESSION
WHERE TRANSCRIPT_TEXT LIKE '%complaint%' OR TRANSCRIPT_TEXT LIKE '%issue%' OR TRANSCRIPT_TEXT LIKE '%problem%'

UNION ALL

-- Survey responses with low scores
SELECT 
    'COMP-SV-' || LPAD(ROW_NUMBER() OVER (ORDER BY RESPONSE_ID)::VARCHAR, 8, '0'),
    CUSTOMER_ID,
    NULL as ACCOUNT_ID,
    'Survey',
    RESPONSE_ID,
    RESPONSE_TIMESTAMP,
    COMMENT_TEXT,
    'survey_feedback',
    SURVEY_TYPE,
    CASE WHEN SCORE <= 2 THEN 'High' ELSE 'Low' END,
    'Closed',
    NULL as NETWORK_INCIDENT_ID,
    CREATED_DATE
FROM SURVEY_RESPONSE
WHERE SCORE <= 3;

SELECT COUNT(*) || ' unified complaints generated' as STATUS FROM UNIFIED_COMPLAINT;

-- =====================================================================
-- SUMMARY - PART 3 COMPLETE
-- =====================================================================

SELECT '================================================' as SEPARATOR;
SELECT 'PART 3 COMPLETE - All complaint data generated!' as STATUS;
SELECT '================================================' as SEPARATOR;

SELECT 'COMPLAINT DATA SUMMARY:' as CATEGORY, COUNT(*) as RECORDS FROM VOICE_TRANSCRIPT
UNION ALL SELECT 'Email Complaints', COUNT(*) FROM EMAIL_COMPLAINT
UNION ALL SELECT 'Social Media Posts', COUNT(*) FROM SOCIAL_MEDIA_POST
UNION ALL SELECT 'Chat Sessions', COUNT(*) FROM CHAT_SESSION
UNION ALL SELECT 'Survey Responses', COUNT(*) FROM SURVEY_RESPONSE
UNION ALL SELECT 'Unified Complaints', COUNT(*) FROM UNIFIED_COMPLAINT
ORDER BY RECORDS DESC;

SELECT '================================================' as SEPARATOR;
SELECT 'ALL DATA GENERATION COMPLETE!' as STATUS;
SELECT 'Next step: Run create_sentiment_models.sql for AI analysis' as NEXT_STEP;
SELECT '================================================' as SEPARATOR;

