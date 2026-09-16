-- =============================================================================
-- KIRAATHANE FINANS & KASA SISTEMI - SUPABASE VERITABANI SEMASI (SQL QUERY)
-- Supabase Dashboard -> SQL Editor alanina yapistirip "Run" tusuna basiniz.
-- =============================================================================

-- 1. DUKKAN VE KIRA AYARLARI TABLOSU
CREATE TABLE IF NOT EXISTS public.app_settings (
  id TEXT PRIMARY KEY DEFAULT 'default_settings',
  cafe_name TEXT DEFAULT 'Huzur Kıraathanesi',
  rent_amount NUMERIC DEFAULT 0,
  rent_due_day INTEGER DEFAULT 15,
  landlord_notes TEXT DEFAULT '',
  last_auto_eod_checked TEXT DEFAULT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. GUNLUK MANUEL CIRO DEFTERI (16 - 15 KAHVE GELIR)
CREATE TABLE IF NOT EXISTS public.manual_daily_ciro (
  date TEXT PRIMARY KEY, -- 'YYYY-MM-DD'
  amount NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TOPTANCILAR TABLOSU (KAHVE GIDERLERI ICIN)
CREATE TABLE IF NOT EXISTS public.coffee_suppliers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TOPTANCI ODEMELERI / KAHVE GIDERLERI TABLOSU
CREATE TABLE IF NOT EXISTS public.supplier_payments (
  id TEXT PRIMARY KEY,
  supplier_id TEXT,
  amount NUMERIC NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  method TEXT DEFAULT 'Nakit',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. KISISEL GIDERLER TABLOSU (SAHSI HARCAMALAR)
CREATE TABLE IF NOT EXISTS public.personal_expenses (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. VERILEN BORCLAR TABLOSU (VERESIYE ALACAKLAR)
CREATE TABLE IF NOT EXISTS public.given_debts (
  id TEXT PRIMARY KEY,
  person_name TEXT NOT NULL,
  phone TEXT DEFAULT '',
  amount NUMERIC NOT NULL DEFAULT 0,
  paid_amount NUMERIC NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. KAHVE / TOPTANCI BORCLARI TABLOSU (TOPTANCIYA OLAN BORCLAR)
CREATE TABLE IF NOT EXISTS public.kahve_borclari (
  id TEXT PRIMARY KEY,
  supplier_name TEXT NOT NULL,
  debt_amount NUMERIC NOT NULL DEFAULT 0,
  phone TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. KASA HAREKETLERI (HIZLI ISLEMLER: CIRO / GELIR / GIDER)
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

-- 9. FATURA VE SABIT GIDER ODEMELERI TABLOSU
CREATE TABLE IF NOT EXISTS public.bill_payments (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. GECE 02:00 VARDIYA / GUN SONU KAPANIS RAPORLARI
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

-- 11. TAM SISTEM SENKRONIZASYON TABLOSU (CANLI BULUT YEDEGI)
CREATE TABLE IF NOT EXISTS public.app_state (
  id TEXT PRIMARY KEY DEFAULT 'singleton_state',
  state JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) VE ANON ERISIM IZINLERI
-- Web sitesinden publishable key ile veri ekleme, okuma, guncelleme ve silme
-- yapilabilmesi icin RLS politikalari:
-- =============================================================================

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manual_daily_ciro ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coffee_suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.given_debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kahve_borclari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.end_of_day_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_state ENABLE ROW LEVEL SECURITY;

-- Tum tablolara anon rolu icin tam okuma ve yazma (SELECT, INSERT, UPDATE, DELETE) izni
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
    'kahve_borclari',
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

-- Baslangic Varsayilan Ayar Kaydini Olustur
INSERT INTO public.app_settings (id, cafe_name, rent_amount, rent_due_day)
VALUES ('default_settings', 'Huzur Kıraathanesi', 0, 15)
ON CONFLICT (id) DO NOTHING;
