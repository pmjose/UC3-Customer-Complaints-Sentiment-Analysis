-- =====================================================================
-- UC3 - GENERATE UC2 REFERENCE DATA IN SNOWFLAKE
-- =====================================================================
-- Purpose: Generate UC2 network reference data directly in Snowflake
-- Usage: Run AFTER setup_customer_complaints.sql
-- Time: ~2-3 minutes
-- Note: Completely SQL-based - no CSV files needed!
-- =====================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE UC3_CUSTOMER_COMPLAINTS;

-- =====================================================================
-- SECTION 1: CREATE UC2 REFERENCE SCHEMA
-- =====================================================================

SELECT 'Creating UC2_REFERENCE schema for network data...' as STATUS;

CREATE SCHEMA IF NOT EXISTS UC2_REFERENCE
    COMMENT = 'UC2 network reference data (cell sites and incidents)';

USE SCHEMA UC2_REFERENCE;

-- =====================================================================
-- SECTION 2: CREATE UC2 REFERENCE TABLES
-- =====================================================================

-- Cell sites table
CREATE OR REPLACE TABLE DIM_CELL_SITE (
    SITE_ID VARCHAR(50) PRIMARY KEY,
    SITE_NAME VARCHAR(200),
    SITE_TYPE VARCHAR(50),
    TECHNOLOGY VARCHAR(20),
    STATUS VARCHAR(20),
    REGION VARCHAR(100),
    DISTRICT VARCHAR(100),
    CITY VARCHAR(100),
    ADDRESS VARCHAR(500),
    POSTAL_CODE VARCHAR(20),
    LATITUDE FLOAT,
    LONGITUDE FLOAT,
    ALTITUDE_METERS INT,
    INSTALLATION_DATE DATE,
    LAST_MAINTENANCE_DATE DATE,
    MAINTENANCE_TEAM_ID VARCHAR(50),
    COVERAGE_RADIUS_KM FLOAT,
    POPULATION_COVERED INT,
    IS_5G_ENABLED BOOLEAN,
    BACKUP_POWER BOOLEAN,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Cell tower and site reference data';

-- Network incidents table
CREATE OR REPLACE TABLE FACT_INCIDENTS (
    INCIDENT_ID VARCHAR(50) PRIMARY KEY,
    SITE_ID VARCHAR(50),
    INCIDENT_TYPE VARCHAR(100),
    SEVERITY VARCHAR(20),
    INCIDENT_TIMESTAMP TIMESTAMP_NTZ,
    RESOLUTION_TIMESTAMP TIMESTAMP_NTZ,
    DURATION_MINUTES INT,
    AFFECTED_SERVICES VARCHAR(200),
    ROOT_CAUSE VARCHAR(500),
    CUSTOMERS_AFFECTED INT,
    STATUS VARCHAR(50),
    PRIORITY VARCHAR(20),
    ASSIGNED_TEAM VARCHAR(100),
    DESCRIPTION TEXT,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Network incident records';

SELECT 'UC2 reference tables created' as STATUS;

-- =====================================================================
-- SECTION 3: GENERATE CELL SITE DATA (500 sites)
-- =====================================================================

SELECT 'Generating 500 cell sites...' as STATUS;

INSERT INTO DIM_CELL_SITE (
    SITE_ID,
    SITE_NAME,
    SITE_TYPE,
    TECHNOLOGY,
    STATUS,
    REGION,
    DISTRICT,
    CITY,
    ADDRESS,
    LATITUDE,
    LONGITUDE,
    ALTITUDE_METERS,
    COVERAGE_RADIUS_KM,
    POPULATION_COVERED,
    IS_5G_ENABLED,
    BACKUP_POWER,
    INSTALLATION_DATE,
    LAST_MAINTENANCE_DATE,
    MAINTENANCE_TEAM_ID
)
WITH SITE_GENERATOR AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT 
    'SITE-' || LPAD(ROW_NUM::VARCHAR, 5, '0') as SITE_ID,
    'Cell Tower ' || ROW_NUM as SITE_NAME,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN 'Macro Cell'
        WHEN 2 THEN 'Small Cell'
        ELSE 'Indoor'
    END as SITE_TYPE,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN '5G'
        WHEN 2 THEN '4G'
        ELSE '3G'
    END as TECHNOLOGY,
    'Active' as STATUS,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'Norte'
        WHEN 2 THEN 'Centro'
        WHEN 3 THEN 'Lisboa'
        WHEN 4 THEN 'Alentejo'
        ELSE 'Algarve'
    END as REGION,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'Porto' WHEN 2 THEN 'Braga' WHEN 3 THEN 'Lisboa'
        WHEN 4 THEN 'Coimbra' WHEN 5 THEN 'Faro' WHEN 6 THEN 'Évora'
        WHEN 7 THEN 'Setúbal' WHEN 8 THEN 'Aveiro' WHEN 9 THEN 'Leiria'
        ELSE 'Viseu'
    END as DISTRICT,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'Porto' WHEN 2 THEN 'Braga' WHEN 3 THEN 'Lisboa'
        WHEN 4 THEN 'Coimbra' WHEN 5 THEN 'Faro' WHEN 6 THEN 'Évora'
        WHEN 7 THEN 'Setúbal' WHEN 8 THEN 'Aveiro' WHEN 9 THEN 'Leiria'
        ELSE 'Viseu'
    END as CITY,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'Rua das Torres' WHEN 2 THEN 'Avenida Central'
        WHEN 3 THEN 'Praça Principal' WHEN 4 THEN 'Rua do Campo'
        WHEN 5 THEN 'Avenida da República' WHEN 6 THEN 'Rua das Antenas'
        WHEN 7 THEN 'Largo Municipal' WHEN 8 THEN 'Rua Industrial'
        WHEN 9 THEN 'Zona Comercial' ELSE 'Parque Empresarial'
    END || ', ' || UNIFORM(1, 300, RANDOM()) as ADDRESS,
    UNIFORM(37.0, 42.0, RANDOM())::FLOAT as LATITUDE,
    UNIFORM(-9.5, -6.5, RANDOM())::FLOAT as LONGITUDE,
    UNIFORM(10, 500, RANDOM()) as ALTITUDE_METERS,
    UNIFORM(1, 10, RANDOM())::FLOAT as COVERAGE_RADIUS_KM,
    UNIFORM(1000, 50000, RANDOM()) as POPULATION_COVERED,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 6 THEN TRUE ELSE FALSE END as IS_5G_ENABLED,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 8 THEN TRUE ELSE FALSE END as BACKUP_POWER,
    DATEADD(day, -UNIFORM(30, 1825, RANDOM()), CURRENT_DATE()) as INSTALLATION_DATE,
    DATEADD(day, -UNIFORM(1, 90, RANDOM()), CURRENT_DATE()) as LAST_MAINTENANCE_DATE,
    'TEAM-' || LPAD(UNIFORM(1, 10, RANDOM())::VARCHAR, 2, '0') as MAINTENANCE_TEAM_ID
FROM SITE_GENERATOR;

SELECT COUNT(*) || ' cell sites generated' as STATUS FROM DIM_CELL_SITE;

-- Verify distribution
SELECT 'Cell Sites by Region:' as SUMMARY;
SELECT REGION, COUNT(*) as SITES 
FROM DIM_CELL_SITE 
GROUP BY REGION 
ORDER BY SITES DESC;

-- =====================================================================
-- SECTION 4: GENERATE NETWORK INCIDENT DATA (5,000 incidents)
-- =====================================================================

SELECT 'Generating 5,000 network incidents...' as STATUS;

INSERT INTO FACT_INCIDENTS (
    INCIDENT_ID,
    SITE_ID,
    INCIDENT_TYPE,
    SEVERITY,
    INCIDENT_TIMESTAMP,
    RESOLUTION_TIMESTAMP,
    DURATION_MINUTES,
    AFFECTED_SERVICES,
    ROOT_CAUSE,
    CUSTOMERS_AFFECTED,
    STATUS,
    PRIORITY,
    ASSIGNED_TEAM,
    DESCRIPTION
)
WITH INCIDENT_GENERATOR AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
),
SITES_RANDOM AS (
    SELECT SITE_ID, REGION, ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM DIM_CELL_SITE
)
SELECT 
    'INC-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as INCIDENT_ID,
    s.SITE_ID,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'Network Outage'
        WHEN 2 THEN 'Degraded Service'
        WHEN 3 THEN 'Equipment Failure'
        WHEN 4 THEN 'Power Failure'
        WHEN 5 THEN 'Configuration Error'
        WHEN 6 THEN 'Software Bug'
        WHEN 7 THEN 'Capacity Overload'
        ELSE 'Planned Maintenance'
    END as INCIDENT_TYPE,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'Critical'
        WHEN 2 THEN 'High'
        WHEN 3 THEN 'Medium'
        ELSE 'Low'
    END as SEVERITY,
    DATEADD(minute, -UNIFORM(1, 259200, RANDOM()), CURRENT_TIMESTAMP()) as INCIDENT_TIMESTAMP,
    DATEADD(minute, UNIFORM(10, 480, RANDOM()), 
        DATEADD(minute, -UNIFORM(1, 259200, RANDOM()), CURRENT_TIMESTAMP())) as RESOLUTION_TIMESTAMP,
    UNIFORM(10, 480, RANDOM()) as DURATION_MINUTES,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'Voice, Data'
        WHEN 2 THEN 'Data Only'
        WHEN 3 THEN 'Voice Only'
        WHEN 4 THEN 'All Services'
        ELSE 'SMS, MMS'
    END as AFFECTED_SERVICES,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'Hardware failure in base station'
        WHEN 2 THEN 'Software configuration issue'
        WHEN 3 THEN 'Power supply interruption'
        WHEN 4 THEN 'Network congestion'
        WHEN 5 THEN 'Fiber optic cable damage'
        WHEN 6 THEN 'Equipment overheating'
        WHEN 7 THEN 'Planned maintenance window'
        ELSE 'Unknown - under investigation'
    END as ROOT_CAUSE,
    UNIFORM(50, 5000, RANDOM()) as CUSTOMERS_AFFECTED,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'Open'
        WHEN 2 THEN 'In Progress'
        WHEN 3 THEN 'Investigating'
        ELSE 'Resolved'
    END as STATUS,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'P1 - Critical'
        WHEN 2 THEN 'P2 - High'
        WHEN 3 THEN 'P3 - Medium'
        ELSE 'P4 - Low'
    END as PRIORITY,
    'Network-Team-' || LPAD(UNIFORM(1, 15, RANDOM())::VARCHAR, 2, '0') as ASSIGNED_TEAM,
    CASE UNIFORM(1, 6, RANDOM())
        WHEN 1 THEN 'Multiple customers reporting no service in coverage area. Technicians dispatched to investigate base station.'
        WHEN 2 THEN 'Degraded performance detected on sector equipment. Running diagnostics and preparing for component replacement.'
        WHEN 3 THEN 'Power outage affecting site operations. Backup generators activated but limited capacity.'
        WHEN 4 THEN 'Scheduled maintenance window for software upgrade. Service interruption expected.'
        WHEN 5 THEN 'Fiber cut reported by transport provider. Working on service restoration via alternate route.'
        ELSE 'Capacity threshold exceeded during peak hours. Analyzing traffic patterns for optimization.'
    END as DESCRIPTION
FROM INCIDENT_GENERATOR ig
LEFT JOIN SITES_RANDOM s ON ((ig.ROW_NUM - 1) % (SELECT COUNT(*) FROM DIM_CELL_SITE)) + 1 = s.RN;

SELECT COUNT(*) || ' incidents generated' as STATUS FROM FACT_INCIDENTS;

-- Verify distribution
SELECT 'Incidents by Severity:' as SUMMARY;
SELECT SEVERITY, COUNT(*) as INCIDENTS 
FROM FACT_INCIDENTS 
GROUP BY SEVERITY 
ORDER BY INCIDENTS DESC;

SELECT 'Recent Incidents (last 6 months):' as SUMMARY;
SELECT COUNT(*) as RECENT_INCIDENTS 
FROM FACT_INCIDENTS 
WHERE INCIDENT_TIMESTAMP >= DATEADD(month, -6, CURRENT_TIMESTAMP());

-- =====================================================================
-- SUMMARY
-- =====================================================================

SELECT '================================================' as SEPARATOR;
SELECT 'UC2 REFERENCE DATA GENERATED SUCCESSFULLY!' as STATUS;
SELECT '================================================' as SEPARATOR;

SELECT 'SUMMARY:' as CATEGORY, '' as COUNT
UNION ALL
SELECT 'Cell Sites Generated:', COUNT(*)::VARCHAR FROM DIM_CELL_SITE
UNION ALL
SELECT 'Network Incidents Generated:', COUNT(*)::VARCHAR FROM FACT_INCIDENTS
UNION ALL
SELECT 'Recent Incidents (6 months):', 
    (SELECT COUNT(*)::VARCHAR FROM FACT_INCIDENTS WHERE INCIDENT_TIMESTAMP >= DATEADD(month, -6, CURRENT_TIMESTAMP()));

SELECT '================================================' as SEPARATOR;
SELECT 'NEXT STEP: Run generate_data_in_snowflake.sql' as NEXT_ACTION;
SELECT '================================================' as SEPARATOR;
