-- =============================================================================
-- KIRAATHANE FINANS & KASA SISTEMI - SUPABASE VERITABANI SEMASI (TAM QUERY)
-- Supabase Dashboard -> SQL Editor alanına yapıştırıp "Run" tuşuna basınız.
-- =============================================================================

-- 1. DÜKKAN VE KİRA AYARLARI TABLOSU
CREATE TABLE IF NOT EXISTS public.app_settings (
  id TEXT PRIMARY KEY DEFAULT 'default_settings',
  cafe_name TEXT DEFAULT 'Huzur Kıraathanesi',
  rent_amount NUMERIC DEFAULT 0,
  rent_due_day INTEGER DEFAULT 15,
  landlord_notes TEXT DEFAULT '',
  last_auto_eod_checked TEXT DEFAULT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. GÜNLÜK MANUEL CİRO DEFTERİ (16 - 15 KAHVE GELİR)
CREATE TABLE IF NOT EXISTS public.manual_daily_ciro (
  date TEXT PRIMARY KEY, -- 'YYYY-MM-DD'
  amount NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TOPTANCILAR TABLOSU (KAHVE GİDERLERİ İÇİN)
CREATE TABLE IF NOT EXISTS public.coffee_suppliers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TOPTANCI ÖDEMELERİ / KAHVE GİDERLERİ TABLOSU (AYLIK ANALİZ MOTORU)
CREATE TABLE IF NOT EXISTS public.supplier_payments (
  id TEXT PRIMARY KEY,
  supplier_id TEXT,
  amount NUMERIC NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  method TEXT DEFAULT 'Nakit',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. KİŞİSEL GİDERLER TABLOSU (ŞAHSİ HARCAMALAR)
CREATE TABLE IF NOT EXISTS public.personal_expenses (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. VERİLEN BORÇLAR TABLOSU (VERESİYE ALACAKLAR & ÇOKLU GÖRSEL)
CREATE TABLE IF NOT EXISTS public.given_debts (
  id TEXT PRIMARY KEY,
  person_name TEXT NOT NULL,
  phone TEXT DEFAULT '',
  amount NUMERIC NOT NULL DEFAULT 0,
  paid_amount NUMERIC NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  notes TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  images JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. VERİLEN BORÇ İŞLEMLERİ / TAHSİLAT GEÇMİŞİ (KALICI İŞLEM LOGLARI)
CREATE TABLE IF NOT EXISTS public.given_debt_transactions (
  id TEXT PRIMARY KEY,
  debt_id TEXT,
  person_name TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  type TEXT DEFAULT 'tahsilat', -- 'tahsilat', 'borc_ekleme'
  remaining_amount NUMERIC DEFAULT 0,
  date TEXT NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. KAHVE / TOPTANCI BORÇLARI TABLOSU (TOPTANCIYA OLAN BORÇLAR & AY BAŞI DEVİR)
CREATE TABLE IF NOT EXISTS public.kahve_borclari (
  id TEXT PRIMARY KEY,
  supplier_name TEXT NOT NULL,
  debt_amount NUMERIC NOT NULL DEFAULT 0,
  initial_debt NUMERIC DEFAULT 0,
  phone TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. KAHVE BORCU AYLIK VERİ VE RAPOR KAYITLARI
CREATE TABLE IF NOT EXISTS public.kahve_borcu_monthly (
  id TEXT PRIMARY KEY,
  supplier_name TEXT NOT NULL,
  period_key TEXT NOT NULL,
  initial_debt NUMERIC DEFAULT 0,
  paid_amount NUMERIC DEFAULT 0,
  borrowed_amount NUMERIC DEFAULT 0,
  current_debt NUMERIC DEFAULT 0,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. KASA HAREKETLERİ (HIZLI İŞLEMLER: CİRO / GELİR / GİDER)
CREATE TABLE IF NOT EXISTS public.transactions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL, -- 'ciro', 'gelir', 'gider'
  amount NUMERIC NOT NULL DEFAULT 0,
  category TEXT NOT NULL,
  payment_method TEXT DEFAULT 'Nakit',
  description TEXT DEFAULT '',
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  shift_date TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. FATURA VE SABİT GİDER ÖDEMELERİ TABLOSU
CREATE TABLE IF NOT EXISTS public.bill_payments (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. GECE 02:00 VARDİYA / GÜN SONU KAPANIŞ RAPORLARI
CREATE TABLE IF NOT EXISTS public.end_of_day_reports (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  shift_date TEXT,
  total_ciro NUMERIC DEFAULT 0,
  total_gelir NUMERIC DEFAULT 0,
  total_gider NUMERIC DEFAULT 0,
  net_kasa NUMERIC DEFAULT 0,
  closed_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT DEFAULT ''
);

-- 13. TAM SİSTEM SENKRONİZASYON TABLOSU (CANLI BULUT YEDEĞİ & SNAPSHOT)
CREATE TABLE IF NOT EXISTS public.app_state (
  id TEXT PRIMARY KEY DEFAULT 'singleton_state',
  state JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- MIGRATION GÜVENCESİ (VAR OLAN TABLOLARA EKSİK SÜTUNLARI EKLE)
-- =============================================================================
ALTER TABLE public.given_debts ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
ALTER TABLE public.given_debts ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.kahve_borclari ADD COLUMN IF NOT EXISTS initial_debt NUMERIC DEFAULT 0;
ALTER TABLE public.kahve_borclari ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
ALTER TABLE public.supplier_payments ADD COLUMN IF NOT EXISTS method TEXT DEFAULT 'Nakit';
ALTER TABLE public.supplier_payments ADD COLUMN IF NOT EXISTS notes TEXT DEFAULT '';

-- Varsayılan Ayar Kaydını Oluştur
INSERT INTO public.app_settings (id, cafe_name, rent_amount, rent_due_day)
VALUES ('default_settings', 'Huzur Kıraathanesi', 0, 15)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- PERFORMANS İNDEKSLERİ (HIZLI RAPORLAMA & SÜTUN GRAFİK SORGU HIZI)
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_supplier_payments_date ON public.supplier_payments(date);
CREATE INDEX IF NOT EXISTS idx_supplier_payments_supplier_id ON public.supplier_payments(supplier_id);
CREATE INDEX IF NOT EXISTS idx_personal_expenses_date ON public.personal_expenses(date);
CREATE INDEX IF NOT EXISTS idx_given_debt_tx_debt_id ON public.given_debt_transactions(debt_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(date);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) VE ANON ERİŞİM İZİNLERİ
-- Web uygulamasından publishable anon key ile tam okuma/yazma erişimi:
-- =============================================================================
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manual_daily_ciro ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coffee_suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.given_debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.given_debt_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kahve_borclari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kahve_borcu_monthly ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.end_of_day_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_state ENABLE ROW LEVEL SECURITY;

DO $$ 
DECLARE
  tbl TEXT;
  tables TEXT[] := ARRAY[
    'app_settings',
    'manual_daily_ciro',
    'coffee_suppliers',
    'supplier_payments',
    'personal_expenses',
    'given_debts',
    'given_debt_transactions',
    'kahve_borclari',
    'kahve_borcu_monthly',
    'transactions',
    'bill_payments',
    'end_of_day_reports',
    'app_state'
  ];
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS "Anon Full Access on %I" ON public.%I;', tbl, tbl);
    EXECUTE format('CREATE POLICY "Anon Full Access on %I" ON public.%I FOR ALL TO anon USING (true) WITH CHECK (true);', tbl, tbl);
  END LOOP;
END $$;

-- =============================================================================
-- SUPABASE STORAGE: 'debt_images' BUCKET VE POLİTİKALARI
-- =============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('debt_images', 'debt_images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Anon Debt Images Select" ON storage.objects;
CREATE POLICY "Anon Debt Images Select" ON storage.objects
FOR SELECT TO anon
USING (bucket_id = 'debt_images');

DROP POLICY IF EXISTS "Anon Debt Images Insert" ON storage.objects;
CREATE POLICY "Anon Debt Images Insert" ON storage.objects
FOR INSERT TO anon
WITH CHECK (bucket_id = 'debt_images');

DROP POLICY IF EXISTS "Anon Debt Images Update" ON storage.objects;
CREATE POLICY "Anon Debt Images Update" ON storage.objects
FOR UPDATE TO anon
USING (bucket_id = 'debt_images')
WITH CHECK (bucket_id = 'debt_images');

DROP POLICY IF EXISTS "Anon Debt Images Delete" ON storage.objects;
CREATE POLICY "Anon Debt Images Delete" ON storage.objects
FOR DELETE TO anon
USING (bucket_id = 'debt_images');
