# Snowflake Intelligence Agent - Setup Guide

**Natural language query interface for UC3 Customer Complaints & Sentiment Analysis**

---

## Overview

The Snowflake Intelligence Agent allows business users to query your customer complaints data using **natural language** instead of SQL. This makes insights accessible to non-technical stakeholders.

**Example queries:**
- "Which customers are at high risk of churning?"
- "Show me negative complaints from this week"
- "What network incidents caused the most complaints?"

---

## What Was Created

### 7 Semantic Views

Semantic views use human-readable column names (with spaces and proper capitalization) that the AI agent can understand:

| View Name | Purpose | Records | Key Metrics |
|-----------|---------|---------|-------------|
| `CUSTOMER_360_SEMANTIC` | Complete customer profiles | 50,000 | Churn risk, health score, complaints, revenue |
| `COMPLAINTS_SENTIMENT_SEMANTIC` | All complaints with sentiment | 30,000 | Sentiment score, emotion, root cause |
| `CHURN_RISK_SEMANTIC` | Churn predictions | 50,000 | Churn probability, risk factors, recommendations |
| `NETWORK_INCIDENT_IMPACT_SEMANTIC` | UC2 incident correlation | 700+ | Complaint rate, sentiment impact, credits given |
| `VOICE_TRANSCRIPTS_SEMANTIC` | Call center analysis | 1,000 | Call metrics, satisfaction, resolution |
| `CRITICAL_ALERTS_SEMANTIC` | High-priority alerts | 1,000+ | Severity, customer value, recommended actions |
| `SENTIMENT_TRENDS_SEMANTIC` | Time-series analysis | Aggregated | Daily/weekly/monthly trends by channel |

### Location

**Database**: `SNOWFLAKE_INTELLIGENCE`
**Schema**: `SEMANTIC_VIEWS`

All views are accessible via:
```sql
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA SEMANTIC_VIEWS;

SELECT * FROM CUSTOMER_360_SEMANTIC LIMIT 10;
```

---

## Deployment Steps

### Step 1: Create Semantic Views (2-3 minutes)

**In Snowflake UI:**

1. Open **Worksheets**
2. Create new worksheet
3. Copy/paste entire `create_semantic_intelligence_agent.sql` file
4. Click **"Run All"**
5. Wait for completion

**Verify:**
- Check for success message: "SEMANTIC LAYER CREATED SUCCESSFULLY!"
- Verify 7 views created in `SNOWFLAKE_INTELLIGENCE.SEMANTIC_VIEWS`

---

### Step 2: Create Intelligence Agent (3-5 minutes)

**In Snowflake UI:**

1. Navigate to **Data** → **Agents** (or **AI & ML** → **Cortex** → **Agents**)
2. Click **"+ Agent"** or **"Create Agent"** button
3. **Configure agent:**
   - **Name**: `Customer Complaints Intelligence Agent`
   - **Description**: `AI agent for analyzing customer complaints, sentiment, and churn risk with natural language queries`
   - **Warehouse**: Select your compute warehouse (MEDIUM or LARGE recommended)

4. **Add semantic views** (click "Add" and select each):
   - ✅ `CUSTOMER_360_SEMANTIC`
   - ✅ `COMPLAINTS_SENTIMENT_SEMANTIC`
   - ✅ `CHURN_RISK_SEMANTIC`
   - ✅ `NETWORK_INCIDENT_IMPACT_SEMANTIC`
   - ✅ `VOICE_TRANSCRIPTS_SEMANTIC`
   - ✅ `CRITICAL_ALERTS_SEMANTIC`
   - ✅ `SENTIMENT_TRENDS_SEMANTIC`

5. **Review suggestions**: Snowflake will auto-detect metrics and dimensions
6. Click **"Create Agent"**
7. Wait for agent initialization (~1-2 minutes)

---

### Step 3: Test the Agent (5 minutes)

**Try these natural language queries:**

**Churn & Risk Analysis:**
```
Which customers are at highest risk of churning?
Show me customers with churn probability above 80%
How much annual revenue is at risk from customer churn?
Which high-value customers need proactive outreach?
```

**Sentiment Analysis:**
```
Show me the most negative complaints from this week
What is the average customer sentiment by channel?
Which complaints have angry customers?
How has sentiment trended over the last month?
```

**Network Impact:**
```
Which network incidents generated the most complaints?
Show me incidents that caused billing disputes
What is the complaint rate for major outages?
How many complaints were related to network issues?
```

**Operational Insights:**
```
What are the top complaint categories?
Which agents have the best customer satisfaction scores?
How many critical alerts do we have today?
What is the average call handling time?
```

**Customer 360:**
```
Show me VIP customers with open cases
Which customers have multiple complaints this month?
What is the health score distribution?
Show me customers in Lisboa with complaints
```

---

## Sample Agent Conversation

**User**: "Which customers are at high risk of churning?"

**Agent Response**: 
```
I found 500 customers at critical risk and 2,500 at high risk.

Top 10 Critical Risk Customers:
- Customer XYZ (Account: ACC-NOR-001234)
  - Churn Probability: 92%
  - Monthly Revenue: €89.99
  - Recommended Action: Immediate intervention - assign retention specialist
  - Recent Complaints: 5 in last 3 months
  - Average Sentiment: -0.73 (highly negative)

[Full table with sortable columns...]

Would you like me to show the recommended actions for these customers?
```

**User**: "Yes, show me the recommended actions"

**Agent Response**:
```
Here are the personalized intervention recommendations:

Critical Risk (500 customers):
- Immediate intervention: Assign retention specialist, offer service credit
- Contact within 24 hours
- Review entire service history
- Escalate to management

High Risk (2,500 customers):  
- High priority: Contact customer within 48h
- Review service quality
- Offer plan optimization
- Monitor for escalation

[Additional details...]
```

---

## Semantic View Details

### 1. CUSTOMER_360_SEMANTIC

**Purpose**: Complete customer profile with all touchpoints

**Key Columns:**
- Customer ID, Name, Type, Tier, Region
- Active Subscriptions, Monthly/Annual Revenue
- Total Cases, Open Cases, Total Complaints
- Average Sentiment Score, Negative Complaints
- Network Incidents Experienced, Billing Disputes
- Churn Probability (%), Risk Level
- Health Score, Intervention Priority
- Recommended Action

**Sample Query:**
```
"Show me Gold tier customers in Porto with open complaints"
```

---

### 2. COMPLAINTS_SENTIMENT_SEMANTIC

**Purpose**: All complaints with AI sentiment analysis

**Key Columns:**
- Complaint ID, Case Number, Customer Name
- Channel, Date, Category, Priority, Status
- Complaint Text Preview
- Sentiment, Sentiment Score, Confidence
- Primary Emotion, Emotion Intensity
- Topic Category, Root Cause, Keywords
- Network Related (Yes/No), UC2 Incident details
- Resolution Time, Customer Satisfaction

**Sample Query:**
```
"Show me angry customer complaints about network outages"
```

---

### 3. CHURN_RISK_SEMANTIC

**Purpose**: Churn prediction with risk factors

**Key Columns:**
- Customer Name, Tier, Region
- Monthly/Annual Revenue
- Churn Probability (%), Risk Level
- Intervention Priority, Recommended Action
- Health Score, Complaint Score, Sentiment Score
- Cases (Last 3 Months), Open Cases
- Billing Disputes, Network Incidents
- Revenue at Risk (EUR)

**Sample Query:**
```
"Which customers need immediate intervention to prevent churn?"
```

---

### 4. NETWORK_INCIDENT_IMPACT_SEMANTIC

**Purpose**: UC2 network incident correlation with customer complaints

**Key Columns:**
- Incident ID, Date, Type, Severity, Root Cause
- Site Name, Region, Duration
- Estimated Affected Customers
- Complaints Received, Complaint Rate (%)
- Average Complaint Sentiment, Angry/Frustrated Customers
- Billing Disputes Created, Credits Given
- High Churn Risk Customers, Revenue at Risk

**Sample Query:**
```
"Which network outages had the highest customer impact?"
```

---

### 5. VOICE_TRANSCRIPTS_SEMANTIC

**Purpose**: Call center conversation analysis

**Key Columns:**
- Call ID, Case Number, Customer Name, Tier
- Call Date, Agent Name, Queue
- Call Duration, Wait Time, Handle Time
- First Call Resolution, Customer Satisfaction
- Sentiment, Emotion, Transcript Preview
- Network Related, Resolution Summary

**Sample Query:**
```
"Show me calls with low satisfaction scores from frustrated customers"
```

---

### 6. CRITICAL_ALERTS_SEMANTIC

**Purpose**: High-priority issues requiring attention

**Key Columns:**
- Alert ID, Case Number, Customer Name, Tier
- Alert Type, Severity, Reason, Date
- Assigned To, Status, Resolution Time
- Complaint Channel, Category, Sentiment, Emotion
- Churn Probability, Risk Level
- Annual Revenue, Recommended Action

**Sample Query:**
```
"What critical alerts need attention right now?"
```

---

### 7. SENTIMENT_TRENDS_SEMANTIC

**Purpose**: Time-series trend analysis

**Key Columns:**
- Date, Week, Month
- Channel, Category, Topic, Root Cause
- Region, City
- Sentiment, Average Sentiment Score
- Emotion, Emotion Intensity
- Complaint Count, Unique Customers
- Network Related Complaints (%), Resolution Rate (%)

**Sample Query:**
```
"How has customer sentiment trended over the last 60 days?"
```

---

## Agent Capabilities

### What the Agent Can Do

✅ **Answer questions in natural language** - No SQL knowledge required
✅ **Query multiple views** - Combines data across semantic models
✅ **Provide context** - Explains results with business context
✅ **Suggest follow-ups** - Recommends related queries
✅ **Generate visualizations** - Creates charts from results
✅ **Export results** - Download as CSV or share via email

### What Makes It Powerful

**1. Business User Friendly:**
- Ask questions naturally: "Show me..." "Which..." "How many..."
- No SQL syntax required
- Human-readable column names
- Contextual responses

**2. Multi-Domain Analysis:**
- Combines CRM, Billing, Complaints, UC2 Network data
- Cross-system correlation
- Complete customer context

**3. Real-Time Insights:**
- Query live data
- Up-to-date metrics
- Immediate answers

**4. Proactive Intelligence:**
- Identifies at-risk customers
- Flags critical issues
- Recommends actions

---

## Use Cases for the Agent

### For Executives:
```
"How much revenue is at risk from customer churn?"
"What are our top 3 customer complaint drivers?"
"Show me the sentiment trend for the last quarter"
```

### For Customer Service Managers:
```
"Which VIP customers have unresolved complaints?"
"What is our first call resolution rate this month?"
"Show me all critical alerts assigned to my team"
```

### For Data Analysts:
```
"Correlate network incidents with complaint spikes"
"Show me sentiment distribution by region and channel"
"What is the average time between incident and complaint?"
```

### For Retention Teams:
```
"Give me a list of customers who need proactive outreach"
"Which customers have declining sentiment trends?"
"Show me high-value customers at critical churn risk"
```

---

## Best Practices

### Writing Effective Queries

**✅ Good Queries:**
- "Which customers are at high risk of churning?"
- "Show me negative complaints from this week"
- "What is the average sentiment score by channel?"

**❌ Avoid:**
- Overly complex multi-part questions
- Asking for data not in semantic views
- Vague queries without context

### Query Tips

1. **Be Specific**: Include time frames ("this week", "last month")
2. **Use Metrics**: Reference specific columns ("churn probability", "sentiment score")
3. **Filter Wisely**: Mention tiers ("Gold customers"), regions ("Porto"), statuses ("open cases")
4. **Ask Follow-ups**: Build on previous queries for deeper insights

---

## Troubleshooting

### Agent Not Finding Data

**Issue**: "I couldn't find any data for that query"

**Solutions:**
- Ensure semantic views have data (run verification queries)
- Check column names match those in semantic views
- Try rephrasing the question
- Be more specific with time frames or filters

### Slow Response Times

**Issue**: Agent takes too long to respond

**Solutions:**
- Use a larger warehouse (MEDIUM or LARGE)
- Add date filters to limit data scanned
- Pre-compute aggregations in semantic views

### Incorrect Results

**Issue**: Agent returns unexpected data

**Solutions:**
- Verify semantic views are up to date
- Check if underlying data changed
- Rephrase query to be more specific
- Use sample queries as templates

---

## Maintenance

### Keep Agent Updated

**Weekly:**
- Refresh semantic views if data changes
- Review agent query logs for improvements
- Add new sample queries based on user patterns

**Monthly:**
- Audit agent usage and accuracy
- Update semantic views with new metrics
- Train agent with additional sample queries

### Refresh Semantic Views

If underlying data changes significantly:
```sql
-- Refresh all semantic views
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA SEMANTIC_VIEWS;

-- Re-run create_semantic_intelligence_agent.sql
-- This will recreate all views with latest data
```

---

## Advanced Features

### Custom Metrics

Add calculated fields to semantic views:
```sql
-- Example: Add NPS score calculation
ALTER VIEW CUSTOMER_360_SEMANTIC AS
SELECT 
    ...,
    CASE 
        WHEN "NPS Score" >= 9 THEN 'Promoter'
        WHEN "NPS Score" >= 7 THEN 'Passive'
        ELSE 'Detractor'
    END as "NPS Category"
FROM ...
```

### Share Agent with Teams

1. Go to agent in Snowflake UI
2. Click "Share"
3. Copy agent URL
4. Share with stakeholders
5. Set permissions (view-only vs edit)

---

## Summary

**You now have:**

✅ **7 Semantic Views** - Business-friendly data access
✅ **12 Sample Queries** - Agent training examples
✅ **Natural Language Interface** - Ask questions in plain English
✅ **Real-Time Insights** - Query 2.2M+ records instantly
✅ **Complete Integration** - CRM + Billing + UC2 + Sentiment data
✅ **Proactive Intelligence** - Churn prevention and alert management

**Deployment:**
- Script: `create_semantic_intelligence_agent.sql`
- Time: 5-10 minutes total
- Complexity: Easy (just run SQL + create agent in UI)

**Business Impact:**
- Democratizes data access across organization
- Enables self-service analytics for non-technical users
- Accelerates decision-making with instant insights
- Reduces dependency on data team for routine queries

---

**Ready to empower your entire organization with AI-driven customer intelligence!** 🚀

---

## Quick Reference

**Create Agent**: Data > Agents > + Agent
**Test Query**: "Which customers are at high risk of churning?"
**Share Agent**: Copy agent URL and distribute
**Documentation**: All sample queries in `create_semantic_intelligence_agent.sql`

**Total Setup Time**: 5-10 minutes
**User Training**: Minimal - natural language is intuitive
**Maintenance**: Low - semantic views auto-update with data







