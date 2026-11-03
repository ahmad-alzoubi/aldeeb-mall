"""
Store Floorplan Heatmap Generator & Spatial Density Engine
Aldeeb Mall Edge Vision System.
Features:
- Normalized (0-100) 2D spatial coordinate mapping onto store zones
- Dwell-time accumulation with exponential decay
- Zone-level density categorization (low, medium, high, critical)
- Heatmap matrix generation for canvas rendering
"""

import time
import math
from typing import Dict, List, Tuple, Any
from dataclasses import dataclass


@dataclass
class StoreZoneDefinition:
    zone_id: str
    name_ar: str
    x_min: float
    x_max: float
    y_min: float
    y_max: float
    capacity_max: int


class StoreHeatmapEngine:
    """
    Computes spatial density and dwell time for store departments.
    """

    STORE_ZONES = [
        StoreZoneDefinition("entrance", "بوابة الدخول الرئيسية", 0, 33, 0, 30, 45),
        StoreZoneDefinition("bakery", "قسم المخبوزات والحلويات", 34, 66, 0, 30, 25),
        StoreZoneDefinition("produce", "الخضار والفواكه الطازجة", 67, 100, 0, 30, 40),
        StoreZoneDefinition("butcher", "الملحمة والأسماك والأجبان", 0, 33, 31, 70, 30),
        StoreZoneDefinition("aisles", "الممرات والمواد التموينية", 34, 66, 31, 70, 60),
        StoreZoneDefinition("beverages", "المشروبات والعصائر", 67, 100, 31, 70, 35),
        StoreZoneDefinition("cashier", "منطقة الكاشير والدفع POS", 0, 50, 71, 100, 50),
        StoreZoneDefinition("loading_dock", "منطقة الاستلام والتسليم للمناديب", 51, 100, 71, 100, 20),
    ]

    def __init__(self, grid_resolution: int = 50, decay_half_life_sec: float = 60.0):
        self.grid_size = grid_resolution
        self.decay_factor = math.log(2) / decay_half_life_sec
        self.heat_grid = [[0.0 for _ in range(grid_resolution)] for _ in range(grid_resolution)]
        self.last_update_ts = time.time()
        self.zone_dwell_times: Dict[str, float] = {z.zone_id: 0.0 for z in self.STORE_ZONES}
        self.zone_shopper_counts: Dict[str, int] = {z.zone_id: 0 for z in self.STORE_ZONES}

    def _apply_decay(self, dt: float):
        """Applies exponential temporal decay to heatmap intensity."""
        rate = math.exp(-self.decay_factor * dt)
        for r in range(self.grid_size):
            for c in range(self.grid_size):
                self.heat_grid[r][c] *= rate

    def ingest_shopper_positions(self, positions: List[Tuple[float, float]]):
        """
        Positions: list of (x, y) where x, y are percentages [0.0 - 100.0].
        """
        now = time.time()
        dt = max(0.1, now - self.last_update_ts)
        self._apply_decay(dt)
        self.last_update_ts = now

        # Reset counts for current frame
        for z in self.STORE_ZONES:
            self.zone_shopper_counts[z.zone_id] = 0

        for x, y in positions:
            x_clamped = max(0.0, min(99.9, x))
            y_clamped = max(0.0, min(99.9, y))

            # Update discrete grid
            grid_r = int((y_clamped / 100.0) * self.grid_size)
            grid_c = int((x_clamped / 100.0) * self.grid_size)
            self.heat_grid[grid_r][grid_c] += 1.0

            # Match zone
            for zone in self.STORE_ZONES:
                if zone.x_min <= x_clamped <= zone.x_max and zone.y_min <= y_clamped <= zone.y_max:
                    self.zone_shopper_counts[zone.zone_id] += 1
                    self.zone_dwell_times[zone.zone_id] += dt
                    break

    def get_zone_densities(self) -> List[Dict[str, Any]]:
        """Produces zone report matching admin frontend StoreZoneDensity format."""
        results = []
        for zone in self.STORE_ZONES:
            count = self.zone_shopper_counts[zone.zone_id]
            cap = zone.capacity_max
            ratio = count / max(1, cap)

            if ratio >= 0.85:
                level = "critical"
                color = "#ef4444"
            elif ratio >= 0.55:
                level = "high"
                color = "#f97316"
            elif ratio >= 0.25:
                level = "medium"
                color = "#eab308"
            else:
                level = "low"
                color = "#22c55e"

            dwell_min = round(self.zone_dwell_times[zone.zone_id] / 60.0, 1)

            results.append({
                "id": zone.zone_id,
                "nameAr": zone.name_ar,
                "currentShoppers": count,
                "capacityMax": cap,
                "avgDwellMinutes": dwell_min,
                "densityLevel": level,
                "heatColor": color
            })
        return results

    def get_heatmap_matrix(self) -> List[List[float]]:
        """Returns the 2D matrix of normalized heat intensities (0.0 to 1.0)."""
        max_val = max(max(row) for row in self.heat_grid) if self.heat_grid else 1.0
        if max_val <= 0:
            return [[0.0 for _ in range(self.grid_size)] for _ in range(self.grid_size)]
        return [[round(val / max_val, 3) for val in row] for row in self.heat_grid]
