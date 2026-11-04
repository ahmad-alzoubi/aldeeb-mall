import base64
import subprocess
import time
import json
import sys

def run_sql_in_supabase(sql: str, wait_seconds: int = 5) -> dict:
    b64_sql = base64.b64encode(sql.encode('utf-8')).decode('utf-8')
    
    js_code = f"""
    (() => {{
        try {{
            const model = window.monaco.editor.getModels()[0];
            const binString = atob('{b64_sql}');
            const bytes = Uint8Array.from(binString, (c) => c.charCodeAt(0));
            const decoded = new TextDecoder().decode(bytes);
            model.setValue(decoded);
            const runBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText && (b.innerText.trim() === 'Run' || b.innerText.includes('Run')));
            if (runBtn) {{
                runBtn.click();
                setTimeout(() => {{
                    const confirmBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText && (b.innerText.includes('Run and enable RLS') || b.innerText.includes('Run without RLS') || b.innerText.trim() === 'Run query' || b.innerText.trim() === 'Confirm'));
                    if (confirmBtn) {{
                        confirmBtn.click();
                    }}
                }}, 700);
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
    
    time.sleep(wait_seconds)
    
    js_read = """
    (() => {
        const errEl = document.querySelector('.text-destructive, [role=alert], div[class*="text-destructive"]');
        const errorText = errEl ? errEl.innerText.trim() : '';
        const bodySnippet = document.body.innerText.slice(0, 1500);
        const rows = Array.from(document.querySelectorAll('[role=row]')).map(r => r.innerText.trim()).filter(Boolean);
        return JSON.stringify({
            error: errorText,
            has_error: errorText.length > 0 && !errorText.includes('0 rows'),
            snippet: bodySnippet,
            rows: rows.slice(0, 50)
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

if __name__ == '__main__':
    sql = sys.argv[1] if len(sys.argv) > 1 else "SELECT 42 as answer;"
    result = run_sql_in_supabase(sql)
    print(json.dumps(result, ensure_ascii=False, indent=2))
