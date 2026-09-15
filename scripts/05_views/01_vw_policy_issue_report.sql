SET search_path TO "SGInsurance";

CREATE OR REPLACE VIEW vw_policy_issue_report AS
SELECT
    bm.BATCH_ID          AS "Batch ID",
    pm.POLICY_NO         AS "Policy Number",
    pr.PROPOSAL_NO       AS "Proposal Number",
    mp.MASTER_POLICY_NO  AS "Master Policy",
    prod.PRODUCT_NAME    AS "Product",
    pm.MAKE              AS "Make",
    pm.MODEL             AS "Model",
    pm.ENGINE_NO         AS "Engine Number",
    pm.CHASSIS_NO        AS "Chassis Number",
    pm.PREMIUM           AS "Premium",
    pd.PAYMENT_STATUS    AS "Payment Status",
    pm.ISSUED_ON         AS "Issued Date",
    um.USERNAME          AS "User"
FROM POLICY_MASTER pm
JOIN PROPOSAL_MASTER pr   ON pr.PROPOSAL_ID = pm.PROPOSAL_ID
JOIN PAYMENT_DETAILS pd   ON pd.PAYMENT_ID = pm.PAYMENT_ID
JOIN MASTER_POLICY mp     ON mp.MASTER_POLICY_ID = pd.MASTER_POLICY_ID
JOIN PRODUCT_MASTER prod  ON prod.PRODUCT_ID = mp.PRODUCT_ID
JOIN BATCH_DETAIL bd      ON bd.DETAIL_ID = pr.DETAIL_ID
JOIN BATCH_MASTER bm      ON bm.BATCH_ID = bd.BATCH_ID
JOIN USER_MASTER um       ON um.USER_ID = bm.USER_ID;
