# UC3 - Quick Start Guide

**Deploy complete platform in Snowflake - 100% SQL-based, no files needed!**

---

## Prerequisites

✅ Snowflake account (Enterprise+ recommended for Cortex AI & Intelligence Agent)  
✅ SYSADMIN role access  
✅ COMPUTE_WH warehouse (or similar)

**No Python, no CSV files, no uploads required!**

---

## 5-Step SQL Deployment (60 minutes)

### Step 1: Create Database (2 minutes)

**In Snowflake UI:**

1. Click **Worksheets** in left sidebar
2. Click **"+"** to create new worksheet
3. Copy/paste entire `setup_customer_complaints.sql` file
4. Click **"Run All"** (dropdown next to Run button)
5. Wait for completion (~1-2 minutes)

**Verify success:**
```sql
SHOW SCHEMAS IN DATABASE UC3_CUSTOMER_COMPLAINTS;
-- Expected: 8 schemas including UC2_REFERENCE
```

---

### Step 2: Generate UC2 Reference Data (3 minutes)

**In Snowflake UI:**

1. Open new worksheet
2. Copy/paste entire `load_uc2_reference_data.sql` file
3. Click **"Run All"**
4. Wait for completion (~2-3 minutes)

**What this generates:**
- 500 cell sites across 5 Portuguese regions
- 5,000 network incidents (last 6 months)
- Realistic geographic distribution

**Verify success:**
```sql
SELECT COUNT(*) FROM UC2_REFERENCE.DIM_CELL_SITE;     -- 500
SELECT COUNT(*) FROM UC2_REFERENCE.FACT_INCIDENTS;    -- 5,000
```

---

### Step 3: Generate CRM & Initial Billing Data (15 minutes)

**In Snowflake UI:**

1. Open new worksheet
2. Copy/paste entire `generate_data_in_snowflake.sql` file
3. Click **"Run All"**
4. Wait for completion (~15 minutes)

**What this generates:**
- 50,000 Accounts (linked to UC2 sites)
- 75,000 Contacts
- 15,000 Cases (30% linked to UC2 incidents)
- 45,000 Case Comments
- 100,000 Assets
- 8,000 Service Contracts
- 50,000 Billing Customers
- 55,000 Billing Accounts
- 120,000 Subscriptions

**Verify success:**
```sql
SELECT COUNT(*) FROM CUSTOMER_DATA.ACCOUNT;           -- 50,000
SELECT COUNT(*) FROM CUSTOMER_DATA.CASE;              -- 15,000
```

---

### Step 4: Generate Complete Billing Data (15 minutes)

**In Snowflake UI:**

1. Open new worksheet
2. Copy/paste entire `generate_data_in_snowflake_part2_billing.sql` file
3. Click **"Run All"**
4. Wait for completion (~15 minutes)

**What this generates:**
- 300,000 Invoices
- 900,000 Invoice Line Items
- 500,000 Usage Records
- 280,000 Payments
- 25,000 Billing Disputes
- 30,000 Billing Adjustments

**Verify success:**
```sql
SELECT COUNT(*) FROM BILLING_DATA.BILL_INVOICE;       -- 300,000
SELECT COUNT(*) FROM BILLING_DATA.PAYMENT;            -- 280,000
```

---

### Step 5: Generate Multi-Channel Complaints (10 minutes)

**In Snowflake UI:**

1. Open new worksheet
2. Copy/paste entire `generate_data_in_snowflake_part3_complaints.sql` file
3. Click **"Run All"**
4. Wait for completion (~10 minutes)

**What this generates:**
- 1,000 Voice Transcripts
- 5,000 Email Complaints
- 3,000 Social Media Posts
- 8,000 Chat Sessions
- 12,000 Survey Responses
- ~30,000 Unified Complaints

**Verify success:**
```sql
SELECT COUNT(*) FROM COMPLAINTS.UNIFIED_COMPLAINT;    -- ~30,000
```

---

### Step 6: Run AI Sentiment Analysis (5 minutes)

**In Snowflake UI:**

1. Open new worksheet
2. Copy/paste entire `create_sentiment_models.sql` file
3. Click **"Run All"**
4. Wait for completion (~5 minutes)

**What this creates:**
- Sentiment scores for all complaints
- Emotion detection
- Topic classification
- Churn risk predictions for all customers
- Critical alerts

**Verify success:**
```sql
SELECT COUNT(*) FROM SENTIMENT.SENTIMENT_SCORE;       -- ~30,000
SELECT COUNT(*) FROM SENTIMENT.CHURN_RISK_PREDICTION; -- 50,000
```

---

### Step 7: Create Intelligence Agent (5 minutes)

**In Snowflake UI:**

1. Open new worksheet
2. Copy/paste entire `create_semantic_intelligence_agent.sql` file
3. Click **"Run All"**
4. Wait for completion (~2-3 minutes)

**Then create the AI Agent:**

5. Navigate to **Data** → **Agents**
6. Click **"+ Agent"** or **"Create Agent"**
7. Configure:
   - **Name**: "Customer Complaints Intelligence Agent"
   - **Description**: "AI agent for analyzing customer complaints, sentiment, and churn risk"
8. Add all 7 semantic views:
   - `CUSTOMER_360_SEMANTIC`
   - `COMPLAINTS_SENTIMENT_SEMANTIC`
   - `CHURN_RISK_SEMANTIC`
   - `NETWORK_INCIDENT_IMPACT_SEMANTIC`
   - `VOICE_TRANSCRIPTS_SEMANTIC`
   - `CRITICAL_ALERTS_SEMANTIC`
   - `SENTIMENT_TRENDS_SEMANTIC`
9. Click **"Create"**
10. Test with natural language queries:
    - "Which customers are at high risk of churning?"
    - "Show me negative complaints from this week"
    - "What network incidents caused the most complaints?"

---

## ✅ Deployment Complete!

**You now have:**
- ✅ 2.5M+ records across 36 tables
- ✅ Complete customer, billing, and complaints data
- ✅ AI-powered sentiment analysis
- ✅ Churn risk predictions for all customers
- ✅ Network-complaint correlation analysis
- ✅ Real-time critical alerts
- ✅ **Snowflake Intelligence Agent**: Ask questions in natural language
- ✅ **7 Semantic Views**: Business-friendly data access
- ✅ **Completely standalone**: Zero external dependencies

**Total Time:** ~60 minutes  
**Data Volume:** 2.5M+ records  
**Tables Created:** 36  
**Status:** ✅ **COMPLETE**

---

## Explore Your Data

**Sample SQL queries:**

```sql
USE DATABASE UC3_CUSTOMER_COMPLAINTS;

-- View sentiment distribution
SELECT OVERALL_SENTIMENT, COUNT(*) 
FROM SENTIMENT.SENTIMENT_SCORE 
GROUP BY OVERALL_SENTIMENT;

-- View high-risk customers
SELECT * 
FROM ANALYTICS.V_HIGH_RISK_CUSTOMERS 
LIMIT 10;

-- View network-complaint correlation
SELECT 
    i.INCIDENT_ID,
    i.SITE_ID,
    COUNT(DISTINCT ncl.COMPLAINT_ID) as COMPLAINTS
FROM UC2_REFERENCE.FACT_INCIDENTS i
JOIN INTEGRATION.NETWORK_COMPLAINT_LINK ncl 
    ON ncl.INCIDENT_ID = i.INCIDENT_ID
GROUP BY i.INCIDENT_ID, i.SITE_ID
ORDER BY COMPLAINTS DESC
LIMIT 10;
```

**Sample natural language queries (using Intelligence Agent):**
- "Which customers are at high risk of churning?"
- "Show me the most negative complaints from this week"
- "What network incidents generated the most complaints?"
- "How much revenue is at risk from customer churn?"
- "Which VIP customers have open cases?"

---

## 📊 Data Summary

| Category | Records |
|----------|---------|
| **UC2 Reference** | 5,500 |
| - Cell Sites | 500 |
| - Network Incidents | 5,000 |
| **CRM Data** | 248,000 |
| - Accounts | 50,000 |
| - Contacts | 75,000 |
| - Cases | 15,000 |
| - Case Comments | 45,000 |
| - Assets | 100,000 |
| - Service Contracts | 8,000 |
| **Billing Data** | 2,035,000 |
| - Customers | 50,000 |
| - Billing Accounts | 55,000 |
| - Subscriptions | 120,000 |
| - Invoices | 300,000 |
| - Invoice Details | 900,000 |
| - Usage Records | 500,000 |
| - Payments | 280,000 |
| - Disputes | 25,000 |
| - Adjustments | 30,000 |
| **Complaints** | 59,000 |
| - Voice Transcripts | 1,000 |
| - Email | 5,000 |
| - Social Media | 3,000 |
| - Chat | 8,000 |
| - Survey | 12,000 |
| - Unified | ~30,000 |
| **Sentiment & AI** | 160,000 |
| - Sentiment Scores | ~30,000 |
| - Emotion Detection | ~30,000 |
| - Topic Classification | ~30,000 |
| - Churn Predictions | 50,000 |
| - Critical Alerts | 1,000+ |
| **TOTAL** | **~2.5M records** |

---

## 🔧 Troubleshooting

### Issue: "Division by zero" error
**Solution:** UC2_REFERENCE tables are empty. Run `load_uc2_reference_data.sql` first

### Issue: "Cortex function not available"
**Solution:** Requires Snowflake Enterprise Edition or higher

### Issue: Scripts running slow
**Solution:** Use larger warehouse:
```sql
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'LARGE';
```

### Issue: Need to regenerate data
**Solution:** 
```sql
DROP DATABASE IF EXISTS UC3_CUSTOMER_COMPLAINTS;
-- Then re-run all scripts from Step 1
```

---

## 🎉 Congratulations!

You've successfully deployed a complete customer complaints and sentiment analysis platform with:
- **50,000 customers** synchronized with network infrastructure
- **30,000 complaints** across 5 channels
- **AI-powered sentiment analysis** using Snowflake Cortex
- **Churn risk predictions** for proactive retention
- **Network-complaint correlation** for root cause analysis

**Your platform is production-ready for demos and analysis!**

---

[← Back to README](README.md) | [Detailed Guide →](SQL_DATA_GENERATION_GUIDE.md)
