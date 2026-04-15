/* eslint-disable react-refresh/only-export-components */
import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react'

type ToastType = 'success' | 'error' | 'info'

interface ToastItem {
  id: number
  message: string
  type: ToastType
}

export interface ToastCtx {
  toast: (message: string, type?: ToastType) => void
}

export const ToastContext = createContext<ToastCtx>({ toast: () => undefined })

export function useToast() {
  return useContext(ToastContext)
}

const ICONS: Record<ToastType, string> = {
  success: '✓',
  error: '✕',
  info: 'ℹ',
}

const COLORS: Record<ToastType, string> = {
  success: '#22c55e',
  error: '#ef4444',
  info: '#6366f1',
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([])
  const counter = useRef(0)

  const toast = useCallback((message: string, type: ToastType = 'info'): void => {
    const id = ++counter.current
    setToasts((prev) => [...prev, { id, message, type }])
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id))
    }, 4000)
  }, [])

  return (
    <ToastContext.Provider value={{ toast }}>
      {children}
      <div
        aria-live="polite"
        style={{
          position: 'fixed',
          bottom: 24,
          right: 24,
          display: 'flex',
          flexDirection: 'column',
          gap: 10,
          zIndex: 1000,
          pointerEvents: 'none',
        }}
      >
        {toasts.map((t) => (
          <ToastBadge key={t.id} item={t} />
        ))}
      </div>
    </ToastContext.Provider>
  )
}

function ToastBadge({ item }: { item: ToastItem }) {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    requestAnimationFrame(() => setVisible(true))
  }, [])

  return (
    <div
      role="status"
      style={{
        background: 'var(--color-surface-raised)',
        border: '1px solid var(--color-border)',
        borderLeft: `3px solid ${COLORS[item.type]}`,
        borderRadius: 'var(--radius-md)',
        padding: '10px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        minWidth: 280,
        maxWidth: 380,
        boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
        pointerEvents: 'auto',
        transition: 'opacity 200ms ease, transform 200ms ease',
        opacity: visible ? 1 : 0,
        transform: visible ? 'translateY(0)' : 'translateY(8px)',
      }}
    >
      <span
        style={{
          color: COLORS[item.type],
          fontWeight: 700,
          fontSize: 13,
          flexShrink: 0,
          width: 18,
          textAlign: 'center',
        }}
      >
        {ICONS[item.type]}
      </span>
      <span style={{ color: 'var(--color-text)', fontSize: 13, lineHeight: 1.4 }}>
        {item.message}
      </span>
    </div>
  )
}
