-- Family Health Tracker Supabase Schema & Security Setup
-- Modern Publishable Key & RLS Compatible

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Families Table
CREATE TABLE IF NOT EXISTS public.families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 3. Family Memberships (Links Supabase Auth Users to a Family with Display Name)
CREATE TABLE IF NOT EXISTS public.family_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

-- 4. Patient Profiles (Dad, Mom, Self, etc.)
CREATE TABLE IF NOT EXISTS public.patient_profiles (
    id TEXT PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    relation TEXT NOT NULL,
    age INTEGER,
    date_of_birth TEXT,
    color_value BIGINT NOT NULL,
    avatar_emoji TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Blood Pressure Readings (with Logged-By attribution)
CREATE TABLE IF NOT EXISTS public.bp_readings (
    id TEXT PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    member_id TEXT NOT NULL REFERENCES public.patient_profiles(id) ON DELETE CASCADE,
    systolic INTEGER NOT NULL,
    diastolic INTEGER NOT NULL,
    pulse INTEGER NOT NULL,
    arm TEXT NOT NULL,
    posture TEXT NOT NULL,
    has_arrhythmia BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    timestamp TIMESTAMPTZ NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    logged_by_name TEXT NOT NULL DEFAULT 'Family Member',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Glucose Readings (with Logged-By attribution)
CREATE TABLE IF NOT EXISTS public.glucose_readings (
    id TEXT PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    member_id TEXT NOT NULL REFERENCES public.patient_profiles(id) ON DELETE CASCADE,
    value_mg_dl REAL NOT NULL,
    meal_context TEXT NOT NULL,
    medication_notes TEXT,
    timestamp TIMESTAMPTZ NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    logged_by_name TEXT NOT NULL DEFAULT 'Family Member',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Indexes
CREATE INDEX IF NOT EXISTS idx_memberships_user ON public.family_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_family ON public.family_memberships(family_id);
CREATE INDEX IF NOT EXISTS idx_patient_profiles_family ON public.patient_profiles(family_id);
CREATE INDEX IF NOT EXISTS idx_bp_readings_family_time ON public.bp_readings(family_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_glucose_readings_family_time ON public.glucose_readings(family_id, timestamp DESC);

-- 8. Row Level Security (RLS)
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bp_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.glucose_readings ENABLE ROW LEVEL SECURITY;

-- Helper function: check if current user is in family
CREATE OR REPLACE FUNCTION public.is_member_of_family(f_id UUID)
RETURNS BOOLEAN SECURITY DEFINER STABLE AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.family_memberships
    WHERE family_id = f_id AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql;

-- Policies for families
DROP POLICY IF EXISTS "Users can view families they belong to" ON public.families;
CREATE POLICY "Users can view families they belong to"
  ON public.families FOR SELECT
  USING (public.is_member_of_family(id));

DROP POLICY IF EXISTS "Authenticated users can create families" ON public.families;
CREATE POLICY "Authenticated users can create families"
  ON public.families FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Policies for family memberships
DROP POLICY IF EXISTS "Users can view family memberships" ON public.family_memberships;
CREATE POLICY "Users can view family memberships"
  ON public.family_memberships FOR SELECT
  USING (user_id = auth.uid() OR public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Users can join family via membership insert" ON public.family_memberships;
CREATE POLICY "Users can join family via membership insert"
  ON public.family_memberships FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their membership" ON public.family_memberships;
CREATE POLICY "Users can update their membership"
  ON public.family_memberships FOR UPDATE
  USING (user_id = auth.uid());

-- Policies for patient profiles
DROP POLICY IF EXISTS "Family members can view profiles" ON public.patient_profiles;
CREATE POLICY "Family members can view profiles"
  ON public.patient_profiles FOR SELECT
  USING (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can insert profiles" ON public.patient_profiles;
CREATE POLICY "Family members can insert profiles"
  ON public.patient_profiles FOR INSERT
  WITH CHECK (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can update profiles" ON public.patient_profiles;
CREATE POLICY "Family members can update profiles"
  ON public.patient_profiles FOR UPDATE
  USING (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can delete profiles" ON public.patient_profiles;
CREATE POLICY "Family members can delete profiles"
  ON public.patient_profiles FOR DELETE
  USING (public.is_member_of_family(family_id));

-- Policies for BP readings
DROP POLICY IF EXISTS "Family members can view BP readings" ON public.bp_readings;
CREATE POLICY "Family members can view BP readings"
  ON public.bp_readings FOR SELECT
  USING (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can insert BP readings" ON public.bp_readings;
CREATE POLICY "Family members can insert BP readings"
  ON public.bp_readings FOR INSERT
  WITH CHECK (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can update BP readings" ON public.bp_readings;
CREATE POLICY "Family members can update BP readings"
  ON public.bp_readings FOR UPDATE
  USING (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can delete BP readings" ON public.bp_readings;
CREATE POLICY "Family members can delete BP readings"
  ON public.bp_readings FOR DELETE
  USING (public.is_member_of_family(family_id));

-- Policies for Glucose readings
DROP POLICY IF EXISTS "Family members can view Glucose readings" ON public.glucose_readings;
CREATE POLICY "Family members can view Glucose readings"
  ON public.glucose_readings FOR SELECT
  USING (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can insert Glucose readings" ON public.glucose_readings;
CREATE POLICY "Family members can insert Glucose readings"
  ON public.glucose_readings FOR INSERT
  WITH CHECK (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can update Glucose readings" ON public.glucose_readings;
CREATE POLICY "Family members can update Glucose readings"
  ON public.glucose_readings FOR UPDATE
  USING (public.is_member_of_family(family_id));

DROP POLICY IF EXISTS "Family members can delete Glucose readings" ON public.glucose_readings;
CREATE POLICY "Family members can delete Glucose readings"
  ON public.glucose_readings FOR DELETE
  USING (public.is_member_of_family(family_id));

-- Helper RPC function to find and join a family by invite code securely
CREATE OR REPLACE FUNCTION public.join_family_by_code(p_invite_code TEXT, p_display_name TEXT)
RETURNS jsonb SECURITY DEFINER AS $$
DECLARE
  v_family RECORD;
  v_user_id UUID;
  v_membership RECORD;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_family FROM public.families WHERE UPPER(invite_code) = UPPER(TRIM(p_invite_code));
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid family invite code';
  END IF;

  INSERT INTO public.family_memberships (family_id, user_id, display_name, role)
  VALUES (v_family.id, v_user_id, p_display_name, 'member')
  ON CONFLICT (family_id, user_id) 
  DO UPDATE SET display_name = EXCLUDED.display_name
  RETURNING * INTO v_membership;

  RETURN jsonb_build_object(
    'family_id', v_family.id,
    'family_name', v_family.name,
    'invite_code', v_family.invite_code,
    'display_name', v_membership.display_name,
    'role', v_membership.role
  );
END;
$$ LANGUAGE plpgsql;

-- 10. Realtime Publication Setup
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'patient_profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.patient_profiles;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'bp_readings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bp_readings;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'glucose_readings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.glucose_readings;
  END IF;
END $$;

