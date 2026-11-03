/**
 * Real Edge Vision & Sensor Gateway Client for Aldeeb Mall
 * Connects directly to Edge Vision API server (Port 8095 / Proxy /api/vision)
 */

import { StoreCamera, SecurityIncident, StoreZoneDensity } from './storeVisionData';

const VISION_BASE_URL = 
  (typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'))
    ? 'http://127.0.0.1:8095'
    : '/api/vision';

export interface FootfallMetrics {
  total_in: number;
  total_out: number;
  net_occupancy: number;
  capacity_max: number;
  occupancy_rate_percent: number;
  hourly_entries?: Record<string, number>;
  hourly_exits?: Record<string, number>;
}

export interface VisionTelemetryData {
  timestamp: number;
  cameras: StoreCamera[];
  footfall: FootfallMetrics;
  zones: StoreZoneDensity[];
  incidents: SecurityIncident[];
}

export async function fetchVisionTelemetry(): Promise<VisionTelemetryData | null> {
  try {
    const res = await fetch(`${VISION_BASE_URL}/api/telemetry`, {
      method: 'GET',
      headers: { 'Accept': 'application/json' },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    return data;
  } catch (err) {
    // Attempt relative proxy fallback if direct port fails
    if (VISION_BASE_URL !== '/api/vision') {
      try {
        const fallbackRes = await fetch(`/api/vision/api/telemetry`);
        if (fallbackRes.ok) return await fallbackRes.json();
      } catch (_) {}
    }
    console.warn('⚠️ Edge Vision Gateway telemetry offline or unreachable:', err);
    return null;
  }
}

export async function fetchLiveCameras(): Promise<StoreCamera[]> {
  try {
    const res = await fetch(`${VISION_BASE_URL}/api/cameras`);
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data.cameras) && data.cameras.length > 0) {
        return data.cameras;
      }
    }
  } catch (_) {}
  return [];
}

export async function fetchLiveFootfall(): Promise<FootfallMetrics | null> {
  try {
    const res = await fetch(`${VISION_BASE_URL}/api/footfall`);
    if (res.ok) {
      const data = await res.json();
      return data.footfall;
    }
  } catch (_) {}
  return null;
}

export async function fetchLiveIncidents(): Promise<SecurityIncident[]> {
  try {
    const res = await fetch(`${VISION_BASE_URL}/api/incidents`);
    if (res.ok) {
      const data = await res.json();
      return data.incidents || [];
    }
  } catch (_) {}
  return [];
}

export async function postTriggerAction(action: string, message: string): Promise<boolean> {
  try {
    const res = await fetch(`${VISION_BASE_URL}/api/actions/trigger`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, message }),
    });
    return res.ok;
  } catch (err) {
    console.warn('Failed to dispatch vision action:', err);
    return false;
  }
}

export async function postUpdateIncidentStatus(
  incidentId: string, 
  status: SecurityIncident['status'], 
  actionTaken: string
): Promise<boolean> {
  try {
    const res = await fetch(`${VISION_BASE_URL}/api/incidents/update`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ incidentId, status, actionTaken }),
    });
    return res.ok;
  } catch (err) {
    console.warn('Failed to update incident on vision server:', err);
    return false;
  }
}
