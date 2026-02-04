-- ========================================================================
-- Network Operations - Semantic Views & Snowflake Intelligence Agent
-- Creates semantic views and AI agent for natural language queries
-- Database: UC1_NETWORK_OPERATIONS
-- ========================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE UC1_NETWORK_OPERATIONS;
USE SCHEMA ANALYTICS;

-- ========================================================================
-- STEP 1: ENABLE SNOWFLAKE INTELLIGENCE
-- ========================================================================

CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;

GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

SELECT 'Snowflake Intelligence enabled' as status;

-- ========================================================================
-- STEP 2: CREATE SEMANTIC VIEW FOR NETWORK PERFORMANCE
-- ========================================================================

CREATE OR REPLACE SEMANTIC VIEW UC1_NETWORK_OPERATIONS.ANALYTICS.NETWORK_SEMANTIC_VIEW
  tables (
    SITES as DIM_CELL_SITE primary key (Cell_ID) with synonyms=('cell sites','towers','cells','base stations') comment='Cell site locations and information',
    PERFORMANCE as FACT_RAN_PERFORMANCE primary key (Timestamp, Cell_ID, Technology) with synonyms=('network performance','ran metrics','kpis') comment='Network performance metrics'
  )
  relationships (
    PERF_TO_SITES as PERFORMANCE(Cell_ID) references SITES(Cell_ID)
  )
  facts (
    PERFORMANCE.RRC_ATTEMPTS as RRC_ConnEstabAtt comment='RRC attempts',
    PERFORMANCE.RRC_SUCCESSES as RRC_ConnEstabSucc comment='RRC successes',
    PERFORMANCE.DL_THROUGHPUT as DL_Throughput_Mbps comment='DL throughput Mbps',
    PERFORMANCE.PRB_UTIL_DL as DL_PRB_Utilization comment='DL PRB utilization %',
    PERFORMANCE.AVAILABILITY as Cell_Availability comment='Cell availability %',
    PERFORMANCE.RECORD_COUNT as 1 comment='Record count'
  )
  dimensions (
    PERFORMANCE.PERF_TIMESTAMP as Timestamp with synonyms=('time','timestamp','when') comment='Measurement time',
    PERFORMANCE.PERF_DATE as DATE(Timestamp) comment='Measurement date',
    PERFORMANCE.PERF_HOUR as HOUR(Timestamp) comment='Hour',
    PERFORMANCE.PERF_MONTH as MONTH(Timestamp) comment='Month',
    PERFORMANCE.PERF_YEAR as YEAR(Timestamp) comment='Year',
    SITES.CELL_ID as CELL_ID,
    SITES.CITY as City with synonyms=('city','location') comment='City',
    SITES.REGION as Region with synonyms=('region','area') comment='Region',
    SITES.TECHNOLOGY as Technology with synonyms=('tech','4g','5g') comment='Technology type'
  )
  metrics (
    PERFORMANCE.RRC_SUCCESS_RATE as (SUM(PERFORMANCE.RRC_SUCCESSES) / NULLIF(SUM(PERFORMANCE.RRC_ATTEMPTS), 0) * 100) comment='RRC success rate % - target >= 95%',
    PERFORMANCE.AVG_THROUGHPUT as AVG(PERFORMANCE.DL_THROUGHPUT) comment='Average throughput Mbps - target >= 10',
    PERFORMANCE.AVG_PRB_UTIL as AVG(PERFORMANCE.PRB_UTIL_DL) comment='Average PRB utilization % - warning > 70%',
    PERFORMANCE.AVG_AVAILABILITY as AVG(PERFORMANCE.AVAILABILITY) comment='Average availability % - target >= 99%',
    PERFORMANCE.TOTAL_SITES as COUNT(DISTINCT SITES.CELL_ID) comment='Total cell sites',
    PERFORMANCE.TOTAL_RECORDS as COUNT(PERFORMANCE.RECORD_COUNT) comment='Total measurements'
  )
  comment='Network performance semantic view for natural language queries'
  with extension (CA='{"tables":[{"name":"SITES","dimensions":[{"name":"CELL_ID"},{"name":"CITY","sample_values":["Lisboa","Porto","Braga"]},{"name":"REGION","sample_values":["Lisboa","Porto","Norte","Centro","Sul"]},{"name":"TECHNOLOGY","sample_values":["4G","5G"]}]},{"name":"PERFORMANCE","dimensions":[{"name":"PERF_TIMESTAMP"},{"name":"PERF_DATE"},{"name":"PERF_HOUR"},{"name":"PERF_MONTH"},{"name":"PERF_YEAR"}],"facts":[{"name":"RRC_ATTEMPTS"},{"name":"RRC_SUCCESSES"},{"name":"DL_THROUGHPUT"},{"name":"PRB_UTIL_DL"},{"name":"AVAILABILITY"},{"name":"RECORD_COUNT"}],"metrics":[{"name":"RRC_SUCCESS_RATE"},{"name":"AVG_THROUGHPUT"},{"name":"AVG_PRB_UTIL"},{"name":"AVG_AVAILABILITY"},{"name":"TOTAL_SITES"},{"name":"TOTAL_RECORDS"}]}],"relationships":[{"name":"PERF_TO_SITES","relationship_type":"many_to_one"}],"custom_instructions":"Data from Sept 2025. Use MAX(Timestamp) then DATEADD backwards. PRB>70%=warning, >85%=critical. RRC>=95% target."}');

SELECT 'Network semantic view created' as status;

-- ========================================================================
-- STEP 3: VERIFY SEMANTIC VIEWS
-- ========================================================================

SHOW SEMANTIC VIEWS IN SCHEMA ANALYTICS;
SHOW SEMANTIC DIMENSIONS;
SHOW SEMANTIC METRICS;

SELECT 'Semantic views verified' as status;

-- ========================================================================
-- STEP 4: CREATE SNOWFLAKE INTELLIGENCE AGENT
-- ========================================================================

GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE ACCOUNTADMIN;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE ACCOUNTADMIN;
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE ACCOUNTADMIN;
GRANT USAGE ON DATABASE UC1_NETWORK_OPERATIONS TO ROLE ACCOUNTADMIN;
GRANT USAGE ON SCHEMA UC1_NETWORK_OPERATIONS.ANALYTICS TO ROLE ACCOUNTADMIN;
GRANT SELECT ON ALL SEMANTIC VIEWS IN SCHEMA UC1_NETWORK_OPERATIONS.ANALYTICS TO ROLE ACCOUNTADMIN;

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.Network_Operations_Agent
WITH PROFILE='{"display_name":"Network Operations AI Agent"}'
COMMENT='AI agent for network performance analysis - ask questions about 4G/5G network performance, RRC success, throughput, capacity, and regional analysis in Portugal'
FROM SPECIFICATION $$
{
  "models": {"orchestration": ""},
  "instructions": {
    "response": "You are a telecom network analyst for Portugal network. Provide insights with charts. Use bar charts for comparisons, line charts for trends. Thresholds: RRC >=95%, PRB <70%, Availability >=99%, Throughput >=10 Mbps.",
    "orchestration": "Data from Sept 2025. Use MAX(Timestamp) then DATEADD backwards for ranges. Default 24h. Join facts to sites for geography. Portugal has 15 cities, 5 regions: Lisboa, Porto, Norte, Centro, Sul. Technologies: 4G (70%), 5G (30%). PRB >70%=warning, >85%=critical.",
    "sample_questions": [
      {"question":"Which cells have RRC below 95%?"},
      {"question":"Show top 10 congested sites"},
      {"question":"Compare 4G vs 5G throughput"},
      {"question":"What is average PRB by region?"},
      {"question":"Show Lisboa performance last 24h"},
      {"question":"Which sites have availability issues?"}
    ]
  },
  "tools": [{
    "tool_spec": {
      "type": "cortex_analyst_text_to_sql",
      "name": "Query Network Data",
      "description": "Query network performance: RRC success, throughput, PRB utilization, availability across 450 sites in Portugal"
    }
  }],
  "tool_resources": {
    "Query Network Data": {
      "semantic_view": "UC1_NETWORK_OPERATIONS.ANALYTICS.NETWORK_SEMANTIC_VIEW"
    }
  }
}
$$;

SELECT 'Agent created' as status;

-- ========================================================================
-- VERIFICATION
-- ========================================================================

SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;

-- Test query
SELECT 
    cs.Cell_ID,
    cs.City,
    cs.Region,
    (SUM(rp.RRC_ConnEstabSucc)/NULLIF(SUM(rp.RRC_ConnEstabAtt),0)*100) as rrc_rate,
    AVG(rp.DL_Throughput_Mbps) as avg_throughput
FROM ANALYTICS.FACT_RAN_PERFORMANCE rp
LEFT JOIN ANALYTICS.DIM_CELL_SITE cs ON rp.Cell_ID = cs.Cell_ID  
WHERE rp.Timestamp >= DATEADD(day, -1, (SELECT MAX(Timestamp) FROM ANALYTICS.FACT_RAN_PERFORMANCE))
GROUP BY cs.Cell_ID, cs.City, cs.Region
LIMIT 10;

SELECT '✅ COMPLETE! Access: Snowflake UI > Data > Agents > Network Operations AI Agent' as status;

/*
HOW TO USE:
1. Snowflake UI > Data > Agents > "Network Operations AI Agent"
2. Ask questions like:
   - "Which cells have low RRC success?"
   - "Show congested sites"
   - "Compare 4G vs 5G"
   - "What is throughput by region?"
*/
