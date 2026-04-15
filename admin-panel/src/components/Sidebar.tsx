interface SidebarProps {
  active: string
  onChange: (page: string) => void
}

const NAV = [
  { id: 'packs', label: 'Preset Packs', icon: PacksIcon },
  { id: 'sounds', label: 'Sounds', icon: SoundsIcon },
  { id: 'users', label: 'Users', icon: UsersIcon },
]

export function Sidebar({ active, onChange }: SidebarProps) {
  return (
    <aside
      style={{
        width: 'var(--sidebar-w)',
        minHeight: '100vh',
        background: 'var(--color-surface)',
        borderRight: '1px solid var(--color-border)',
        display: 'flex',
        flexDirection: 'column',
        flexShrink: 0,
        position: 'sticky',
        top: 0,
        height: '100vh',
        overflow: 'auto',
      }}
    >
      {/* Logo */}
      <div
        style={{
          padding: '22px 20px 18px',
          borderBottom: '1px solid var(--color-border)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div
            style={{
              width: 32,
              height: 32,
              borderRadius: 8,
              background: 'var(--color-primary)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <SoundWaveIcon />
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--color-text)', letterSpacing: '-0.01em' }}>
              ChargeSound
            </div>
            <div style={{ fontSize: 11, color: 'var(--color-text-muted)', marginTop: 1 }}>Admin Panel</div>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav style={{ flex: 1, padding: '12px 10px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--color-text-muted)', letterSpacing: '0.06em', textTransform: 'uppercase', padding: '4px 10px 8px' }}>
          Content
        </div>
        {NAV.map(({ id, label, icon: Icon }) => {
          const isActive = active === id
          return (
            <button
              key={id}
              onClick={() => onChange(id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                width: '100%',
                padding: '9px 12px',
                borderRadius: 'var(--radius-sm)',
                border: 'none',
                cursor: 'pointer',
                marginBottom: 2,
                background: isActive ? 'var(--color-primary-muted)' : 'transparent',
                color: isActive ? 'var(--color-primary-hover)' : 'var(--color-text-muted)',
                fontWeight: isActive ? 600 : 400,
                fontSize: 13.5,
                textAlign: 'left',
                transition: 'background 150ms, color 150ms',
              }}
              onMouseEnter={(e) => {
                if (!isActive) {
                  e.currentTarget.style.background = 'rgba(255,255,255,0.04)'
                  e.currentTarget.style.color = 'var(--color-text)'
                }
              }}
              onMouseLeave={(e) => {
                if (!isActive) {
                  e.currentTarget.style.background = 'transparent'
                  e.currentTarget.style.color = 'var(--color-text-muted)'
                }
              }}
            >
              <Icon active={isActive} />
              {label}
            </button>
          )
        })}
      </nav>

      {/* Footer */}
      <div
        style={{
          padding: '14px 20px',
          borderTop: '1px solid var(--color-border)',
          fontSize: 11,
          color: 'var(--color-text-muted)',
        }}
      >
        v1.0.0 · sound-trigger-prod
      </div>
    </aside>
  )
}

function SoundWaveIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
      <rect x="1" y="5" width="2" height="6" rx="1" fill="white" />
      <rect x="4.5" y="3" width="2" height="10" rx="1" fill="white" />
      <rect x="8" y="1" width="2" height="14" rx="1" fill="white" />
      <rect x="11.5" y="3" width="2" height="10" rx="1" fill="white" />
    </svg>
  )
}

function PacksIcon({ active }: { active?: boolean }) {
  return (
    <svg width="15" height="15" viewBox="0 0 15 15" fill="none" style={{ flexShrink: 0 }}>
      <rect x="1" y="1" width="6" height="6" rx="1.5" stroke={active ? '#818cf8' : '#64748b'} strokeWidth="1.3" />
      <rect x="8" y="1" width="6" height="6" rx="1.5" stroke={active ? '#818cf8' : '#64748b'} strokeWidth="1.3" />
      <rect x="1" y="8" width="6" height="6" rx="1.5" stroke={active ? '#818cf8' : '#64748b'} strokeWidth="1.3" />
      <rect x="8" y="8" width="6" height="6" rx="1.5" stroke={active ? '#818cf8' : '#64748b'} strokeWidth="1.3" />
    </svg>
  )
}

function SoundsIcon({ active }: { active?: boolean }) {
  const c = active ? '#818cf8' : '#64748b'
  return (
    <svg width="15" height="15" viewBox="0 0 15 15" fill="none" style={{ flexShrink: 0 }}>
      <circle cx="5.5" cy="10.5" r="2.5" stroke={c} strokeWidth="1.3" />
      <path d="M8 10V3l5-1v1" stroke={c} strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function UsersIcon({ active }: { active?: boolean }) {
  const c = active ? '#818cf8' : '#64748b'
  return (
    <svg width="15" height="15" viewBox="0 0 15 15" fill="none" style={{ flexShrink: 0 }}>
      <circle cx="5.5" cy="5" r="2.5" stroke={c} strokeWidth="1.3" />
      <path d="M1 13c0-2.21 2.015-4 4.5-4S10 10.79 10 13" stroke={c} strokeWidth="1.3" strokeLinecap="round" />
      <circle cx="11.5" cy="5" r="1.8" stroke={c} strokeWidth="1.3" />
      <path d="M13 13c0-1.657-1.343-3-3-3" stroke={c} strokeWidth="1.3" strokeLinecap="round" />
    </svg>
  )
}
