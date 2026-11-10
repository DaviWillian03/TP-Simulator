#!/usr/bin/env python3
"""Nova logo do F1 Guidelines (pedido de 2026-11-10). A ideia vem do lance Verstappen × Norris em Austin 2024: um carro passa
por FORA da linha branca do limite da pista. "Guidelines" = as linhas brancas. Carros genéricos de topo (laranja e azul-marinho,
sem patrocínios nem marcas), texto convertido em contornos (Kanit, OFL) para o SVG não depender de fonte.
Uso: python tools/make_logo_v2.py <pasta_saida> [a|b]   -> gera logo-<opcao>.svg, logo-<opcao>-light.svg, icon-<opcao>.svg"""
import math
import pathlib
import sys

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT_BLACK_IT = ROOT / "design/mockups/fonts/Kanit-BlackItalic.ttf"
FONT_SEMI_IT = ROOT / "design/mockups/fonts/Kanit-SemiBoldItalic.ttf"
ORANGE, ORANGE_D = "#FF8A1F", "#C2560B"
NAVY, NAVY_D = "#2B4C9B", "#16265A"
RED, GOLD = "#E10600", "#F5C542"


def text_path(font_file, text, size, x, y, tracking=0.0):
    font = TTFont(font_file)
    gs, cmap, hmtx = font.getGlyphSet(), font.getBestCmap(), font["hmtx"]
    scale = size / font["head"].unitsPerEm
    pen, cur = SVGPathPen(gs), 0.0
    for ch in text:
        g = cmap[ord(ch)]
        gs[g].draw(TransformPen(pen, (scale, 0, 0, -scale, x + cur, y)))
        cur += hmtx[g][0] * scale + tracking
    return pen.getCommands(), cur - tracking


def bez(p0, p1, p2, p3, t):
    u = 1 - t
    x = u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0]
    y = u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]
    dx = 3 * u * u * (p1[0] - p0[0]) + 6 * u * t * (p2[0] - p1[0]) + 3 * t * t * (p3[0] - p2[0])
    dy = 3 * u * u * (p1[1] - p0[1]) + 6 * u * t * (p2[1] - p1[1]) + 3 * t * t * (p3[1] - p2[1])
    return x, y, math.atan2(dy, dx)


def car(x, y, ang, body, dark, scale=1.0):
    """Carro de fórmula visto de cima, apontando para +x (genérico, sem patrocínios)."""
    s = f'<g transform="translate({x:.1f} {y:.1f}) rotate({math.degrees(ang):.1f}) scale({scale})">'
    for wx, wy in [(15, -13), (15, 13), (-17, -14), (-17, 14)]:  # pneus
        s += f'<rect x="{wx - 6}" y="{wy - 4.5}" width="12" height="9" rx="2.5" fill="#0b0d11"/>'
    s += (f'<rect x="-30" y="-12" width="7" height="24" rx="2" fill="{dark}"/>'  # asa traseira
          f'<path d="M-24 -5 L8 -7 L30 -2.5 L30 2.5 L8 7 L-24 5 Z" fill="{body}"/>'  # corpo
          f'<rect x="31" y="-13" width="6" height="26" rx="2" fill="{dark}"/>'  # asa dianteira
          f'<ellipse cx="-3" cy="0" rx="6" ry="3.6" fill="#0b0d11"/><ellipse cx="-3" cy="0" rx="2.6" ry="1.8" fill="#fff"/>'  # cockpit e capacete
          f'<path d="M-24 -5 L8 -7 L30 -2.5" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="1.2"/></g>')
    return s


def mark(size=200, bg=True):
    """Curva com a linha branca do limite: laranja passa por fora (zona vermelha), azul por dentro (asfalto)."""
    p0, p1, p2, p3 = (30, 176), (30, 86), (86, 30), (176, 30)
    out = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 200 200">'
           '<defs><linearGradient id="bgg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#232838"/><stop offset="1" stop-color="#0a0c10"/></linearGradient>'
           '<clipPath id="rr"><rect width="200" height="200" rx="44"/></clipPath>'
           '<pattern id="kerb" width="14" height="14" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="7" height="14" fill="#fff"/><rect x="7" width="7" height="14" fill="#E10600"/></pattern></defs>')
    out += '<g clip-path="url(#rr)">'
    if bg:
        out += '<rect width="200" height="200" fill="url(#bgg)"/>'
    # zona de escape (fora da linha), com zebra vermelha e branca
    out += ('<path d="M30 176 C30 86 86 30 176 30 L200 30 L200 0 L0 0 L0 176 Z" fill="#B9342B"/>'
            '<path d="M30 176 C30 86 86 30 176 30 L200 30 L200 14 L176 14 C70 14 14 70 14 176 Z" fill="url(#kerb)" opacity=".28"/>')
    out += f'<path d="M{p0[0]} {p0[1]} C{p1[0]} {p1[1]} {p2[0]} {p2[1]} {p3[0]} {p3[1]}" fill="none" stroke="#fff" stroke-width="9" stroke-linecap="round"/>'
    # carros: azul por dentro (atrás), laranja por fora (à frente, passando pela zona de escape)
    bx, by, ba = bez(p0, p1, p2, p3, 0.30)
    out += car(bx - math.sin(ba) * 26, by + math.cos(ba) * 26, ba, NAVY, NAVY_D, 0.78)
    ox, oy, oa = bez(p0, p1, p2, p3, 0.56)
    out += car(ox + math.sin(oa) * 24, oy - math.cos(oa) * 24, oa, ORANGE, ORANGE_D, 0.82)
    out += '</g></svg>'
    return out


def lockup(light=False):
    ink = "#0b0d11" if light else "#FFFFFF"
    sub = "#3a4150" if light else "#C9D0DC"
    d1, w1 = text_path(FONT_BLACK_IT, "F1", 150, 0, 0)
    d2, w2 = text_path(FONT_SEMI_IT, "GUIDELINES", 46, 0, 0, tracking=7)
    m = mark(200)
    inner = m.split(">", 1)[1].rsplit("</svg>", 1)[0]
    width = 200 + 40 + max(w1, w2) + 24
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width:.0f}" height="200" viewBox="0 0 {width:.0f} 200">'
           f'<g>{inner}</g>'
           f'<g transform="translate(240 112)"><path d="{d1}" fill="{ink}"/></g>'
           f'<g transform="translate(244 168)"><path d="{d2}" fill="{sub}"/></g>'
           f'<path d="M244 130 L{244 + w2:.0f} 130" stroke="{RED}" stroke-width="5" stroke-linecap="round" opacity="0"/>'
           f'<defs><linearGradient id="ln" x1="0" x2="1"><stop offset="0" stop-color="{RED}"/><stop offset="1" stop-color="{GOLD}"/></linearGradient></defs>'
           f'<rect x="244" y="124" width="{w2:.0f}" height="5" rx="2.5" fill="url(#ln)"/></svg>')
    return svg


def badge(size=220):
    """Opção B: anel = linha branca do limite; o laranja corta por fora do anel, o azul por dentro."""
    cx = cy = 110
    r = 70
    s = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 220 220"><defs><radialGradient id="g" cx=".5" cy=".4" r=".8"><stop offset="0" stop-color="#2a3042"/><stop offset="1" stop-color="#0a0c10"/></radialGradient></defs>'
         f'<circle cx="110" cy="110" r="106" fill="url(#g)"/><circle cx="110" cy="110" r="{r + 24}" fill="#B9342B" opacity=".9"/><circle cx="110" cy="110" r="{r}" fill="#1b1f2a"/>'
         f'<circle cx="110" cy="110" r="{r}" fill="none" stroke="#fff" stroke-width="8"/>')
    a1, a2 = math.radians(-125), math.radians(-60)
    s += car(cx + (r + 22) * math.cos(math.radians(-80)), cy + (r + 22) * math.sin(math.radians(-80)), math.radians(10), ORANGE, ORANGE_D, 0.62)
    s += car(cx + (r - 20) * math.cos(math.radians(-112)), cy + (r - 20) * math.sin(math.radians(-112)), math.radians(-22), NAVY, NAVY_D, 0.56)
    d1, w1 = text_path(FONT_BLACK_IT, "F1", 64, 0, 0)
    s += f'<g transform="translate({110 - w1 / 2:.1f} 126)"><path d="{d1}" fill="#fff"/></g>'
    d2, w2 = text_path(FONT_SEMI_IT, "GUIDELINES", 13, 0, 0, tracking=2)
    s += f'<g transform="translate({110 - w2 / 2:.1f} 150)"><path d="{d2}" fill="#C9D0DC"/></g></svg>'
    return s


if __name__ == "__main__":
    out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "design/mockups/logo")
    out.mkdir(parents=True, exist_ok=True)
    (out / "logo-a.svg").write_text(lockup(False), encoding="utf-8")
    (out / "logo-a-light.svg").write_text(lockup(True), encoding="utf-8")
    (out / "icon-a.svg").write_text(mark(512), encoding="utf-8")
    (out / "badge-b.svg").write_text(badge(512), encoding="utf-8")
    if "--install" in sys.argv:  # grava nos arquivos usados pelo jogo (logo do menu, logo para fundo claro e ícone do app)
        (ROOT / "game/assets/branding/logo.svg").write_text(lockup(False), encoding="utf-8")
        (ROOT / "game/assets/branding/logo-light.svg").write_text(lockup(True), encoding="utf-8")
        (ROOT / "game/icon.svg").write_text(mark(512), encoding="utf-8")
        print("instalado em game/assets/branding e game/icon.svg")
    print("ok", out)
