# Streamlit Dashboard - Quick Reference

## 🚀 Quick Deploy

```sql
-- In Snowsight:
-- 1. Go to Projects → Streamlit → + Streamlit App
-- 2. Name: Customer_Complaints_Dashboard
-- 3. Copy/paste streamlit_app.py contents
-- 4. Click Run
```

---

## 📊 Dashboard Overview

### 5 Persona Views:

| Icon | Dashboard | Purpose | Key Features |
|------|-----------|---------|--------------|
| 🎯 | **Executive Summary** | Strategic overview | KPIs, trends, AI predictions, alerts |
| 📞 | **Customer Service** | Operations | Case management, resolution tracking, staffing |
| 🌐 | **Network Operations** | Infrastructure | Incident correlation, geographic impact |
| 💰 | **Billing & Finance** | Revenue | Dispute analysis, financial impact |
| 📊 | **Data Analyst** | Deep Analytics | Correlations, statistics, data export |

---

## 🎨 Visual Components

### Each Dashboard Includes:
- ✅ 3-5 KPI metric cards
- ✅ 4-20 interactive Plotly charts
- ✅ Data tables (where relevant)
- ✅ AI recommendation panel
- ✅ Filters (via sidebar)
- ✅ **Customer 360° View** (Customer Service only) ⭐ NEW!

### Chart Types:
- 📊 Bar charts (categories, priorities)
- 🥧 Pie charts (distributions)
- 📈 Line charts (trends over time)
- 🔥 Heatmaps (volume patterns)
- 🎯 Gauge charts (performance)
- 💧 Waterfall charts (financial impact)

---

## 🔧 Key Features

### Customer 360° View: ⭐ NEW!
- **Location:** Customer Service Manager dashboard (top)
- **Access:** Click "🔍 CUSTOMER 360° VIEW" expander
- **Search:** Enter any Customer ID or Account ID
- **Sample Customers:** 3 buttons with guaranteed data
- **Data Sources:** 9 database tables unified
- **Tabs:** 8 organized sections
  - Summary (metrics + LTV)
  - All Complaints
  - Voice Transcripts (read actual text!)
  - Billing Info
  - Subscriptions
  - Invoice History
  - Billing Disputes
  - Support Cases
- **Load Time:** ~5 seconds
- **Export:** Complete profile download

### Navigation:
- **Sidebar:** Radio buttons for dashboard selection
- **Global Filters:** Date range applies to all views
- **Refresh:** Manual cache clear button

### Data:
- **Source:** UC3_CUSTOMER_COMPLAINTS database
- **Caching:** 5-minute TTL
- **Real-time:** Updates as new complaints added

### AI Insights:
- **Predictive:** Future trends and risks
- **Prescriptive:** Actionable recommendations
- **Confidence Scores:** 75-95% accuracy indicators

---

## 📋 SQL Queries Used

### Core Functions (15 total):
1. `get_complaint_summary()` - Overall stats
2. `get_channel_distribution()` - By channel
3. `get_daily_complaint_trend()` - Time series
4. `get_top_categories()` - Category breakdown
5. `get_status_distribution()` - Status counts
6. `get_priority_distribution()` - Priority levels
7. `get_network_incident_stats()` - Network impact
8. `get_resolution_metrics()` - Resolution by channel
9. `get_high_priority_cases()` - Open high-priority
10. `get_complaint_volume_heatmap()` - Hour/day patterns
11. `get_billing_disputes()` - Dispute stats
12. `get_dispute_by_type()` - Dispute categories
13. `get_network_complaint_correlation()` - Incident correlation
14. `get_channel_performance()` - Channel metrics
15. `get_customer_impact_by_tier()` - Customer tier analysis

---

## 🤖 AI Recommendations by Persona

### Executive (4 insights):
- Complaint volume predictions
- Network incident impact forecasts
- Sentiment trend alerts
- Churn risk identification

### Customer Service (4 insights):
- Routing optimization
- Agent training needs
- Staffing recommendations
- SLA risk alerts

### Network Operations (4 insights):
- Tower/site anomalies
- Service degradation predictions
- Proactive notifications
- Incident pattern analysis

### Billing & Finance (4 insights):
- Automation opportunities
- Revenue recovery
- Retention offers
- Churn prevention

### Data Analyst (4 insights):
- Correlation discoveries
- Anomaly detection
- Statistical patterns
- Model performance metrics

---

## 🎨 Snowflake Theme Colors

```python
Primary:   #29B5E8  # Snowflake blue
Secondary: #146EF5  # Darker blue
Success:   #28C840  # Green
Warning:   #FFA500  # Orange
Danger:    #DC3545  # Red
Purple:    #667eea  # AI insights gradient
```

---

## 🔑 Key Metrics

### Executive Summary:
- Total Complaints
- Resolution Rate (%)
- Affected Customers
- High Priority Open

### Customer Service:
- Open Cases
- First Call Resolution (%)
- Avg Handle Time (min)
- Resolution Rate (%)

### Network Operations:
- Network Complaints
- Unique Incidents
- Avg Impact (customers)
- Service Quality (%)

### Billing & Finance:
- Total Disputes
- Dispute Amount (€)
- Avg Dispute Value (€)
- Resolution Rate (%)

---

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| No data showing | Check date range includes data |
| Slow loading | Use smaller date range or larger warehouse |
| "Object not found" | Verify database is UC3_CUSTOMER_COMPLAINTS |
| Charts not rendering | Clear cache, check data types |
| Session error | Must run in Snowflake SiS |

---

## ⚡ Performance Tips

1. **Date Range:** Start with 7-30 days
2. **Warehouse:** Use SMALL or MEDIUM for demos
3. **Caching:** Leverages 5-min cache automatically
4. **Queries:** All optimized with LIMIT clauses

---

## 📱 Access

**Via Snowsight:**
```
Projects → Streamlit → Customer_Complaints_Dashboard
```

**Share with:**
```sql
GRANT USAGE ON STREAMLIT CUSTOMER_COMPLAINTS_DASHBOARD 
TO ROLE <role_name>;
```

---

## 🔄 Update Process

1. Edit `streamlit_app.py`
2. Re-upload to Snowflake
3. Refresh browser
4. Changes apply immediately

---

## 📦 File Structure

**Single File:** `streamlit_app.py` (~1000 lines)

**Sections:**
1. Imports & Config (lines 1-20)
2. Session & Constants (lines 21-40)
3. Custom CSS (lines 41-80)
4. SQL Functions (lines 81-300)
5. Chart Helpers (lines 301-450)
6. AI Recommendations (lines 451-550)
7. Dashboard Functions (lines 551-950)
8. Sidebar (lines 951-1000)
9. Router (lines 1001-1020)

---

## ✅ Pre-Launch Checklist

- [ ] Data generated in database
- [ ] Warehouse running
- [ ] File uploaded to Snowflake
- [ ] App created successfully
- [ ] All dashboards load
- [ ] Charts display correctly
- [ ] AI panels appear
- [ ] Date filters work
- [ ] Export functions (where applicable)
- [ ] Shared with appropriate roles

---

## 🎯 Use Cases

### Demos:
- Executive presentations
- Stakeholder reviews
- Customer showcases

### Operations:
- Daily monitoring
- Incident response
- Trend analysis

### Analytics:
- Deep-dive investigations
- Pattern discovery
- Data exports

---

## 📞 Quick Support

**Check First:**
1. Query History (any SQL errors?)
2. Streamlit logs (any Python errors?)
3. Data availability (tables populated?)

**Common Fixes:**
- Refresh browser
- Clear cache (sidebar button)
- Adjust date range
- Check warehouse running

---

**Version:** 1.0  
**Platform:** Streamlit in Snowflake  
**Database:** UC3_CUSTOMER_COMPLAINTS  
**Dependencies:** Native (Snowpark, Plotly, Pandas)

