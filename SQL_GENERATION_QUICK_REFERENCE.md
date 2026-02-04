# SQL Data Generation - Quick Reference

**Generate 2.5M+ records in Snowflake - 100% SQL, zero files!**

---

## ✅ Checklist

- [ ] **Step 1:** Create database (2 min)
- [ ] **Step 2:** Generate UC2 reference data (3 min)
- [ ] **Step 3:** Generate CRM data (15 min)
- [ ] **Step 4:** Generate billing data (15 min)
- [ ] **Step 5:** Generate complaints (10 min)
- [ ] **Step 6:** Run AI analysis (10 min)

**Total Time:** 60 minutes  
**Result:** Standalone platform with 2.5M+ records

---

## 📋 Commands

### 1. Create Database (2 min)
```sql
-- File: setup_customer_complaints.sql
-- Run All in Snowflake UI
```

### 2. Generate UC2 Data (3 min)
```sql
-- File: load_uc2_reference_data.sql
-- Run All
-- Generates: 500 sites + 5,000 incidents
```

### 3. Generate CRM (15 min)
```sql
-- File: generate_data_in_snowflake.sql
-- Run All
-- Generates: 50,000 accounts + cases
```

### 4. Generate Billing (15 min)
```sql
-- File: generate_data_in_snowflake_part2_billing.sql
-- Run All
-- Generates: 300,000 invoices + payments
```

### 5. Generate Complaints (10 min)
```sql
-- File: generate_data_in_snowflake_part3_complaints.sql
-- Run All
-- Generates: 30,000 complaints
```

### 6. AI Analysis (10 min)
```sql
-- File: create_sentiment_models.sql → Run All
-- File: create_semantic_intelligence_agent.sql → Run All
-- Then create agent in UI: Data > Agents
```

---

## ✅ Verify

```sql
SELECT 'UC2 Sites' as TABLE, COUNT(*) FROM UC2_REFERENCE.DIM_CELL_SITE
UNION ALL SELECT 'UC2 Incidents', COUNT(*) FROM UC2_REFERENCE.FACT_INCIDENTS
UNION ALL SELECT 'Accounts', COUNT(*) FROM CUSTOMER_DATA.ACCOUNT
UNION ALL SELECT 'Invoices', COUNT(*) FROM BILLING_DATA.BILL_INVOICE
UNION ALL SELECT 'Complaints', COUNT(*) FROM COMPLAINTS.UNIFIED_COMPLAINT;

-- Expected:
-- UC2 Sites: 500
-- UC2 Incidents: 5,000
-- Accounts: 50,000
-- Invoices: 300,000
-- Complaints: ~30,000
```

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Division by zero | Run step 2 first (UC2 data) |
| Script slow | `ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'LARGE';` |
| Start over | `DROP DATABASE IF EXISTS UC3_CUSTOMER_COMPLAINTS;` |

---

## 📊 What You Get

- ✅ 2.5M+ records
- ✅ Standalone database (no files!)
- ✅ AI sentiment analysis
- ✅ Intelligence Agent
- ✅ Production-ready

**7 SQL scripts - run sequentially - done!**

---

[Full Guide →](SQL_DATA_GENERATION_GUIDE.md) | [Quick Start →](QUICK_START.md)
