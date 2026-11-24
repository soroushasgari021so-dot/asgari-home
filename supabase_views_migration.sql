-- ASGARI HOME: شمارنده بازدید آگهی‌ها
-- این اسکریپت را یک‌بار در Supabase Dashboard > SQL Editor اجرا کنید.

ALTER TABLE public.public_listings
ADD COLUMN IF NOT EXISTS view_count BIGINT NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION public.increment_listing_view(p_listing_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.public_listings
  SET view_count = COALESCE(view_count, 0) + 1
  WHERE id::text = p_listing_id
    AND is_published = TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.increment_listing_view(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_listing_view(TEXT) TO anon, authenticated;
