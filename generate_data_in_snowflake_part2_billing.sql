-- =====================================================================
-- UC3 - GENERATE SAMPLE DATA IN SNOWFLAKE - PART 2: BILLING DATA
-- =====================================================================
-- Purpose: Generate remaining billing data (invoices, payments, disputes)
-- Usage: Run AFTER generate_data_in_snowflake.sql (Part 1)
-- Time: ~10-15 minutes
-- =====================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE UC3_CUSTOMER_COMPLAINTS;
USE SCHEMA BILLING_DATA;

SELECT 'Starting Part 2: Billing data generation...' as STATUS;
SELECT '================================================' as SEPARATOR;

-- =====================================================================
-- STEP 11: GENERATE INVOICES (300,000 invoices across 6 months)
-- =====================================================================

SELECT 'Step 11: Generating 300,000 invoices...' as STATUS;

INSERT INTO BILL_INVOICE (
    INVOICE_ID,
    BILLING_ACCOUNT_ID,
    INVOICE_NUMBER,
    INVOICE_DATE,
    DUE_DATE,
    BILLING_PERIOD_START,
    BILLING_PERIOD_END,
    SUBTOTAL_AMOUNT,
    TAX_AMOUNT,
    TOTAL_AMOUNT,
    AMOUNT_PAID,
    BALANCE,
    STATUS,
    PAYMENT_RECEIVED_DATE,
    CURRENCY,
    CREATED_DATE
)
WITH INVOICE_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 300000))
),
BILLING_ACCOUNTS_REPEATED AS (
    SELECT 
        BILLING_ACCOUNT_ID,
        ROW_NUMBER() OVER (PARTITION BY BILLING_ACCOUNT_ID ORDER BY RANDOM()) as MONTH_NUM
    FROM BILLING_ACCOUNT,
         TABLE(GENERATOR(ROWCOUNT => 6))  -- 6 months of invoices per account
),
NUMBERED_ACCOUNTS AS (
    SELECT 
        BILLING_ACCOUNT_ID,
        MONTH_NUM,
        ROW_NUMBER() OVER (ORDER BY BILLING_ACCOUNT_ID, MONTH_NUM) as GLOBAL_NUM
    FROM BILLING_ACCOUNTS_REPEATED
)
SELECT 
    'INV-' || LPAD(ROW_NUM::VARCHAR, 10, '0') as INVOICE_ID,
    na.BILLING_ACCOUNT_ID,
    'INV-' || LPAD(ROW_NUM::VARCHAR, 12, '0') as INVOICE_NUMBER,
    DATEADD(month, -(6 - na.MONTH_NUM), DATE_TRUNC('month', CURRENT_DATE())) as INVOICE_DATE,
    DATEADD(day, 15, DATEADD(month, -(6 - na.MONTH_NUM), DATE_TRUNC('month', CURRENT_DATE()))) as DUE_DATE,
    DATEADD(month, -(7 - na.MONTH_NUM), DATE_TRUNC('month', CURRENT_DATE())) as BILLING_PERIOD_START,
    DATEADD(day, -1, DATEADD(month, -(6 - na.MONTH_NUM), DATE_TRUNC('month', CURRENT_DATE()))) as BILLING_PERIOD_END,
    UNIFORM(50, 500, RANDOM())::NUMBER(15,2) as SUBTOTAL_AMOUNT,
    UNIFORM(50, 500, RANDOM())::NUMBER(15,2) * 0.23 as TAX_AMOUNT,  -- 23% VAT (Portugal)
    UNIFORM(50, 500, RANDOM())::NUMBER(15,2) * 1.23 as TOTAL_AMOUNT,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 8
        THEN UNIFORM(50, 500, RANDOM())::NUMBER(15,2) * 1.23
        ELSE UNIFORM(0, 50, RANDOM())::NUMBER(15,2)
    END as AMOUNT_PAID,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 8
        THEN 0
        ELSE UNIFORM(50, 500, RANDOM())::NUMBER(15,2)
    END as BALANCE,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'pending'
        WHEN 2 THEN 'cancelled'
        WHEN 3 THEN 'overdue'
        WHEN 4 THEN 'disputed'
        ELSE 'paid'
    END as STATUS,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 7
        THEN DATEADD(day, UNIFORM(0, 30, RANDOM()), DATEADD(month, -(6 - na.MONTH_NUM), DATE_TRUNC('month', CURRENT_DATE())))
        ELSE NULL
    END as PAYMENT_RECEIVED_DATE,
    'EUR' as CURRENCY,
    DATEADD(month, -(6 - na.MONTH_NUM), DATE_TRUNC('month', CURRENT_DATE())) as CREATED_DATE
FROM INVOICE_GENERATOR ig
LEFT JOIN NUMBERED_ACCOUNTS na ON ig.ROW_NUM = na.GLOBAL_NUM
WHERE na.GLOBAL_NUM IS NOT NULL;

SELECT COUNT(*) || ' invoices generated' as STATUS FROM BILL_INVOICE;

-- =====================================================================
-- STEP 12: GENERATE INVOICE LINE ITEMS (900,000 detail records)
-- =====================================================================

SELECT 'Step 12: Generating 900,000 invoice line items...' as STATUS;

INSERT INTO BILL_INVOICE_DETAIL (
    DETAIL_ID,
    INVOICE_ID,
    LINE_NUMBER,
    CHARGE_TYPE,
    DESCRIPTION,
    SUBSCRIPTION_ID,
    SERVICE_PERIOD_START,
    SERVICE_PERIOD_END,
    QUANTITY,
    UNIT_PRICE,
    AMOUNT,
    TAX_AMOUNT,
    CREATED_DATE
)
WITH DETAIL_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 900000))
),
INVOICES_REPEATED AS (
    SELECT 
        INVOICE_ID,
        INVOICE_DATE,
        BILLING_PERIOD_START,
        BILLING_PERIOD_END,
        ROW_NUMBER() OVER (PARTITION BY INVOICE_ID ORDER BY RANDOM()) as LINE_NUM
    FROM BILL_INVOICE,
         TABLE(GENERATOR(ROWCOUNT => 3))  -- Average 3 lines per invoice
),
NUMBERED_INVOICES AS (
    SELECT 
        INVOICE_ID,
        INVOICE_DATE,
        BILLING_PERIOD_START,
        BILLING_PERIOD_END,
        LINE_NUM,
        ROW_NUMBER() OVER (ORDER BY INVOICE_ID, LINE_NUM) as GLOBAL_NUM
    FROM INVOICES_REPEATED
)
SELECT 
    'INVD-' || LPAD(ROW_NUM::VARCHAR, 10, '0') as DETAIL_ID,
    ni.INVOICE_ID,
    ni.LINE_NUM as LINE_NUMBER,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'subscription'
        WHEN 2 THEN 'usage'
        WHEN 3 THEN 'one_time'
        WHEN 4 THEN 'adjustment'
        ELSE 'tax'
    END as CHARGE_TYPE,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN '5G Premium Plan - Monthly subscription fee'
        WHEN 2 THEN '4G Standard Service - Monthly recurring charge'
        WHEN 3 THEN 'Data Overage Charges - Additional usage'
        WHEN 4 THEN 'International Roaming - Voice and data'
        WHEN 5 THEN 'Voice Minutes - Additional usage beyond plan'
        WHEN 6 THEN 'SMS Bundle - Monthly package'
        WHEN 7 THEN 'Device Insurance - Monthly premium'
        WHEN 8 THEN 'Premium Support - Service fee'
        WHEN 9 THEN 'Cloud Storage 100GB - Monthly subscription'
        ELSE 'Equipment Rental - Monthly lease'
    END as DESCRIPTION,
    NULL as SUBSCRIPTION_ID,  -- Could be linked but keeping NULL for simplicity
    ni.BILLING_PERIOD_START as SERVICE_PERIOD_START,
    ni.BILLING_PERIOD_END as SERVICE_PERIOD_END,
    UNIFORM(1, 10, RANDOM())::DECIMAL(15,4) as QUANTITY,
    UNIFORM(5, 100, RANDOM())::DECIMAL(15,4) as UNIT_PRICE,
    UNIFORM(5, 1000, RANDOM())::DECIMAL(15,2) as AMOUNT,
    UNIFORM(1, 230, RANDOM())::DECIMAL(15,2) as TAX_AMOUNT,
    ni.INVOICE_DATE as CREATED_DATE
FROM DETAIL_GENERATOR dg
LEFT JOIN NUMBERED_INVOICES ni ON dg.ROW_NUM = ni.GLOBAL_NUM
WHERE ni.GLOBAL_NUM IS NOT NULL;

SELECT COUNT(*) || ' invoice line items generated' as STATUS FROM BILL_INVOICE_DETAIL;

-- =====================================================================
-- STEP 13: GENERATE USAGE RECORDS (500,000 usage records)
-- =====================================================================

SELECT 'Step 13: Generating 500,000 usage records...' as STATUS;

INSERT INTO RATED_EVENTS (
    EVENT_ID,
    SUBSCRIPTION_ID,
    EVENT_TYPE,
    EVENT_TIMESTAMP,
    DURATION_SECONDS,
    VOLUME_MB,
    QUANTITY,
    DESTINATION,
    RATED_AMOUNT,
    ROAMING,
    RATED_DATE
)
WITH USAGE_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 500000))
),
SUBSCRIPTIONS_RANDOM AS (
    SELECT 
        SUBSCRIPTION_ID,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM SUBSCRIPTION
),
SUBSCRIPTION_COUNT AS (
    SELECT COUNT(*) as CNT FROM SUBSCRIPTION
)
SELECT 
    'EVENT-' || LPAD(ROW_NUM::VARCHAR, 10, '0') as EVENT_ID,
    s.SUBSCRIPTION_ID,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'voice'
        WHEN 2 THEN 'data'
        WHEN 3 THEN 'sms'
        ELSE 'mms'
    END as EVENT_TYPE,
    DATEADD(hour, -UNIFORM(1, 4320, RANDOM()), CURRENT_TIMESTAMP()) as EVENT_TIMESTAMP,  -- Last 6 months
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN UNIFORM(10, 3600, RANDOM())  -- Voice call duration
        ELSE NULL
    END as DURATION_SECONDS,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 2 THEN UNIFORM(1, 5000, RANDOM())::DECIMAL(15,4)  -- Data volume
        ELSE NULL
    END as VOLUME_MB,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 3 THEN 1  -- SMS
        WHEN 4 THEN 1  -- MMS
        ELSE UNIFORM(1, 10, RANDOM())
    END as QUANTITY,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'National'
        WHEN 2 THEN 'International'
        WHEN 3 THEN 'EU Roaming'
        WHEN 4 THEN 'Worldwide'
        ELSE 'Premium'
    END as DESTINATION,
    UNIFORM(0.10, 50.00, RANDOM())::DECIMAL(15,4) as RATED_AMOUNT,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN TRUE ELSE FALSE END as ROAMING,
    DATEADD(hour, -UNIFORM(1, 4320, RANDOM()), CURRENT_TIMESTAMP()) as RATED_DATE
FROM USAGE_GENERATOR ug
CROSS JOIN SUBSCRIPTION_COUNT sc
LEFT JOIN SUBSCRIPTIONS_RANDOM s ON ((ug.ROW_NUM - 1) % sc.CNT) + 1 = s.RN;

SELECT COUNT(*) || ' usage events generated' as STATUS FROM RATED_EVENTS;

-- =====================================================================
-- STEP 14: GENERATE PAYMENTS (280,000 payment records)
-- =====================================================================

SELECT 'Step 14: Generating 280,000 payments...' as STATUS;

INSERT INTO PAYMENT (
    PAYMENT_ID,
    BILLING_ACCOUNT_ID,
    INVOICE_ID,
    PAYMENT_NUMBER,
    PAYMENT_DATE,
    AMOUNT,
    PAYMENT_METHOD,
    STATUS,
    TRANSACTION_REFERENCE,
    BANK_REFERENCE,
    CREATED_DATE
)
WITH PAYMENT_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 280000))
),
INVOICES_FOR_PAYMENT AS (
    SELECT 
        INVOICE_ID,
        BILLING_ACCOUNT_ID,
        TOTAL_AMOUNT,
        INVOICE_DATE,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM BILL_INVOICE
    WHERE STATUS IN ('paid', 'overdue')
),
INVOICE_COUNT AS (
    SELECT COUNT(*) as CNT FROM INVOICES_FOR_PAYMENT
)
SELECT 
    'PAY-' || LPAD(ROW_NUM::VARCHAR, 10, '0') as PAYMENT_ID,
    ifp.BILLING_ACCOUNT_ID,
    ifp.INVOICE_ID,
    'PMT-' || LPAD(ROW_NUM::VARCHAR, 12, '0') as PAYMENT_NUMBER,
    DATEADD(day, UNIFORM(1, 30, RANDOM()), ifp.INVOICE_DATE) as PAYMENT_DATE,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 8
        THEN ifp.TOTAL_AMOUNT
        ELSE ifp.TOTAL_AMOUNT * UNIFORM(25, 75, RANDOM()) / 100
    END::DECIMAL(15,2) as AMOUNT,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'direct_debit'
        WHEN 2 THEN 'credit_card'
        WHEN 3 THEN 'bank_transfer'
        WHEN 4 THEN 'multibanco'
        ELSE 'cash'
    END as PAYMENT_METHOD,
    CASE UNIFORM(1, 20, RANDOM())
        WHEN 1 THEN 'failed'
        WHEN 2 THEN 'pending'
        WHEN 3 THEN 'reversed'
        ELSE 'successful'
    END as STATUS,
    'TXN-' || LPAD(UNIFORM(1000000000, 9999999999, RANDOM())::VARCHAR, 16, '0') as TRANSACTION_REFERENCE,
    'REF-' || LPAD(UNIFORM(100000, 999999, RANDOM())::VARCHAR, 9, '0') as BANK_REFERENCE,
    DATEADD(day, UNIFORM(1, 30, RANDOM()), ifp.INVOICE_DATE) as CREATED_DATE
FROM PAYMENT_GENERATOR pg
CROSS JOIN INVOICE_COUNT ic
LEFT JOIN INVOICES_FOR_PAYMENT ifp ON ((pg.ROW_NUM - 1) % ic.CNT) + 1 = ifp.RN;

SELECT COUNT(*) || ' payments generated' as STATUS FROM PAYMENT;

-- =====================================================================
-- STEP 15: GENERATE DISPUTES (25,000 billing disputes)
-- =====================================================================

SELECT 'Step 15: Generating 25,000 billing disputes...' as STATUS;

INSERT INTO DISPUTE (
    DISPUTE_ID,
    BILLING_ACCOUNT_ID,
    INVOICE_ID,
    DISPUTE_NUMBER,
    DISPUTE_AMOUNT,
    DISPUTE_REASON,
    CATEGORY,
    OPENED_DATE,
    RESOLVED_DATE,
    STATUS,
    RESOLUTION_TYPE,
    ADJUSTMENT_GIVEN,
    ASSIGNED_TO,
    CREATED_DATE
)
WITH DISPUTE_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 25000))
),
INVOICES_FOR_DISPUTE AS (
    SELECT 
        INVOICE_ID,
        BILLING_ACCOUNT_ID,
        TOTAL_AMOUNT,
        INVOICE_DATE,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM BILL_INVOICE
),
INVOICE_COUNT_FOR_DISPUTE AS (
    SELECT COUNT(*) as CNT FROM BILL_INVOICE
)
SELECT 
    'DISP-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as DISPUTE_ID,
    ifd.BILLING_ACCOUNT_ID,
    ifd.INVOICE_ID,
    'DSP-' || LPAD(ROW_NUM::VARCHAR, 10, '0') as DISPUTE_NUMBER,
    ifd.TOTAL_AMOUNT * UNIFORM(10, 100, RANDOM()) / 100::DECIMAL(15,2) as DISPUTE_AMOUNT,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'Incorrect charges on invoice'
        WHEN 2 THEN 'Service not received as billed'
        WHEN 3 THEN 'Unauthorized charges detected'
        WHEN 4 THEN 'Rate plan mismatch'
        WHEN 5 THEN 'Duplicate billing identified'
        WHEN 6 THEN 'Promotion discount not applied'
        WHEN 7 THEN 'Equipment charges incorrect'
        ELSE 'Data overage charges disputed'
    END as DISPUTE_REASON,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'incorrect_charge'
        WHEN 2 THEN 'service_interruption'
        WHEN 3 THEN 'unauthorized_charge'
        ELSE 'other'
    END as CATEGORY,
    DATEADD(day, UNIFORM(1, 45, RANDOM()), ifd.INVOICE_DATE) as OPENED_DATE,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 7
        THEN DATEADD(day, UNIFORM(1, 30, RANDOM()), DATEADD(day, UNIFORM(1, 45, RANDOM()), ifd.INVOICE_DATE))
        ELSE NULL
    END as RESOLVED_DATE,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'open'
        WHEN 2 THEN 'investigating'
        WHEN 3 THEN 'resolved'
        WHEN 4 THEN 'rejected'
        ELSE 'cancelled'
    END as STATUS,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'credit_issued'
        WHEN 2 THEN 'charge_corrected'
        WHEN 3 THEN 'dispute_rejected'
        WHEN 4 THEN 'partial_credit'
        ELSE NULL
    END as RESOLUTION_TYPE,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 6
        THEN ifd.TOTAL_AMOUNT * UNIFORM(10, 100, RANDOM()) / 100::DECIMAL(15,2)
        ELSE NULL
    END as ADJUSTMENT_GIVEN,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'billing.team@company.com'
        WHEN 2 THEN 'disputes.agent1@company.com'
        WHEN 3 THEN 'disputes.agent2@company.com'
        WHEN 4 THEN 'disputes.supervisor@company.com'
        ELSE 'billing.manager@company.com'
    END as ASSIGNED_TO,
    DATEADD(day, UNIFORM(1, 45, RANDOM()), ifd.INVOICE_DATE) as CREATED_DATE
FROM DISPUTE_GENERATOR dg
CROSS JOIN INVOICE_COUNT_FOR_DISPUTE icfd
LEFT JOIN INVOICES_FOR_DISPUTE ifd ON ((dg.ROW_NUM - 1) % icfd.CNT) + 1 = ifd.RN;

SELECT COUNT(*) || ' disputes generated' as STATUS FROM DISPUTE;

-- =====================================================================
-- STEP 16: GENERATE ADJUSTMENT HISTORY
-- =====================================================================

SELECT 'Step 16: Generating adjustment history...' as STATUS;

INSERT INTO ADJUSTMENT (
    ADJUSTMENT_ID,
    BILLING_ACCOUNT_ID,
    INVOICE_ID,
    ADJUSTMENT_TYPE,
    AMOUNT,
    REASON,
    REASON_CODE,
    APPLIED_DATE,
    APPROVED_BY,
    CREATED_DATE
)
WITH ADJUSTMENT_GENERATOR AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ROW_NUM
    FROM TABLE(GENERATOR(ROWCOUNT => 30000))
),
INVOICES_FOR_ADJUSTMENT AS (
    SELECT 
        INVOICE_ID,
        BILLING_ACCOUNT_ID,
        TOTAL_AMOUNT,
        INVOICE_DATE,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) as RN
    FROM BILL_INVOICE
),
INVOICE_COUNT_FOR_ADJUSTMENT AS (
    SELECT COUNT(*) as CNT FROM BILL_INVOICE
)
SELECT 
    'ADJ-' || LPAD(ROW_NUM::VARCHAR, 8, '0') as ADJUSTMENT_ID,
    ifa.BILLING_ACCOUNT_ID,
    ifa.INVOICE_ID,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN 'credit'
        WHEN 2 THEN 'debit'
        ELSE 'correction'
    END as ADJUSTMENT_TYPE,
    UNIFORM(-200, 200, RANDOM())::DECIMAL(15,2) as AMOUNT,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'Service outage compensation'
        WHEN 2 THEN 'Billing error correction'
        WHEN 3 THEN 'Goodwill credit'
        WHEN 4 THEN 'Dispute resolution'
        WHEN 5 THEN 'Promotional credit'
        WHEN 6 THEN 'Rate plan change'
        WHEN 7 THEN 'Equipment return credit'
        ELSE 'Other adjustment'
    END as REASON,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'OUTAGE_COMP'
        WHEN 2 THEN 'BILL_ERROR'
        WHEN 3 THEN 'GOODWILL'
        WHEN 4 THEN 'DISPUTE_RES'
        WHEN 5 THEN 'PROMO'
        WHEN 6 THEN 'PLAN_CHANGE'
        WHEN 7 THEN 'EQUIP_RETURN'
        ELSE 'OTHER'
    END as REASON_CODE,
    DATEADD(day, UNIFORM(1, 30, RANDOM()), ifa.INVOICE_DATE) as APPLIED_DATE,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'system_auto'
        WHEN 2 THEN 'billing.agent@company.com'
        WHEN 3 THEN 'customer.service@company.com'
        ELSE 'billing.manager@company.com'
    END as APPROVED_BY,
    DATEADD(day, UNIFORM(1, 30, RANDOM()), ifa.INVOICE_DATE) as CREATED_DATE
FROM ADJUSTMENT_GENERATOR ag
CROSS JOIN INVOICE_COUNT_FOR_ADJUSTMENT icfa
LEFT JOIN INVOICES_FOR_ADJUSTMENT ifa ON ((ag.ROW_NUM - 1) % icfa.CNT) + 1 = ifa.RN;

SELECT COUNT(*) || ' adjustments generated' as STATUS FROM ADJUSTMENT;

-- =====================================================================
-- SUMMARY
-- =====================================================================

SELECT '================================================' as SEPARATOR;
SELECT 'PART 2 COMPLETE - All billing data generated!' as STATUS;
SELECT '================================================' as SEPARATOR;

SELECT 'BILLING DATA SUMMARY:' as CATEGORY, COUNT(*) as RECORDS FROM CUSTOMER_MASTER
UNION ALL SELECT 'Billing Accounts', COUNT(*) FROM BILLING_ACCOUNT
UNION ALL SELECT 'Subscriptions', COUNT(*) FROM SUBSCRIPTION
UNION ALL SELECT 'Invoices', COUNT(*) FROM BILL_INVOICE
UNION ALL SELECT 'Invoice Details', COUNT(*) FROM BILL_INVOICE_DETAIL
UNION ALL SELECT 'Usage Events', COUNT(*) FROM RATED_EVENTS
UNION ALL SELECT 'Payments', COUNT(*) FROM PAYMENT
UNION ALL SELECT 'Disputes', COUNT(*) FROM DISPUTE
UNION ALL SELECT 'Adjustments', COUNT(*) FROM ADJUSTMENT
ORDER BY RECORDS DESC;

SELECT '================================================' as SEPARATOR;
SELECT 'Next: Run Part 3 to generate complaint data' as NEXT_STEP;
SELECT '================================================' as SEPARATOR;

