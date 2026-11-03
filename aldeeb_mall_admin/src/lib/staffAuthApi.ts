import { supabase } from './supabase';
import { StaffMember } from '../types';

export const SESSION_STORAGE_KEY = 'aldeeb_admin_session_token';
export const JWT_STORAGE_KEY = 'aldeeb_admin_jwt';
export const USER_ID_KEY = 'aldeeb_admin_user_id';

export interface AuthResponse {
  success: boolean;
  code?: string;
  message?: string;
  error?: string;
  session_token?: string;
  token?: string;
  expires_at?: string;
  staff?: StaffMember;
}

export interface VerifyResponse {
  valid: boolean;
  code?: string;
  message?: string;
  session_token?: string;
  expires_at?: string;
  staff?: StaffMember;
}

export const staffAuthApi = {
  // Read saved session token from localStorage
  getSessionToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(SESSION_STORAGE_KEY);
  },

  // Read saved JWT token
  getJwtToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(JWT_STORAGE_KEY);
  },

  // Save session tokens to localStorage
  saveSession(sessionToken: string, jwtToken?: string, userId?: string) {
    if (typeof window === 'undefined') return;
    localStorage.setItem(SESSION_STORAGE_KEY, sessionToken);
    if (jwtToken) {
      localStorage.setItem(JWT_STORAGE_KEY, jwtToken);
    }
    if (userId) {
      localStorage.setItem(USER_ID_KEY, userId);
    }
  },

  // Clear all session artifacts from storage
  clearSession() {
    if (typeof window === 'undefined') return;
    localStorage.removeItem(SESSION_STORAGE_KEY);
    localStorage.removeItem(JWT_STORAGE_KEY);
    localStorage.removeItem(USER_ID_KEY);
    localStorage.removeItem('aldeeb_admin_auth');
  },

  // Real server-side login using PostgreSQL RPC staff_login
  async loginStaff(username: string, password: string): Promise<AuthResponse> {
    try {
      const { data, error } = await supabase.rpc('staff_login', {
        p_username: username.trim(),
        p_password: password.trim(),
      });

      if (error) {
        console.error('Server staff_login error:', error);
        return {
          success: false,
          code: 'SERVER_ERROR',
          message: error.message || 'تعذر الاتصال بخادم المصادقة المركزي',
        };
      }

      const res = data as AuthResponse;
      if (res && res.success && res.session_token) {
        this.saveSession(res.session_token, res.token, res.staff?.id);
      }
      return res;
    } catch (err: any) {
      console.error('Login network/rpc exception:', err);
      return {
        success: false,
        code: 'NETWORK_ERROR',
        message: 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت أو حالة الخدمة.',
      };
    }
  },

  // Verify server session validity, expiration, active status, and anti-tampering
  async verifySession(tokenOverride?: string): Promise<VerifyResponse> {
    const token = tokenOverride || this.getSessionToken();
    if (!token) {
      return {
        valid: false,
        code: 'NO_SESSION',
        message: 'لا توجد جلسة نشطة',
      };
    }

    try {
      const { data, error } = await supabase.rpc('verify_staff_session', {
        p_session_token: token,
      });

      if (error) {
        console.error('Server verify_staff_session error:', error);
        return {
          valid: false,
          code: 'SERVER_ERROR',
          message: 'خطأ أثناء التحقق من الجلسة على الخادم',
        };
      }

      const res = data as VerifyResponse;
      if (!res || !res.valid) {
        // If server marked session invalid/revoked/expired, clean local storage
        this.clearSession();
      }
      return res;
    } catch (err: any) {
      console.error('Session verification exception:', err);
      return {
        valid: false,
        code: 'NETWORK_ERROR',
        message: 'تعذر التحقق من الجلسة بسبب انقطاع الاتصال',
      };
    }
  },

  // Terminate session on server and clear local state
  async logoutStaff(): Promise<boolean> {
    const token = this.getSessionToken();
    if (token) {
      try {
        await supabase.rpc('staff_logout', { p_session_token: token });
      } catch (err) {
        console.warn('Logout RPC error (ignored for graceful exit):', err);
      }
    }
    this.clearSession();
    return true;
  },

  // Super Admin: Force-terminate all active sessions for an employee
  async terminateStaffSession(targetStaffId: string): Promise<{ success: boolean; message: string }> {
    const adminToken = this.getSessionToken();
    if (!adminToken) {
      return { success: false, message: 'جلسة الإدارة غير متوفرة' };
    }

    try {
      const { data, error } = await supabase.rpc('staff_terminate_session', {
        p_admin_session_token: adminToken,
        p_target_staff_id: targetStaffId,
      });

      if (error) {
        return { success: false, message: error.message };
      }
      return data as { success: boolean; message: string };
    } catch (err: any) {
      return { success: false, message: err.message || 'خطأ في إنهاء الجلسة' };
    }
  },

  // Super Admin: Toggle account active/frozen with instant session revocation
  async toggleStaffActive(targetStaffId: string, isActive: boolean): Promise<{ success: boolean; message: string }> {
    const adminToken = this.getSessionToken();
    if (!adminToken) {
      return { success: false, message: 'جلسة الإدارة غير متوفرة' };
    }

    try {
      const { data, error } = await supabase.rpc('staff_toggle_active', {
        p_admin_session_token: adminToken,
        p_target_staff_id: targetStaffId,
        p_is_active: isActive,
      });

      if (error) {
        return { success: false, message: error.message };
      }
      return data as { success: boolean; message: string };
    } catch (err: any) {
      return { success: false, message: err.message || 'خطأ في تحديث حالة الحساب' };
    }
  },

  // Super Admin: Reset password with server-side bcrypt hashing and session revocation
  async adminResetPassword(targetStaffId: string, newPassword: string): Promise<{ success: boolean; message: string }> {
    const adminToken = this.getSessionToken();
    if (!adminToken) {
      return { success: false, message: 'جلسة الإدارة غير متوفرة' };
    }

    try {
      const { data, error } = await supabase.rpc('staff_admin_reset_password', {
        p_admin_session_token: adminToken,
        p_target_staff_id: targetStaffId,
        p_new_password: newPassword,
      });

      if (error) {
        return { success: false, message: error.message };
      }
      return data as { success: boolean; message: string };
    } catch (err: any) {
      return { success: false, message: err.message || 'خطأ في تعيين كلمة المرور' };
    }
  },

  // Self-Service: Change password if permission granted
  async selfChangePassword(newPassword: string): Promise<{ success: boolean; message: string }> {
    const token = this.getSessionToken();
    if (!token) {
      return { success: false, message: 'لا توجد جلسة نشطة' };
    }

    try {
      const { data, error } = await supabase.rpc('staff_self_change_password', {
        p_session_token: token,
        p_new_password: newPassword,
      });

      if (error) {
        return { success: false, message: error.message };
      }
      return data as { success: boolean; message: string };
    } catch (err: any) {
      return { success: false, message: err.message || 'خطأ في تحديث كلمة المرور' };
    }
  },

  // Super Admin: Create a new employee with server-hashed password
  async createStaffAccount(employeeData: Partial<StaffMember>, password: string): Promise<{ success: boolean; staff?: StaffMember; message: string }> {
    const adminToken = this.getSessionToken();
    if (!adminToken) {
      return { success: false, message: 'جلسة الإدارة غير متوفرة' };
    }

    try {
      const { data, error } = await supabase.rpc('staff_create_account', {
        p_admin_session_token: adminToken,
        p_employee_data: employeeData,
        p_password: password,
      });

      if (error) {
        return { success: false, message: error.message };
      }
      return data as { success: boolean; staff?: StaffMember; message: string };
    } catch (err: any) {
      return { success: false, message: err.message || 'خطأ في إنشاء حساب الموظف' };
    }
  },

  // Super Admin: Generate offline recovery PIN (valid for 15 minutes)
  async generateRecoveryToken(targetStaffId: string): Promise<{ success: boolean; token?: string; expires_at?: string; message: string }> {
    const adminToken = this.getSessionToken();
    if (!adminToken) {
      return { success: false, message: 'جلسة الإدارة غير متوفرة' };
    }

    try {
      const { data, error } = await supabase.rpc('staff_generate_recovery_token', {
        p_admin_session_token: adminToken,
        p_target_staff_id: targetStaffId,
      });

      if (error) {
        return { success: false, message: error.message };
      }
      return data as { success: boolean; token?: string; expires_at?: string; message: string };
    } catch (err: any) {
      return { success: false, message: err.message || 'خطأ في توليد رمز الاستعادة' };
    }
  },
};
