SET search_path TO "motorportal";

CREATE OR REPLACE PROCEDURE sp_advance_batch_status(p_batch_id BIGINT, p_new_status VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order   VARCHAR[] := ARRAY['UPLOADED','VALIDATED','PREMIUM_CALCULATED','GST_CALCULATED',
                                  'PROPOSAL_CREATED','PAYMENT_PENDING','PAYMENT_PROCESSED',
                                  'POLICY_CREATED','PRINTED'];
    v_current VARCHAR;
    v_cur_idx INT;
    v_new_idx INT;
BEGIN
    SELECT STATUS INTO v_current FROM BATCH_MASTER WHERE BATCH_ID = p_batch_id FOR UPDATE;
    IF v_current IS NULL THEN
        RAISE EXCEPTION 'Batch % not found', p_batch_id;
    END IF;

    v_cur_idx := array_position(v_order, v_current);
    v_new_idx := array_position(v_order, p_new_status);

    IF v_new_idx IS NULL THEN
        RAISE EXCEPTION 'Unknown batch status %', p_new_status;
    END IF;

    IF v_new_idx <> v_cur_idx + 1 THEN
        RAISE EXCEPTION 'Invalid batch status transition from % to %', v_current, p_new_status;
    END IF;

    UPDATE BATCH_MASTER SET STATUS = p_new_status WHERE BATCH_ID = p_batch_id;
END;
$$;
