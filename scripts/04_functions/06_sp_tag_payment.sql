SET search_path TO "motorportal";

CREATE OR REPLACE PROCEDURE sp_tag_payment(p_proposal_id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_master_policy_id  BIGINT;
    v_master_policy_no  VARCHAR(40);
    v_balance           NUMERIC(15,2);
    v_amount            NUMERIC(12,2);
    v_pf_ref_no         VARCHAR(40);
BEGIN
    SELECT mp.MASTER_POLICY_ID, mp.MASTER_POLICY_NO, mp.CD_BALANCE, pr.PREMIUM_AMOUNT
    INTO v_master_policy_id, v_master_policy_no, v_balance, v_amount
    FROM PROPOSAL_MASTER pr
    JOIN BATCH_DETAIL bd ON bd.DETAIL_ID = pr.DETAIL_ID
    JOIN MASTER_POLICY mp ON mp.MASTER_POLICY_NO = bd.MASTER_POLICY_NO
    WHERE pr.PROPOSAL_ID = p_proposal_id
    FOR UPDATE OF mp;

    IF v_master_policy_id IS NULL THEN
        RAISE EXCEPTION 'Proposal % has no resolvable master policy', p_proposal_id;
    END IF;

    IF v_balance < v_amount THEN
        RAISE EXCEPTION 'Insufficient CD balance for master policy % (balance %, required %)', v_master_policy_no, v_balance, v_amount;
    END IF;

    UPDATE MASTER_POLICY SET CD_BALANCE = CD_BALANCE - v_amount WHERE MASTER_POLICY_ID = v_master_policy_id;

    v_pf_ref_no := 'PF' || to_char(now(), 'YYYYMMDDHH24MISS') || lpad(p_proposal_id::VARCHAR, 6, '0');

    INSERT INTO PAYMENT_DETAILS (PROPOSAL_ID, MASTER_POLICY_ID, PF_REF_NO, AMOUNT, PAYMENT_STATUS, TAGGED_ON)
    VALUES (p_proposal_id, v_master_policy_id, v_pf_ref_no, v_amount, 'PROCESSED', now());
END;
$$;
