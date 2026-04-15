import { useState, type FormEvent } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { AdminShell } from './components/admin-shell'
import { Badge, Button, LoadingState, Surface, TextInput } from './components/ui'
import { ToastProvider, useToast } from './components/Toast'
import { AdminAuthProvider, useAdminAuth } from './providers/admin-auth-provider'
import { DashboardPage } from './pages/dashboard-page'
import { UsersPage } from './pages/users-page'
import { BillingPage } from './pages/billing-page'
import { CatalogPage } from './pages/catalog-page'
import { IngestionPage } from './pages/ingestion-page'
import { SettingsPage } from './pages/settings-page'
import './App.css'

function SignInScreen() {
  const { signIn, error, demoMode } = useAdminAuth()
  const { toast } = useToast()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setSubmitting(true)
    try {
      await signIn(email, password)
      toast('Signed in successfully.', 'success')
    } catch (err) {
      toast((err as Error).message, 'error')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-dvh items-center justify-center bg-[var(--color-bg)] px-5 py-10">
      <Surface className="w-full max-w-xl p-8">
        <div className="mb-6 space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="text-balance text-2xl font-semibold text-[var(--color-text)]">
              ChargeSound admin
            </h1>
            {demoMode ? <Badge tone="warning">Demo mode</Badge> : null}
          </div>
          <p className="text-pretty text-sm text-[var(--color-text-muted)]">
            Staff access is gated by Supabase Auth plus `staff_roles`. Billing and catalog mutations are expected to run through the server-side admin command function.
          </p>
        </div>

        {demoMode ? (
          <div className="rounded-[var(--radius-md)] border border-[var(--color-warning)]/50 bg-[var(--color-warning-muted)] p-4 text-sm text-[var(--color-text)]">
            Demo mode is enabled because the admin panel is running without Supabase browser credentials. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` to use live auth.
          </div>
        ) : (
          <form className="space-y-4" onSubmit={handleSubmit}>
            <div className="space-y-2">
              <label className="text-sm font-medium text-[var(--color-text)]">Email</label>
              <TextInput
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="admin@chargesound.app"
                autoComplete="email"
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium text-[var(--color-text)]">Password</label>
              <TextInput
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Enter your password"
                autoComplete="current-password"
              />
            </div>
            <Button className="w-full" type="submit" disabled={submitting || !email || !password}>
              {submitting ? 'Signing in…' : 'Sign in'}
            </Button>
          </form>
        )}

        {error ? (
          <div className="mt-4 rounded-[var(--radius-md)] border border-[var(--color-danger)]/50 bg-[var(--color-danger-muted)] p-4 text-sm text-[var(--color-text)]">
            {error}
          </div>
        ) : null}
      </Surface>
    </div>
  )
}

function AppRoutes() {
  const { authenticated, booting, demoMode } = useAdminAuth()

  if (booting) {
    return <LoadingState label="Starting admin panel…" />
  }

  if (!authenticated && !demoMode) {
    return <SignInScreen />
  }

  return (
    <Routes>
      <Route element={<AdminShell />}>
        <Route index element={<DashboardPage />} />
        <Route path="/users" element={<UsersPage />} />
        <Route path="/billing" element={<BillingPage />} />
        <Route path="/catalog" element={<CatalogPage />} />
        <Route path="/ingestion" element={<IngestionPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  )
}

export default function App() {
  return (
    <ToastProvider>
      <AdminAuthProvider>
        <AppRoutes />
      </AdminAuthProvider>
    </ToastProvider>
  )
}
