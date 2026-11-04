/**
 * Central Enterprise Audit Logger for Aldeeb Mall
 * Tracks all security, staff, financial, inventory, and administrative actions
 * with persistent database storage in public.audit_logs and local offline fallback.
 */

import { supabase } from './supabase';

export interface AuditLogEntry {
  id: string;
  actor_id: string;
  actor_name: string;
  actor_role: string;
  action: string;
  category: 'auth' | 'staff' | 'inventory' | 'orders' | 'financial' | 'system';
  target_id?: string;
  target_type?: string;
  details: string;
  branch_id?: string;
  branch_name?: string;
  timestamp: string;
  metadata?: Record<string, any>;
}

const AUDIT_STORAGE_KEY = 'aldeeb_enterprise_audit_trail_v2';

export function getAuditLogs(): AuditLogEntry[] {
  try {
    const raw = localStorage.getItem(AUDIT_STORAGE_KEY);
    if (raw) return JSON.parse(raw);
  } catch (_) {}
  return [];
}

export function logAuditEvent(entry: Omit<AuditLogEntry, 'id' | 'timestamp'>): AuditLogEntry {
  const newLog: AuditLogEntry = {
    id: `audit-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
    ...entry,
    timestamp: new Date().toISOString(),
  };

  // 1. Update local cache
  try {
    const current = getAuditLogs();
    const updated = [newLog, ...current].slice(0, 500);
    localStorage.setItem(AUDIT_STORAGE_KEY, JSON.stringify(updated));
  } catch (_) {}

  // 2. Persist to PostgreSQL Server via Supabase / PostgREST
  try {
    supabase
      .from('audit_logs')
      .insert({
        actor_id: entry.actor_id,
        actor_name: entry.actor_name,
        actor_role: entry.actor_role,
        action: entry.action,
        category: entry.category,
        target_id: entry.target_id || null,
        target_type: entry.target_type || null,
        branch_id: entry.branch_id || null,
        details: entry.details,
        metadata: entry.metadata || {},
      })
      .then(
        ({ error }) => {
          if (error) {
            console.warn('[AuditLogger] Failed to write to server audit_logs:', error.message);
          }
        },
        (err: unknown) => {
          console.warn('[AuditLogger] Network error writing audit log:', err);
        }
      );
  } catch (_) {}

  return newLog;
}
