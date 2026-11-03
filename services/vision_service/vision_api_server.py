"""
Aldeeb Mall Edge Vision & RTSP Gateway API Server
Standard Python HTTP Server (Zero extra pip dependencies required to boot).
Runs locally on Edge NVR / In-Store Server (Default port: 8095).
"""

import sys
import json
import time
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

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

# Configured cameras for Aldeeb Mall
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
        camera_name="ممر الملحمة والأجبان الطازجة",
        rtsp_url="rtsp://192.168.10.102:554/live/stream1",
        target_fps=25,
        zone="butcher"
    ),
    CameraStreamConfig(
        camera_id="CAM-03",
        camera_name="ممر المواد التموينية والعطور",
        rtsp_url="rtsp://192.168.10.103:554/live/stream1",
        target_fps=25,
        zone="aisles"
    ),
    CameraStreamConfig(
        camera_id="CAM-04",
        camera_name="محطات الكاشير والدفع POS 1-4",
        rtsp_url="rtsp://192.168.10.104:554/live/stream1",
        target_fps=30,
        zone="cashier"
    )
]

CONNECTORS = [RTSPConnector(cfg) for cfg in CONFIGURED_CAMERAS]


class VisionRequestHandler(BaseHTTPRequestHandler):

    def _set_headers(self, status=200, content_type="application/json"):
        self.send_response(status)
        self.send_header("Content-Type", f"{content_type}; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(204)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/health" or path == "/api/health":
            self._set_headers(200)
            res = {
                "service": "Aldeeb Mall Edge Vision Gateway",
                "status": "online",
                "timestamp": time.time(),
                "accelerator": HardwareAccelerationDetector.detect_device(),
                "cameras_configured": len(CONFIGURED_CAMERAS)
            }
            self.wfile.write(json.dumps(res, ensure_ascii=False).encode('utf-8'))

        elif path == "/api/cameras":
            self._set_headers(200)
            statuses = [conn.get_status_dict() for conn in CONNECTORS]
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "cameras": statuses
            }, ensure_ascii=False).encode('utf-8'))

        elif path == "/api/footfall":
            self._set_headers(200)
            stats = FOOTFALL_COUNTER.get_stats()
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "footfall": stats
            }, ensure_ascii=False).encode('utf-8'))

        elif path == "/api/heatmap":
            self._set_headers(200)
            zones = HEATMAP_ENGINE.get_zone_densities()
            matrix = HEATMAP_ENGINE.get_heatmap_matrix()
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "zones": zones,
                "matrix": matrix
            }, ensure_ascii=False).encode('utf-8'))

        elif path == "/api/incidents":
            self._set_headers(200)
            incidents = LOSS_PREVENTION.get_active_incidents()
            self.wfile.write(json.dumps({
                "timestamp": time.time(),
                "incidents": incidents
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

        if path == "/api/pos/scan":
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

        elif path == "/api/footfall/ingest":
            centroids = data.get("centroids", [])
            # centroids: list of [track_id, x, y]
            stats = FOOTFALL_COUNTER.update_tracks(centroids)
            self._set_headers(200)
            self.wfile.write(json.dumps(stats, ensure_ascii=False).encode('utf-8'))

        elif path == "/api/heatmap/ingest":
            positions = data.get("positions", [])
            # positions: list of [x, y] (0-100)
            HEATMAP_ENGINE.ingest_shopper_positions(positions)
            self._set_headers(200)
            self.wfile.write(json.dumps({
                "success": True,
                "zones": HEATMAP_ENGINE.get_zone_densities()
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
