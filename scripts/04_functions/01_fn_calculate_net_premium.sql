SET search_path TO "SGInsurance";

CREATE OR REPLACE FUNCTION fn_calculate_net_premium(
    p_base_premium  NUMERIC,
    p_addon_premium NUMERIC,
    p_discount      NUMERIC
) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN ROUND(COALESCE(p_base_premium, 0) + COALESCE(p_addon_premium, 0) - COALESCE(p_discount, 0), 2);
END;
$$;
