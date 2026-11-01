/**
 * Central Enterprise Audit Logger for Aldeeb Mall
 * Tracks all security, staff, financial, inventory, and administrative actions
 */

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
}

const AUDIT_STORAGE_KEY = 'aldeeb_enterprise_audit_trail_v1';

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

  try {
    const current = getAuditLogs();
    const updated = [newLog, ...current].slice(0, 500); // keep last 500 actions
    localStorage.setItem(AUDIT_STORAGE_KEY, JSON.stringify(updated));
  } catch (_) {}

  return newLog;
}
