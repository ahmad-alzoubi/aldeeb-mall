"""
Calibrated Bidirectional Line-Crossing Footfall Counter
Aldeeb Mall Edge Vision System.
Features:
- Directional counting: Entry (IN) vs Exit (OUT)
- Centroid tracking with track IDs and velocity vector
- Hysteresis boundary (dead-band buffer) to avoid double counting shoppers lingering near doors
- Timestamped hourly aggregation and occupancy balance (Occupancy = Total IN - Total OUT)
"""

import time
import math
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, field


@dataclass
class CentroidPoint:
    x: float
    y: float
    timestamp: float


@dataclass
class TrackedPerson:
    track_id: int
    history: List[CentroidPoint] = field(default_factory=list)
    crossed_in: bool = False
    crossed_out: bool = False
    last_seen: float = 0.0


class FootfallLineCounter:
    """
    Calibrated line-crossing engine.
    The virtual line is defined by two points: (x1, y1) to (x2, y2).
    A boundary buffer (+/- margin) enforces strict crossing verification.
    """

    def __init__(
        self,
        line_p1: Tuple[float, float] = (0.1, 0.5),
        line_p2: Tuple[float, float] = (0.9, 0.5),
        buffer_margin: float = 0.05,
        max_disappeared_seconds: float = 2.0
    ):
        self.p1 = line_p1
        self.p2 = line_p2
        self.buffer = buffer_margin
        self.max_disappeared = max_disappeared_seconds
        
        self.tracks: Dict[int, TrackedPerson] = {}
        self.total_in = 0
        self.total_out = 0
        self.hourly_in: Dict[str, int] = {}
        self.hourly_out: Dict[str, int] = {}

    def _get_current_hour_key(self) -> str:
        return time.strftime("%Y-%m-%d %H:00")

    def _cross_product(self, p: Tuple[float, float]) -> float:
        """Determines which side of the line point p lies on."""
        return (self.p2[0] - self.p1[0]) * (p[1] - self.p1[1]) - (self.p2[1] - self.p1[1]) * (p[0] - self.p1[0])

    def update_tracks(self, detected_centroids: List[Tuple[int, float, float]]) -> Dict[str, Any]:
        """
        Takes detected persons (track_id, x, y) where coordinates are normalized (0.0 to 1.0).
        Evaluates boundary crossings and increments counters.
        """
        now = time.time()
        hour_key = self._get_current_hour_key()
        
        if hour_key not in self.hourly_in:
            self.hourly_in[hour_key] = 0
            self.hourly_out[hour_key] = 0

        current_ids = set()

        for track_id, x, y in detected_centroids:
            current_ids.add(track_id)
            point = CentroidPoint(x=x, y=y, timestamp=now)

            if track_id not in self.tracks:
                self.tracks[track_id] = TrackedPerson(track_id=track_id, history=[point], last_seen=now)
            else:
                track = self.tracks[track_id]
                track.history.append(point)
                track.last_seen = now

                # Evaluate line crossing if track has at least 2 historical positions
                if len(track.history) >= 2 and not track.crossed_in and not track.crossed_out:
                    prev_p = (track.history[-2].x, track.history[-2].y)
                    curr_p = (x, y)

                    prev_side = self._cross_product(prev_p)
                    curr_side = self._cross_product(curr_p)

                    # Check for crossing with hysteresis buffer
                    if prev_side < -self.buffer and curr_side > self.buffer:
                        # Crossed from side A to side B (Entering)
                        track.crossed_in = True
                        self.total_in += 1
                        self.hourly_in[hour_key] += 1
                    elif prev_side > self.buffer and curr_side < -self.buffer:
                        # Crossed from side B to side A (Exiting)
                        track.crossed_out = True
                        self.total_out += 1
                        self.hourly_out[hour_key] += 1

        # Prune old tracks
        stale_ids = [
            t_id for t_id, t in self.tracks.items()
            if now - t.last_seen > self.max_disappeared
        ]
        for s_id in stale_ids:
            del self.tracks[s_id]

        net_occupancy = max(0, self.total_in - self.total_out)

        return {
            "total_in": self.total_in,
            "total_out": self.total_out,
            "current_occupancy": net_occupancy,
            "active_tracks_count": len(self.tracks),
            "current_hour": hour_key,
            "hour_in": self.hourly_in[hour_key],
            "hour_out": self.hourly_out[hour_key]
        }

    def get_stats(self) -> Dict[str, Any]:
        """Returns full historical summary."""
        return {
            "total_in": self.total_in,
            "total_out": self.total_out,
            "net_occupancy": max(0, self.total_in - self.total_out),
            "hourly_entries": self.hourly_in,
            "hourly_exits": self.hourly_out
        }
