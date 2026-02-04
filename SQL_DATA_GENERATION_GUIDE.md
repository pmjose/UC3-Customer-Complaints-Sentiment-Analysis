# SQL-Based Data Generation Guide

**Generate all UC3 sample data directly in Snowflake - 100% SQL, zero files!**

---

## Overview

Generate 2.5M+ records directly in Snowflake using native SQL. This is a **completely standalone** deployment with zero external dependencies.

### What You'll Get

✅ **2.5M+ records** across 36 tables  
✅ **50,000 customers** with realistic data  
✅ **300,000 invoices** with billing history  
✅ **30,000 complaints** across 5 channels  
✅ **500 cell sites** + 5,000 network incidents  
✅ **Completely standalone** - no files, no Python, no uploads

**Total Time:** ~60 minutes

---

## Prerequisites

- ✅ Snowflake account with SYSADMIN access
- ✅ COMPUTE_WH warehouse (or similar)

**That's it! Everything else is generated in SQL!**

---

## 6-Step Process

### Step 1: Create Database Structure (2 minutes)

**File:** `setup_customer_complaints.sql`

**Action:**
1. Open Snowflake UI → Worksheets
2. Copy/paste entire file
3. Click **"Run All"**

**Creates:**
- Database: `UC3_CUSTOMER_COMPLAINTS`
- 8 Schemas (including `UC2_REFERENCE`)
- 36 Tables (empty, ready for data)
- Stages and file formats

**Verify:**
```sql
SHOW SCHEMAS IN DATABASE UC3_CUSTOMER_COMPLAINTS;
-- Should show 8 schemas including UC2_REFERENCE
```

---

### Step 2: Generate UC2 Reference Data (3 minutes)

**File:** `load_uc2_reference_data.sql`

**Action:**
1. Open new worksheet
2. Copy/paste entire file
3. Click **"Run All"**
4. Wait ~2-3 minutes

**Generates:**
- 500 Cell Sites (across 5 Portuguese regions)
- 5,000 Network Incidents (last 6 months)
- Realistic geographic distribution
- Network quality patterns

**Verify:**
```sql
SELECT COUNT(*) FROM UC2_REFERENCE.DIM_CELL_SITE;     -- 500
SELECT COUNT(*) FROM UC2_REFERENCE.FACT_INCIDENTS;    -- 5,000

-- Check distribution
SELECT REGION, COUNT(*) as SITES 
FROM UC2_REFERENCE.DIM_CELL_SITE 
GROUP BY REGION;
-- Expected: Norte, Centro, Lisboa, Alentejo, Algarve
```

---

### Step 3: Generate CRM & Initial Billing Data (15 minutes)

**File:** `generate_data_in_snowflake.sql`

**Action:**
1. Open new worksheet
2. Copy/paste entire file
3. Click **"Run All"**
4. Wait ~15 minutes

**Generates:**
- 50,000 Accounts (linked to UC2 sites)
- 75,000 Contacts
- 15,000 Cases (30% linked to UC2 incidents)
- 45,000 Case Comments
- 100,000 Assets
- 8,000 Service Contracts
- 50,000 Billing Customers
- 55,000 Billing Accounts
- 120,000 Subscriptions

**Progress Monitoring:**
The script outputs status messages:
```
Step 1: Verifying UC2 reference data...
Step 2: Generating 50000 customer accounts...
50000 accounts generated
Step 3: Generating 75000 contacts...
...
PART 1 COMPLETE!
```

**Verify:**
```sql
SELECT COUNT(*) FROM CUSTOMER_DATA.ACCOUNT;           -- 50,000
SELECT COUNT(*) FROM CUSTOMER_DATA.CASE;              -- 15,000

-- Check UC2 integration
SELECT COUNT(*) as CASES_WITH_INCIDENTS
FROM CUSTOMER_DATA.CASE
WHERE NETWORK_INCIDENT_ID IS NOT NULL;
-- Expected: ~4,500 (30% of cases)
```

---

### Step 4: Generate Complete Billing Data (15 minutes)

**File:** `generate_data_in_snowflake_part2_billing.sql`

**Action:**
1. Open new worksheet
2. Copy/paste entire file
3. Click **"Run All"**
4. Wait ~15 minutes

**Generates:**
- 300,000 Invoices (6 months per account)
- 900,000 Invoice Line Items
- 500,000 Usage Records
- 280,000 Payments
- 25,000 Billing Disputes
- 30,000 Billing Adjustments

**Verify:**
```sql
SELECT COUNT(*) FROM BILLING_DATA.BILL_INVOICE;       -- 300,000
SELECT COUNT(*) FROM BILLING_DATA.PAYMENT;            -- 280,000
SELECT COUNT(*) FROM BILLING_DATA.DISPUTE;            -- 25,000
```

---

### Step 5: Generate Multi-Channel Complaints (10 minutes)

**File:** `generate_data_in_snowflake_part3_complaints.sql`

**Action:**
1. Open new worksheet
2. Copy/paste entire file
3. Click **"Run All"**
4. Wait ~10 minutes

**Generates:**
- 1,000 Voice Transcripts (realistic conversations)
- 5,000 Email Complaints (full text)
- 3,000 Social Media Posts (5% viral, 5% influencers)
- 8,000 Chat Sessions (full transcripts)
- 12,000 Survey Responses (NPS, CSAT, CES)
- ~30,000 Unified Complaints (aggregated)

**Verify:**
```sql
SELECT COUNT(*) FROM COMPLAINTS.VOICE_TRANSCRIPT;     -- 1,000
SELECT COUNT(*) FROM COMPLAINTS.EMAIL_COMPLAINT;      -- 5,000
SELECT COUNT(*) FROM COMPLAINTS.UNIFIED_COMPLAINT;    -- ~30,000
```

---

### Step 6: Run AI Analysis (10 minutes)

#### Step 6a: Sentiment Analysis (5 minutes)

**File:** `create_sentiment_models.sql`

**Action:**
1. Open new worksheet
2. Copy/paste entire file
3. Click **"Run All"**
4. Wait ~5 minutes

**Creates:**
- Sentiment scores (using Snowflake Cortex AI)
- Emotion detection
- Topic classification
- Churn risk predictions
- Critical alerts

**Verify:**
```sql
SELECT COUNT(*) FROM SENTIMENT.SENTIMENT_SCORE;       -- ~30,000
SELECT COUNT(*) FROM SENTIMENT.CHURN_RISK_PREDICTION; -- 50,000
```

#### Step 6b: Intelligence Agent (5 minutes)

**File:** `create_semantic_intelligence_agent.sql`

**Action:**
1. Open new worksheet
2. Copy/paste entire file
3. Click **"Run All"**

**Creates:** 7 semantic views for natural language queries

**Then in Snowflake UI:**
1. Navigate to **Data** → **Agents**
2. Click **"+ Agent"**
3. Name: "Customer Complaints Intelligence Agent"
4. Add all 7 semantic views
5. Click **"Create"**
6. Test with: "Which customers are at high risk of churning?"

---

## ✅ Complete Verification

After all steps complete:

```sql
USE DATABASE UC3_CUSTOMER_COMPLAINTS;

-- Overall summary
SELECT 'UC2 Cell Sites' as CATEGORY, COUNT(*) as RECORDS 
FROM UC2_REFERENCE.DIM_CELL_SITE
UNION ALL
SELECT 'UC2 Incidents', COUNT(*) FROM UC2_REFERENCE.FACT_INCIDENTS
UNION ALL
SELECT 'Accounts', COUNT(*) FROM CUSTOMER_DATA.ACCOUNT
UNION ALL
SELECT 'Cases', COUNT(*) FROM CUSTOMER_DATA.CASE
UNION ALL
SELECT 'Invoices', COUNT(*) FROM BILLING_DATA.BILL_INVOICE
UNION ALL
SELECT 'Complaints', COUNT(*) FROM COMPLAINTS.UNIFIED_COMPLAINT
UNION ALL
SELECT 'Sentiment Scores', COUNT(*) FROM SENTIMENT.SENTIMENT_SCORE
UNION ALL
SELECT 'Churn Predictions', COUNT(*) FROM SENTIMENT.CHURN_RISK_PREDICTION;
```

**Expected Results:**
- UC2 Cell Sites: 500
- UC2 Incidents: 5,000
- Accounts: 50,000
- Cases: 15,000
- Invoices: 300,000
- Complaints: ~30,000
- Sentiment Scores: ~30,000
- Churn Predictions: 50,000

**Grand Total:** ~2.5 million records

---

## 🔧 Troubleshooting

### Issue: "Division by zero"
**Cause:** UC2_REFERENCE tables are empty  
**Solution:** Run `load_uc2_reference_data.sql` first

```sql
SELECT COUNT(*) FROM UC2_REFERENCE.DIM_CELL_SITE;
-- If 0, re-run load_uc2_reference_data.sql
```

### Issue: Scripts running slowly
**Solution:** Use larger warehouse

```sql
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'LARGE';
```

### Issue: Need to start over
**Solution:** Drop and recreate

```sql
DROP DATABASE IF EXISTS UC3_CUSTOMER_COMPLAINTS;
-- Then re-run from Step 1
```

---

## 📊 What You Get

### Database Structure

```
UC3_CUSTOMER_COMPLAINTS (One standalone database)
├── UC2_REFERENCE (Generated in SQL)
│   ├── DIM_CELL_SITE (500 sites)
│   └── FACT_INCIDENTS (5,000 incidents)
├── CUSTOMER_DATA (50,000 accounts)
├── BILLING_DATA (300,000 invoices)
├── COMPLAINTS (30,000 complaints)
├── SENTIMENT (AI analysis results)
├── ANALYTICS (Views & KPIs)
├── STAGING (For stages)
└── INTEGRATION (Cross-system links)

Total: 2.5M+ records
Files needed: ZERO
External dependencies: ZERO
```

### Data Summary

| Category | Tables | Records |
|----------|--------|---------|
| **UC2 Reference** | 2 | 5,500 |
| **CRM Data** | 6 | 248,000 |
| **Billing Data** | 9 | 2,035,000 |
| **Complaints** | 6 | 59,000 |
| **Sentiment/AI** | 5 | 160,000 |
| **TOTAL** | 28+ | **2.5M+** |

---

## 🎯 Key Features

✅ **100% SQL-Based** - No Python, no CSV files, no uploads  
✅ **Standalone Deployment** - Everything in one database  
✅ **UC2 Integration** - Customers linked to sites, complaints to incidents  
✅ **Realistic Data** - Portuguese names, addresses, realistic patterns  
✅ **Multi-Channel** - Voice, email, social, chat, survey complaints  
✅ **AI-Ready** - Sentiment analysis, churn prediction built-in  
✅ **Production Quality** - Full referential integrity, comprehensive data model

---

## 📋 Quick Reference - File Execution Order

```
1. setup_customer_complaints.sql (2 min)
   Creates database structure
   ↓
2. load_uc2_reference_data.sql (3 min)
   Generates 500 sites + 5,000 incidents
   ↓
3. generate_data_in_snowflake.sql (15 min)
   Generates CRM + initial billing
   ↓
4. generate_data_in_snowflake_part2_billing.sql (15 min)
   Generates complete billing data
   ↓
5. generate_data_in_snowflake_part3_complaints.sql (10 min)
   Generates multi-channel complaints
   ↓
6. create_sentiment_models.sql (5 min)
   AI sentiment analysis
   ↓
7. create_semantic_intelligence_agent.sql (5 min)
   Semantic layer + agent setup

Total: ~60 minutes
```

---

## ✅ You're Done!

After completing all steps, you have:

- ✅ **Standalone UC3 database** - No external dependencies
- ✅ **2.5M+ records** - Complete realistic dataset
- ✅ **AI analysis** - Sentiment, emotion, topics, churn risk
- ✅ **Intelligence Agent** - Natural language queries
- ✅ **Production ready** - Demo, testing, or development

**All generated from SQL - no files needed!**

---

[← Back to README](README.md) | [Quick Reference →](SQL_GENERATION_QUICK_REFERENCE.md)
