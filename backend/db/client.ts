import { createClient, SupabaseClient } from '@supabase/supabase-js'
import type { Database } from './types'

const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || ''
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || ''

/**
 * Standard Supabase client (subject to Row Level Security)
 */
export function getDbClient(accessToken?: string): SupabaseClient<Database> {
  const options = accessToken
    ? {
        global: {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        },
      }
    : undefined

  return createClient<Database>(supabaseUrl, supabaseAnonKey, options)
}

/**
 * Admin / Service Role Supabase client (bypasses Row Level Security)
 * Use only for backend tasks, system triggers, or administrative operations.
 */
export function getAdminDbClient(): SupabaseClient<Database> {
  const key = supabaseServiceKey || supabaseAnonKey
  return createClient<Database>(supabaseUrl, key, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  })
}

export const db = getDbClient()

