SET search_path TO "SGInsurance";

CREATE SEQUENCE IF NOT EXISTS seq_proposal_no START WITH 1202304500 INCREMENT BY 1;

CREATE OR REPLACE FUNCTION fn_generate_proposal_no()
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_base   BIGINT;
    v_suffix VARCHAR(2) := '01';
BEGIN
    v_base := nextval('seq_proposal_no');
    RETURN v_base::VARCHAR || '/' || v_suffix;
END;
$$;
