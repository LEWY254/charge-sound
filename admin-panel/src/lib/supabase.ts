import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const key =
  (import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined) ??
  (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)

export const hasSupabaseConfig = Boolean(url && key)
export const isDemoMode =
  import.meta.env.VITE_ADMIN_DEMO_MODE === 'true' || !hasSupabaseConfig
export const adminCommandFunction =
  (import.meta.env.VITE_ADMIN_EDGE_COMMAND_FN as string | undefined) ?? 'admin-command'

export const supabase =
  url && key
    ? createClient(url, key, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
        },
      })
    : null
