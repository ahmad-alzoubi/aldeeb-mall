-- Migration: Add Product Bundle (Frequently Bought Together) Controls
-- Allows admins to enable/disable bundles per product, specify custom bundle discount percentages,
-- define custom bundle headlines, and manually select complementary bundle product IDs.

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS bundle_enabled BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS bundle_discount_percent INTEGER NOT NULL DEFAULT 15,
ADD COLUMN IF NOT EXISTS bundle_title TEXT,
ADD COLUMN IF NOT EXISTS bundle_product_ids TEXT[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.products.bundle_enabled IS 'Toggle whether the Frequently Bought Together bundle is displayed on this product page';
COMMENT ON COLUMN public.products.bundle_discount_percent IS 'Discount percentage applied when buying the bundle together';
COMMENT ON COLUMN public.products.bundle_title IS 'Custom display title for the bundle offer';
COMMENT ON COLUMN public.products.bundle_product_ids IS 'Explicit product IDs to bundle with this product (empty = auto-select from category)';
