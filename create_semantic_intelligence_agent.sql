-- ========================================
-- CUSTOMER COMPLAINTS & SENTIMENT ANALYSIS
-- Snowflake Intelligence Agent Setup
-- ========================================
-- This script creates semantic views and AI agent for natural language queries
-- Prerequisite: setup_customer_complaints.sql and data generation must be completed
-- Following pattern from demo_setup.sql
-- ========================================

USE ROLE SYSADMIN;

-- Enable Snowflake Intelligence
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS;

GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE SYSADMIN;
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE SYSADMIN;

USE DATABASE UC3_CUSTOMER_COMPLAINTS;
USE SCHEMA COMPLAINTS;

-- ========================================
-- CREATE SEMANTIC VIEW FOR COMPLAINTS
-- ========================================

CREATE OR REPLACE SEMANTIC VIEW UC3_CUSTOMER_COMPLAINTS.COMPLAINTS.COMPLAINTS_SEMANTIC_VIEW
  tables (
    COMPLAINTS as UNIFIED_COMPLAINT primary key (COMPLAINT_ID) with synonyms=('customer complaints','complaints','issues') comment='All customer complaints from multiple channels'
  )
  facts (
    COMPLAINTS.COMPLAINT_RECORD as 1 comment='Count of complaints'
  )
  dimensions (
    COMPLAINTS.COMPLAINT_ID as COMPLAINT_ID,
    COMPLAINTS.CUSTOMER_ID as CUSTOMER_ID,
    COMPLAINTS.ACCOUNT_ID as ACCOUNT_ID,
    COMPLAINTS.COMPLAINT_DATE as DATE(COMPLAINT_TIMESTAMP) with synonyms=('date','complaint date') comment='Date of the complaint',
    COMPLAINTS.COMPLAINT_MONTH as MONTH(COMPLAINT_TIMESTAMP) comment='Month of complaint',
    COMPLAINTS.COMPLAINT_YEAR as YEAR(COMPLAINT_TIMESTAMP) comment='Year of complaint',
    COMPLAINTS.CHANNEL as channel with synonyms=('channel','contact method') comment='Communication channel (Voice, Email, Social, Chat, Survey)',
    COMPLAINTS.CATEGORY as category with synonyms=('category','issue type','problem type') comment='Complaint category',
    COMPLAINTS.SUBCATEGORY as subcategory with synonyms=('subcategory','detailed type') comment='Complaint subcategory',
    COMPLAINTS.PRIORITY as priority with synonyms=('priority','urgency','importance') comment='Priority level (Critical, High, Medium, Low)',
    COMPLAINTS.STATUS as status with synonyms=('status','state','complaint status') comment='Complaint status (Open, Resolved, Closed, Escalated)',
    COMPLAINTS.NETWORK_INCIDENT_ID as network_incident_id with synonyms=('incident','network issue') comment='Network incident ID if network-related'
  )
  metrics (
    COMPLAINTS.TOTAL_COMPLAINTS as COUNT(COMPLAINTS.complaint_record) comment='Total number of complaints',
    COMPLAINTS.OPEN_COMPLAINTS as COUNT(CASE WHEN COMPLAINTS.status IN ('Open','Escalated') THEN COMPLAINTS.complaint_record END) comment='Number of open complaints',
    COMPLAINTS.RESOLVED_COMPLAINTS as COUNT(CASE WHEN COMPLAINTS.status IN ('Resolved','Closed') THEN COMPLAINTS.complaint_record END) comment='Number of resolved complaints',
    COMPLAINTS.RESOLUTION_RATE as (COUNT(CASE WHEN COMPLAINTS.status IN ('Resolved','Closed') THEN COMPLAINTS.complaint_record END) * 100.0 / COUNT(COMPLAINTS.complaint_record)) comment='Percentage of resolved complaints'
  )
  comment='Semantic view for customer complaints analysis';

SELECT 'COMPLAINTS_SEMANTIC_VIEW created' as status;

-- ========================================
-- CREATE INTELLIGENCE AGENT
-- ========================================

USE ROLE SYSADMIN;

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.Customer_Complaints_Agent
WITH PROFILE='{ "display_name": "Customer Complaints Intelligence Agent" }'
    COMMENT=$$ AI agent for analyzing customer complaints, sentiment, and churn risk $$
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": ""
  },
  "instructions": {
    "response": "You are a customer service analyst with access to customer complaints data across multiple channels. Provide insights on complaint trends, resolution rates, customer satisfaction, and help identify at-risk customers. Always provide clear, actionable recommendations.",
    "orchestration": "Analyze customer complaints from voice, email, social media, chat, and surveys. Focus on resolution rates, customer tier analysis, and network-related issues. Provide visualizations for trends.",
    "sample_questions": [
      {
        "question": "How many complaints did we receive this week?"
      },
      {
        "question": "Which VIP customers have open complaints?"
      },
      {
        "question": "What is the resolution rate by channel?"
      },
      {
        "question": "Show me critical priority complaints"
      }
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Customer Complaints",
        "description": "Allows users to query customer complaints data including channels, categories, priorities, and resolution status"
      }
    }
  ],
  "tool_resources": {
    "Query Customer Complaints": {
      "semantic_view": "UC3_CUSTOMER_COMPLAINTS.COMPLAINTS.COMPLAINTS_SEMANTIC_VIEW"
    }
  }
}
$$;

-- ========================================
-- VERIFICATION
-- ========================================

SELECT '========================================' as status
UNION ALL SELECT 'SEMANTIC VIEW AND AGENT CREATED!'
UNION ALL SELECT '========================================'
UNION ALL SELECT 'Database: SNOWFLAKE_INTELLIGENCE'
UNION ALL SELECT 'Schema: AGENTS'
UNION ALL SELECT 'Agent: Customer_Complaints_Agent'
UNION ALL SELECT 'Semantic View: COMPLAINTS_SEMANTIC_VIEW'
UNION ALL SELECT ''
UNION ALL SELECT 'Test your agent by asking:'
UNION ALL SELECT '  - "How many complaints this week?"'
UNION ALL SELECT '  - "Which VIP customers have issues?"'
UNION ALL SELECT '  - "What is the resolution rate?"'
UNION ALL SELECT '========================================';

-- Show created objects
SHOW SEMANTIC VIEWS IN UC3_CUSTOMER_COMPLAINTS.COMPLAINTS;
SHOW AGENTS IN SNOWFLAKE_INTELLIGENCE.AGENTS;
