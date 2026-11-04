import subprocess
import time
import json
import re
import sys
import base64

files_to_run = [
    "supabase/DEPLOY_TO_REMOTE_SUPABASE_ALL_STAFF_AUTH.sql",
    "supabase/migrations/20261104_019_real_inventory_and_movements.sql",
    "supabase/migrations/20261104_025_delivery_zones_and_fulfillment_engine.sql",
    "supabase/migrations/20261104_025_pos_shifts_cashier_and_atomic_checkout.sql",
    "supabase/migrations/20261104_026_fix_pos_and_order_atomic_governance.sql"
]

def run_sql(sql: str) -> dict:
    b64_sql = base64.b64encode(sql.encode('utf-8')).decode('utf-8')
    
    js_code = f"""
    (() => {{
        try {{
            const model = window.monaco.editor.getModels()[0];
            const decoded = decodeURIComponent(escape(atob('{b64_sql}')));
            model.setValue(decoded);
            const runBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText && b.innerText.includes('Run'));
            if (runBtn) {{
                runBtn.click();
                return 'CLICKED_RUN';
            }}
            return 'NO_RUN_BTN';
        }} catch(e) {{
            return 'ERR: ' + e.message;
        }}
    }})()
    """
    escaped_js = js_code.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ')
    
    script_set = f'''
tell application "Safari"
    repeat with w in windows
        repeat with t in tabs of w
            if (URL of t) starts with "https://supabase.com" then
                set res to do JavaScript "{escaped_js}" in t
                return res
            end if
        end repeat
    end repeat
    return "NO_TAB"
end tell
'''
    res = subprocess.check_output(['osascript', '-e', script_set], text=True).strip()
    if res != 'CLICKED_RUN':
        return {"status": "error", "message": f"Failed to click run: {res}"}
    
    # Wait for execution depending on size
    wait_time = 6 if len(sql) > 10000 else 4
    time.sleep(wait_time)
    
    js_read = """
    (() => {
        const err = document.querySelector('.text-destructive, [role=alert]');
        const rows = Array.from(document.querySelectorAll('[role=row]')).map(r => r.innerText.trim()).filter(Boolean);
        const allText = document.body.innerText;
        const hasSuccess = allText.includes('Success') || allText.includes('rows') || allText.includes('Results');
        return JSON.stringify({
            error: err ? err.innerText : null,
            rowsCount: rows.length,
            hasSuccess: hasSuccess
        });
    })()
    """
    escaped_read = js_read.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ')
    
    script_read = f'''
tell application "Safari"
    repeat with w in windows
        repeat with t in tabs of w
            if (URL of t) starts with "https://supabase.com" then
                set res to do JavaScript "{escaped_read}" in t
                return res
            end if
        end repeat
    end repeat
    return "{{}}"
end tell
'''
    read_res = subprocess.check_output(['osascript', '-e', script_read], text=True).strip()
    try:
        data = json.loads(read_res)
        return {"status": "success", "data": data}
    except Exception as e:
        return {"status": "error", "raw": read_res, "error": str(e)}

def main():
    for fpath in files_to_run:
        print(f"🚀 Deploying: {fpath}...")
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
        content = re.sub(r'CREATE SCHEMA IF NOT EXISTS auth;?', '', content)
        
        res = run_sql(content)
        print(f"Result for {fpath}:", json.dumps(res, ensure_ascii=False))
        if res.get('status') == 'success' and res.get('data', {}).get('error'):
            print(f"⚠️ Warning/Error: {res['data']['error']}")
        time.sleep(2)

    # Finally notify schema reload
    print("🔄 Reloading PostgREST schema cache...")
    reload_res = run_sql("NOTIFY pgrst, 'reload schema';")
    print("Reload result:", reload_res)

if __name__ == '__main__':
    main()
