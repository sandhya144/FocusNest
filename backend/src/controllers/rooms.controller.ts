import { Response } from 'express'
import { AuthenticatedRequest } from '../middleware/auth.middleware.js'
import { getDbClient, getAdminDbClient } from '../../db/client.js'

export async function listRooms(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const supabase = req.token ? getDbClient(req.token) : getAdminDbClient()
    const { data: rooms, error } = await supabase
      .from('rooms')
      .select(`
        id,
        name,
        topic,
        visibility,
        tags,
        planned_duration_minutes,
        ends_at,
        created_at,
        updated_at,
        host:profiles!host_id (id, full_name, avatar_url),
        room_members (user_id, role, joined_at)
      `)
      .order('updated_at', { ascending: false })

    if (error) {
      res.status(500).json({ error: error.message })
      return
    }

    res.json({ rooms })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error'
    res.status(500).json({ error: message })
  }
}

export async function getRoom(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params
    const supabase = req.token ? getDbClient(req.token) : getAdminDbClient()

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const [roomRes, membersRes, rulesRes]: any[] = await Promise.all([
      supabase.from('rooms').select('*').eq('id', id).single(),
      supabase.from('room_members').select('*, profiles(*)').eq('room_id', id),
      supabase.from('room_rules').select('*').eq('room_id', id).maybeSingle(),
    ])

    if (roomRes.error || !roomRes.data) {
      res.status(404).json({ error: 'Room not found' })
      return
    }

    res.json({
      room: roomRes.data,
      members: (membersRes as { data?: unknown[] }).data || [],
      rules: (rulesRes as { data?: unknown }).data || null,
    })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error'
    res.status(500).json({ error: message })
  }
}

export async function createRoom(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    if (!req.user || !req.token) {
      res.status(401).json({ error: 'Unauthorized' })
      return
    }

    const { name, topic, tags = [], duration_minutes = 50 } = req.body
    if (!name || typeof name !== 'string') {
      res.status(400).json({ error: 'Room name is required' })
      return
    }

    const supabase = getDbClient(req.token)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { data: roomId, error } = await (supabase.rpc as any)('create_room', {
      p_name: name,
      p_topic: topic || null,
      p_tags: tags,
      p_duration_minutes: duration_minutes,
    })

    if (error) {
      res.status(500).json({ error: error.message })
      return
    }

    res.status(201).json({ roomId, message: 'Room created successfully' })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error'
    res.status(500).json({ error: message })
  }
}
