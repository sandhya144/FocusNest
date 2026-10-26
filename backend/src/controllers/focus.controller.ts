import { Response } from 'express'
import { AuthenticatedRequest } from '../middleware/auth.middleware.js'
import { getDbClient, getAdminDbClient } from '../../db/client.js'

const DEFAULT_BLOCKED_DOMAINS = [
  'youtube.com',
  'reddit.com',
  'twitter.com',
  'x.com',
  'tiktok.com',
  'instagram.com',
  'facebook.com',
  'netflix.com',
  'twitch.tv',
]

const DEFAULT_ALLOWED_DOMAINS = [
  'docs.google.com',
  'stackoverflow.com',
  'github.com',
  'developer.mozilla.org',
  'localhost',
  'chatgpt.com',
  'anthropic.com',
]

function classifyDomain(domain: string, allowed: string[] = DEFAULT_ALLOWED_DOMAINS, blocked: string[] = DEFAULT_BLOCKED_DOMAINS): 'allowed' | 'blocked' | 'unlisted' {
  const clean = domain.toLowerCase().trim()
  if (allowed.some(d => clean === d || clean.endsWith('.' + d))) return 'allowed'
  if (blocked.some(d => clean === d || clean.endsWith('.' + d))) return 'blocked'
  return 'unlisted'
}

export async function reportActivity(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { domain, room_id } = req.body

    if (!domain || typeof domain !== 'string') {
      res.status(400).json({ error: 'Missing or invalid domain' })
      return
    }

    const user = req.user
    const supabase = req.token ? getDbClient(req.token) : getAdminDbClient()

    let allowed = [...DEFAULT_ALLOWED_DOMAINS]
    let blocked = [...DEFAULT_BLOCKED_DOMAINS]

    if (user && room_id) {
      const [roomRulesRes, userRulesRes] = await Promise.all([
        supabase.from('room_rules').select('allowed_domains, blocked_domains').eq('room_id', room_id).maybeSingle(),
        supabase.from('user_rules').select('personal_allowed_domains, personal_blocked_domains').eq('user_id', user.id).maybeSingle(),
      ])

      const roomRules = roomRulesRes.data as { allowed_domains?: string[]; blocked_domains?: string[] } | null
      const userRules = userRulesRes.data as { personal_allowed_domains?: string[]; personal_blocked_domains?: string[] } | null

      if (roomRules) {
        allowed = [...allowed, ...(roomRules.allowed_domains || [])]
        blocked = [...blocked, ...(roomRules.blocked_domains || [])]
      }

      if (userRules) {
        allowed = [...allowed, ...(userRules.personal_allowed_domains || [])]
        blocked = [...blocked, ...(userRules.personal_blocked_domains || [])]
      }
    }

    const classification = classifyDomain(domain, allowed, blocked)
    let focusState: 'on-task' | 'warning' | 'locked' | 'approved-break' = 'on-task'

    if (classification === 'blocked') focusState = 'locked'
    else if (classification === 'unlisted') focusState = 'warning'

    if (user && room_id) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (supabase.from('room_member_focus') as any).upsert(
        {
          room_id,
          user_id: user.id,
          focus_state: focusState,
          tab_domain: domain.slice(0, 500),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'room_id,user_id' }
      )
    }

    res.json({
      status: classification,
      focusState,
      domain,
    })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error'
    res.status(500).json({ error: message })
  }
}

export async function getFocusState(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { roomId } = req.params
    const supabase = req.token ? getDbClient(req.token) : getAdminDbClient()

    const { data, error } = await supabase
      .from('room_member_focus')
      .select('*, profiles(id, full_name, avatar_url)')
      .eq('room_id', roomId)

    if (error) {
      res.status(500).json({ error: error.message })
      return
    }

    res.json({ membersFocus: data || [] })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error'
    res.status(500).json({ error: message })
  }
}

