"""Protótipo do cenário procedural (estilo ilustração de revista) para os mockups do Marco 3.
A mesma lógica será portada para o Godot (desenho em código, sem imagens externas).

scenery_svg(circuit_json, w, h, weather="dry"|"rain", night=bool) -> SVG
"""
import math
import random

PAL = {
    "day": {"ground": "#e6e4cf", "ink": "#141414", "tree": "#aebf8f", "tree2": "#93a876", "water": "#bccfd6",
            "build": "#d8d1c2", "build2": "#c7bfae", "stand": "#cfc6b4", "track": "#141414", "sand": "#e8d9b0"},
    "night": {"ground": "#1d2436", "ink": "#e9e3d6", "tree": "#2b3a3a", "tree2": "#24332f", "water": "#16213a",
              "build": "#2a3247", "build2": "#323b54", "stand": "#2f374b", "track": "#e9e3d6", "sand": "#2a2a33"},
}
THEME_GROUND = {"desert": "#ecdcb6", "dunes": "#ece0bf", "city": "#e3dfd4", "oldcity": "#e6dcc8", "strip": "#1d2436"}


def fit(points, w, h, margin=34):
    xs, ys = [p[0] for p in points], [p[1] for p in points]
    bw, bh = max(xs) - min(xs), max(ys) - min(ys)
    s = min((w - 2 * margin) / bw, (h - 2 * margin) / bh)
    ox = margin + (w - 2 * margin - bw * s) / 2 - min(xs) * s
    oy = margin + (h - 2 * margin - bh * s) / 2 - min(ys) * s
    return [(x * s + ox, y * s + oy) for x, y in points]


def dist_to_poly(p, pts):
    best = 1e9
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = dx * dx + dy * dy or 1
        t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / L))
        best = min(best, math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy))
    return best


def inside(p, pts):
    c = False
    j = len(pts) - 1
    for i in range(len(pts)):
        if (pts[i][1] > p[1]) != (pts[j][1] > p[1]) and p[0] < (pts[j][0] - pts[i][0]) * (p[1] - pts[i][1]) / (pts[j][1] - pts[i][1] + 1e-9) + pts[i][0]:
            c = not c
        j = i
    return c


def scenery_svg(c, w, h, weather="dry", night=None):
    night = c.get("night", False) if night is None else night
    P = PAL["night" if night else "day"]
    theme = c["scenery"]["theme"]
    lm = c["scenery"]["landmark"]
    rnd = random.Random(c["id"])
    pts = fit(c["points"], w, h)
    ground = P["ground"] if night else THEME_GROUND.get(theme, P["ground"])
    out = [f'<rect width="{w}" height="{h}" fill="{ground}"/>']
    # grade de amostragem: pontos livres (longe da pista)
    free = []
    for gy in range(8, h, 14):
        for gx in range(8, w, 14):
            p = (gx + rnd.uniform(-4, 4), gy + rnd.uniform(-4, 4))
            d = dist_to_poly(p, pts)
            if d > 20:
                free.append((p, d, inside(p, pts)))
    # água
    water_themes = {"lake", "harbor", "marina", "bay", "coast", "river", "dunes"}
    if theme in water_themes:
        if theme == "lake":
            cand = max((f for f in free if f[2]), key=lambda f: f[1], default=max(free, key=lambda f: f[1]))
            (cx, cy), r = cand[0], min(cand[1] - 8, 70)
            blob = " ".join(f"{cx + math.cos(a) * r * (1 + 0.18 * math.sin(3 * a + 1)) * 1.3:.1f},{cy + math.sin(a) * r * (0.75 + 0.1 * math.cos(2 * a)):.1f}" for a in [i * math.pi / 18 for i in range(36)])
            out.append(f'<polygon points="{blob}" fill="{P["water"]}" stroke="{P["ink"]}" stroke-width="1.2"/>')
            for k in range(4):
                yy = cy - r * 0.3 + k * r * 0.2
                out.append(f'<path d="M{cx - r * 0.6:.0f},{yy:.0f} q8,-4 16,0 t16,0" fill="none" stroke="{P["ink"]}" stroke-opacity=".35" stroke-width="1"/>')
            free = [f for f in free if math.hypot(f[0][0] - cx, f[0][1] - cy) > r * 1.4]
        else:
            # faixa de água no lado com mais espaço livre
            sides = {"bottom": sum(1 for f in free if f[0][1] > h * 0.75), "top": sum(1 for f in free if f[0][1] < h * 0.25),
                     "left": sum(1 for f in free if f[0][0] < w * 0.2), "right": sum(1 for f in free if f[0][0] > w * 0.8)}
            side = max(sides, key=sides.get)
            depth = 0.2 if side in ("bottom", "top") else 0.16
            if side == "bottom":
                y0 = h * (1 - depth)
                edge = " ".join(f"{x},{y0 + 6 * math.sin(x / 37):.1f}" for x in range(0, w + 20, 20))
                poly = f"0,{h} {edge} {w},{h}"
                free = [f for f in free if f[0][1] < y0 - 10]
            elif side == "top":
                y0 = h * depth
                edge = " ".join(f"{x},{y0 + 6 * math.sin(x / 37):.1f}" for x in range(0, w + 20, 20))
                poly = f"0,0 {edge} {w},0"
                free = [f for f in free if f[0][1] > y0 + 10]
            elif side == "left":
                x0 = w * depth
                edge = " ".join(f"{x0 + 6 * math.sin(y / 37):.1f},{y}" for y in range(0, h + 20, 20))
                poly = f"0,0 {edge} 0,{h}"
                free = [f for f in free if f[0][0] > x0 + 10]
            else:
                x0 = w * (1 - depth)
                edge = " ".join(f"{x0 + 6 * math.sin(y / 37):.1f},{y}" for y in range(0, h + 20, 20))
                poly = f"{w},0 {edge} {w},{h}"
                free = [f for f in free if f[0][0] < x0 - 10]
            out.append(f'<polygon points="{poly}" fill="{P["water"]}" stroke="{P["ink"]}" stroke-width="1.2"/>')
            for k in range(10):
                if side in ("bottom", "top"):
                    x, y = rnd.uniform(20, w - 40), (rnd.uniform(h * (1 - depth) + 14, h - 10) if side == "bottom" else rnd.uniform(8, h * depth - 14))
                else:
                    x, y = (rnd.uniform(8, w * depth - 30) if side == "left" else rnd.uniform(w * (1 - depth) + 14, w - 30)), rnd.uniform(20, h - 20)
                out.append(f'<path d="M{x:.0f},{y:.0f} q5,-3 10,0 t10,0" fill="none" stroke="{P["ink"]}" stroke-opacity=".3"/>')
                if lm in ("yachts", "hotel", "sea") and k < 6:
                    out.append(f'<path d="M{x + 30:.0f},{y + 4:.0f} l14,0 l-3,4 l-9,0 z" fill="#fff" stroke="{P["ink"]}" stroke-width=".8"/>'
                               f'<path d="M{x + 37:.0f},{y + 4:.0f} l0,-9 l5,8 z" fill="#fff" stroke="{P["ink"]}" stroke-width=".6"/>')
    # elementos espalhados por tema
    trees = theme in {"park", "forest", "lake", "hills", "mountains", "river", "airfield", "prairie"}
    builds = theme in {"city", "oldcity", "harbor", "bay", "strip", "marina", "coast"}
    dense = {"forest": 0.55, "park": 0.45, "lake": 0.3, "hills": 0.25, "mountains": 0.2, "river": 0.3, "prairie": 0.08, "airfield": 0.08}
    for (p, d, ins) in free:
        n = math.sin(p[0] / 61.0 + c["round"]) * math.cos(p[1] / 47.0) + rnd.uniform(-0.3, 0.3)
        if trees and n > 1 - dense.get(theme, 0.2) * 2 and rnd.random() < 0.8:
            r = rnd.uniform(4, 7)
            out.append(f'<circle cx="{p[0]:.1f}" cy="{p[1]:.1f}" r="{r:.1f}" fill="{rnd.choice([P["tree"], P["tree2"]])}" stroke="{P["ink"]}" stroke-width=".8"/>')
        elif builds and d > 26 and n > -0.2 and rnd.random() < 0.55:
            bw, bh = rnd.uniform(7, 14), rnd.uniform(6, 12)
            out.append(f'<rect x="{p[0] + 2:.1f}" y="{p[1] + 2:.1f}" width="{bw:.1f}" height="{bh:.1f}" fill="{P["ink"]}" opacity=".18"/>'
                       f'<rect x="{p[0]:.1f}" y="{p[1]:.1f}" width="{bw:.1f}" height="{bh:.1f}" fill="{rnd.choice([P["build"], P["build2"]])}" stroke="{P["ink"]}" stroke-width=".8"/>')
            if night and rnd.random() < 0.6:
                out.append(f'<rect x="{p[0] + 2:.1f}" y="{p[1] + 2:.1f}" width="2" height="2" fill="#ffd36b"/>')
        elif theme in ("desert", "dunes") and rnd.random() < 0.05:
            out.append(f'<path d="M{p[0]:.0f},{p[1]:.0f} q10,-7 20,0" fill="none" stroke="{P["ink"]}" stroke-opacity=".35"/>')
        elif theme == "mountains" and rnd.random() < 0.03:
            out.append(f'<path d="M{p[0] - 14:.0f},{p[1] + 8:.0f} l14,-20 l14,20" fill="#d9d3c0" stroke="{P["ink"]}" stroke-width="1"/>')
    # arquibancadas ao longo da reta principal (perto da linha de chegada)
    n0 = len(pts)
    for k in (-3, -2, -1, 1, 2):
        a, b = pts[k % n0], pts[(k + 1) % n0]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        cx, cy = (a[0] + b[0]) / 2 + nx * 17, (a[1] + b[1]) / 2 + ny * 17
        ang = math.degrees(math.atan2(dy, dx))
        out.append(f'<g transform="translate({cx:.1f},{cy:.1f}) rotate({ang:.1f})"><rect x="-{L / 2:.1f}" y="-4" width="{L:.1f}" height="8" fill="{P["stand"]}" stroke="{P["ink"]}" stroke-width=".8"/>'
                   f'<line x1="-{L / 2:.1f}" y1="0" x2="{L / 2:.1f}" y2="0" stroke="{P["ink"]}" stroke-opacity=".4"/></g>')
    # marco visual no maior espaço livre
    if free:
        (lx, ly), ld, _ = max(free, key=lambda f: f[1] if 60 < f[0][0] < w - 60 and 50 < f[0][1] < h - 40 else 0)
        out.append(landmark(lm, lx, ly, P, night))
    # pista por cima
    poly = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    out.append(f'<polygon points="{poly}" fill="none" stroke="{P["track"]}" stroke-width="9" stroke-linejoin="round"/>')
    if night:
        out.append(f'<polygon points="{poly}" fill="none" stroke="#ffd36b" stroke-opacity=".25" stroke-width="18" stroke-linejoin="round"/>')
    if weather == "rain":
        out.append(f'<rect width="{w}" height="{h}" fill="#1f6fe5" opacity=".08"/>')
        for i in range(0, w + h, 22):
            for j in range(0, h, 38):
                out.append(f'<line x1="{i - j * 0.36:.0f}" y1="{j}" x2="{i - j * 0.36 - 5:.0f}" y2="{j + 14}" stroke="#1f6fe5" stroke-opacity=".35" stroke-width="1.4"/>')
    return f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg">{"".join(out)}</svg>'


def landmark(kind, x, y, P, night):
    ink = P["ink"]
    if kind == "skyline":
        parts = []
        for i, (bw, bh) in enumerate([(10, 34), (8, 48), (12, 28), (9, 56), (11, 38), (8, 30)]):
            parts.append(f'<rect x="{x - 30 + i * 11}" y="{y - bh}" width="{bw}" height="{bh}" fill="#cfc7b6" stroke="{ink}" stroke-width=".9"/>')
        return "".join(parts) + f'<text x="{x - 30}" y="{y + 12}" font-family="ArchivoN" font-size="9" fill="{ink}" opacity=".7">SÃO PAULO</text>'
    if kind == "ferris_wheel":
        spokes = "".join(f'<line x1="{x}" y1="{y}" x2="{x + 22 * math.cos(a):.1f}" y2="{y + 22 * math.sin(a):.1f}" stroke="{ink}" stroke-width=".7"/>' for a in [i * math.pi / 6 for i in range(12)])
        return f'<circle cx="{x}" cy="{y}" r="22" fill="none" stroke="{ink}" stroke-width="1.6"/>{spokes}<path d="M{x - 12},{y + 30} L{x},{y} L{x + 12},{y + 30}" fill="none" stroke="{ink}" stroke-width="1.4"/>'
    if kind == "sphere":
        return (f'<circle cx="{x}" cy="{y}" r="26" fill="#ffd36b" opacity=".25"/><circle cx="{x}" cy="{y}" r="18" fill="#f5a623" stroke="{ink}" stroke-width="1"/>'
                f'<path d="M{x - 9},{y - 3} q9,8 18,0" fill="none" stroke="#141414" stroke-width="1.5"/>')
    if kind == "yachts":
        return f'<text x="{x - 24}" y="{y}" font-family="ArchivoBlack" font-size="11" fill="{ink}" opacity=".6">PORTO HÉRCULES</text>'
    if kind in ("mountains", "hills"):
        return (f'<path d="M{x - 50},{y + 20} l28,-38 l18,22 l20,-30 l34,46 z" fill="#d9d3c0" stroke="{ink}" stroke-width="1.2"/>'
                f'<path d="M{x - 2},{y - 26} l6,8 l-4,-1 z" fill="#fff"/>')
    if kind == "stadium":
        return f'<ellipse cx="{x}" cy="{y}" rx="30" ry="18" fill="#d8d1c2" stroke="{ink}" stroke-width="1.4"/><ellipse cx="{x}" cy="{y}" rx="18" ry="9" fill="#aebf8f" stroke="{ink}"/>'
    if kind == "tower":
        return f'<path d="M{x},{y - 40} l-6,40 l12,0 z" fill="#E10600" stroke="{ink}"/><circle cx="{x}" cy="{y - 40}" r="5" fill="#fff" stroke="{ink}"/>'
    if kind == "hangars":
        return "".join(f'<path d="M{x - 40 + i * 28},{y + 10} q12,-24 24,0 z" fill="#d8d1c2" stroke="{ink}"/>' for i in range(3))
    if kind == "biosphere":
        return f'<circle cx="{x}" cy="{y}" r="20" fill="none" stroke="{ink}" stroke-width="1.4"/><path d="M{x - 20},{y} h40 M{x},{y - 20} v40 M{x - 14},{y - 14} l28,28 M{x + 14},{y - 14} l-28,28" stroke="{ink}" stroke-width=".7"/>'
    if kind == "flame_towers":
        return "".join(f'<path d="M{x - 18 + i * 14},{y + 10} q-6,-22 5,-40 q9,18 5,40 z" fill="#9fb4c9" stroke="{ink}"/>' for i in range(3))
    if kind == "hotel":
        return f'<path d="M{x - 40},{y} q40,-28 80,0 l0,10 l-80,0 z" fill="#d8d1c2" stroke="{ink}" stroke-width="1.2"/>'
    if kind == "lights":
        return "".join(f'<circle cx="{x - 40 + i * 16}" cy="{y}" r="3" fill="#ffd36b"/><circle cx="{x - 40 + i * 16}" cy="{y}" r="8" fill="#ffd36b" opacity=".2"/>' for i in range(6))
    if kind == "towers":
        return "".join(f'<rect x="{x - 20 + i * 14}" y="{y - 46}" width="10" height="46" fill="#cfc7b6" stroke="{ink}"/>' for i in range(4))
    if kind == "grandstand_wings":
        return f'<path d="M{x - 30},{y} q30,-26 60,0" fill="none" stroke="{ink}" stroke-width="2"/><rect x="{x - 30}" y="{y}" width="60" height="8" fill="#cfc6b4" stroke="{ink}"/>'
    return ""
