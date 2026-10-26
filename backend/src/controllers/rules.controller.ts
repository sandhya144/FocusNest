import { Response } from 'express'
import { AuthenticatedRequest } from '../middleware/auth.middleware.js'
import { getDbClient } from '../../db/client.js'

export async function getRules(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    if (!req.user || !req.token) {
      res.status(401).json({ error: 'Unauthorized' })
      return
    }

    const { roomId } = req.query
    const supabase = getDbClient(req.token)

    const [userRulesRes, roomRulesRes] = await Promise.all([
      supabase.from('user_rules').select('*').eq('user_id', req.user.id).maybeSingle(),
      roomId ? supabase.from('room_rules').select('*').eq('room_id', String(roomId)).maybeSingle() : Promise.resolve({ data: null, error: null }),
    ])

    res.json({
      userRules: userRulesRes.data || null,
      roomRules: roomRulesRes.data || null,
    })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error'
    res.status(500).json({ error: message })
  }
}

export async function updatePersonalRules(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    if (!req.user || !req.token) {
      res.status(401).json({ error: 'Unauthorized' })
      return
    }

    const { allowed_domains, blocked_domains } = req.body
    const supabase = getDbClient(req.token)

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { data, error } = await (supabase.from('user_rules') as any)
      .upsert({
        user_id: req.user.id,
        personal_allowed_domains: allowed_domains || [],
        personal_blocked_domains: blocked_domains || [],
        updated_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (error) {
      res.status(500).json({ error: error.message })
      return
    }

    res.json({ rules: data })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error'
    res.status(500).json({ error: message })
  }
}

