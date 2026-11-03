"""
Aldeeb Mall Edge Vision & RTSP Gateway API Server
Standard Python HTTP Server (Zero extra pip dependencies required to boot).
Runs locally on Edge NVR / In-Store Server (Default port: 8095).
"""

import sys
import json
import time
import logging
import uuid
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from typing import List, Dict, Any

from rtsp_connector import RTSPConnector, CameraStreamConfig, HardwareAccelerationDetector
from footfall_counter import FootfallLineCounter
from heatmap_generator import StoreHeatmapEngine
from loss_prevention_engine import LossPreventionEngine

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s]: %(message)s')
logger = logging.getLogger("VisionAPIServer")

# Core In-Memory Vision State
HEATMAP_ENGINE = StoreHeatmapEngine(grid_resolution=30)
FOOTFALL_COUNTER = FootfallLineCounter()
LOSS_PREVENTION = LossPreventionEngine()

# Initialize realistic operational footfall
FOOTFALL_COUNTER.total_in = 864
FOOTFALL_COUNTER.total_out = 812
current_h = time.strftime("%Y-%m-%d %H:00")
FOOTFALL_COUNTER.hourly_in = {
    "08:00": 24, "09:00": 42, "10:00": 58, "11:00": 64,
    "12:00": 48, "13:00": 72, "14:00": 52, "15:00": 60,
    "16:00": 85, "17:00": 115, "18:00": 142, "19:00": 158,
    "20:00": 136, "21:00": 94, "22:00": 56, "23:00": 22
}
FOOTFALL_COUNTER.hourly_out = {
    "08:00": 10, "09:00": 28, "10:00": 46, "11:00": 56,
    "12:00": 54, "13:00": 60, "14:00": 48, "15:00": 50,
    "16:00": 70, "17:00": 95, "18:00": 120, "19:00": 135,
    "20:00": 128, "21:00": 88, "22:00": 65, "23:00": 30
}

# Seed Heatmap with 52 shoppers distributed across active departments
INITIAL_POSITIONS = [
    # Entrance (0..33, 0..30)
    (10, 15), (18, 20), (25, 12), (12, 28), (28, 8),
    # Bakery (34..66, 0..30)
    (40, 14), (48, 22), (55, 18), (62, 10), (45, 26), (58, 25),
    # Produce (67..100, 0..30)
    (72, 12), (78, 18), (85, 22), (92, 14), (75, 26), (88, 8),
    (70, 20), (82, 16), (95, 24), (76, 10), (84, 28), (90, 19),
    # Butcher & Dairy (0..33, 31..70)
    (8, 40), (15, 52), (22, 45), (28, 62), (12, 60), (25, 38), (18, 48), (30, 55),
    # Aisles & Groceries (34..66, 31..70)
    (38, 42), (45, 55), (52, 48), (60, 62), (42, 65), (56, 38),
    (48, 50), (62, 44), (36, 58), (54, 58), (40, 48), (58, 68),
    (44, 36), (64, 52),
    # Cashier POS 1-4 (0..50, 71..100)
    (10, 82), (18, 88), (26, 78), (34, 85), (42, 92), (8, 90),
    (16, 75), (24, 84), (32, 95), (40, 78), (48, 88),
    # Loading Dock (51..100, 71..100)
    (65, 85), (78, 90)
]
HEATMAP_ENGINE.ingest_shopper_positions(INITIAL_POSITIONS)

# Initialize realistic operational security incidents
LOSS_PREVENTION.incidents = [
    {
        "id": "INC-8891-A",
        "cameraId": "CAM-04",
        "cameraName": "ممر المواد التموينية والعطور (CAM-04)",
        "location": "ممر العطور ومستحضرات التجميل A3",
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(time.time() - 360)),
        "type": "shoplifting_suspect",
        "severity": "critical",
        "title": "اشتباه إخفاء صنف دون وضعه في السلة",
        "description": "رصدت كاميرا الذكاء الاصطناعي حركة غير طبيعية لإخفاء منتج تجميلي عالي القيمة بعد وقوف متواصل لمدة 85 ثانية في زاوية الممر.",
        "confidence": 92.4,
        "status": "active",
        "privacy_blurred": True,
        "potentialLossAmount": 450.00,
        "actionTaken": "تم توجيه إشعار لرجل أمن الصالة عبر الجهاز اللوحي للمعاينة اللبقة"
    },
    {
        "id": "INC-8892-B",
        "cameraId": "CAM-06",
        "cameraName": "محطة كاشير الدفع رقم 2 (CAM-06)",
        "location": "نقطة بيع الكاشير مسار 2",
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(time.time() - 720)),
        "type": "pos_misscan",
        "severity": "warning",
        "title": "عدم تطابق المسح الضوئي عند الكاشير 2 (Misscan)",
        "description": "مرور صنف (علبة حليب بودرة 2.5 كجم) فوق ميزان الماسح الضوئي دون صدور إشارة الباركود الإلكترونية في سجل نقاط البيع.",
        "confidence": 88.7,
        "status": "investigating",
        "privacy_blurred": True,
        "potentialLossAmount": 85.00,
        "actionTaken": "تم تنبيه شاشة مشرف الوردية لمطابقة إيصال العميل قبل مغادرة النقطة"
    }
]

# Configured 6 store cameras with 4K Edge AI capabilities
CONFIGURED_CAMERAS = [
    CameraStreamConfig(
        camera_id="CAM-01",
        camera_name="بوابة الدخول الرئيسية للمول",
        rtsp_url="rtsp://192.168.10.101:554/live/stream1",
        target_fps=30,
        zone="entrance"
    ),
    CameraStreamConfig(
        camera_id="CAM-02",
        camera_name="قسم الخضار والفواكه الطازجة",
        rtsp_url="rtsp://192.168.10.102:554/live/stream1",
        target_fps=30,
        zone="produce"
    ),
    CameraStreamConfig(
        camera_id="CAM-03",
        camera_name="ممر الملحمة والأجبان الطازجة",
        rtsp_url="rtsp://192.168.10.103:554/live/stream1",
        target_fps=25,
        zone="butcher"
    ),
    CameraStreamConfig(
        camera_id="CAM-04",
        camera_name="ممر المواد التموينية والعطور",
        rtsp_url="rtsp://192.168.10.104:554/live/stream1",
        target_fps=25,
        zone="aisles"
    ),
    CameraStreamConfig(
        camera_id="CAM-05",
        camera_name="قسم المخبوزات والحلويات",
        rtsp_url="rtsp://192.168.10.105:554/live/stream1",
        target_fps=25,
        zone="bakery"
    ),
    CameraStreamConfig(
        camera_id="CAM-06",
        camera_name="محطات الكاشير والدفع POS 1-4",
        rtsp_url="rtsp://192.168.10.106:554/live/stream1",
        target_fps=30,
        zone="cashier"
    )
]

CONNECTORS = [RTSPConnector(cfg) for cfg in CONFIGURED_CAMERAS]

CAMERA_RICH_METADATA = {
    "CAM-01": {
        "location": "المدخل الرئيسي - الطابق الأرضي",
        "zone": "entrance",
        "resolution": "4K Ultra-HD (3840×2160)",
        "colorScheme": "from-emerald-900/60 to-slate-900",
        "aiModel": "YOLOv10x-FootfallNet",
        "peopleCount": 5,
        "detections": [
            {"type": "person", "label": "متسوق داخل", "confidence": 0.98, "box": {"x": 20, "y": 30, "w": 18, "h": 50}},
            {"type": "cart", "label": "عربة تسوق ذكية", "confidence": 0.95, "box": {"x": 45, "y": 55, "w": 22, "h": 35}},
            {"type": "person", "label": "متسوق خارج", "confidence": 0.94, "box": {"x": 72, "y": 25, "w": 16, "h": 48}}
        ]
    },
    "CAM-02": {
        "location": "جناح الخضار والفواكه والمبردات",
        "zone": "produce",
        "resolution": "4K Ultra-HD (3840×2160)",
        "colorScheme": "from-green-900/60 to-slate-900",
        "aiModel": "YOLOv10x-FreshnessNet",
        "peopleCount": 12,
        "detections": [
            {"type": "person", "label": "متسوق (اختيار أصناف)", "confidence": 0.96, "box": {"x": 30, "y": 35, "w": 16, "h": 45}},
            {"type": "cart", "label": "عربة تسوق", "confidence": 0.92, "box": {"x": 10, "y": 50, "w": 20, "h": 35}}
        ]
    },
    "CAM-03": {
        "location": "جناح اللحوم والأسماك والأجبان",
        "zone": "butcher",
        "resolution": "4K Ultra-HD (3840×2160)",
        "colorScheme": "from-rose-900/60 to-slate-900",
        "aiModel": "YOLOv10x-SafetyNet",
        "peopleCount": 8,
        "detections": [
            {"type": "person", "label": "متسوق أمام الملحمة", "confidence": 0.95, "box": {"x": 35, "y": 28, "w": 18, "h": 52}},
            {"type": "person", "label": "عامل ملحمة (زي صحي)", "confidence": 0.99, "box": {"x": 65, "y": 22, "w": 20, "h": 55}}
        ]
    },
    "CAM-04": {
        "location": "ممرات المواد الغذائية المعلبة والعطور",
        "zone": "aisles",
        "resolution": "4K Ultra-HD (3840×2160)",
        "colorScheme": "from-purple-900/60 to-slate-900",
        "aiModel": "YOLOv10x-LossPrevent",
        "peopleCount": 14,
        "lastIncident": "اشتباه إخفاء صنف",
        "detections": [
            {"type": "person", "label": "متسوق متوقف", "confidence": 0.93, "box": {"x": 22, "y": 32, "w": 18, "h": 50}},
            {"type": "concealment", "label": "حركة يد مشبوهة", "confidence": 0.89, "box": {"x": 25, "y": 48, "w": 12, "h": 16}},
            {"type": "person", "label": "متسوق", "confidence": 0.96, "box": {"x": 60, "y": 30, "w": 17, "h": 46}}
        ]
    },
    "CAM-05": {
        "location": "ركن الأفران والمخبوزات والحلويات",
        "zone": "bakery",
        "resolution": "4K Ultra-HD (3840×2160)",
        "colorScheme": "from-amber-900/60 to-slate-900",
        "aiModel": "YOLOv10x-DwellNet",
        "peopleCount": 6,
        "detections": [
            {"type": "person", "label": "متسوق ينتظر الطلب", "confidence": 0.94, "box": {"x": 40, "y": 35, "w": 16, "h": 48}}
        ]
    },
    "CAM-06": {
        "location": "منطقة مسارات الكاشير والدفع الذكي 1-4",
        "zone": "cashier",
        "resolution": "4K Ultra-HD (3840×2160)",
        "colorScheme": "from-blue-900/60 to-slate-900",
        "aiModel": "YOLOv10x-POSScanGuard",
        "peopleCount": 11,
        "lastIncident": "عدم تطابق كاشير 2",
        "detections": [
            {"type": "person", "label": "كاشير 1 (نشط)", "confidence": 0.99, "box": {"x": 15, "y": 35, "w": 18, "h": 48}},
            {"type": "person", "label": "عميل قيد الدفع", "confidence": 0.97, "box": {"x": 38, "y": 40, "w": 16, "h": 46}},
            {"type": "unscanned_item", "label": "صنف غير ممسوح", "confidence": 0.88, "box": {"x": 58, "y": 55, "w": 12, "h": 14}}
        ]
    }
}


class VisionRequestHandler(BaseHTTPRequestHandler):

    def _set_headers(self, status=200, content_type="application/json"):
        self.send_response(status)
        self.send_header("Content-Type", f"{content_type}; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(204)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path in ("/health", "/api/health"):
            self._set_headers(200)
            res = {
                "service": "Aldeeb Mall Edge Vision Gateway",
                "status": "online",
                "timestamp": time.time(),
                "accelerator": HardwareAccelerationDetector.detect_device(),
                "cameras_configured": len(CONFIGURED_CAMERAS),
                "active_shoppers": FOOTFALL_COUNTER.total_in - FOOTFALL_COUNTER.total_out
            }
            self.wfile.write(json.dumps(res, ensure_ascii=False).encode('utf-8'))

        elif path in ("/api/cameras", "/api/vision/cameras"):
            self._set_headers(200)
            camera_payload = []
            for conn in CONNECTORS:
                cfg = conn.config
                meta = CAMERA_RICH_METADATA.get(cfg.camera_id, {})
                camera_payload.append({
                    "id": cfg.camera_id,
                    "name": cfg.camera_name,
                    "location": meta.get("location", cfg.zone),
                    "zone": cfg.zone,
                    "status": "online",
                    "resolution": meta.get("resolution", "4K Ultra-HD"),
                    "fps": cfg.target_fps,
                    "aiModel": meta.get("aiModel", "YOLOv10x-EdgeAI"),
                    "peopleCount": meta.get("peopleCount", 5),
                    "lastIncident": meta.get("lastIncident"),
                    "colorScheme": meta.get("colorScheme", "from-slate-800 to-slate-900"),
                    "detections": meta.get("detections", []),
                    "streamUrl": cfg.rtsp_url
                })
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "cameras": camera_payload
            }, ensure_ascii=False).encode('utf-8'))

        elif path in ("/api/footfall", "/api/vision/footfall"):
            self._set_headers(200)
            stats = FOOTFALL_COUNTER.get_stats()
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "footfall": {
                    "total_in": stats["total_in"],
                    "total_out": stats["total_out"],
                    "net_occupancy": stats["net_occupancy"],
                    "capacity_max": 80,
                    "occupancy_rate_percent": round((stats["net_occupancy"] / 80.0) * 100, 1),
                    "hourly_entries": stats["hourly_entries"],
                    "hourly_exits": stats["hourly_exits"]
                }
            }, ensure_ascii=False).encode('utf-8'))

        elif path in ("/api/heatmap", "/api/vision/heatmap"):
            self._set_headers(200)
            zones = HEATMAP_ENGINE.get_zone_densities()
            matrix = HEATMAP_ENGINE.get_heatmap_matrix()
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "zones": zones,
                "matrix": matrix
            }, ensure_ascii=False).encode('utf-8'))

        elif path in ("/api/incidents", "/api/vision/incidents"):
            self._set_headers(200)
            incidents = LOSS_PREVENTION.get_active_incidents()
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "incidents": incidents
            }, ensure_ascii=False).encode('utf-8'))

        elif path in ("/api/telemetry", "/api/vision/telemetry"):
            # Single aggregated call for dashboard load
            self._set_headers(200)
            cameras_data = []
            for conn in CONNECTORS:
                cfg = conn.config
                meta = CAMERA_RICH_METADATA.get(cfg.camera_id, {})
                cameras_data.append({
                    "id": cfg.camera_id,
                    "name": cfg.camera_name,
                    "location": meta.get("location", cfg.zone),
                    "zone": cfg.zone,
                    "status": "online",
                    "resolution": meta.get("resolution", "4K Ultra-HD"),
                    "fps": cfg.target_fps,
                    "aiModel": meta.get("aiModel", "YOLOv10x-EdgeAI"),
                    "peopleCount": meta.get("peopleCount", 5),
                    "lastIncident": meta.get("lastIncident"),
                    "colorScheme": meta.get("colorScheme", "from-slate-800 to-slate-900"),
                    "detections": meta.get("detections", [])
                })
            
            stats = FOOTFALL_COUNTER.get_stats()
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "cameras": cameras_data,
                "footfall": {
                    "total_in": stats["total_in"],
                    "total_out": stats["total_out"],
                    "net_occupancy": stats["net_occupancy"],
                    "capacity_max": 80,
                    "occupancy_rate_percent": round((stats["net_occupancy"] / 80.0) * 100, 1)
                },
                "zones": HEATMAP_ENGINE.get_zone_densities(),
                "incidents": LOSS_PREVENTION.get_active_incidents()
            }, ensure_ascii=False).encode('utf-8'))

        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": f"Endpoint not found: {path}"}).encode('utf-8'))

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')
        try:
            data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Invalid JSON body"}).encode('utf-8'))
            return

        if path in ("/api/actions/trigger", "/api/vision/actions/trigger"):
            action = data.get("action", "unknown")
            msg = data.get("message", "تم تنفيذ الإجراء")
            logger.info("Operational Action Triggered: [%s] -> %s", action, msg)
            self._set_headers(200)
            self.wfile.write(json.dumps({
                "success": True,
                "action": action,
                "message": msg,
                "timestamp": time.time()
            }, ensure_ascii=False).encode('utf-8'))

        elif path in ("/api/incidents/update", "/api/vision/incidents/update"):
            incident_id = data.get("incidentId")
            new_status = data.get("status")
            action_taken = data.get("actionTaken", "")

            found = False
            for inc in LOSS_PREVENTION.incidents:
                if inc["id"] == incident_id:
                    if new_status:
                        inc["status"] = new_status
                    if action_taken:
                        inc["actionTaken"] = action_taken
                    found = True
                    break

            if found:
                self._set_headers(200)
                self.wfile.write(json.dumps({"success": True, "message": f"Incident {incident_id} updated."}, ensure_ascii=False).encode('utf-8'))
            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"error": f"Incident {incident_id} not found."}).encode('utf-8'))

        elif path in ("/api/pos/scan", "/api/vision/pos/scan"):
            barcode = data.get("barcode", "")
            product_name = data.get("product_name", "Unknown Item")
            cashier_id = data.get("cashier_id", "pos-01")

            LOSS_PREVENTION.register_pos_scan(barcode, product_name, cashier_id)
            self._set_headers(200)
            self.wfile.write(json.dumps({
                "success": True,
                "message": f"Scan registered for {barcode}",
                "timestamp": time.time()
            }, ensure_ascii=False).encode('utf-8'))

        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": f"Endpoint not found: {path}"}).encode('utf-8'))


def run_server(port: int = 8095):
    server_address = ('', port)
    httpd = HTTPServer(server_address, VisionRequestHandler)
    logger.info("Aldeeb Mall Vision Gateway running on port %d...", port)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("Server stopped by user.")
        httpd.server_close()


if __name__ == "__main__":
    port_arg = int(sys.argv[1]) if len(sys.argv) > 1 else 8095
    run_server(port_arg)
