-- =====================================================================
-- UC3 - Customer Complaints & Sentiment Analysis
-- Sentiment Models and AI Integration Script
-- =====================================================================
-- Purpose: Set up Snowflake Cortex AI for sentiment analysis
-- Prerequisite: Run load_customer_data.sql first
-- Execution: Run in Snowflake UI (Worksheets) with "Run All"
-- Time: ~5-10 minutes
-- =====================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE UC3_CUSTOMER_COMPLAINTS;

-- =====================================================================
-- SECTION 1: SENTIMENT ANALYSIS PROCEDURES
-- =====================================================================

USE SCHEMA SENTIMENT;

SELECT 'Creating sentiment analysis procedures...' as STATUS;

-- Procedure to analyze sentiment using Cortex AI
CREATE OR REPLACE PROCEDURE ANALYZE_COMPLAINT_SENTIMENT()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
  result_set RESULTSET;
BEGIN
  result_set := (
    SELECT 
      c.COMPLAINT_ID,
      c.CHANNEL,
      c.COMPLAINT_TEXT,
      c.COMPLAINT_TIMESTAMP,
      -- Use Snowflake Cortex for sentiment analysis
      SNOWFLAKE.CORTEX.SENTIMENT(c.COMPLAINT_TEXT) as SENTIMENT_SCORE,
      CASE 
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(c.COMPLAINT_TEXT) > 0.3 THEN 'Positive'
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(c.COMPLAINT_TEXT) < -0.3 THEN 'Negative'
        ELSE 'Neutral'
      END as SENTIMENT_CATEGORY
    FROM COMPLAINTS.UNIFIED_COMPLAINT c
    LEFT JOIN SENTIMENT.SENTIMENT_SCORE s 
      ON s.COMPLAINT_ID = c.COMPLAINT_ID
    WHERE s.SENTIMENT_ID IS NULL -- Only analyze new complaints
    LIMIT 100 -- Process in batches
  );
  RETURN TABLE(result_set);
END;
$$;

-- Procedure to batch update sentiment scores
CREATE OR REPLACE PROCEDURE UPDATE_SENTIMENT_SCORES()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  rows_inserted INT;
BEGIN
  -- Insert sentiment scores for complaints
  INSERT INTO SENTIMENT.SENTIMENT_SCORE (
    SENTIMENT_ID,
    COMPLAINT_ID,
    OVERALL_SENTIMENT,
    SENTIMENT_SCORE,
    CONFIDENCE_LEVEL,
    ANALYZED_TIMESTAMP,
    MODEL_VERSION,
    CREATED_DATE
  )
  SELECT 
    'SEN-' || MD5(c.COMPLAINT_ID) as SENTIMENT_ID,
    c.COMPLAINT_ID,
    CASE 
      WHEN SNOWFLAKE.CORTEX.SENTIMENT(c.COMPLAINT_TEXT) > 0.3 THEN 'Positive'
      WHEN SNOWFLAKE.CORTEX.SENTIMENT(c.COMPLAINT_TEXT) < -0.3 THEN 'Negative'
      ELSE 'Neutral'
    END as OVERALL_SENTIMENT,
    SNOWFLAKE.CORTEX.SENTIMENT(c.COMPLAINT_TEXT) as SENTIMENT_SCORE,
    0.85 as CONFIDENCE_LEVEL,
    CURRENT_TIMESTAMP() as ANALYZED_TIMESTAMP,
    'cortex_v1' as MODEL_VERSION,
    CURRENT_TIMESTAMP() as CREATED_DATE
  FROM COMPLAINTS.UNIFIED_COMPLAINT c
  WHERE c.COMPLAINT_ID NOT IN (SELECT COMPLAINT_ID FROM SENTIMENT.SENTIMENT_SCORE);
  
  rows_inserted := SQLROWCOUNT;
  
  RETURN 'Sentiment scores updated: ' || rows_inserted || ' rows inserted';
END;
$$;

-- Procedure to classify complaint topics
CREATE OR REPLACE PROCEDURE CLASSIFY_COMPLAINT_TOPICS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  rows_inserted INT;
BEGIN
  -- Insert topic classifications
  INSERT INTO SENTIMENT.TOPIC_CLASSIFICATION (
    TOPIC_ID,
    COMPLAINT_ID,
    PRIMARY_CATEGORY,
    SUBCATEGORY,
    ROOT_CAUSE,
    KEYWORDS_DETECTED,
    CLASSIFICATION_CONFIDENCE,
    ANALYZED_TIMESTAMP,
    CREATED_DATE
  )
  SELECT
    'TOP-' || MD5(c.COMPLAINT_ID) as TOPIC_ID,
    c.COMPLAINT_ID,
    c.CATEGORY as PRIMARY_CATEGORY,
    c.SUBCATEGORY,
    -- Simple keyword-based root cause detection
    CASE
      WHEN LOWER(c.COMPLAINT_TEXT) LIKE '%down%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%outage%' 
        THEN 'Service Outage'
      WHEN LOWER(c.COMPLAINT_TEXT) LIKE '%slow%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%speed%' 
        THEN 'Performance Issue'
      WHEN LOWER(c.COMPLAINT_TEXT) LIKE '%bill%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%charge%' 
        THEN 'Billing Issue'
      WHEN LOWER(c.COMPLAINT_TEXT) LIKE '%router%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%modem%' 
        THEN 'Equipment Issue'
      ELSE 'General'
    END as ROOT_CAUSE,
    -- Extract key terms
    SUBSTR(c.COMPLAINT_TEXT, 1, 200) as KEYWORDS_DETECTED,
    0.75 as CLASSIFICATION_CONFIDENCE,
    CURRENT_TIMESTAMP() as ANALYZED_TIMESTAMP,
    CURRENT_TIMESTAMP() as CREATED_DATE
  FROM COMPLAINTS.UNIFIED_COMPLAINT c
  WHERE c.COMPLAINT_ID NOT IN (SELECT COMPLAINT_ID FROM SENTIMENT.TOPIC_CLASSIFICATION);
  
  rows_inserted := SQLROWCOUNT;
  
  RETURN 'Topic classifications created: ' || rows_inserted || ' rows inserted';
END;
$$;

-- Procedure to detect emotions
CREATE OR REPLACE PROCEDURE DETECT_EMOTIONS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  rows_inserted INT;
BEGIN
  -- Insert emotion detections
  INSERT INTO SENTIMENT.EMOTION_DETECTION (
    EMOTION_ID,
    COMPLAINT_ID,
    PRIMARY_EMOTION,
    EMOTION_INTENSITY,
    SECONDARY_EMOTIONS,
    ANALYZED_TIMESTAMP,
    CREATED_DATE
  )
  SELECT
    'EMO-' || MD5(c.COMPLAINT_ID) as EMOTION_ID,
    c.COMPLAINT_ID,
    -- Simple keyword-based emotion detection
    CASE
      WHEN LOWER(c.COMPLAINT_TEXT) LIKE '%terrible%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%horrible%' 
           OR LOWER(c.COMPLAINT_TEXT) LIKE '%worst%'
        THEN 'Angry'
      WHEN LOWER(c.COMPLAINT_TEXT) LIKE '%frustrated%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%annoying%' 
           OR LOWER(c.COMPLAINT_TEXT) LIKE '%upset%'
        THEN 'Frustrated'
      WHEN LOWER(c.COMPLAINT_TEXT) LIKE '%confused%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%don''t understand%' 
        THEN 'Confused'
      WHEN LOWER(c.COMPLAINT_TEXT) LIKE '%excellent%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%great%' 
           OR LOWER(c.COMPLAINT_TEXT) LIKE '%happy%' OR LOWER(c.COMPLAINT_TEXT) LIKE '%satisfied%'
        THEN 'Satisfied'
      ELSE 'Neutral'
    END as PRIMARY_EMOTION,
    -- Calculate intensity based on sentiment score
    CASE
      WHEN ABS(ss.SENTIMENT_SCORE) > 0.7 THEN 90
      WHEN ABS(ss.SENTIMENT_SCORE) > 0.5 THEN 70
      WHEN ABS(ss.SENTIMENT_SCORE) > 0.3 THEN 50
      ELSE 30
    END as EMOTION_INTENSITY,
    NULL as SECONDARY_EMOTIONS,
    CURRENT_TIMESTAMP() as ANALYZED_TIMESTAMP,
    CURRENT_TIMESTAMP() as CREATED_DATE
  FROM COMPLAINTS.UNIFIED_COMPLAINT c
  LEFT JOIN SENTIMENT.SENTIMENT_SCORE ss ON ss.COMPLAINT_ID = c.COMPLAINT_ID
  WHERE c.COMPLAINT_ID NOT IN (SELECT COMPLAINT_ID FROM SENTIMENT.EMOTION_DETECTION);
  
  rows_inserted := SQLROWCOUNT;
  
  RETURN 'Emotion detections created: ' || rows_inserted || ' rows inserted';
END;
$$;

-- Procedure to predict churn risk
CREATE OR REPLACE PROCEDURE PREDICT_CHURN_RISK()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  rows_inserted INT;
BEGIN
  -- Calculate churn risk for customers
  INSERT INTO SENTIMENT.CHURN_RISK_PREDICTION (
    PREDICTION_ID,
    CUSTOMER_ID,
    CHURN_PROBABILITY,
    RISK_LEVEL,
    RISK_FACTORS,
    PREDICTION_DATE,
    MODEL_VERSION,
    RECOMMENDED_ACTION,
    INTERVENTION_PRIORITY,
    CREATED_DATE
  )
  SELECT
    'CHR-' || MD5(cis.CUSTOMER_ID) as PREDICTION_ID,
    cis.CUSTOMER_ID,
    -- Calculate churn probability based on multiple factors
    LEAST(100, (
      (100 - cis.OVERALL_HEALTH_SCORE) * 0.40 +
      (100 - cis.COMPLAINT_FREQUENCY_SCORE) * 0.30 +
      (100 - cis.SENTIMENT_TREND_SCORE) * 0.20 +
      (100 - cis.BILLING_DISPUTE_SCORE) * 0.10
    )) as CHURN_PROBABILITY,
    -- Determine risk level
    CASE
      WHEN cis.OVERALL_HEALTH_SCORE < 50 OR cis.CHURN_RISK_FLAG = TRUE THEN 'Critical'
      WHEN cis.OVERALL_HEALTH_SCORE < 65 THEN 'High'
      WHEN cis.OVERALL_HEALTH_SCORE < 80 THEN 'Medium'
      ELSE 'Low'
    END as RISK_LEVEL,
    -- Build risk factors JSON
    OBJECT_CONSTRUCT(
      'health_score', cis.OVERALL_HEALTH_SCORE,
      'complaint_frequency', cis.COMPLAINT_FREQUENCY_SCORE,
      'sentiment_trend', cis.SENTIMENT_TREND_SCORE,
      'billing_disputes', cis.BILLING_DISPUTE_SCORE,
      'payment_behavior', cis.PAYMENT_BEHAVIOR_SCORE
    ) as RISK_FACTORS,
    CURRENT_DATE() as PREDICTION_DATE,
    'rule_based_v1' as MODEL_VERSION,
    -- Recommended actions
    CASE
      WHEN cis.OVERALL_HEALTH_SCORE < 50 THEN 'Immediate intervention: Assign retention specialist, offer service credit'
      WHEN cis.OVERALL_HEALTH_SCORE < 65 THEN 'High priority: Contact customer within 24h, review service quality'
      WHEN cis.OVERALL_HEALTH_SCORE < 80 THEN 'Monitor closely: Schedule proactive check-in call'
      ELSE 'Standard monitoring: Continue regular customer service'
    END as RECOMMENDED_ACTION,
    -- Priority for intervention
    CASE
      WHEN cis.OVERALL_HEALTH_SCORE < 50 THEN 1
      WHEN cis.OVERALL_HEALTH_SCORE < 65 THEN 2
      WHEN cis.OVERALL_HEALTH_SCORE < 80 THEN 3
      ELSE 4
    END as INTERVENTION_PRIORITY,
    CURRENT_TIMESTAMP() as CREATED_DATE
  FROM INTEGRATION.CUSTOMER_IMPACT_SCORE cis
  WHERE cis.CUSTOMER_ID NOT IN (SELECT CUSTOMER_ID FROM SENTIMENT.CHURN_RISK_PREDICTION);
  
  rows_inserted := SQLROWCOUNT;
  
  RETURN 'Churn risk predictions created: ' || rows_inserted || ' rows inserted';
END;
$$;

-- Procedure to create alerts for critical issues
CREATE OR REPLACE PROCEDURE CREATE_CRITICAL_ALERTS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  rows_inserted INT;
BEGIN
  -- Create alerts for high-risk situations
  INSERT INTO SENTIMENT.ALERT_TRIGGER (
    ALERT_ID,
    COMPLAINT_ID,
    CUSTOMER_ID,
    ALERT_TYPE,
    SEVERITY,
    ALERT_REASON,
    TRIGGERED_TIMESTAMP,
    ASSIGNED_TO,
    STATUS,
    CREATED_DATE
  )
  SELECT
    'ALT-' || MD5(c.COMPLAINT_ID) as ALERT_ID,
    c.COMPLAINT_ID,
    c.CUSTOMER_ID,
    -- Determine alert type
    CASE
      WHEN crp.RISK_LEVEL = 'Critical' THEN 'High_Churn_Risk'
      WHEN sp.INFLUENCER_FLAG = TRUE THEN 'Viral_Social'
      WHEN a.TIER = 'Gold' THEN 'VIP_Customer'
      WHEN COUNT(*) OVER (PARTITION BY c.CUSTOMER_ID) > 3 THEN 'Repeated_Issue'
      ELSE 'Critical_Complaint'
    END as ALERT_TYPE,
    -- Severity
    CASE
      WHEN crp.RISK_LEVEL = 'Critical' OR sp.INFLUENCER_FLAG = TRUE THEN 'Critical'
      WHEN a.TIER = 'Gold' OR crp.RISK_LEVEL = 'High' THEN 'High'
      ELSE 'Medium'
    END as SEVERITY,
    -- Alert reason
    'Customer ' || c.CUSTOMER_ID || ' requires immediate attention: ' ||
    CASE
      WHEN crp.RISK_LEVEL = 'Critical' THEN 'High churn risk detected'
      WHEN sp.INFLUENCER_FLAG = TRUE THEN 'Public social media complaint from influencer'
      WHEN a.TIER = 'Gold' THEN 'VIP customer complaint'
      ELSE 'Multiple complaints in short period'
    END as ALERT_REASON,
    CURRENT_TIMESTAMP() as TRIGGERED_TIMESTAMP,
    'SYSTEM_ASSIGN' as ASSIGNED_TO,
    'New' as STATUS,
    CURRENT_TIMESTAMP() as CREATED_DATE
  FROM COMPLAINTS.UNIFIED_COMPLAINT c
  JOIN CUSTOMER_DATA.ACCOUNT a ON a.ACCOUNT_ID = c.CUSTOMER_ID
  LEFT JOIN SENTIMENT.CHURN_RISK_PREDICTION crp ON crp.CUSTOMER_ID = c.CUSTOMER_ID
  LEFT JOIN COMPLAINTS.SOCIAL_MEDIA_POST sp ON sp.POST_ID = c.SOURCE_ID AND c.CHANNEL = 'Social'
  WHERE 
    (crp.RISK_LEVEL IN ('Critical', 'High') 
     OR sp.INFLUENCER_FLAG = TRUE 
     OR a.TIER = 'Gold'
     OR c.PRIORITY = 'Critical')
    AND c.COMPLAINT_ID NOT IN (SELECT COMPLAINT_ID FROM SENTIMENT.ALERT_TRIGGER WHERE COMPLAINT_ID IS NOT NULL);
  
  rows_inserted := SQLROWCOUNT;
  
  RETURN 'Critical alerts created: ' || rows_inserted || ' alerts';
END;
$$;

-- =====================================================================
-- SECTION 2: EXECUTE AI ANALYSIS
-- =====================================================================

SELECT 'Executing AI analysis procedures...' as STATUS;

-- Run sentiment analysis
CALL UPDATE_SENTIMENT_SCORES();

-- Classify topics
CALL CLASSIFY_COMPLAINT_TOPICS();

-- Detect emotions
CALL DETECT_EMOTIONS();

-- Predict churn risk
CALL PREDICT_CHURN_RISK();

-- Create critical alerts
CALL CREATE_CRITICAL_ALERTS();

-- =====================================================================
-- SECTION 3: VERIFY RESULTS
-- =====================================================================

SELECT 'Verifying AI analysis results...' as STATUS;

-- Check sentiment distribution
SELECT 
    'Sentiment Distribution' as METRIC,
    OVERALL_SENTIMENT,
    COUNT(*) as COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as PERCENTAGE
FROM SENTIMENT.SENTIMENT_SCORE
GROUP BY OVERALL_SENTIMENT
ORDER BY COUNT DESC;

-- Check emotion distribution
SELECT 
    'Emotion Distribution' as METRIC,
    PRIMARY_EMOTION,
    COUNT(*) as COUNT,
    ROUND(AVG(EMOTION_INTENSITY), 2) as AVG_INTENSITY
FROM SENTIMENT.EMOTION_DETECTION
GROUP BY PRIMARY_EMOTION
ORDER BY COUNT DESC;

-- Check churn risk levels
SELECT 
    'Churn Risk Distribution' as METRIC,
    RISK_LEVEL,
    COUNT(*) as COUNT,
    ROUND(AVG(CHURN_PROBABILITY), 2) as AVG_CHURN_PROBABILITY
FROM SENTIMENT.CHURN_RISK_PREDICTION
GROUP BY RISK_LEVEL
ORDER BY 
    CASE RISK_LEVEL
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'Low' THEN 4
    END;

-- Check alert distribution
SELECT 
    'Alert Distribution' as METRIC,
    ALERT_TYPE,
    SEVERITY,
    COUNT(*) as COUNT
FROM SENTIMENT.ALERT_TRIGGER
GROUP BY ALERT_TYPE, SEVERITY
ORDER BY COUNT DESC;

-- =====================================================================
-- SECTION 4: CREATE HELPER VIEWS
-- =====================================================================

USE SCHEMA ANALYTICS;

SELECT 'Creating analytics helper views...' as STATUS;

-- Sentiment trend by channel
CREATE OR REPLACE VIEW V_SENTIMENT_BY_CHANNEL AS
SELECT
    c.CHANNEL,
    COUNT(*) as TOTAL_COMPLAINTS,
    SUM(CASE WHEN s.OVERALL_SENTIMENT = 'Positive' THEN 1 ELSE 0 END) as POSITIVE_COUNT,
    SUM(CASE WHEN s.OVERALL_SENTIMENT = 'Neutral' THEN 1 ELSE 0 END) as NEUTRAL_COUNT,
    SUM(CASE WHEN s.OVERALL_SENTIMENT = 'Negative' THEN 1 ELSE 0 END) as NEGATIVE_COUNT,
    ROUND(AVG(s.SENTIMENT_SCORE), 4) as AVG_SENTIMENT_SCORE,
    ROUND(SUM(CASE WHEN s.OVERALL_SENTIMENT = 'Negative' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as NEGATIVE_PERCENTAGE
FROM COMPLAINTS.UNIFIED_COMPLAINT c
JOIN SENTIMENT.SENTIMENT_SCORE s ON s.COMPLAINT_ID = c.COMPLAINT_ID
GROUP BY c.CHANNEL
ORDER BY NEGATIVE_PERCENTAGE DESC;

-- High risk customers
CREATE OR REPLACE VIEW V_HIGH_RISK_CUSTOMERS AS
SELECT
    a.ACCOUNT_ID,
    a.ACCOUNT_NAME,
    a.ACCOUNT_TYPE,
    a.TIER,
    a.REGION,
    crp.CHURN_PROBABILITY,
    crp.RISK_LEVEL,
    crp.RECOMMENDED_ACTION,
    cis.OVERALL_HEALTH_SCORE,
    cis.COMPLAINT_FREQUENCY_SCORE,
    cis.BILLING_DISPUTE_SCORE,
    COUNT(DISTINCT c.COMPLAINT_ID) as RECENT_COMPLAINTS,
    AVG(s.SENTIMENT_SCORE) as AVG_SENTIMENT,
    crp.PREDICTION_DATE
FROM CUSTOMER_DATA.ACCOUNT a
JOIN SENTIMENT.CHURN_RISK_PREDICTION crp ON crp.CUSTOMER_ID = a.ACCOUNT_ID
JOIN INTEGRATION.CUSTOMER_IMPACT_SCORE cis ON cis.CUSTOMER_ID = a.ACCOUNT_ID
LEFT JOIN COMPLAINTS.UNIFIED_COMPLAINT c 
    ON c.CUSTOMER_ID = a.ACCOUNT_ID 
    AND c.COMPLAINT_TIMESTAMP >= DATEADD(MONTH, -3, CURRENT_DATE())
LEFT JOIN SENTIMENT.SENTIMENT_SCORE s ON s.COMPLAINT_ID = c.COMPLAINT_ID
WHERE crp.RISK_LEVEL IN ('Critical', 'High')
GROUP BY 
    a.ACCOUNT_ID, a.ACCOUNT_NAME, a.ACCOUNT_TYPE, a.TIER, a.REGION,
    crp.CHURN_PROBABILITY, crp.RISK_LEVEL, crp.RECOMMENDED_ACTION,
    cis.OVERALL_HEALTH_SCORE, cis.COMPLAINT_FREQUENCY_SCORE, cis.BILLING_DISPUTE_SCORE,
    crp.PREDICTION_DATE
ORDER BY crp.CHURN_PROBABILITY DESC;

-- =====================================================================
-- SECTION 5: SUMMARY
-- =====================================================================

SELECT '==========================================================' as MESSAGE
UNION ALL SELECT 'SENTIMENT ANALYSIS & AI MODELS SETUP COMPLETE'
UNION ALL SELECT '==========================================================='
UNION ALL SELECT ''
UNION ALL SELECT 'SUMMARY:'
UNION ALL SELECT '-----------------------------------------------------------'
UNION ALL SELECT 'Sentiment Analysis:'
UNION ALL SELECT '  - Sentiment Scores: ' || (SELECT COUNT(*) FROM SENTIMENT.SENTIMENT_SCORE)
UNION ALL SELECT '  - Topic Classifications: ' || (SELECT COUNT(*) FROM SENTIMENT.TOPIC_CLASSIFICATION)
UNION ALL SELECT '  - Emotion Detections: ' || (SELECT COUNT(*) FROM SENTIMENT.EMOTION_DETECTION)
UNION ALL SELECT ''
UNION ALL SELECT 'Predictive Models:'
UNION ALL SELECT '  - Churn Risk Predictions: ' || (SELECT COUNT(*) FROM SENTIMENT.CHURN_RISK_PREDICTION)
UNION ALL SELECT '  - Critical Alerts: ' || (SELECT COUNT(*) FROM SENTIMENT.ALERT_TRIGGER)
UNION ALL SELECT ''
UNION ALL SELECT 'Churn Risk Summary:'
UNION ALL SELECT '  - Critical Risk: ' || (SELECT COUNT(*) FROM SENTIMENT.CHURN_RISK_PREDICTION WHERE RISK_LEVEL = 'Critical')
UNION ALL SELECT '  - High Risk: ' || (SELECT COUNT(*) FROM SENTIMENT.CHURN_RISK_PREDICTION WHERE RISK_LEVEL = 'High')
UNION ALL SELECT '  - Medium Risk: ' || (SELECT COUNT(*) FROM SENTIMENT.CHURN_RISK_PREDICTION WHERE RISK_LEVEL = 'Medium')
UNION ALL SELECT '  - Low Risk: ' || (SELECT COUNT(*) FROM SENTIMENT.CHURN_RISK_PREDICTION WHERE RISK_LEVEL = 'Low')
UNION ALL SELECT ''
UNION ALL SELECT '==========================================================='
UNION ALL SELECT 'NEXT STEP: Deploy Streamlit application'
UNION ALL SELECT '===========================================================';

-- Sample high-risk customers
SELECT 'Sample High-Risk Customers:' as INFO;

SELECT 
    ACCOUNT_ID,
    ACCOUNT_NAME,
    TIER,
    CHURN_PROBABILITY as CHURN_PROB_PCT,
    RISK_LEVEL,
    RECENT_COMPLAINTS,
    ROUND(AVG_SENTIMENT, 2) as AVG_SENTIMENT
FROM ANALYTICS.V_HIGH_RISK_CUSTOMERS
ORDER BY CHURN_PROBABILITY DESC
LIMIT 10;

