# Streamlit in Snowflake Deployment Guide
## Customer Complaints & Sentiment Analysis Dashboard

---

## 📋 Overview

This guide walks you through deploying the Customer Complaints Analytics dashboard as a **Streamlit in Snowflake (SiS)** application.

**File:** `streamlit_app.py` (single file - 1,000+ lines)

---

## ✅ Prerequisites

Before deploying, ensure you have:

1. ✅ **Data Generated:** All complaint data in `UC3_CUSTOMER_COMPLAINTS` database
2. ✅ **Snowflake Account:** With ACCOUNTADMIN or appropriate role
3. ✅ **Warehouse:** Running warehouse (e.g., `COMPUTE_WH`)
4. ✅ **Permissions:** CREATE STREAMLIT privilege

---

## 🚀 Deployment Steps

### Option 1: Snowsight UI Deployment (Recommended)

1. **Log into Snowflake Snowsight**
   - Navigate to: `Projects` → `Streamlit`

2. **Create New Streamlit App**
   - Click `+ Streamlit App`
   - App Name: `Customer_Complaints_Dashboard`
   - Warehouse: `COMPUTE_WH`
   - App Location: `UC3_CUSTOMER_COMPLAINTS.PUBLIC`

3. **Upload Code**
   - Delete the default code
   - Copy entire contents of `streamlit_app.py`
   - Paste into the editor
   - Click `Run` (top right)

4. **Verify Deployment**
   - App should load with Executive Summary
   - Test navigation between dashboards
   - Verify data appears correctly

### Option 2: SQL Command Deployment

```sql
-- 1. Create a stage for the app
USE DATABASE UC3_CUSTOMER_COMPLAINTS;
USE SCHEMA PUBLIC;

CREATE OR REPLACE STAGE STREAMLIT_STAGE;

-- 2. Upload the file (use SnowSQL or UI)
PUT file:///path/to/streamlit_app.py @STREAMLIT_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- 3. Create the Streamlit app
CREATE OR REPLACE STREAMLIT CUSTOMER_COMPLAINTS_DASHBOARD
  ROOT_LOCATION = '@UC3_CUSTOMER_COMPLAINTS.PUBLIC.STREAMLIT_STAGE'
  MAIN_FILE = 'streamlit_app.py'
  QUERY_WAREHOUSE = 'COMPUTE_WH'
  TITLE = 'Customer Complaints & Sentiment Analytics';

-- 4. Grant access
GRANT USAGE ON STREAMLIT CUSTOMER_COMPLAINTS_DASHBOARD TO ROLE SYSADMIN;
```

---

## 🎨 Dashboard Features

### **5 Persona Dashboards:**

1. **🎯 Executive Summary**
   - High-level KPIs and trends
   - AI-powered predictions
   - Priority alerts

2. **📞 Customer Service Manager**
   - Operational metrics
   - Case management
   - Agent performance
   - Resolution tracking

3. **🌐 Network Operations Manager**
   - Network incident correlation
   - Geographic distribution
   - Service quality monitoring
   - Predictive maintenance alerts

4. **💰 Billing & Finance Manager**
   - Dispute analytics
   - Revenue impact
   - Customer tier analysis
   - Cost recovery recommendations

5. **📊 Data Analyst**
   - Advanced analytics
   - Correlation analysis
   - Statistical insights
   - Data export capabilities

---

## 🔧 Configuration

### Date Range
- Default: Last 30 days
- Adjustable via sidebar date pickers
- Affects all dashboards globally

### Data Refresh
- Cached for 5 minutes (`@st.cache_data(ttl=300)`)
- Manual refresh via sidebar button
- Auto-refresh on date change

### Database Connection
- Uses Snowflake session: `get_active_session()`
- No external credentials needed
- Automatic connection management

---

## 🎯 Key Metrics Displayed

### Executive Summary
- Total Complaints
- Resolution Rate
- Affected Customers
- High Priority Open Issues

### Customer Service
- Open vs Closed Cases
- First Call Resolution Rate
- Average Handle Time
- SLA Compliance

### Network Operations
- Network-Related Complaints
- Unique Incidents
- Average Customer Impact
- Service Quality Score

### Billing & Finance
- Total Disputes
- Dispute Amount (€)
- Average Dispute Value
- Resolution Rate

### Data Analyst
- Total Records
- Correlation Scores
- Model Accuracy
- Data Quality Score

---

## 📊 Visualizations

### Chart Types Used:
- **Pie Charts:** Channel distribution, status breakdown
- **Bar Charts:** Categories, priorities, resolution rates
- **Line Charts:** Daily trends, time series
- **Heatmaps:** Complaint volume by hour/day
- **Gauge Charts:** Performance indicators
- **Waterfall Charts:** Revenue impact
- **Scatter Plots:** Performance correlation
- **Funnel Charts:** Status pipeline

### Color Scheme:
- Primary: `#29B5E8` (Snowflake Blue)
- Secondary: `#146EF5`
- Success: `#28C840`
- Warning: `#FFA500`
- Danger: `#DC3545`

---

## 🤖 AI Recommendations

Each dashboard includes **AI-powered insights** (simulated for demo):

### Types of Recommendations:
1. **Predictive:** Future complaint volume, churn risk
2. **Prescriptive:** Staffing optimization, routing suggestions
3. **Diagnostic:** Root cause analysis, pattern detection
4. **Alerting:** Anomalies, threshold violations

### Confidence Scores:
- All recommendations show confidence levels (75-95%)
- Impact/severity ratings included
- Actionable next steps suggested

---

## 🔐 Security & Permissions

### Required Roles:
```sql
-- Grant app access
GRANT USAGE ON DATABASE UC3_CUSTOMER_COMPLAINTS TO ROLE ANALYST_ROLE;
GRANT USAGE ON SCHEMA COMPLAINTS TO ROLE ANALYST_ROLE;
GRANT USAGE ON SCHEMA BILLING_DATA TO ROLE ANALYST_ROLE;
GRANT USAGE ON SCHEMA CUSTOMER_DATA TO ROLE ANALYST_ROLE;

-- Grant table access
GRANT SELECT ON ALL TABLES IN SCHEMA UC3_CUSTOMER_COMPLAINTS.COMPLAINTS TO ROLE ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA UC3_CUSTOMER_COMPLAINTS.BILLING_DATA TO ROLE ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA UC3_CUSTOMER_COMPLAINTS.CUSTOMER_DATA TO ROLE ANALYST_ROLE;

-- Grant Streamlit access
GRANT USAGE ON STREAMLIT CUSTOMER_COMPLAINTS_DASHBOARD TO ROLE ANALYST_ROLE;
```

---

## 🐛 Troubleshooting

### Common Issues:

**1. "Object does not exist" error**
```
Solution: Verify database name is UC3_CUSTOMER_COMPLAINTS
Check: SELECT CURRENT_DATABASE();
```

**2. "Session not found" error**
```
Solution: Ensure running in Snowflake SiS environment
Check: Must deploy to Snowflake, not local
```

**3. No data appearing**
```
Solution: 
- Verify data generation completed
- Run: SELECT COUNT(*) FROM UC3_CUSTOMER_COMPLAINTS.COMPLAINTS.UNIFIED_COMPLAINT;
- Check date range includes data
```

**4. Charts not loading**
```
Solution:
- Check warehouse is running
- Increase warehouse size if needed
- Clear cache and refresh
```

**5. Performance issues**
```
Solution:
- Use larger warehouse (MEDIUM or LARGE)
- Reduce date range
- Add indexes if needed
```

---

## 📈 Performance Optimization

### Query Optimization:
- All queries use `@st.cache_data(ttl=300)` for 5-minute caching
- Limit results where appropriate (TOP 10, LIMIT 20)
- Use appropriate date filters

### Warehouse Sizing:
- **Development:** XSMALL or SMALL
- **Demo:** SMALL or MEDIUM
- **Production:** MEDIUM or LARGE

### Best Practices:
1. Start with narrower date ranges (7-30 days)
2. Use auto-suspend for warehouse
3. Monitor query performance in Query History
4. Add materialized views for complex queries (future enhancement)

---

## 🔄 Updates & Maintenance

### Updating the App:
1. Edit `streamlit_app.py` locally
2. Re-upload to Snowflake
3. App auto-refreshes on next load

### Adding New Features:
- All code in single file for easy maintenance
- Follow existing pattern for new dashboards
- Test locally with Snowpark emulator (optional)

### Data Refresh:
- Data updates automatically as new complaints added
- Cache clears every 5 minutes
- Manual refresh available via sidebar button

---

## 📱 Access & Sharing

### Sharing the Dashboard:
1. Navigate to app in Snowsight
2. Click "Share" button
3. Select roles/users to grant access
4. Users access via: `Snowsight` → `Projects` → `Streamlit`

### URL Format:
```
https://<account>.snowflakecomputing.com/streamlit/UC3_CUSTOMER_COMPLAINTS.PUBLIC.CUSTOMER_COMPLAINTS_DASHBOARD
```

---

## 📚 Additional Resources

### Documentation:
- [Streamlit in Snowflake Docs](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- [Snowpark Python API](https://docs.snowflake.com/en/developer-guide/snowpark/python/index)
- [Plotly Documentation](https://plotly.com/python/)

### Support:
- Check Query History for SQL errors
- Review Streamlit logs in Snowsight
- Test queries independently in Worksheets

---

## ✅ Testing Checklist

Before going live:

- [ ] All 5 dashboards load without errors
- [ ] Date filters work correctly
- [ ] All charts display data
- [ ] AI recommendations appear
- [ ] Navigation works smoothly
- [ ] Tables are scrollable and formatted
- [ ] Metrics show correct calculations
- [ ] Export functionality works (Data Analyst page)
- [ ] Performance is acceptable (<5 sec load time)
- [ ] Mobile/responsive view looks good

---

## 🎉 Success!

Your Customer Complaints & Sentiment Analysis dashboard is now deployed!

**Next Steps:**
1. Share with stakeholders
2. Gather feedback
3. Monitor usage in Snowflake
4. Iterate based on user needs
5. Consider adding Semantic Intelligence Agent integration (future)

---

## 📞 Support

For issues or questions:
1. Check Snowflake Query History
2. Review Streamlit logs
3. Verify all prerequisites met
4. Test with smaller date ranges

**App Version:** 1.0  
**Last Updated:** 2025-01-14  
**Maintainer:** Data Engineering Team

