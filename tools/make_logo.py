"""Gera a logo do F1 Guidelines em SVG (texto convertido em contornos com a fonte Inter, OFL-1.1).

Requer: fonttools (pip install fonttools) e a fonte Inter instalada em /usr/share/fonts/opentype/inter/.
Uso: python tools/make_logo.py <pasta_saida>
Gera: icon.svg (ícone do app, com fundo), logo.svg (para fundo escuro) e logo-light.svg (para fundo claro).
Copie icon.svg para game/icon.svg e os logos para game/assets/branding/.
"""
import math
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

OUT = sys.argv[1]
INTER = "/usr/share/fonts/opentype/inter/"

GRAD_A = "#FFC400"   # âmbar
GRAD_B = "#FF3D2E"   # vermelho


def text_path(font_file, text, size, x, y, tracking=0.0):
    """Converte texto em um único 'd' de path SVG. (x, y) = início da linha de base."""
    font = TTFont(font_file)
    gs = font.getGlyphSet()
    cmap = font.getBestCmap()
    upm = font["head"].unitsPerEm
    hmtx = font["hmtx"]
    scale = size / upm
    pen = SVGPathPen(gs)
    cursor = 0.0
    for ch in text:
        gname = cmap[ord(ch)]
        # y invertido: fonte tem y para cima, SVG para baixo
        tpen = TransformPen(pen, (scale, 0, 0, -scale, x + cursor, y))
        gs[gname].draw(tpen)
        cursor += hmtx[gname][0] * scale + tracking * size
    width = cursor - tracking * size
    return pen.getCommands(), width


def racing_line_points(cx, cy, r, swing, a0, a1, n=140):
    """Linha de corrida: por fora na entrada, por dentro no ápice (180°), por fora na saída."""
    pts = []
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        rr = r - swing * math.cos(math.radians(a - 180))
        pts.append((cx + rr * math.cos(math.radians(a)), cy + rr * math.sin(math.radians(a))))
    return pts


def arc_d(cx, cy, r, a0, a1, sweep):
    """Arco SVG de a0 a a1 (graus). sweep=0: sentido anti-horário na tela."""
    x0, y0 = cx + r * math.cos(math.radians(a0)), cy + r * math.sin(math.radians(a0))
    x1, y1 = cx + r * math.cos(math.radians(a1)), cy + r * math.sin(math.radians(a1))
    span = (a0 - a1) % 360 if sweep == 0 else (a1 - a0) % 360
    large = 1 if span > 180 else 0
    return f"M{x0:.1f},{y0:.1f} A{r},{r} 0 {large},{sweep} {x1:.1f},{y1:.1f}"


def mark(prefix):
    """Símbolo 'G' formado por uma curva de pista com a linha de corrida (caixa 512x512)."""
    cx, cy, R, half = 256, 250, 150, 50
    a_start, a_end = -40, -345  # sentido anti-horário na tela: topo-direita → esquerda → baixo → direita
    band = arc_d(cx, cy, R, a_start, 6, 0)
    edge_out = arc_d(cx, cy, R + half, a_start, 6, 0)
    edge_in = arc_d(cx, cy, R - half, a_start, 6, 0)
    kerb = arc_d(cx, cy, R - half + 7, 238, 122, 0)
    pts = racing_line_points(cx, cy, R, 32, a_start, a_end)
    line_d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    ex, ey = pts[-1]
    bar_x = 292
    line_d += f" L{bar_x},{ey:.1f}"
    return f"""
  <defs>
    <linearGradient id="{prefix}rl" x1="380" y1="90" x2="300" y2="420" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="{GRAD_A}"/>
      <stop offset="1" stop-color="{GRAD_B}"/>
    </linearGradient>
  </defs>
  <path d="{band}" fill="none" stroke="#2B3954" stroke-width="{2*half}" stroke-linecap="butt"/>
  <path d="{edge_out}" fill="none" stroke="#E8EEF8" stroke-width="5" stroke-opacity="0.85"/>
  <path d="{edge_in}" fill="none" stroke="#E8EEF8" stroke-width="5" stroke-opacity="0.85"/>
  <path d="{kerb}" fill="none" stroke="#FFFFFF" stroke-width="14"/>
  <path d="{kerb}" fill="none" stroke="#E10600" stroke-width="14" stroke-dasharray="13 13"/>
  <path d="{line_d}" fill="none" stroke="url(#{prefix}rl)" stroke-width="30"
        stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="{bar_x}" cy="{ey:.1f}" r="27" fill="#FFFFFF" stroke="{GRAD_B}" stroke-width="9"/>
"""


def icon_svg():
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="512" y2="512" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#16233D"/>
      <stop offset="1" stop-color="#070C17"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="112" fill="url(#bg)"/>
  <g transform="translate(256 256) scale(0.86) translate(-256 -250)">{mark("i_")}</g>
</svg>
"""


def logo_svg(f1_color="#FFFFFF", sub_color="#C9D4E8"):
    # Marca à esquerda (512 -> 420 px), nome à direita.
    f1_d, f1_w = text_path(INTER + "InterDisplay-BlackItalic.otf", "F1", 230, 470, 245)
    gl_d, gl_w = text_path(INTER + "Inter-ExtraBold.otf", "GUIDELINES", 76, 478, 345, tracking=0.16)
    width = int(max(470 + f1_w, 478 + gl_w) + 40)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="420" viewBox="0 0 {width} 420">
  <defs>
    <linearGradient id="txt" x1="470" y1="0" x2="{width}" y2="0" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="{GRAD_A}"/>
      <stop offset="1" stop-color="{GRAD_B}"/>
    </linearGradient>
  </defs>
  <g transform="translate(0 0) scale(0.82)">{mark("l_")}</g>
  <path d="{f1_d}" fill="{f1_color}"/>
  <rect x="478" y="268" width="{gl_w:.0f}" height="9" rx="4.5" fill="url(#txt)"/>
  <path d="{gl_d}" fill="{sub_color}"/>
</svg>
"""


with open(f"{OUT}/icon.svg", "w") as f:
    f.write(icon_svg())
with open(f"{OUT}/logo.svg", "w") as f:
    f.write(logo_svg())
with open(f"{OUT}/logo-light.svg", "w") as f:  # para fundo claro (direção Paddock)
    f.write(logo_svg("#141414", "#141414"))
print("ok")
