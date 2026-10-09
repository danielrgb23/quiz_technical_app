#!/usr/bin/env python3
"""Gera ícone e splash (paleta pastel): nó da trilha com estrela.

Requer Pillow. Uso: python3 scripts/generate_branding.py
Depois: cd quiz_app && dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "quiz_app" / "assets" / "branding"
PEACH, PEACH_DARK = (246, 169, 122), (233, 139, 90)
CREAM, BROWN = (255, 247, 240), (74, 42, 24)
EDGE = (222, 205, 190)


def star(cx, cy, r_out, r_in, n=5):
    pts = []
    for i in range(n * 2):
        r = r_out if i % 2 == 0 else r_in
        a = -math.pi / 2 + i * math.pi / n
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def node(size, bg, face=CREAM, edge=EDGE):
    """Nó 3D (círculo creme com 'borda' inferior) com estrela marrom."""
    s = size * 4  # supersampling
    img = Image.new("RGBA", (s, s), bg)
    d = ImageDraw.Draw(img)
    r = int(s * 0.30)
    cx, cy = s // 2, int(s * 0.47)
    depth = int(s * 0.04)
    d.ellipse([cx - r, cy - r + depth, cx + r, cy + r + depth], fill=edge)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=face)
    d.polygon(star(cx, cy + s * 0.005, r * 0.62, r * 0.26), fill=BROWN)
    return img.resize((size, size), Image.LANCZOS)


node(1024, PEACH + (255,)).convert("RGB").save(OUT / "icon.png")
# Splash: nó pêssego sobre fundo creme (a cor de fundo vem do pubspec).
node(512, (0, 0, 0, 0), face=PEACH, edge=PEACH_DARK).save(OUT / "splash.png")
print("Branding gerado em", OUT)
