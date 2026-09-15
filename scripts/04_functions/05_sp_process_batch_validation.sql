SET search_path TO "SGInsurance";

CREATE OR REPLACE PROCEDURE sp_process_batch_validation(p_batch_id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id     INT;
    v_detail         RECORD;
    v_error          VARCHAR(255);
    v_valid_count    INT := 0;
    v_invalid_count  INT := 0;
    v_master_product INT;
BEGIN
    SELECT PRODUCT_ID INTO v_product_id FROM BATCH_MASTER WHERE BATCH_ID = p_batch_id;
    IF v_product_id IS NULL THEN
        RAISE EXCEPTION 'Batch % not found', p_batch_id;
    END IF;

    -- clear any prior validation output for this batch (idempotent re-run)
    DELETE FROM INVALID_RECORDS WHERE BATCH_ID = p_batch_id;

    FOR v_detail IN
        SELECT * FROM BATCH_DETAIL WHERE BATCH_ID = p_batch_id ORDER BY DETAIL_ID
    LOOP
        v_error := NULL;

        -- 8. mandatory fields present
        IF v_detail.MASTER_POLICY_NO IS NULL OR v_detail.MASTER_POLICY_NO = ''
           OR v_detail.ENGINE_NO IS NULL OR v_detail.ENGINE_NO = ''
           OR v_detail.CHASSIS_NO IS NULL OR v_detail.CHASSIS_NO = ''
           OR v_detail.INVOICE_NO IS NULL OR v_detail.INVOICE_NO = ''
           OR v_detail.TRANSIT_DATE IS NULL THEN
            v_error := 'Mandatory field missing (master policy, engine no, chassis no, invoice no or transit date)';
        END IF;

        -- 9. datatype correctness (transit date not in the future)
        IF v_error IS NULL AND v_detail.TRANSIT_DATE > CURRENT_DATE THEN
            v_error := 'Invalid transit date';
        END IF;

        -- 1. master policy exists
        IF v_error IS NULL THEN
            SELECT PRODUCT_ID INTO v_master_product
            FROM MASTER_POLICY WHERE MASTER_POLICY_NO = v_detail.MASTER_POLICY_NO;

            IF v_master_product IS NULL THEN
                v_error := 'Master policy not found';
            -- 2. product mapping valid for the batch''s product
            ELSIF v_master_product <> v_product_id THEN
                v_error := 'Master policy does not belong to the selected product';
            END IF;
        END IF;

        -- 3 & 4. engine/chassis not already registered as an issued policy
        IF v_error IS NULL AND EXISTS (
            SELECT 1 FROM POLICY_MASTER
            WHERE ENGINE_NO = v_detail.ENGINE_NO OR CHASSIS_NO = v_detail.CHASSIS_NO
        ) THEN
            v_error := 'Engine and Chassis number already registered';
        END IF;

        -- 5. no vehicle duplication within the batch (earlier row wins)
        IF v_error IS NULL AND EXISTS (
            SELECT 1 FROM BATCH_DETAIL
            WHERE BATCH_ID = p_batch_id
              AND DETAIL_ID < v_detail.DETAIL_ID
              AND (ENGINE_NO = v_detail.ENGINE_NO OR CHASSIS_NO = v_detail.CHASSIS_NO)
        ) THEN
            v_error := 'Duplicate vehicle within batch';
        END IF;

        -- 6/7. duplicate transaction within batch (same engine+chassis+invoice)
        IF v_error IS NULL AND EXISTS (
            SELECT 1 FROM BATCH_DETAIL
            WHERE BATCH_ID = p_batch_id
              AND DETAIL_ID < v_detail.DETAIL_ID
              AND ENGINE_NO = v_detail.ENGINE_NO
              AND CHASSIS_NO = v_detail.CHASSIS_NO
              AND INVOICE_NO = v_detail.INVOICE_NO
        ) THEN
            v_error := 'Duplicate transaction in batch';
        END IF;

        IF v_error IS NOT NULL THEN
            INSERT INTO INVALID_RECORDS (BATCH_ID, DETAIL_ID, TRANSIT_DATE, INVOICE_NO, ENGINE_NO, CHASSIS_NO, ERROR_REMARKS)
            VALUES (p_batch_id, v_detail.DETAIL_ID, v_detail.TRANSIT_DATE, v_detail.INVOICE_NO, v_detail.ENGINE_NO, v_detail.CHASSIS_NO, v_error);

            UPDATE BATCH_DETAIL SET RECORD_STATUS = 'INVALID' WHERE DETAIL_ID = v_detail.DETAIL_ID;
            v_invalid_count := v_invalid_count + 1;
        ELSE
            UPDATE BATCH_DETAIL SET RECORD_STATUS = 'VALID' WHERE DETAIL_ID = v_detail.DETAIL_ID;
            v_valid_count := v_valid_count + 1;
        END IF;
    END LOOP;

    UPDATE BATCH_MASTER
    SET VALID_RECORDS = v_valid_count,
        INVALID_RECORDS = v_invalid_count
    WHERE BATCH_ID = p_batch_id;

    CALL sp_advance_batch_status(p_batch_id, 'VALIDATED');
END;
$$;
