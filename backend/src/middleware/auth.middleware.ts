import { Request, Response, NextFunction } from 'express'
import { User } from '@supabase/supabase-js'
import { getDbClient } from '../../db/client.js'

export interface AuthenticatedRequest extends Request {
  user?: User
  token?: string
}

export async function requireAuth(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
  const authHeader = req.headers.authorization

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized: missing or invalid Authorization header' })
    return
  }

  const token = authHeader.split(' ')[1]

  try {
    const supabase = getDbClient(token)
    const { data: { user }, error } = await supabase.auth.getUser()

    if (error || !user) {
      res.status(401).json({ error: 'Unauthorized: invalid token' })
      return
    }

    req.user = user
    req.token = token
    next()
  } catch {
    res.status(401).json({ error: 'Unauthorized: authentication failed' })
  }
}

export async function optionalAuth(req: AuthenticatedRequest, _res: Response, next: NextFunction): Promise<void> {
  const authHeader = req.headers.authorization

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next()
  }

  const token = authHeader.split(' ')[1]

  try {
    const supabase = getDbClient(token)
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      req.user = user
      req.token = token
    }
  } catch {
    // Continue unauthenticated
  }

  next()
}

