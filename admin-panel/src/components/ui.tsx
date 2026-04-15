import type { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode, SelectHTMLAttributes } from 'react'
import { cn } from '../lib/cn'

export function Surface({
  className,
  children,
}: {
  className?: string
  children: ReactNode
}) {
  return (
    <section
      className={cn(
        'rounded-[var(--radius-lg)] border border-white/8 bg-[var(--color-surface)] shadow-[var(--shadow-card)]',
        className,
      )}
    >
      {children}
    </section>
  )
}

export function SectionHeader({
  title,
  subtitle,
  actions,
}: {
  title: string
  subtitle?: string
  actions?: ReactNode
}) {
  return (
    <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
      <div className="space-y-1">
        <h1 className="text-balance text-2xl font-semibold text-[var(--color-text)]">
          {title}
        </h1>
        {subtitle ? (
          <p className="text-pretty text-sm text-[var(--color-text-muted)]">
            {subtitle}
          </p>
        ) : null}
      </div>
      {actions ? <div className="flex flex-wrap gap-3">{actions}</div> : null}
    </div>
  )
}

export function Button({
  className,
  variant = 'primary',
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
}) {
  return (
    <button
      className={cn(
        'inline-flex min-h-11 items-center justify-center rounded-[var(--radius-sm)] px-4 text-sm font-medium transition-opacity disabled:cursor-not-allowed disabled:opacity-50',
        variant === 'primary' &&
          'bg-[var(--color-primary)] text-white hover:opacity-90',
        variant === 'secondary' &&
          'border border-white/10 bg-[var(--color-surface-raised)] text-[var(--color-text)] hover:bg-white/5',
        variant === 'ghost' &&
          'border border-white/10 bg-transparent text-[var(--color-text-muted)] hover:text-[var(--color-text)]',
        variant === 'danger' &&
          'bg-[var(--color-danger-muted)] text-[var(--color-danger)] hover:opacity-90',
        className,
      )}
      {...props}
    />
  )
}

export function TextInput({
  className,
  ...props
}: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        'min-h-11 rounded-[var(--radius-sm)] border border-white/10 bg-[var(--color-surface-raised)] px-3 text-sm text-[var(--color-text)] outline-none ring-0 placeholder:text-[var(--color-text-muted)] focus:border-[var(--color-primary)]',
        className,
      )}
      {...props}
    />
  )
}

export function SelectInput({
  className,
  children,
  ...props
}: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select
      className={cn(
        'min-h-11 rounded-[var(--radius-sm)] border border-white/10 bg-[var(--color-surface-raised)] px-3 text-sm text-[var(--color-text)] outline-none ring-0 focus:border-[var(--color-primary)]',
        className,
      )}
      {...props}
    >
      {children}
    </select>
  )
}

export function Label({
  children,
  className,
}: {
  children: ReactNode
  className?: string
}) {
  return (
    <label className={cn('text-sm font-medium text-[var(--color-text)]', className)}>
      {children}
    </label>
  )
}

export function Badge({
  className,
  tone = 'default',
  children,
}: {
  className?: string
  tone?: 'default' | 'success' | 'warning' | 'critical' | 'muted'
  children: ReactNode
}) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium tabular-nums',
        tone === 'default' && 'bg-[var(--color-primary-muted)] text-[var(--color-primary-hover)]',
        tone === 'success' && 'bg-[var(--color-success-muted)] text-[var(--color-success)]',
        tone === 'warning' && 'bg-[var(--color-warning-muted)] text-[var(--color-warning)]',
        tone === 'critical' && 'bg-[var(--color-danger-muted)] text-[var(--color-danger)]',
        tone === 'muted' && 'bg-white/5 text-[var(--color-text-muted)]',
        className,
      )}
    >
      {children}
    </span>
  )
}

export function StatCard({
  label,
  value,
  delta,
  tone = 'default',
  helpText,
}: {
  label: string
  value: string
  delta: string
  tone?: 'default' | 'success' | 'warning'
  helpText: string
}) {
  return (
    <Surface className="p-5">
      <div className="space-y-3">
        <div className="text-xs font-medium uppercase text-[var(--color-text-muted)]">
          {label}
        </div>
        <div className="flex items-end justify-between gap-3">
          <div className="text-3xl font-semibold tabular-nums text-[var(--color-text)]">
            {value}
          </div>
          <Badge tone={tone === 'success' ? 'success' : tone === 'warning' ? 'warning' : 'default'}>
            {delta}
          </Badge>
        </div>
        <p className="text-pretty text-sm text-[var(--color-text-muted)]">{helpText}</p>
      </div>
    </Surface>
  )
}

export function EmptyState({
  title,
  body,
  action,
}: {
  title: string
  body: string
  action?: ReactNode
}) {
  return (
    <Surface className="p-8 text-center">
      <div className="mx-auto max-w-xl space-y-3">
        <h2 className="text-balance text-lg font-semibold text-[var(--color-text)]">
          {title}
        </h2>
        <p className="text-pretty text-sm text-[var(--color-text-muted)]">{body}</p>
        {action ? <div className="flex justify-center pt-2">{action}</div> : null}
      </div>
    </Surface>
  )
}

export function LoadingState({ label = 'Loading data…' }: { label?: string }) {
  return (
    <div className="flex min-h-44 items-center justify-center text-sm text-[var(--color-text-muted)]">
      {label}
    </div>
  )
}

export function TableShell({
  className,
  children,
}: {
  className?: string
  children: ReactNode
}) {
  return <Surface className={cn('overflow-hidden', className)}>{children}</Surface>
}
