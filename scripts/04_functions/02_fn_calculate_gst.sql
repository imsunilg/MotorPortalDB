SET search_path TO "SGInsurance";

CREATE OR REPLACE FUNCTION fn_calculate_gst(
    p_net_premium NUMERIC,
    p_gst_rate    NUMERIC
) RETURNS TABLE (gst_amount NUMERIC, final_premium NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    gst_amount := ROUND(COALESCE(p_net_premium, 0) * COALESCE(p_gst_rate, 0) / 100.0, 2);
    final_premium := ROUND(COALESCE(p_net_premium, 0) + gst_amount, 2);
    RETURN NEXT;
END;
$$;
