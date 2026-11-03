#!/usr/bin/env python3
# Draws the macOS 26 menu toggle (54x24 pt track, 32x20 pt capsule knob inset
# 2 pt) at 2x as toggle_<on|off>_<light|dark>.png, next to this script.
# Pure standard library: run it again after changing a size or color.

import os
import struct
import zlib

SCALE = 2
TRACK_W, TRACK_H = 54 * SCALE, 24 * SCALE
KNOB_W, KNOB_H = 32 * SCALE, 20 * SCALE
INSET = 2 * SCALE
SAMPLES = 4  # supersampling per axis for anti-aliased edges

TRACK = {
    ("on", "light"): (0x00, 0x7A, 0xFF, 1.0),
    ("on", "dark"): (0x0A, 0x84, 0xFF, 1.0),
    ("off", "light"): (0x78, 0x78, 0x80, 0.20),
    ("off", "dark"): (0x78, 0x78, 0x80, 0.36),
}


def capsule_distance(x, y, left, top, width, height):
    """Signed distance from (x, y) to a capsule (negative inside)."""
    radius = height / 2
    cx = min(max(x, left + radius), left + width - radius)
    cy = top + radius
    return ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 - radius


def coverage(x, y, *shape):
    inside = 0
    for sy in range(SAMPLES):
        for sx in range(SAMPLES):
            px = x + (sx + 0.5) / SAMPLES
            py = y + (sy + 0.5) / SAMPLES
            inside += capsule_distance(px, py, *shape) <= 0
    return inside / (SAMPLES * SAMPLES)


def over(dst, src):
    """Source-over compositing of straight-alpha RGBA floats."""
    sr, sg, sb, sa = src
    dr, dg, db, da = dst
    out_a = sa + da * (1 - sa)
    if out_a == 0:
        return (0, 0, 0, 0)
    mix = lambda s, d: (s * sa + d * da * (1 - sa)) / out_a
    return (mix(sr, dr), mix(sg, dg), mix(sb, db), out_a)


def render(state, appearance):
    track = (0, 0, TRACK_W, TRACK_H)
    knob_left = TRACK_W - INSET - KNOB_W if state == "on" else INSET
    knob = (knob_left, INSET, KNOB_W, KNOB_H)
    r, g, b, a = TRACK[(state, appearance)]

    rows = []
    for y in range(TRACK_H):
        row = bytearray()
        for x in range(TRACK_W):
            pixel = (0.0, 0.0, 0.0, 0.0)
            pixel = over(pixel, (r, g, b, a * coverage(x, y, *track)))
            # Soft shadow under the knob, clipped to the track
            d = capsule_distance(x + 0.5, y + 0.5 - 0.5 * SCALE, *knob)
            shadow = 0.12 * max(0.0, min(1.0, 1 - d / (1.5 * SCALE)))
            pixel = over(pixel, (0, 0, 0, shadow * coverage(x, y, *track)))
            pixel = over(pixel, (255, 255, 255, coverage(x, y, *knob)))
            pr, pg, pb, pa = pixel
            row += bytes((round(pr), round(pg), round(pb), round(pa * 255)))
        rows.append(row)
    return rows


def write_png(path, rows):
    height, width = len(rows), len(rows[0]) // 4
    raw = b"".join(b"\x00" + bytes(row) for row in rows)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    for state in ("on", "off"):
        for appearance in ("light", "dark"):
            write_png(os.path.join(here, f"toggle_{state}_{appearance}.png"), render(state, appearance))
