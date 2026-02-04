# UC3 - Customer Incident Data Guide

**Complete guide to all customer incident types and how to access them**

---

## 📊 Available Incident Data

### Overview

Your platform captures **ALL types of customer incidents** across multiple systems:

| System | Incident Types | Records | Purpose |
|--------|---------------|---------|---------|
| **CRM Cases** | 5 categories | 15,000 | Customer-reported issues |
| **Billing Disputes** | 3 categories | 25,000 | Payment & billing problems |
| **Network Incidents** | From UC2 | 705 | Infrastructure failures |
| **Service Issues** | Multi-channel | 30,000 | Complaints across all channels |

**Total Incident Records: 70,000+**

---

## 1️⃣ CRM Case Incidents (CUSTOMER_DATA.CASE)

**15,000 cases covering all customer-reported incidents**

### Incident Categories

| Category | Count | % | Description | UC2 Linked |
|----------|-------|---|-------------|------------|
| **Network Outage** | 4,500 | 30% | Complete service loss, no connectivity | ✅ Yes |
| **Billing Dispute** | 3,750 | 25% | Incorrect charges, billing questions | Partial |
| **Technical Support** | 3,000 | 20% | Speed issues, WiFi problems, configuration | Partial |
| **Service Activation** | 2,250 | 15% | Installation delays, activation problems | No |
| **General Inquiry** | 1,500 | 10% | Account questions, plan changes | No |

### Query Examples

**All incidents by type:**
```sql
USE DATABASE UC3_CUSTOMER_COMPLAINTS;

-- Get incident summary by category
SELECT 
    CATEGORY,
    COUNT(*) as INCIDENT_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as PERCENTAGE,
    AVG(RESOLUTION_TIME_MINUTES) as AVG_RESOLUTION_MINUTES,
    SUM(CASE WHEN STATUS IN ('Resolved', 'Closed') THEN 1 ELSE 0 END) as RESOLVED_COUNT
FROM CUSTOMER_DATA.CASE
GROUP BY CATEGORY
ORDER BY INCIDENT_COUNT DESC;
```

**Network-related incidents:**
```sql
-- All incidents linked to network issues
SELECT 
    c.CASE_ID,
    c.CASE_NUMBER,
    c.CATEGORY,
    c.PRIORITY,
    c.STATUS,
    c.CREATED_DATE,
    c.NETWORK_INCIDENT_ID,
    i.INCIDENT_TYPE as UC2_INCIDENT_TYPE,
    i.SEVERITY as UC2_SEVERITY,
    i.ROOT_CAUSE as UC2_ROOT_CAUSE
FROM CUSTOMER_DATA.CASE c
LEFT JOIN UC2_PREDICTIVE_MAINTENANCE.INCIDENTS.FACT_INCIDENTS i
    ON i.INCIDENT_ID = c.NETWORK_INCIDENT_ID
WHERE c.NETWORK_INCIDENT_ID IS NOT NULL
ORDER BY c.CREATED_DATE DESC;
```

**Customer incident history:**
```sql
-- All incidents for a specific customer
SELECT 
    CASE_NUMBER,
    CATEGORY,
    SUBJECT,
    PRIORITY,
    STATUS,
    CREATED_DATE,
    CLOSED_DATE,
    RESOLUTION_TIME_MINUTES,
    CHANNEL
FROM CUSTOMER_DATA.CASE
WHERE ACCOUNT_ID = 'ACC-NOR-000001'
ORDER BY CREATED_DATE DESC;
```

---

## 2️⃣ Billing Incidents (BILLING_DATA.DISPUTE)

**25,000 billing-related incidents**

### Billing Incident Types

| Category | Count | % | Description | Network Impact |
|----------|-------|---|-------------|----------------|
| **Service Interruption** | 15,000 | 60% | Credits for outages, service down | ✅ UC2 linked |
| **Incorrect Charge** | 7,500 | 30% | Wrong amounts, unexpected fees | No |
| **Unauthorized Charge** | 2,000 | 8% | Charges not ordered | No |
| **Other** | 500 | 2% | Miscellaneous billing issues | No |

### Query Examples

**Billing disputes by type:**
```sql
-- Billing incident summary
SELECT 
    CATEGORY,
    COUNT(*) as DISPUTE_COUNT,
    AVG(DISPUTE_AMOUNT) as AVG_AMOUNT,
    SUM(DISPUTE_AMOUNT) as TOTAL_DISPUTED,
    SUM(ADJUSTMENT_GIVEN) as TOTAL_CREDITS_ISSUED,
    ROUND(AVG(CASE 
        WHEN RESOLVED_DATE IS NOT NULL 
        THEN DATEDIFF(day, OPENED_DATE, RESOLVED_DATE) 
    END), 1) as AVG_RESOLUTION_DAYS
FROM BILLING_DATA.DISPUTE
GROUP BY CATEGORY
ORDER BY DISPUTE_COUNT DESC;
```

**Network-caused billing incidents:**
```sql
-- Disputes caused by network incidents
SELECT 
    d.DISPUTE_ID,
    d.DISPUTE_NUMBER,
    d.DISPUTE_AMOUNT,
    d.CATEGORY,
    d.DISPUTE_REASON,
    d.NETWORK_INCIDENT_ID,
    d.ADJUSTMENT_GIVEN,
    d.STATUS,
    i.INCIDENT_TYPE,
    i.DURATION_MINUTES,
    i.AFFECTED_CUSTOMERS
FROM BILLING_DATA.DISPUTE d
JOIN UC2_PREDICTIVE_MAINTENANCE.INCIDENTS.FACT_INCIDENTS i
    ON i.INCIDENT_ID = d.NETWORK_INCIDENT_ID
WHERE d.NETWORK_INCIDENT_ID IS NOT NULL
ORDER BY d.DISPUTE_AMOUNT DESC;
```

---

## 3️⃣ Network Infrastructure Incidents (UC2 Integration)

**705 network incidents from UC2 Predictive Maintenance**

### Network Incident Types (from UC2)

| Type | Description | Customer Impact |
|------|-------------|-----------------|
| **Hardware Failure** | Equipment breakdown | High - service outage |
| **Software Failure** | System crashes, bugs | Medium - degraded service |
| **Configuration Error** | Misconfiguration | Medium - intermittent issues |
| **Environmental** | Power, cooling, weather | High - site down |
| **Planned Maintenance** | Scheduled work | Low - planned downtime |
| **Security** | Attacks, breaches | Variable |
| **Capacity** | Overload, congestion | Medium - slow speeds |

### Query Examples

**Network incidents with customer complaints:**
```sql
-- Network incidents that generated customer complaints
SELECT 
    i.INCIDENT_ID,
    i.INCIDENT_TYPE,
    i.SEVERITY,
    i.INCIDENT_TIMESTAMP,
    i.DURATION_MINUTES,
    i.AFFECTED_CUSTOMERS as ESTIMATED_AFFECTED,
    i.SITE_ID,
    s.SITE_NAME,
    s.REGION,
    COUNT(DISTINCT c.CASE_ID) as COMPLAINTS_RECEIVED,
    COUNT(DISTINCT d.DISPUTE_ID) as BILLING_DISPUTES,
    SUM(adj.AMOUNT) as TOTAL_CREDITS_GIVEN
FROM UC2_PREDICTIVE_MAINTENANCE.INCIDENTS.FACT_INCIDENTS i
LEFT JOIN UC2_PREDICTIVE_MAINTENANCE.EQUIPMENT.DIM_CELL_SITE s 
    ON s.SITE_ID = i.SITE_ID
LEFT JOIN CUSTOMER_DATA.CASE c 
    ON c.NETWORK_INCIDENT_ID = i.INCIDENT_ID
LEFT JOIN BILLING_DATA.DISPUTE d 
    ON d.NETWORK_INCIDENT_ID = i.INCIDENT_ID
LEFT JOIN BILLING_DATA.ADJUSTMENT adj 
    ON adj.NETWORK_INCIDENT_ID = i.INCIDENT_ID
GROUP BY i.INCIDENT_ID, i.INCIDENT_TYPE, i.SEVERITY, i.INCIDENT_TIMESTAMP, 
         i.DURATION_MINUTES, i.AFFECTED_CUSTOMERS, i.SITE_ID, s.SITE_NAME, s.REGION
HAVING COUNT(DISTINCT c.CASE_ID) > 0
ORDER BY COMPLAINTS_RECEIVED DESC;
```

**Incident impact analysis:**
```sql
-- Detailed incident impact (network, billing, customer sentiment)
SELECT 
    i.INCIDENT_ID,
    i.INCIDENT_TYPE,
    i.ROOT_CAUSE,
    i.SITE_ID,
    i.DURATION_MINUTES,
    i.AFFECTED_CUSTOMERS,
    COUNT(DISTINCT ncl.COMPLAINT_ID) as TOTAL_COMPLAINTS,
    AVG(ss.SENTIMENT_SCORE) as AVG_SENTIMENT,
    SUM(CASE WHEN ss.OVERALL_SENTIMENT = 'Negative' THEN 1 ELSE 0 END) as NEGATIVE_COMPLAINTS,
    SUM(adj.AMOUNT) as CREDITS_ISSUED
FROM UC2_PREDICTIVE_MAINTENANCE.INCIDENTS.FACT_INCIDENTS i
LEFT JOIN INTEGRATION.NETWORK_COMPLAINT_LINK ncl 
    ON ncl.INCIDENT_ID = i.INCIDENT_ID
LEFT JOIN SENTIMENT.SENTIMENT_SCORE ss 
    ON ss.COMPLAINT_ID = ncl.COMPLAINT_ID
LEFT JOIN BILLING_DATA.ADJUSTMENT adj 
    ON adj.NETWORK_INCIDENT_ID = i.INCIDENT_ID
GROUP BY i.INCIDENT_ID, i.INCIDENT_TYPE, i.ROOT_CAUSE, i.SITE_ID, 
         i.DURATION_MINUTES, i.AFFECTED_CUSTOMERS
ORDER BY i.INCIDENT_TIMESTAMP DESC;
```

---

## 4️⃣ Multi-Channel Service Incidents (COMPLAINTS Schema)

**30,000 complaints across all channels = All types of service issues**

### By Channel

| Channel | Incidents | Types Covered |
|---------|-----------|---------------|
| **Voice** | 1,000 | Network, billing, technical, activation |
| **Email** | 5,000 | All formal complaints |
| **Social** | 3,000 | Public complaints, viral issues |
| **Chat** | 8,000 | Quick issues, simple problems |
| **Survey** | 12,000 | Satisfaction issues, feedback |

### Query Examples

**All service incidents by channel:**
```sql
-- Service incident summary by channel
SELECT 
    CHANNEL,
    COUNT(*) as INCIDENT_COUNT,
    AVG(CASE 
        WHEN RESOLVED_DATE IS NOT NULL 
        THEN DATEDIFF(hour, COMPLAINT_TIMESTAMP, RESOLVED_DATE)
    END) as AVG_RESOLUTION_HOURS,
    COUNT(DISTINCT CUSTOMER_ID) as AFFECTED_CUSTOMERS,
    SUM(CASE WHEN RESOLVED = TRUE THEN 1 ELSE 0 END) as RESOLVED_COUNT
FROM COMPLAINTS.UNIFIED_COMPLAINT
GROUP BY CHANNEL
ORDER BY INCIDENT_COUNT DESC;
```

**Critical service incidents:**
```sql
-- High-priority unresolved incidents
SELECT 
    uc.COMPLAINT_ID,
    uc.CHANNEL,
    uc.CATEGORY,
    uc.COMPLAINT_TIMESTAMP,
    uc.COMPLAINT_TEXT,
    uc.PRIORITY,
    uc.STATUS,
    ss.SENTIMENT_SCORE,
    ed.PRIMARY_EMOTION,
    a.ACCOUNT_NAME,
    a.TIER
FROM COMPLAINTS.UNIFIED_COMPLAINT uc
LEFT JOIN SENTIMENT.SENTIMENT_SCORE ss ON ss.COMPLAINT_ID = uc.COMPLAINT_ID
LEFT JOIN SENTIMENT.EMOTION_DETECTION ed ON ed.COMPLAINT_ID = uc.COMPLAINT_ID
LEFT JOIN CUSTOMER_DATA.ACCOUNT a ON a.ACCOUNT_ID = uc.CUSTOMER_ID
WHERE uc.RESOLVED = FALSE
  AND uc.PRIORITY IN ('Critical', 'High')
ORDER BY uc.COMPLAINT_TIMESTAMP DESC;
```

---

## 5️⃣ Comprehensive Incident View (All Systems Combined)

### Root Cause Analysis View

**Query to see ALL incident types with root causes:**

```sql
-- Complete incident analysis across all systems
WITH all_incidents AS (
    -- CRM Cases
    SELECT 
        CASE_ID as INCIDENT_ID,
        'CRM_CASE' as SOURCE_SYSTEM,
        CATEGORY as INCIDENT_TYPE,
        SUBCATEGORY as INCIDENT_SUBTYPE,
        CREATED_DATE as INCIDENT_DATE,
        ACCOUNT_ID as CUSTOMER_ID,
        PRIORITY,
        STATUS,
        NETWORK_INCIDENT_ID,
        NULL as DISPUTE_AMOUNT
    FROM CUSTOMER_DATA.CASE
    
    UNION ALL
    
    -- Billing Disputes
    SELECT 
        DISPUTE_ID as INCIDENT_ID,
        'BILLING_DISPUTE' as SOURCE_SYSTEM,
        'Billing' as INCIDENT_TYPE,
        CATEGORY as INCIDENT_SUBTYPE,
        OPENED_DATE as INCIDENT_DATE,
        ba.CUSTOMER_ID,
        'High' as PRIORITY,
        STATUS,
        NETWORK_INCIDENT_ID,
        DISPUTE_AMOUNT
    FROM BILLING_DATA.DISPUTE d
    JOIN BILLING_DATA.BILLING_ACCOUNT ba ON ba.BILLING_ACCOUNT_ID = d.BILLING_ACCOUNT_ID
    
    UNION ALL
    
    -- Complaints
    SELECT 
        COMPLAINT_ID as INCIDENT_ID,
        'COMPLAINT_' || CHANNEL as SOURCE_SYSTEM,
        CATEGORY as INCIDENT_TYPE,
        SUBCATEGORY as INCIDENT_SUBTYPE,
        COMPLAINT_TIMESTAMP as INCIDENT_DATE,
        CUSTOMER_ID,
        PRIORITY,
        STATUS,
        NETWORK_INCIDENT_ID,
        NULL as DISPUTE_AMOUNT
    FROM COMPLAINTS.UNIFIED_COMPLAINT
)
SELECT 
    SOURCE_SYSTEM,
    INCIDENT_TYPE,
    INCIDENT_SUBTYPE,
    COUNT(*) as INCIDENT_COUNT,
    COUNT(DISTINCT CUSTOMER_ID) as AFFECTED_CUSTOMERS,
    SUM(CASE WHEN NETWORK_INCIDENT_ID IS NOT NULL THEN 1 ELSE 0 END) as NETWORK_RELATED,
    AVG(DISPUTE_AMOUNT) as AVG_AMOUNT
FROM all_incidents
GROUP BY SOURCE_SYSTEM, INCIDENT_TYPE, INCIDENT_SUBTYPE
ORDER BY INCIDENT_COUNT DESC;
```

### Customer Incident Timeline

**See all incidents for a specific customer across ALL systems:**

```sql
-- Complete incident history for a customer
WITH customer_incidents AS (
    -- CRM Cases
    SELECT 
        CASE_NUMBER as INCIDENT_NUMBER,
        'CRM Case' as INCIDENT_TYPE,
        CATEGORY as CATEGORY,
        SUBJECT as DESCRIPTION,
        CREATED_DATE as INCIDENT_DATE,
        STATUS,
        PRIORITY,
        CHANNEL,
        NETWORK_INCIDENT_ID
    FROM CUSTOMER_DATA.CASE
    WHERE ACCOUNT_ID = 'ACC-NOR-000001'
    
    UNION ALL
    
    -- Billing Disputes
    SELECT 
        DISPUTE_NUMBER as INCIDENT_NUMBER,
        'Billing Dispute' as INCIDENT_TYPE,
        CATEGORY as CATEGORY,
        DISPUTE_REASON as DESCRIPTION,
        OPENED_DATE as INCIDENT_DATE,
        STATUS,
        'High' as PRIORITY,
        'Billing' as CHANNEL,
        NETWORK_INCIDENT_ID
    FROM BILLING_DATA.DISPUTE d
    JOIN BILLING_DATA.BILLING_ACCOUNT ba ON ba.BILLING_ACCOUNT_ID = d.BILLING_ACCOUNT_ID
    WHERE ba.CUSTOMER_ID = 'BIL-ACC-NOR-000001'
    
    UNION ALL
    
    -- Complaints
    SELECT 
        COMPLAINT_ID as INCIDENT_NUMBER,
        'Complaint' as INCIDENT_TYPE,
        CATEGORY as CATEGORY,
        SUBSTR(COMPLAINT_TEXT, 1, 100) as DESCRIPTION,
        COMPLAINT_TIMESTAMP as INCIDENT_DATE,
        STATUS,
        PRIORITY,
        CHANNEL,
        NETWORK_INCIDENT_ID
    FROM COMPLAINTS.UNIFIED_COMPLAINT
    WHERE CUSTOMER_ID = 'ACC-NOR-000001'
)
SELECT 
    INCIDENT_DATE,
    INCIDENT_TYPE,
    CATEGORY,
    DESCRIPTION,
    PRIORITY,
    STATUS,
    CHANNEL,
    CASE WHEN NETWORK_INCIDENT_ID IS NOT NULL THEN 'Yes' ELSE 'No' END as NETWORK_RELATED
FROM customer_incidents
ORDER BY INCIDENT_DATE DESC;
```

---

## 6️⃣ Incident Metrics & Analytics

### Pre-Built Analytics Views

**Available analytical views:**

```sql
-- 1. Root cause analysis with financial impact
SELECT * FROM ANALYTICS.V_ROOT_CAUSE_ANALYSIS;

-- 2. Network incident impact on customers
SELECT * FROM ANALYTICS.V_NETWORK_INCIDENT_IMPACT;

-- 3. Customer health scores including incident history
SELECT * FROM ANALYTICS.V_CUSTOMER_360;

-- 4. Complaint trends over time
SELECT * FROM ANALYTICS.V_COMPLAINT_TRENDS;
```

### Key Metrics Dashboard Query

```sql
-- Comprehensive incident metrics
SELECT 
    'Total Incidents (All Types)' as METRIC,
    (SELECT COUNT(*) FROM CUSTOMER_DATA.CASE) +
    (SELECT COUNT(*) FROM BILLING_DATA.DISPUTE) +
    (SELECT COUNT(*) FROM COMPLAINTS.UNIFIED_COMPLAINT) as VALUE
    
UNION ALL

SELECT 
    'Network-Related Incidents',
    (SELECT COUNT(*) FROM CUSTOMER_DATA.CASE WHERE NETWORK_INCIDENT_ID IS NOT NULL) +
    (SELECT COUNT(*) FROM BILLING_DATA.DISPUTE WHERE NETWORK_INCIDENT_ID IS NOT NULL)
    
UNION ALL

SELECT 
    'Billing Incidents',
    (SELECT COUNT(*) FROM BILLING_DATA.DISPUTE)
    
UNION ALL

SELECT 
    'Service Quality Incidents',
    (SELECT COUNT(*) FROM COMPLAINTS.UNIFIED_COMPLAINT 
     WHERE CATEGORY IN ('Technical', 'Service', 'Network'))
    
UNION ALL

SELECT 
    'Customer Service Incidents',
    (SELECT COUNT(*) FROM COMPLAINTS.UNIFIED_COMPLAINT 
     WHERE CATEGORY = 'Feedback')
    
UNION ALL

SELECT 
    'UC2 Network Incidents',
    (SELECT COUNT(*) FROM UC2_PREDICTIVE_MAINTENANCE.INCIDENTS.FACT_INCIDENTS)
    
UNION ALL

SELECT 
    'Total Affected Customers',
    (SELECT COUNT(DISTINCT ACCOUNT_ID) FROM CUSTOMER_DATA.CASE) +
    (SELECT COUNT(DISTINCT CUSTOMER_ID) FROM COMPLAINTS.UNIFIED_COMPLAINT);
```

---

## 📈 Incident Trend Analysis

### Time-Series Analysis

```sql
-- Incident volume trends by type over time
SELECT 
    DATE_TRUNC('week', CREATED_DATE) as WEEK,
    CATEGORY,
    COUNT(*) as INCIDENT_COUNT,
    AVG(RESOLUTION_TIME_MINUTES) as AVG_RESOLUTION_MINUTES,
    SUM(CASE WHEN NETWORK_INCIDENT_ID IS NOT NULL THEN 1 ELSE 0 END) as NETWORK_RELATED_COUNT
FROM CUSTOMER_DATA.CASE
WHERE CREATED_DATE >= DATEADD(month, -6, CURRENT_DATE())
GROUP BY WEEK, CATEGORY
ORDER BY WEEK DESC, INCIDENT_COUNT DESC;
```

### Geographic Incident Distribution

```sql
-- Incidents by region
SELECT 
    a.REGION,
    a.CITY,
    COUNT(DISTINCT c.CASE_ID) as CASE_COUNT,
    COUNT(DISTINCT uc.COMPLAINT_ID) as COMPLAINT_COUNT,
    COUNT(DISTINCT c.NETWORK_INCIDENT_ID) as NETWORK_INCIDENT_COUNT,
    COUNT(DISTINCT a.ACCOUNT_ID) as AFFECTED_CUSTOMERS
FROM CUSTOMER_DATA.ACCOUNT a
LEFT JOIN CUSTOMER_DATA.CASE c ON c.ACCOUNT_ID = a.ACCOUNT_ID
LEFT JOIN COMPLAINTS.UNIFIED_COMPLAINT uc ON uc.CUSTOMER_ID = a.ACCOUNT_ID
GROUP BY a.REGION, a.CITY
ORDER BY CASE_COUNT DESC;
```

---

## 🎯 Summary

### You Have Complete Incident Data:

✅ **CRM Cases**: 15,000 customer-reported incidents (5 types)
✅ **Billing Disputes**: 25,000 billing-related incidents (4 types)
✅ **Network Incidents**: 705 infrastructure incidents from UC2 (7+ types)
✅ **Service Complaints**: 30,000 multi-channel complaints (all service issues)
✅ **Sentiment Data**: 30,000 AI-analyzed incidents with emotions
✅ **Integration**: All systems linked for complete incident view

### Total Incident Coverage: 70,000+ Records

**Every customer issue is captured:**
- Network problems (outages, degradation, coverage)
- Billing issues (disputes, payment, charges)
- Technical support (configuration, setup, troubleshooting)
- Service quality (activation, changes, interruptions)
- Customer experience (satisfaction, feedback, complaints)

### Access All Incidents:

1. **By System**: Query individual tables (CRM, Billing, Complaints)
2. **By Customer**: Get complete incident timeline per customer
3. **By Type**: Filter by category/subcategory
4. **By Impact**: Link to network incidents, sentiment, financial
5. **By Time**: Trend analysis over 6 months
6. **By Geography**: Regional and site-level analysis

---

**Your platform provides COMPLETE incident visibility across all customer touchpoints!** 🎯

All incident types are captured, categorized, and linked to:
- Network infrastructure (UC2)
- Customer accounts (CRM)
- Billing system (payments/disputes)
- Sentiment analysis (AI)
- Churn risk predictions (ML)

Ready for comprehensive incident analysis and demonstration!

