# Aldeeb Mall Local Edge Vision & Loss Prevention Gateway

This directory contains the production-grade Python edge service for real-time video stream ingestion, bidirectional visitor line-crossing, spatial floorplan heatmapping, and AI loss prevention.

## Architecture & Modules
- `rtsp_connector.py`: RTSP stream ingestion, socket health probes, hardware acceleration auto-detection (CUDA / Apple Silicon Metal / CPU multi-threading), and graceful disconnect handling.
- `footfall_counter.py`: Calibrated virtual line-crossing counter (In vs Out) with hysteresis buffer zone preventing false triggers from lingering shoppers.
- `heatmap_generator.py`: Discrete spatial 2D occupancy mapping onto store departments with temporal exponential decay.
- `loss_prevention_engine.py`: Correlates optical cashier item movement with POS barcode registrations to detect un-scanned items (Misscans) and suspicious shelf concealment gestures.
- `vision_api_server.py`: Low-latency HTTP/REST server serving telemetry to the Central Admin Dashboard (`http://localhost:8095`).

## Configuration
Edit camera stream configurations in `services/vision_service/vision_api_server.py`:
```python
CONFIGURED_CAMERAS = [
    CameraStreamConfig(
        camera_id="CAM-01",
        camera_name="بوابة الدخول الرئيسية",
        rtsp_url="rtsp://admin:password@192.168.10.101:554/h264Preview_01_main",
        target_fps=30,
        zone="entrance"
    ),
    ...
]
```

## Running the Service
```bash
python3 services/vision_service/vision_api_server.py 8095
```

## API Endpoints
- `GET /health` - Service status, detected hardware accelerator, and active camera count.
- `GET /api/cameras` - Real-time connectivity status and diagnostics for each configured RTSP stream.
- `GET /api/footfall` - Bidirectional visitor counting (in, out, and current occupancy).
- `GET /api/heatmap` - Floorplan zone densities and 2D normalized heat matrix.
- `GET /api/incidents` - Active loss prevention security incidents.
- `POST /api/pos/scan` - Registers a barcode scan from the POS Cashier.
- `POST /api/footfall/ingest` - Ingests detected centroids from YOLO/object tracker.
- `POST /api/heatmap/ingest` - Ingests 2D floorplan coordinates.
