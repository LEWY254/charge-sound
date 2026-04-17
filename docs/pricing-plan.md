# Pricing Plan

## Positioning

Charge Sound is a consumer Android utility app. Pricing should optimize for conversion and retention, not enterprise ARPU.

## Recommended Tiers

### Free
- Price: `$0`
- Goal: product-led acquisition and habit formation
- Includes:
  - Basic event-to-sound assignment
  - Local library import and recording
  - Limited active event configs (example: up to 8)
  - Ads or occasional upgrade prompts (optional)

### Pro
- Price: `$5.99/month` or `$39.99/year`
- Goal: primary revenue tier for power users
- Includes everything in Free, plus:
  - Unlimited event configs
  - Cloud sync across devices/accounts
  - Advanced trim and sound processing controls
  - Priority access to curated sound packs
  - Backup/restore reliability features

### Creator Plus
- Price: `$11.99/month` or `$79.99/year`
- Goal: high-intent users without overpricing
- Includes everything in Pro, plus:
  - Early access / beta automation features
  - Expanded cloud storage and larger sound limits
  - Advanced organization (folders/tags presets)
  - Faster support SLA (for individual users)

## Not Recommended Right Now

### `$99/month` Plan
Do not launch this for the current app state.

To justify `$99/month`, ship a true B2B/team product first:
- Team workspaces with seats and role-based access
- Shared sound libraries and admin policies
- Organization billing controls and audit logs
- SSO and enterprise security/compliance features
- Dedicated support and SLA commitments

Until those exist, `$99` will suppress conversion and increase churn risk.

## Feature Gating Proposal

Use entitlement flags to gate premium features in app:
- `is_pro`: unlock Pro tier features
- `is_creator_plus`: unlock Creator Plus features

Initial gated features:
1. Unlimited event configs (Free cap)
2. Cloud sync
3. Advanced editor controls
4. Premium pack access

## Launch Plan (30 Days)

### Week 1
- Finalize tier definitions and paywall copy
- Implement in-app entitlement checks
- Instrument funnel events (view paywall, start trial, subscribe, cancel)

### Week 2
- Release annual discount and trial experiments
- Add upgrade prompts at natural usage limits (not interruptive)

### Week 3
- Run A/B pricing tests:
  - Pro monthly: `$4.99` vs `$5.99`
  - Pro annual: `$34.99` vs `$39.99`
- Measure conversion and day-30 retention impact

### Week 4
- Lock winning price points
- Improve onboarding-to-upgrade flow using observed drop-off points

## Success Metrics

- Free -> paid conversion: target `3% to 7%`
- Trial -> paid conversion: target `25%+`
- Monthly churn (paid): target `< 6%`
- Annual plan mix: target `35%+` of new paid users

## Default Recommendation

If you need one decision now:
- Ship with **Free + Pro (`$5.99/mo` or `$39.99/yr`)**
- Keep **Creator Plus** hidden until premium feature gating is fully live
- Revisit higher tiers only after team/enterprise functionality exists
