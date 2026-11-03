/**
 * Aldeeb Mall - Anti-Tampering & Live Session Revocation Browser Test
 * Verifies that client-side tampering of localStorage cannot bypass server authentication,
 * and that active sessions can be revoked in real-time from the database.
 */

const puppeteer = require('../aldeeb_mall_admin/node_modules/puppeteer-core');
const { execSync } = require('child_process');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const BASE_URL = 'http://127.0.0.1:5173';

function runSql(query) {
  const cmd = `/opt/homebrew/bin/psql -h localhost -p 5432 -U ahmad_alzoubi -d aldeeb_mall_prod -t -A -c "${query.replace(/"/g, '\\"')}"`;
  return execSync(cmd, { encoding: 'utf8' }).trim();
}

async function runAntiTamperingTest() {
  console.log('='.repeat(80));
  console.log('🛡️ ALDEEB MALL - BROWSER ANTI-TAMPERING & SERVER-SESSION DEFENSE AUDIT');
  console.log('='.repeat(80));

  let browser;
  let passed = 0;
  let total = 0;

  try {
    browser = await puppeteer.launch({
      executablePath: CHROME_PATH,
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu', '--window-size=1440,900']
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1440, height: 900 });

    // ------------------------------------------------------------------------
    // SCENARIO 1: Tampering localStorage with aldeeb_admin_auth = 'true' (No Token)
    // ------------------------------------------------------------------------
    total++;
    console.log('\n[TEST 1] Client Tampering: localStorage.aldeeb_admin_auth = "true" without token');
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
      localStorage.clear();
      localStorage.setItem('aldeeb_admin_auth', 'true');
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => document.body.innerText.includes('تسجيل الدخول'), { timeout: 8000 });

    const isLoginRendered1 = await page.evaluate(() => 
      document.body.innerText.includes('الديب مول') && document.body.innerText.includes('تسجيل الدخول')
    );
    const authFlag1 = await page.evaluate(() => localStorage.getItem('aldeeb_admin_auth'));

    if (isLoginRendered1 && authFlag1 !== 'true') {
      console.log('   ✅ Defense Confirmed: Forged aldeeb_admin_auth without session token was invalidated.');
      console.log('   Evidence: User remained on login screen; localStorage cleared.');
      passed++;
    } else {
      throw new Error(`Tamper bypass occurred! isLogin=${isLoginRendered1}, authFlag=${authFlag1}`);
    }

    // ------------------------------------------------------------------------
    // SCENARIO 2: Tampering with Fabricated Session Token
    // ------------------------------------------------------------------------
    total++;
    console.log('\n[TEST 2] Client Tampering: Injected Fake Session Token');
    await page.evaluate(() => {
      localStorage.setItem('aldeeb_admin_session_token', 'st_fake_tampered_token_99999');
      localStorage.setItem('aldeeb_admin_user_id', 'usr-fake-attacker');
      localStorage.setItem('aldeeb_admin_auth', 'true');
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => document.body.innerText.includes('تسجيل الدخول'), { timeout: 8000 });

    const isLoginRendered2 = await page.evaluate(() => 
      document.body.innerText.includes('الديب مول') && document.body.innerText.includes('تسجيل الدخول')
    );
    const storedToken2 = await page.evaluate(() => localStorage.getItem('aldeeb_admin_session_token'));

    if (isLoginRendered2 && !storedToken2) {
      console.log('   ✅ Defense Confirmed: Server RPC verify_staff_session rejected fake token.');
      console.log('   Evidence: Client purged invalid session credentials and kept login wall locked.');
      passed++;
    } else {
      throw new Error(`Forged token bypass occurred! token=${storedToken2}`);
    }

    // ------------------------------------------------------------------------
    // SCENARIO 3: Legitimate Login & Session Registration in Database
    // ------------------------------------------------------------------------
    total++;
    console.log('\n[TEST 3] Legitimate Server Login: Authenticating "admin" with bcrypt');
    await page.evaluate(() => {
      const buttons = Array.from(document.querySelectorAll('button'));
      const adminBtn = buttons.find(b => b.innerText.includes('حسام') || b.innerText.includes('admin'));
      if (adminBtn) adminBtn.click();
    });
    await new Promise(r => setTimeout(r, 400));

    await page.evaluate(() => {
      const submitBtn = document.querySelector('form button[type="submit"]') || 
        Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('تسجيل الدخول'));
      if (submitBtn) submitBtn.click();
    });
    await page.waitForSelector('aside', { timeout: 12000 });

    const realToken = await page.evaluate(() => localStorage.getItem('aldeeb_admin_session_token'));
    if (!realToken || !realToken.startsWith('st_')) {
      throw new Error(`Real session token not stored properly: ${realToken}`);
    }

    // Verify token exists and is active in database
    const dbSessionCount = runSql(`SELECT count(*) FROM public.staff_sessions WHERE session_token = '${realToken}' AND is_revoked = false;`);
    if (parseInt(dbSessionCount, 10) >= 1) {
      console.log(`   ✅ Real Authentication Confirmed: Active server session registered [${realToken.slice(0, 15)}...]`);
      console.log(`   Evidence: Verified in PostgreSQL staff_sessions (active rows = ${dbSessionCount})`);
      passed++;
    } else {
      throw new Error(`Session token not found in PostgreSQL staff_sessions table!`);
    }

    // ------------------------------------------------------------------------
    // SCENARIO 4: Refresh Page with Valid Session (Session Persistence)
    // ------------------------------------------------------------------------
    total++;
    console.log('\n[TEST 4] Session Persistence: Reloading page with valid server session');
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForSelector('aside', { timeout: 12000 });

    const stillLoggedIn = await page.evaluate(() => Boolean(document.querySelector('aside')));
    if (stillLoggedIn) {
      console.log('   ✅ Persistence Confirmed: Server verified active token on reload without asking for password.');
      passed++;
    } else {
      throw new Error('Valid session was lost on page reload!');
    }

    // ------------------------------------------------------------------------
    // SCENARIO 5: Server-Side Instant Session Revocation
    // ------------------------------------------------------------------------
    total++;
    console.log('\n[TEST 5] Instant Server Revocation: Revoking active session in database');
    runSql(`UPDATE public.staff_sessions SET is_revoked = true, revoked_reason = 'admin_emergency_kill' WHERE session_token = '${realToken}';`);
    
    // Trigger verification on page via reload
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => document.body.innerText.includes('تسجيل الدخول'), { timeout: 8000 });

    const isKickedOut = await page.evaluate(() => 
      document.body.innerText.includes('الديب مول') && document.body.innerText.includes('تسجيل الدخول')
    );
    const tokenCleared = await page.evaluate(() => localStorage.getItem('aldeeb_admin_session_token'));

    if (isKickedOut && !tokenCleared) {
      console.log('   ✅ Revocation Confirmed: Revoked session was rejected immediately on verification.');
      console.log('   Evidence: User evicted to login screen, token cleared from client storage.');
      passed++;
    } else {
      throw new Error(`Revoked session was still accepted! tokenCleared=${tokenCleared}`);
    }

    // ------------------------------------------------------------------------
    // SCENARIO 6: Account Freezing / Suspension Defense
    // ------------------------------------------------------------------------
    total++;
    console.log('\n[TEST 6] Account Freezing Defense: Attempting login with frozen account');
    // Freeze cashier_omar account in DB
    runSql(`UPDATE public.staff_members SET is_active = false WHERE username = 'cashier_omar';`);

    // Try to login as cashier_omar
    await page.evaluate(() => {
      const buttons = Array.from(document.querySelectorAll('button'));
      const cashierBtn = buttons.find(b => b.innerText.includes('عمر الدوسري') || b.innerText.includes('cashier_omar'));
      if (cashierBtn) cashierBtn.click();
    });
    await new Promise(r => setTimeout(r, 400));

    await page.evaluate(() => {
      const submitBtn = document.querySelector('form button[type="submit"]') || 
        Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('تسجيل الدخول'));
      if (submitBtn) submitBtn.click();
    });
    await new Promise(r => setTimeout(r, 1500));

    // Verify error message rendered
    const errorText = await page.evaluate(() => {
      const errBox = document.querySelector('.bg-rose-500\\/15') || document.body;
      return errBox.innerText;
    });

    const hasFreezeError = errorText.includes('مجمد') || errorText.includes('موقوف');

    // Unfreeze account back to true
    runSql(`UPDATE public.staff_members SET is_active = true WHERE username = 'cashier_omar';`);

    if (hasFreezeError) {
      console.log('   ✅ Account Freezing Defense Confirmed: Server blocked frozen account from logging in.');
      console.log(`   Evidence: Displayed security alert: "${errorText.trim().replace(/\n/g, ' ')}"`);
      passed++;
    } else {
      throw new Error(`Frozen account was permitted or did not show freeze error: ${errorText}`);
    }

    console.log('\n' + '='.repeat(80));
    console.log(`🎯 ANTI-TAMPERING & REVOCATION AUDIT: ${passed}/${total} Scenarios Passed (100% Zero Defect)`);
    console.log('='.repeat(80));

  } catch (err) {
    console.error('\n❌ Anti-Tampering Audit Failed:', err.message);
    process.exitCode = 1;
  } finally {
    // Restore cashier_omar active status just in case
    try {
      runSql(`UPDATE public.staff_members SET is_active = true WHERE username = 'cashier_omar';`);
    } catch (_) {}
    if (browser) await browser.close();
  }
}

runAntiTamperingTest();
