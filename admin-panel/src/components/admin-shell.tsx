import { NavLink, Outlet } from 'react-router-dom'
import { useAdminAuth } from '../providers/admin-auth-provider'
import { Button, Badge } from './ui'
import { cn } from '../lib/cn'

const navItems = [
  { to: '/', label: 'Dashboard' },
  { to: '/users', label: 'Users' },
  { to: '/billing', label: 'Billing' },
  { to: '/catalog', label: 'Catalog' },
  { to: '/ingestion', label: 'Ingestion' },
  { to: '/settings', label: 'Settings' },
]

export function AdminShell() {
  const { identity, signOut, demoMode } = useAdminAuth()

  return (
    <div className="flex min-h-dvh bg-[var(--color-bg)] text-[var(--color-text)]">
      <aside className="hidden w-[260px] shrink-0 border-r border-white/8 bg-[var(--color-surface)] lg:flex lg:flex-col">
        <div className="border-b border-white/8 px-6 py-6">
          <div className="flex items-center gap-3">
            <div className="flex size-10 items-center justify-center rounded-xl bg-[var(--color-primary)] text-sm font-semibold text-white">
              CS
            </div>
            <div>
              <div className="text-sm font-semibold text-[var(--color-text)]">
                ChargeSound
              </div>
              <div className="text-sm text-[var(--color-text-muted)]">Admin control plane</div>
            </div>
          </div>
        </div>

        <nav className="flex-1 space-y-1 px-4 py-5">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                cn(
                  'flex min-h-11 items-center rounded-[var(--radius-sm)] px-4 text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-[var(--color-primary-muted)] text-[var(--color-primary-hover)]'
                    : 'text-[var(--color-text-muted)] hover:bg-white/5 hover:text-[var(--color-text)]',
                )
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="space-y-4 border-t border-white/8 px-4 py-5">
          <div className="space-y-2 rounded-[var(--radius-md)] border border-white/8 bg-[var(--color-surface-raised)] p-4">
            <div className="flex flex-wrap items-center gap-2">
              <div className="text-sm font-medium">{identity?.fullName ?? 'Staff user'}</div>
              <Badge tone="default">{identity?.role ?? 'viewer'}</Badge>
              {demoMode ? <Badge tone="warning">Demo mode</Badge> : null}
            </div>
            <div className="text-sm text-[var(--color-text-muted)]">{identity?.email}</div>
          </div>
          <Button variant="ghost" onClick={() => void signOut()} className="w-full">
            Sign out
          </Button>
        </div>
      </aside>

      <div className="min-w-0 flex-1">
        <header className="sticky top-0 z-20 border-b border-white/8 bg-[rgba(15,17,23,0.92)] px-5 py-4 backdrop-blur-sm lg:px-8">
          <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-sm font-medium text-[var(--color-text)]">
                Admin panel
              </p>
              <p className="text-sm text-[var(--color-text-muted)]">
                Catalog operations, billing visibility, and entitlement support.
              </p>
            </div>
            <div className="flex flex-wrap gap-2 lg:hidden">
              {navItems.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === '/'}
                  className={({ isActive }) =>
                    cn(
                      'rounded-full border px-3 py-1.5 text-sm',
                      isActive
                        ? 'border-[var(--color-primary)] bg-[var(--color-primary-muted)] text-[var(--color-primary-hover)]'
                        : 'border-white/10 text-[var(--color-text-muted)]',
                    )
                  }
                >
                  {item.label}
                </NavLink>
              ))}
            </div>
          </div>
        </header>

        <main className="px-5 py-6 lg:px-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
