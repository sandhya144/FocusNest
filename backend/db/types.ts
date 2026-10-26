/**
 * GroupLock Database TypeScript Definitions
 * Mirrors the PostgreSQL database schema and Supabase public schema.
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type FocusState = 'on-task' | 'warning' | 'locked' | 'approved-break'
export type RoomVisibility = 'private' | 'friends' | 'link'
export type RoomRole = 'host' | 'member'
export type FriendStatus = 'pending' | 'accepted' | 'blocked'
export type StrictnessLevel = 'chill' | 'standard' | 'hardcore'
export type MessageType = 'message' | 'system' | 'reaction'

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          username: string | null
          full_name: string | null
          avatar_url: string | null
          school: string | null
          bio: string | null
          created_at: string
        }
        Insert: {
          id: string
          username?: string | null
          full_name?: string | null
          avatar_url?: string | null
          school?: string | null
          bio?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          username?: string | null
          full_name?: string | null
          avatar_url?: string | null
          school?: string | null
          bio?: string | null
          created_at?: string
        }
      }
      friends: {
        Row: {
          id: string
          user_id: string
          friend_id: string
          status: FriendStatus
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          friend_id: string
          status?: FriendStatus
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          friend_id?: string
          status?: FriendStatus
          created_at?: string
        }
      }
      rooms: {
        Row: {
          id: string
          host_id: string
          name: string
          topic: string | null
          visibility: RoomVisibility
          tags: string[]
          planned_duration_minutes: number | null
          ends_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          host_id: string
          name: string
          topic?: string | null
          visibility?: RoomVisibility
          tags?: string[]
          planned_duration_minutes?: number | null
          ends_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          host_id?: string
          name?: string
          topic?: string | null
          visibility?: RoomVisibility
          tags?: string[]
          planned_duration_minutes?: number | null
          ends_at?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      room_members: {
        Row: {
          room_id: string
          user_id: string
          role: RoomRole
          joined_at: string
          left_at: string | null
        }
        Insert: {
          room_id: string
          user_id: string
          role?: RoomRole
          joined_at?: string
          left_at?: string | null
        }
        Update: {
          room_id?: string
          user_id?: string
          role?: RoomRole
          joined_at?: string
          left_at?: string | null
        }
      }
      focus_sessions: {
        Row: {
          id: string
          room_id: string
          user_id: string
          started_at: string
          ended_at: string | null
          goal: string | null
          planned_duration_minutes: number | null
          actual_focus_minutes: number | null
          off_task_events: number | null
        }
        Insert: {
          id?: string
          room_id: string
          user_id: string
          started_at?: string
          ended_at?: string | null
          goal?: string | null
          planned_duration_minutes?: number | null
          actual_focus_minutes?: number | null
          off_task_events?: number | null
        }
        Update: {
          id?: string
          room_id?: string
          user_id?: string
          started_at?: string
          ended_at?: string | null
          goal?: string | null
          planned_duration_minutes?: number | null
          actual_focus_minutes?: number | null
          off_task_events?: number | null
        }
      }
      messages: {
        Row: {
          id: string
          room_id: string
          user_id: string
          content: string
          type: MessageType
          created_at: string
        }
        Insert: {
          id?: string
          room_id: string
          user_id: string
          content: string
          type?: MessageType
          created_at?: string
        }
        Update: {
          id?: string
          room_id?: string
          user_id?: string
          content?: string
          type?: MessageType
          created_at?: string
        }
      }
      focus_events: {
        Row: {
          id: string
          user_id: string
          room_id: string | null
          session_id: string | null
          event_type: string
          domain: string | null
          url: string | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          room_id?: string | null
          session_id?: string | null
          event_type: string
          domain?: string | null
          url?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          room_id?: string | null
          session_id?: string | null
          event_type?: string
          domain?: string | null
          url?: string | null
          created_at?: string
        }
      }
      room_rules: {
        Row: {
          id: string
          room_id: string
          allowed_domains: string[]
          blocked_domains: string[]
          strictness: StrictnessLevel
          grace_seconds_before_warning: number | null
          max_warnings_before_lock: number | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          room_id: string
          allowed_domains?: string[]
          blocked_domains?: string[]
          strictness?: StrictnessLevel
          grace_seconds_before_warning?: number | null
          max_warnings_before_lock?: number | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          room_id?: string
          allowed_domains?: string[]
          blocked_domains?: string[]
          strictness?: StrictnessLevel
          grace_seconds_before_warning?: number | null
          max_warnings_before_lock?: number | null
          created_at?: string
          updated_at?: string
        }
      }
      user_rules: {
        Row: {
          id: string
          user_id: string
          personal_allowed_domains: string[]
          personal_blocked_domains: string[]
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          personal_allowed_domains?: string[]
          personal_blocked_domains?: string[]
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          personal_allowed_domains?: string[]
          personal_blocked_domains?: string[]
          created_at?: string
          updated_at?: string
        }
      }
      user_settings: {
        Row: {
          id: string
          user_id: string
          email_room_invites: boolean | null
          email_focus_recaps: boolean | null
          push_break_reminders: boolean | null
          show_real_name: boolean | null
          share_current_room_with_friends: boolean | null
          share_focus_history_with_room: boolean | null
          theme: 'light' | 'dark' | 'system'
          density: 'comfortable' | 'compact'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          email_room_invites?: boolean | null
          email_focus_recaps?: boolean | null
          push_break_reminders?: boolean | null
          show_real_name?: boolean | null
          share_current_room_with_friends?: boolean | null
          share_focus_history_with_room?: boolean | null
          theme?: 'light' | 'dark' | 'system'
          density?: 'comfortable' | 'compact'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          email_room_invites?: boolean | null
          email_focus_recaps?: boolean | null
          push_break_reminders?: boolean | null
          show_real_name?: boolean | null
          share_current_room_with_friends?: boolean | null
          share_focus_history_with_room?: boolean | null
          theme?: 'light' | 'dark' | 'system'
          density?: 'comfortable' | 'compact'
          created_at?: string
          updated_at?: string
        }
      }
      user_focus_settings: {
        Row: {
          id: string
          user_id: string
          default_strictness: StrictnessLevel
          grace_seconds_before_warning: number | null
          max_warnings_before_lock: number | null
          allow_break_requests: boolean | null
          auto_share_off_task_events: boolean | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          default_strictness?: StrictnessLevel
          grace_seconds_before_warning?: number | null
          max_warnings_before_lock?: number | null
          allow_break_requests?: boolean | null
          auto_share_off_task_events?: boolean | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          default_strictness?: StrictnessLevel
          grace_seconds_before_warning?: number | null
          max_warnings_before_lock?: number | null
          allow_break_requests?: boolean | null
          auto_share_off_task_events?: boolean | null
          created_at?: string
          updated_at?: string
        }
      }
      room_member_focus: {
        Row: {
          room_id: string
          user_id: string
          focus_state: FocusState
          tab_domain: string | null
          updated_at: string
        }
        Insert: {
          room_id: string
          user_id: string
          focus_state?: FocusState
          tab_domain?: string | null
          updated_at?: string
        }
        Update: {
          room_id?: string
          user_id?: string
          focus_state?: FocusState
          tab_domain?: string | null
          updated_at?: string
        }
      }
      extension_devices: {
        Row: {
          id: string
          user_id: string
          device_label: string | null
          browser_type: string | null
          last_seen_at: string | null
          token_id: string | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          device_label?: string | null
          browser_type?: string | null
          last_seen_at?: string | null
          token_id?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          device_label?: string | null
          browser_type?: string | null
          last_seen_at?: string | null
          token_id?: string | null
          created_at?: string
        }
      }
    }
    Functions: {
      create_room: {
        Args: {
          p_name: string
          p_topic?: string | null
          p_tags?: string[]
          p_duration_minutes?: number
        }
        Returns: string
      }
      user_can_access_room: {
        Args: {
          p_room_id: string
        }
        Returns: boolean
      }
    }
  }
}

