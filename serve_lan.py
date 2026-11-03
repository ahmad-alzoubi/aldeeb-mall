import http.server
import socketserver
import threading
import sys
import os
import json
import urllib.request
import urllib.error

STORE_SETTINGS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'store_settings.json')
SUPPORT_TICKETS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'support_tickets.json')

DEFAULT_SETTINGS = {
    "primaryColor": "#0D47A1",
    "primaryDarkColor": "#0A2E6B",
    "secondaryColor": "#E53935",
    "accentColor": "#FFB300",
    "backgroundColor": "#F8FAFC",
    "surfaceColor": "#FFFFFF",
    "textPrimaryColor": "#0F172A",
    "textSecondaryColor": "#64748B",
    "storeNameAr": "الديب مول",
    "storeNameEn": "Aldeeb Mall",
    "taglineAr": "هايبرماركت العائلة الأول - جودة وتوفير بلا حدود",
    "announcementText": "🚚 توصيل مجاني للطلبات فوق 100 ل.س | صفقات حصرية يومياً",
    "expressDeliveryText": "توصيل إكسبريس فوري خلال 15 دقيقة ⚡",
    "smartExperiencesTitle": "تجارب الديب الذكية",
    "smartExperiencesSubtitle": "وفّر مع الجيران، ونظّم مقاضيك الشهرية بذكاء وسرعة",
    "groupDealsTitle": "الشراء الجماعي الذكي",
    "groupDealsSubtitle": "وفّر حتى 40% مع عروض الجيران التشاركية الحية",
    "groceryListTitle": "القائمة الذكية ومخطط المقاضي",
    "groceryListSubtitle": "تنظيم ومزامنة المقاضي العائلية بذكاء",
    "currency": "ل.س",
    "deliveryFee": 10.0,
    "freeThreshold": 100.0,
    "phone": "+971 50 123 4567",
    "whatsapp": "+971 50 123 4567"
}

def get_current_settings():
    if os.path.exists(STORE_SETTINGS_FILE):
        try:
            with open(STORE_SETTINGS_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            pass
    return DEFAULT_SETTINGS

def get_current_tickets():
    if os.path.exists(SUPPORT_TICKETS_FILE):
        try:
            with open(SUPPORT_TICKETS_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            pass
    return []

def save_current_tickets(data):
    try:
        with open(SUPPORT_TICKETS_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        sys.stderr.write(f"Error saving support_tickets.json: {e}\n")

def save_current_settings(data):
    try:
        with open(STORE_SETTINGS_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        sys.stderr.write(f"Error saving store_settings.json: {e}\n")

    # Also mirror into app and admin assets if folders exist
    sync_paths = [
        os.path.join(os.path.dirname(os.path.abspath(__file__)), 'aldeeb_mall_app', 'build', 'web', 'assets', 'store_settings.json'),
        os.path.join(os.path.dirname(os.path.abspath(__file__)), 'aldeeb_mall_admin', 'dist', 'store_settings.json'),
        os.path.join(os.path.dirname(os.path.abspath(__file__)), 'aldeeb_mall_app', 'assets', 'store_settings.json'),
    ]
    for sp in sync_paths:
        try:
            os.makedirs(os.path.dirname(sp), exist_ok=True)
            with open(sp, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except Exception:
            pass

class RobustHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        '.wasm': 'application/wasm',
        '.js': 'application/javascript',
        '.mjs': 'application/javascript',
        '.json': 'application/json',
        '.otf': 'font/otf',
        '.ttf': 'font/ttf',
        '.css': 'text/css',
    }

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, apikey, Prefer, Range')
        super().end_headers()

    def proxy_postgrest(self, method):
        target_path = self.path
        if target_path.startswith('/rest/v1'):
            target_path = target_path[8:]
        if not target_path.startswith('/'):
            target_path = '/' + target_path
        target_url = f"http://127.0.0.1:54321{target_path}"

        headers = {}
        for k, v in self.headers.items():
            if k.lower() not in ['host', 'content-length']:
                headers[k] = v

        body = None
        if method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            length = int(self.headers.get('Content-Length', 0))
            if length > 0:
                body = self.rfile.read(length)

        req = urllib.request.Request(target_url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                self.send_response(resp.status)
                for k, v in resp.headers.items():
                    if k.lower() not in ['transfer-encoding', 'content-length', 'access-control-allow-origin']:
                        self.send_header(k, v)
                self.send_header('Access-Control-Allow-Origin', '*')
                resp_body = resp.read()
                self.send_header('Content-Length', str(len(resp_body)))
                self.end_headers()
                self.wfile.write(resp_body)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            for k, v in e.headers.items():
                if k.lower() not in ['transfer-encoding', 'content-length', 'access-control-allow-origin']:
                    self.send_header(k, v)
            self.send_header('Access-Control-Allow-Origin', '*')
            err_body = e.read()
            self.send_header('Content-Length', str(len(err_body)))
            self.end_headers()
            self.wfile.write(err_body)
        except Exception as e:
            err = json.dumps({'error': str(e)}).encode('utf-8')
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Length', str(len(err)))
            self.end_headers()
            self.wfile.write(err)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, apikey, Prefer, Range')
        self.send_header('Content-Length', '0')
        self.end_headers()

    def do_GET(self):
        if self.path.startswith('/rest/v1'):
            self.proxy_postgrest('GET')
            return

        if self.path.startswith('/api/store_settings'):
            data = get_current_settings()
            body = json.dumps(data, ensure_ascii=False).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path.startswith('/api/support_tickets'):
            tickets = get_current_tickets()
            body = json.dumps(tickets, ensure_ascii=False).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        super().do_GET()

    def do_POST(self):
        if self.path.startswith('/rest/v1'):
            self.proxy_postgrest('POST')
            return

        if self.path.startswith('/api/store_settings'):
            try:
                length = int(self.headers.get('Content-Length', 0))
                raw_body = self.rfile.read(length).decode('utf-8')
                new_settings = json.loads(raw_body)
                current = get_current_settings()
                if isinstance(new_settings, dict):
                    current.update(new_settings)
                    save_current_settings(current)
                
                resp = json.dumps({'success': True, 'settings': current}, ensure_ascii=False).encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Content-Length', str(len(resp)))
                self.end_headers()
                self.wfile.write(resp)
                return
            except Exception as e:
                err_resp = json.dumps({'success': False, 'error': str(e)}).encode('utf-8')
                self.send_response(500)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Content-Length', str(len(err_resp)))
                self.end_headers()
                self.wfile.write(err_resp)
                return

        if self.path.startswith('/api/support_tickets'):
            try:
                length = int(self.headers.get('Content-Length', 0))
                raw_body = self.rfile.read(length).decode('utf-8')
                payload = json.loads(raw_body)
                tickets = get_current_tickets()
                
                if isinstance(payload, dict) and 'id' in payload:
                    existing_idx = next((i for i, t in enumerate(tickets) if t.get('id') == payload['id']), -1)
                    if existing_idx >= 0:
                        tickets[existing_idx].update(payload)
                    else:
                        tickets.insert(0, payload)
                    save_current_tickets(tickets)
                elif isinstance(payload, list):
                    tickets = payload
                    save_current_tickets(tickets)

                resp = json.dumps({'success': True, 'tickets': tickets}, ensure_ascii=False).encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Content-Length', str(len(resp)))
                self.end_headers()
                self.wfile.write(resp)
                return
            except Exception as e:
                err_resp = json.dumps({'success': False, 'error': str(e)}).encode('utf-8')
                self.send_response(500)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Content-Length', str(len(err_resp)))
                self.end_headers()
                self.wfile.write(err_resp)
                return

        self.send_response(404)
        self.end_headers()

    def do_PATCH(self):
        if self.path.startswith('/rest/v1'):
            self.proxy_postgrest('PATCH')
            return
        self.send_response(404)
        self.end_headers()

    def do_DELETE(self):
        if self.path.startswith('/rest/v1'):
            self.proxy_postgrest('DELETE')
            return
        self.send_response(404)
        self.end_headers()

    def do_PUT(self):
        if self.path.startswith('/rest/v1'):
            self.proxy_postgrest('PUT')
            return
        self.send_response(404)
        self.end_headers()

    def copyfile(self, source, outputfile):
        try:
            super().copyfile(source, outputfile)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_HEAD(self):
        self.do_GET()

    def log_message(self, format, *args):
        sys.stderr.write(f"[{self.server.server_port}] {args[0]} {args[1]}\n")

class PosRedirectHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        host = self.headers.get('Host', '').split(':')[0] or '192.168.0.100'
        target_url = f"http://{host}:3000/#pos"
        html = f"""<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <title>الديب مول | بوابة الكاشير المستقلة (POS)</title>
    <meta http-equiv="refresh" content="0; url={target_url}">
</head>
<body style="background:#020617;color:white;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;">
    <div style="text-align:center;">
        <h2 style="font-size:24px;margin-bottom:8px;">🚀 جاري فتح محطة الكاشير ونقاط البيع (POS Terminal)...</h2>
        <p style="color:#94a3b8;"><a href="{target_url}" style="color:#38bdf8;">انقر هنا إن لم يتم نقلك تلقائياً</a></p>
    </div>
    <script>window.location.href = "{target_url}";</script>
</body>
</html>"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Content-length', str(len(html.encode('utf-8'))))
        self.end_headers()
        self.wfile.write(html.encode('utf-8'))

    def do_HEAD(self):
        self.do_GET()

    def log_message(self, format, *args):
        pass

class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

def serve(port, directory):
    handler = lambda *args, **kwargs: RobustHandler(*args, directory=directory, **kwargs)
    server = ThreadingHTTPServer(('0.0.0.0', port), handler)
    print(f"🚀 Serving {directory} at http://0.0.0.0:{port}", flush=True)
    server.serve_forever()

def serve_pos_redirect(port):
    server = ThreadingHTTPServer(('0.0.0.0', port), PosRedirectHandler)
    print(f"🖥️ Serving Standalone POS Terminal on http://0.0.0.0:{port}", flush=True)
    server.serve_forever()

if __name__ == '__main__':
    admin_dir = "/Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/dist"
    app_dir = "/Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/build/web"

    t1 = threading.Thread(target=serve, args=(3000, admin_dir), daemon=True)
    t2 = threading.Thread(target=serve, args=(8080, app_dir), daemon=True)
    t3 = threading.Thread(target=serve_pos_redirect, args=(3050,), daemon=True)

    t1.start()
    t2.start()
    t3.start()

    print("✅ All servers started successfully on port 3000 (Admin), 3050 (Standalone POS), and 8080 (User App).", flush=True)
    t1.join()
