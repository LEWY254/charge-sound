import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type ActionName =
  | 'create_pack'
  | 'create_sound'
  | 'set_pack_active'
  | 'set_user_override'
  | 'queue_manual_import'
  | 'publish_import'

type CommandPayload = Record<string, unknown>

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required.')
}

const adminClient = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
})

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}

function getBearerToken(req: Request) {
  const header = req.headers.get('Authorization')
  if (!header) {
    throw new Error('Missing Authorization header.')
  }

  const [scheme, token] = header.split(' ')
  if (scheme !== 'Bearer' || !token) {
    throw new Error('Authorization header must be Bearer <token>.')
  }

  return token
}

async function requireStaffUser(req: Request) {
  const token = getBearerToken(req)
  const {
    data: { user },
    error,
  } = await adminClient.auth.getUser(token)

  if (error || !user) {
    throw new Error('Unable to resolve authenticated user.')
  }

  const { data: role, error: roleError } = await adminClient
    .from('staff_roles')
    .select('user_id, role, active')
    .eq('user_id', user.id)
    .eq('active', true)
    .maybeSingle()

  if (roleError) {
    throw roleError
  }

  if (!role) {
    throw new Error('Authenticated user does not have admin access.')
  }

  return {
    userId: user.id,
    role: role.role as string,
  }
}

function asString(payload: CommandPayload, key: string) {
  const value = payload[key]
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`Expected "${key}" to be a non-empty string.`)
  }

  return value.trim()
}

function asOptionalString(payload: CommandPayload, key: string) {
  const value = payload[key]
  if (value == null) return null
  if (typeof value !== 'string') {
    throw new Error(`Expected "${key}" to be a string when provided.`)
  }
  const trimmed = value.trim()
  return trimmed.length > 0 ? trimmed : null
}

function asBoolean(payload: CommandPayload, key: string) {
  const value = payload[key]
  if (typeof value !== 'boolean') {
    throw new Error(`Expected "${key}" to be a boolean.`)
  }

  return value
}

function asNumber(payload: CommandPayload, key: string) {
  const value = payload[key]
  if (typeof value !== 'number' || Number.isNaN(value)) {
    throw new Error(`Expected "${key}" to be a number.`)
  }
  return value
}

function asStringArray(payload: CommandPayload, key: string) {
  const value = payload[key]
  if (!Array.isArray(value)) {
    throw new Error(`Expected "${key}" to be an array of strings.`)
  }
  const out = value
    .map((item) => (typeof item === 'string' ? item.trim() : ''))
    .filter((item) => item.length > 0)
  return out
}

async function writeAuditLog(actorUserId: string, action: string, entityType: string, entityId: string, payload: CommandPayload) {
  await adminClient.from('audit_logs').insert({
    actor_user_id: actorUserId,
    action,
    entity_type: entityType,
    entity_id: entityId,
    payload,
  })
}

async function handleCreatePack(actorUserId: string, payload: CommandPayload) {
  const name = asString(payload, 'name')
  const slug = asString(payload, 'slug')

  const { data, error } = await adminClient
    .from('preset_packs')
    .insert({
      name,
      slug,
      is_active: false,
      visibility: 'staged',
    })
    .select('id')
    .single()

  if (error) throw error

  await writeAuditLog(actorUserId, 'create_pack', 'preset_pack', data.id, payload)

  return { ok: true, message: `Created pack "${name}".` }
}

async function handleCreateSound(actorUserId: string, payload: CommandPayload) {
  const name = asString(payload, 'name')
  const slug = asString(payload, 'slug')
  const packId = asString(payload, 'packId')
  const storagePath = asString(payload, 'storagePath')
  const previewPath = asOptionalString(payload, 'previewPath')
  const category = asString(payload, 'category')
  const tags = asStringArray(payload, 'tags')
  const licenseLabel = asString(payload, 'licenseLabel')
  const licenseUrl = asString(payload, 'licenseUrl')
  const creatorName = asString(payload, 'creatorName')
  const sourceAttribution = asString(payload, 'sourceAttribution')
  const sourceProvider = asString(payload, 'sourceProvider')
  const isMarketplaceVisible = asBoolean(payload, 'isMarketplaceVisible')
  const featuredRank = Math.floor(asNumber(payload, 'featuredRank'))

  const { data, error } = await adminClient
    .from('preset_sounds')
    .insert({
      name,
      slug,
      pack_id: packId,
      storage_path: storagePath,
      storage_bucket: 'preset-packs',
      status: 'draft',
      is_marketplace_visible: isMarketplaceVisible,
      is_free: true,
      preview_path: previewPath,
      license_label: licenseLabel,
      license_url: licenseUrl,
      creator_name: creatorName,
      source_attribution: sourceAttribution,
      category,
      tags,
      featured_rank: featuredRank,
      source_provider: sourceProvider,
    })
    .select('id')
    .single()

  if (error) throw error

  await writeAuditLog(actorUserId, 'create_sound', 'preset_sound', data.id, payload)

  return { ok: true, message: `Created sound "${name}".` }
}

async function handleSetPackActive(actorUserId: string, payload: CommandPayload) {
  const packId = asString(payload, 'packId')
  const isActive = asBoolean(payload, 'isActive')

  if (isActive) {
    const { data: packSounds, error: packSoundsError } = await adminClient
      .from('preset_sounds')
      .select('id,name,status,is_marketplace_visible,is_free,license_label,license_url,creator_name,source_attribution')
      .eq('pack_id', packId)
      .order('created_at', { ascending: true })

    if (packSoundsError) throw packSoundsError
    if (!packSounds || packSounds.length === 0) {
      throw new Error('Cannot publish an empty pack. Add approved sounds first.')
    }
    const invalidSound = packSounds.find((sound) => {
      return (
        sound.status !== 'approved' ||
        sound.is_marketplace_visible !== true ||
        sound.is_free !== true ||
        !sound.license_label?.trim() ||
        !sound.license_url?.trim() ||
        !sound.creator_name?.trim() ||
        !sound.source_attribution?.trim()
      )
    })
    if (invalidSound) {
      throw new Error(
        `Cannot publish pack. Sound "${invalidSound.name}" is missing required metadata or approval.`,
      )
    }
  }

  const { error } = await adminClient
    .from('preset_packs')
    .update({
      is_active: isActive,
      visibility: isActive ? 'public' : 'staged',
    })
    .eq('id', packId)

  if (error) throw error

  await writeAuditLog(actorUserId, 'set_pack_active', 'preset_pack', packId, payload)

  return { ok: true, message: isActive ? 'Pack published.' : 'Pack moved back to staged.' }
}

async function handleSetUserOverride(actorUserId: string, payload: CommandPayload) {
  const userId = asString(payload, 'userId')
  const enabled = asBoolean(payload, 'enabled')

  const { error: overrideError } = await adminClient
    .from('manual_entitlement_overrides')
    .insert({
      user_id: userId,
      actor_user_id: actorUserId,
      enabled,
      plan_key: 'pro_support',
      reason: enabled
        ? 'Granted from admin panel.'
        : 'Removed from admin panel.',
    })

  if (overrideError) throw overrideError

  if (enabled) {
    const { error: entitlementError } = await adminClient
      .from('entitlements')
      .insert({
        user_id: userId,
        source: 'manual_override',
        plan_key: 'pro_support',
        is_pro: true,
        status: 'manual',
        starts_at: new Date().toISOString(),
        reason: 'Granted from admin panel.',
      })

    if (entitlementError) throw entitlementError
  } else {
    const { error: deleteError } = await adminClient
      .from('entitlements')
      .delete()
      .eq('user_id', userId)
      .eq('source', 'manual_override')

    if (deleteError) throw deleteError
  }

  await writeAuditLog(actorUserId, 'set_user_override', 'user', userId, payload)

  return {
    ok: true,
    message: enabled ? 'Manual Pro override enabled.' : 'Manual Pro override removed.',
  }
}

async function handleQueueManualImport(actorUserId: string, payload: CommandPayload) {
  const providerId = asString(payload, 'providerId')
  const title = asString(payload, 'title')
  const sourceUrl = asString(payload, 'sourceUrl')
  const licenseLabel = asString(payload, 'licenseLabel')
  const attributionRequired = asBoolean(payload, 'attributionRequired')

  const { data, error } = await adminClient
    .from('catalog_import_items')
    .insert({
      provider_id: providerId,
      title,
      source_url: sourceUrl,
      preview_url: sourceUrl,
      license_label: licenseLabel,
      attribution_required: attributionRequired,
      status: 'draft',
      duplicate_risk: 'low',
    })
    .select('id')
    .single()

  if (error) throw error

  await writeAuditLog(actorUserId, 'queue_manual_import', 'catalog_import_item', data.id, payload)

  return { ok: true, message: 'Import queued for review.' }
}

async function handlePublishImport(actorUserId: string, payload: CommandPayload) {
  const itemId = asString(payload, 'itemId')

  const { data: item, error: itemError } = await adminClient
    .from('catalog_import_items')
    .select('id,provider_id,title,source_url,license_label,attribution_required')
    .eq('id', itemId)
    .single()

  if (itemError) throw itemError

  const slug = item.title.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '')
  const storagePath = `imports/${slug}.mp3`

  const { error: assetError } = await adminClient
    .from('catalog_assets')
    .insert({
      import_item_id: item.id,
      provider_id: item.provider_id,
      title: item.title,
      slug,
      storage_path: storagePath,
      source_url: item.source_url,
      license_label: item.license_label,
      attribution_required: item.attribution_required,
    })

  if (assetError) throw assetError

  const { error: statusError } = await adminClient
    .from('catalog_import_items')
    .update({
      status: 'approved',
    })
    .eq('id', itemId)

  if (statusError) throw statusError

  await writeAuditLog(actorUserId, 'publish_import', 'catalog_import_item', itemId, payload)

  return { ok: true, message: `"${item.title}" approved for publishing.` }
}

async function dispatchCommand(actorUserId: string, action: ActionName, payload: CommandPayload) {
  switch (action) {
    case 'create_pack':
      return handleCreatePack(actorUserId, payload)
    case 'create_sound':
      return handleCreateSound(actorUserId, payload)
    case 'set_pack_active':
      return handleSetPackActive(actorUserId, payload)
    case 'set_user_override':
      return handleSetUserOverride(actorUserId, payload)
    case 'queue_manual_import':
      return handleQueueManualImport(actorUserId, payload)
    case 'publish_import':
      return handlePublishImport(actorUserId, payload)
    default:
      throw new Error(`Unsupported action: ${action}`)
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return json(405, { ok: false, message: 'Method not allowed.' })
  }

  try {
    const { userId } = await requireStaffUser(req)
    const body = await req.json()
    const action = body?.action as ActionName | undefined
    const payload = (body?.payload ?? {}) as CommandPayload

    if (!action) {
      return json(400, { ok: false, message: 'Missing action.' })
    }

    const result = await dispatchCommand(userId, action, payload)
    return json(200, result)
  } catch (error) {
    return json(400, {
      ok: false,
      message: error instanceof Error ? error.message : 'Unexpected admin command failure.',
    })
  }
})
