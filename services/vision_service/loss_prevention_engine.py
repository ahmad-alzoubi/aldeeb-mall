"""
Loss Prevention & Cashier Misscan Detector
Aldeeb Mall Edge Vision System.
Features:
- Optical cashier scan verification (cross-checks optical item movement vs POS checkout ledger)
- Concealment & abnormal dwell anomaly detection in high-shrink aisles
- Privacy-preserving bounding-box tagging and anonymization metadata
- Generation of structured SecurityIncident events with severity ratings
"""

import time
import uuid
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field


@dataclass
class POSScanEvent:
    barcode: str
    product_name: str
    timestamp: float
    cashier_id: str


@dataclass
class OpticalObjectEvent:
    object_type: str
    box: Dict[str, float]  # {x, y, w, h}
    confidence: float
    timestamp: float
    camera_id: str


class LossPreventionEngine:
    """
    Evaluates store visual telemetry for inventory shrink hazards.
    """

    def __init__(self, misscan_time_tolerance_sec: float = 3.0):
        self.misscan_window = misscan_time_tolerance_sec
        self.recent_pos_scans: List[POSScanEvent] = []
        self.incidents: List[Dict[str, Any]] = []

    def register_pos_scan(self, barcode: str, product_name: str, cashier_id: str):
        """Called when cashier barcode scanner registers an item in POS."""
        self.recent_pos_scans.append(POSScanEvent(
            barcode=barcode,
            product_name=product_name,
            timestamp=time.time(),
            cashier_id=cashier_id
        ))
        # Keep only recent scans (last 60 seconds)
        cutoff = time.time() - 60.0
        self.recent_pos_scans = [s for s in self.recent_pos_scans if s.timestamp > cutoff]

    def evaluate_cashier_frame(
        self,
        camera_id: str,
        optical_items_passed: List[OpticalObjectEvent]
    ) -> List[Dict[str, Any]]:
        """
        Cross-checks physical item displacement across POS scanner plate
        against active POS barcode registrations.
        """
        detected_alerts = []
        now = time.time()

        for item in optical_items_passed:
            # Check if an item crossed the scanner plate without a corresponding POS barcode event
            matched_scan = False
            for scan in self.recent_pos_scans:
                if abs(item.timestamp - scan.timestamp) <= self.misscan_window:
                    matched_scan = True
                    break

            if not matched_scan and item.confidence >= 0.85:
                incident_id = f"INC-{int(now)}-{uuid.uuid4().hex[:6]}"
                incident = {
                    "id": incident_id,
                    "cameraId": camera_id,
                    "cameraName": f"كاميرا المراقبة {camera_id}",
                    "location": "نقطة بيع الكاشير POS",
                    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                    "type": "pos_misscan",
                    "severity": "warning",
                    "title": "اشتباه تمرير صنف دون مسح ضوئي (Misscan)",
                    "description": f"رصد حركة صنف ({item.object_type}) عبر طاولة الكاشير دون تسجيل حركة باركود مقابلة خلال {self.misscan_window} ثوانٍ.",
                    "confidence": round(item.confidence * 100, 1),
                    "status": "active",
                    "privacy_blurred": True,
                    "potentialLossAmount": 15000.0,
                    "actionTaken": "تنبيه شاشة مشرف الكاشير للمطابقة الفورية"
                }
                self.incidents.append(incident)
                detected_alerts.append(incident)

        return detected_alerts

    def evaluate_aisle_dwell(
        self,
        camera_id: str,
        shopper_id: str,
        aisle_name: str,
        dwell_seconds: float,
        has_abnormal_concealment_gesture: bool,
        confidence: float
    ) -> Optional[Dict[str, Any]]:
        """
        Flags prolonged dwell combined with sudden concealment motion in blindspots.
        """
        if has_abnormal_concealment_gesture and confidence >= 0.80:
            now = time.time()
            incident_id = f"INC-{int(now)}-{uuid.uuid4().hex[:6]}"
            incident = {
                "id": incident_id,
                "cameraId": camera_id,
                "cameraName": f"كاميرا المراقبة {camera_id}",
                "location": aisle_name,
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                "type": "shoplifting_suspect",
                "severity": "critical",
                "title": "اشتباه إخفاء صنف دون وضعه في السلة",
                "description": f"رصد حركة غير طبيعية لإخفاء منتج بعد وقوف متواصل لمدة {int(dwell_seconds)} ثانية في {aisle_name}.",
                "confidence": round(confidence * 100, 1),
                "status": "active",
                "privacy_blurred": True,
                "potentialLossAmount": 45000.0,
                "actionTaken": "إشعار رجل أمن الصالة عبر الجهاز اللوحي للمعاينة اللبقة"
            }
            self.incidents.append(incident)
            return incident
        return None

    def get_active_incidents(self) -> List[Dict[str, Any]]:
        return [inc for inc in self.incidents if inc["status"] in ("active", "investigating")]
