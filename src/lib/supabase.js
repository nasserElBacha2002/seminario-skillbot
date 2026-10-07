import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !anonKey) {
  throw new Error('Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY. Copiá .env.example a .env.local y completalos.')
}

// El login es una demo sin Supabase Auth, asi que no hay sesion que persistir.
export const supabase = createClient(url, anonKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

// Tiene que coincidir con public.demo_profile_id() en la migracion.
export const DEMO_PROFILE_ID = '11111111-1111-4111-8111-111111111111'
