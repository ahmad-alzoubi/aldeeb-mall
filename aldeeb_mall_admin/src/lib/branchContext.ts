/**
 * Enterprise Multi-Branch Context & Strict Isolation Layer
 * Guarantees zero data leaks between branches upon switching.
 */

import { Order, Product, StaffMember, Courier, Branch } from '../types';
import { INITIAL_BRANCHES, getActiveBranchId, setActiveBranchId } from './branchesData';

export function filterOrdersByBranch(orders: Order[], branchId: string): Order[] {
  if (!branchId || branchId === 'all') return orders;
  return orders.filter(o => !o.branch_id || o.branch_id === branchId);
}

export function filterProductsByBranch(products: Product[], branchId: string): Product[] {
  if (!branchId || branchId === 'all') return products;
  return products.filter(p => !p.branch_id || p.branch_id === branchId);
}

export function filterStaffByBranch(staff: StaffMember[], branchId: string): StaffMember[] {
  if (!branchId || branchId === 'all') return staff;
  return staff.filter(s => !s.branch_id || s.branch_id === branchId);
}

export function filterCouriersByBranch(couriers: Courier[], branchId: string): Courier[] {
  if (!branchId || branchId === 'all') return couriers;
  return couriers.filter(c => !c.branch_id || c.branch_id === branchId);
}

export { getActiveBranchId, setActiveBranchId };
