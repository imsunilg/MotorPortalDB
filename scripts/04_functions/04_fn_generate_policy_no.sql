SET search_path TO "motorportal";

CREATE SEQUENCE IF NOT EXISTS seq_policy_no START WITH 443668109 INCREMENT BY 1;

CREATE OR REPLACE FUNCTION fn_generate_policy_no(
    p_office_code VARCHAR DEFAULT '3010',
    p_class_code  VARCHAR DEFAULT 'A'
) RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_seq BIGINT;
BEGIN
    v_seq := nextval('seq_policy_no');
    RETURN p_office_code || '/' || p_class_code || '/' || v_seq::VARCHAR || '/00/000';
END;
$$;
