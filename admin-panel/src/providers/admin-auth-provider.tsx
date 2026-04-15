/* eslint-disable react-refresh/only-export-components */
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import type { Session } from '@supabase/supabase-js'
import { isDemoMode, supabase } from '../lib/supabase'
import type { AdminRole } from '../types/admin'

interface AdminIdentity {
  email: string
  fullName: string
  role: AdminRole
}

interface AuthContextValue {
  booting: boolean
  authenticated: boolean
  identity: AdminIdentity | null
  error: string | null
  demoMode: boolean
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | null>(null)

async function resolveAdminIdentity(session: Session | null): Promise<AdminIdentity | null> {
  if (!session?.user?.email) {
    return null
  }

  if (!supabase) {
    return null
  }

  const { data, error } = await supabase
    .from('staff_roles')
    .select('email, full_name, role, active')
    .eq('email', session.user.email)
    .eq('active', true)
    .maybeSingle()

  if (error) {
    throw error
  }

  if (!data) {
    return null
  }

  return {
    email: data.email,
    fullName: data.full_name,
    role: data.role,
  }
}

export function AdminAuthProvider({ children }: { children: ReactNode }) {
  const [booting, setBooting] = useState(true)
  const [identity, setIdentity] = useState<AdminIdentity | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (isDemoMode) {
      setIdentity({
        email: 'admin@chargesound.app',
        fullName: 'ChargeSound Admin',
        role: 'owner',
      })
      setBooting(false)
      return
    }

    if (!supabase) {
      setError('Supabase is not configured for admin sign-in.')
      setBooting(false)
      return
    }

    const client = supabase

    let cancelled = false

    async function bootstrap() {
      try {
        const {
          data: { session },
        } = await client.auth.getSession()
        const resolved = await resolveAdminIdentity(session)
        if (!cancelled) {
          setIdentity(resolved)
          setError(
            session && !resolved
              ? 'Your account is signed in but does not have a staff role.'
              : null,
          )
        }
      } catch (err) {
        if (!cancelled) {
          setError((err as Error).message)
        }
      } finally {
        if (!cancelled) {
          setBooting(false)
        }
      }
    }

    void bootstrap()

    const { data: listener } = client.auth.onAuthStateChange((_event, session) => {
      void resolveAdminIdentity(session)
        .then((resolved) => {
          if (!cancelled) {
            setIdentity(resolved)
            setError(
              session && !resolved
                ? 'Your account is signed in but does not have a staff role.'
                : null,
            )
          }
        })
        .catch((err: Error) => {
          if (!cancelled) {
            setError(err.message)
          }
        })
    })

    return () => {
      cancelled = true
      listener.subscription.unsubscribe()
    }
  }, [])

  const value = useMemo<AuthContextValue>(
    () => ({
      booting,
      authenticated: Boolean(identity),
      identity,
      error,
      demoMode: isDemoMode,
      async signIn(email, password) {
        if (!supabase) {
          throw new Error('Supabase is not configured.')
        }

        const { error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        })

        if (signInError) {
          throw signInError
        }
      },
      async signOut() {
        if (isDemoMode || !supabase) {
          return
        }

        const { error: signOutError } = await supabase.auth.signOut()
        if (signOutError) {
          throw signOutError
        }
      },
    }),
    [booting, error, identity],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAdminAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAdminAuth must be used within AdminAuthProvider.')
  }

  return context
}
