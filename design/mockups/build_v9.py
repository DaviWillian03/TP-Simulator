"""Campanha — Carro (árvore de P&D, inspirada na do F1 2017) e Fábrica (investimento em estrutura).
Uso: python design/mockups/build_v9.py   (gera v9-*.html nesta pasta)
Equipe criada de exemplo (Aurora Racing, fictícia). Custos, prazos, notas e níveis são EXEMPLOS PROVISÓRIOS.
Estrutura (decisões do usuário): 4 departamentos (Motor, Aerodinâmica, Chassi, Durabilidade), cada um com
4 categorias em braços (as duas últimas sempre "Eficiência do departamento" e "Controle de qualidade");
nós menor (hexágono) / importante (quadrado) / definitiva (quadrado grande); pago com dinheiro do
orçamento; leva dias de calendário; projetos simultâneos limitados pela fábrica; carro atual × carro do
ano seguinte em abas, com a mesma reserva de dinheiro e de projetos.
"""
import math
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v6 as S6  # noqa: E402

HERE = B.HERE
ico = V.ico
C1, C2 = S6.C1, S6.C2
ARM = ["#ffd24a", "#3c9d5d", "#5c93ea", "#ff6a5a"]  # cima, direita, baixo, esquerda
K = 0.83  # escala da árvore (cabe entre a barra de navegação e a base)
DIRS = [((0, -1), (1, 0)), ((1, 0), (0, 1)), ((0, 1), (-1, 0)), ((-1, 0), (0, -1))]

CSS = S6.CSS + """
.rail{position:absolute;left:44px;top:150px;width:196px;display:flex;flex-direction:column;gap:8px}
.dep{height:84px;border-radius:18px;background:rgba(255,255,255,.07);padding:0 14px;display:flex;align-items:center;gap:12px;position:relative}
.dep.on{background:#f3f4f6;color:#11141a}.dep.off{opacity:.45}
.dep b{display:block;font-size:17px;font-weight:900;line-height:1.1}.dep small{font-size:12px;color:#a8b0bd;font-weight:700}.dep.on small{color:#4b5260}
.dep .ring{flex:none}
.leg{position:absolute;left:44px;bottom:26px;width:196px;border-radius:18px;background:rgba(255,255,255,.05);padding:12px 14px;font-size:13px;color:#c3c9d3}
.leg div{display:flex;align-items:center;gap:10px;height:30px}
.chipm small{margin-right:8px}
.rp{position:absolute;right:44px;top:96px;width:384px}
.dh h2{font-size:30px;font-weight:900;line-height:1}.dh p{font-size:13px;color:#a8b0bd;line-height:1.45;margin-top:6px}
.cat{display:flex;align-items:center;gap:10px;height:32px;font-size:15px;font-weight:700;border-bottom:1px solid rgba(255,255,255,.07)}
.cat .c{flex:1}.cat small{color:#a8b0bd;font-weight:700;font-size:13px}
.nodecard{border-radius:20px;background:#f3f4f6;color:#11141a;padding:12px 16px 12px 22px;position:relative;margin-top:8px}
.nodecard:before{content:"";position:absolute;left:0;top:0;bottom:0;width:7px;background:#E10600;border-radius:20px 0 0 20px}
.nodecard .k{font-size:12px;letter-spacing:2.5px;color:#4b5260;font-weight:700}.nodecard h3{font-size:21px;font-weight:900;line-height:1.1;margin:2px 0 4px}
.nodecard p{font-size:13px;color:#4b5260;line-height:1.4}
.facts{display:flex;gap:8px;margin:8px 0 10px}.facts div{flex:1;background:#e3e6eb;border-radius:12px;padding:6px 10px;font-size:12px;color:#4b5260;line-height:1.2}.facts b{display:block;font-size:17px;color:#11141a;font-weight:900}
.slots{display:flex;gap:8px;margin-top:10px}.slot{flex:1;height:62px;border-radius:14px;background:rgba(255,255,255,.07);padding:8px 10px;font-size:12px;position:relative}
.slot b{display:block;font-size:13px;font-weight:900;line-height:1.2}.slot small{color:#a8b0bd;font-weight:700}.slot.free{border:2px dashed rgba(255,255,255,.18);background:none;display:grid;place-items:center;color:#8f98a7;font-weight:700;font-size:13px}
.slot i{position:absolute;left:10px;right:10px;bottom:8px;height:6px;border-radius:3px;background:rgba(255,255,255,.12)}.slot i s{position:absolute;inset:0 auto 0 0;border-radius:3px;display:block}
.seg2{display:flex;background:rgba(255,255,255,.07);border-radius:22px;padding:4px;gap:4px}.seg2 span{height:38px;padding:0 16px;border-radius:19px;display:grid;place-items:center;font-size:14px;font-weight:700;color:#c3c9d3}.seg2 span.on{background:#f3f4f6;color:#11141a}
.fc{position:absolute;width:574px;height:252px;border-radius:22px;background:rgba(255,255,255,.06);padding:18px 22px}
.fc .hd{display:flex;align-items:center;gap:14px}.fc .ic{width:52px;height:52px;border-radius:50%;display:grid;place-items:center;flex:none}
.fc h3{font-size:22px;font-weight:900;line-height:1.05}.fc .sub{font-size:12px;color:#a8b0bd;font-weight:700;letter-spacing:1.5px}
.lv{display:flex;gap:5px;margin-left:auto}.lv i{width:26px;height:10px;border-radius:5px;background:rgba(255,255,255,.14)}.lv i.f{background:#f3f4f6}.lv i.b{background:repeating-linear-gradient(135deg,#ffd24a 0 6px,#8a6f00 6px 12px)}
.cmp{display:flex;gap:12px;margin-top:14px}.cmp>div{flex:1;border-radius:14px;padding:10px 14px;font-size:14px;line-height:1.45}.cmp .now{background:rgba(255,255,255,.07)}.cmp .nx{background:rgba(60,157,93,.18)}
.cmp small{display:block;font-size:11px;letter-spacing:2px;color:#a8b0bd;font-weight:700}.cmp b{font-weight:900}
.fc .ft{position:absolute;left:22px;right:22px;bottom:16px;display:flex;align-items:center;gap:14px}
.fc .ft .cost{font-size:13px;color:#c3c9d3;line-height:1.35}.fc .ft .cost b{color:#fff;font-size:17px;font-weight:900}
.btn2.ghost{background:#e3e6eb}
.btn2{margin-left:auto;height:48px;padding:0 22px;border-radius:14px;background:#f3f4f6;color:#11141a;display:flex;align-items:center;font-size:16px;font-weight:900;letter-spacing:.5px}
.btn2.red{background:#E10600;color:#fff;clip-path:polygon(0 0,calc(100% - 14px) 0,100% 14px,100% 100%,0 100%)}
.btn2.dis{background:rgba(255,255,255,.1);color:#8f98a7}
.build{margin-left:auto;width:230px}.build .prog{margin:6px 0 4px}
"""

# ---------------------------------------------------------------- geometria da árvore -----
# (distância ao centro, deslocamento lateral, tipo, índice do pai); pai -1 = hub
ARM_NODES = [
    [(100, 0, "m", -1), (142, -46, "m", 0), (142, 46, "m", 0), (184, 0, "i", 0), (226, -46, "m", 3), (226, 46, "m", 3), (268, 0, "d", 3)],
    [(100, 0, "m", -1), (142, -46, "m", 0), (142, 46, "m", 0), (184, 0, "i", 0), (226, 0, "m", 3), (268, 0, "d", 4)],
    [(100, 0, "m", -1), (142, -40, "m", 0), (142, 40, "m", 0), (190, 0, "i", 0), (240, 0, "d", 3)],
    [(100, 0, "m", -1), (142, -40, "m", 0), (142, 40, "m", 0), (190, 0, "i", 0), (240, 0, "d", 3)],
]


def hexagon(x, y, r):
    pts = " ".join(f"{x + r * math.cos(math.radians(60 * k + 30)):.1f},{y + r * math.sin(math.radians(60 * k + 30)):.1f}" for k in range(6))
    return pts


def node(x, y, kind, state, color, sel=False, days=None):
    """state: done | now | open | lock"""
    fill = {"done": color, "now": "#0b0c0f", "open": "#0b0c0f", "lock": "#0b0c0f"}[state]
    stroke = {"done": color, "now": color, "open": "#eef0f3", "lock": "#4b5260"}[state]
    ink = "#11141a" if state == "done" else ("#eef0f3" if state != "lock" else "#4b5260")
    sw = 2.4
    out = ""
    if sel:
        out += f'<circle cx="{x}" cy="{y}" r="{31 if kind == "d" else 26}" fill="none" stroke="#fff" stroke-width="2.4" stroke-dasharray="4 5"/>'
    if kind == "m":
        out += f'<polygon points="{hexagon(x, y, 16)}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
    elif kind == "i":
        out += f'<rect x="{x - 15}" y="{y - 15}" width="30" height="30" rx="6" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
    else:
        out += (f'<rect x="{x - 21}" y="{y - 21}" width="42" height="42" rx="8" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
                f'<rect x="{x - 15}" y="{y - 15}" width="30" height="30" rx="5" fill="none" stroke="{stroke}" stroke-width="1.4" opacity=".7"/>')
    if state == "done":
        out += f'<path d="M{x - 6} {y}l4 4 8-8" fill="none" stroke="{ink}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
    elif state == "now":
        a = 0.62  # progresso
        r = 22 if kind != "d" else 28
        c = 2 * math.pi * r
        out += (f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="rgba(255,255,255,.14)" stroke-width="4"/>'
                f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="{color}" stroke-width="4" stroke-linecap="round" stroke-dasharray="{c * a:.1f} {c:.1f}" transform="rotate(-90 {x} {y})"/>'
                f'<text x="{x}" y="{y + 5}" text-anchor="middle" font-size="13" font-weight="900" fill="#eef0f3">{days}d</text>')
    elif state == "lock":
        out += f'<rect x="{x - 4.5}" y="{y - 1}" width="9" height="7" rx="1.5" fill="{stroke}"/><path d="M{x - 3} {y - 1}v-2a3 3 0 0 1 6 0v2" fill="none" stroke="{stroke}" stroke-width="1.6"/>'
    else:
        out += f'<circle cx="{x}" cy="{y}" r="2.6" fill="{ink}"/>'
    return out


def tree(cx, cy, states, sel, hub_title, hub_sub, locked=False, hub_color="#E10600"):
    """states[arm] = lista de estados por nó; sel = (arm, índice) ou None."""
    s = f'<svg style="position:absolute;left:0;top:0" width="1280" height="720" viewBox="0 0 1280 720">'
    # diagonais (outros departamentos) como na árvore do F1 2017
    for k, (dx, dy) in enumerate([(1, -1), (1, 1), (-1, 1), (-1, -1)]):
        s += f'<line x1="{cx + dx * 62}" y1="{cy + dy * 62}" x2="{cx + dx * 150}" y2="{cy + dy * 150}" stroke="rgba(255,106,90,.45)" stroke-width="2"/>'
    s += f'<circle cx="{cx}" cy="{cy}" r="94" fill="none" stroke="{hub_color}" stroke-opacity=".28" stroke-width="10"/>'
    s += f'<circle cx="{cx}" cy="{cy}" r="64" fill="#0f1116" stroke="{hub_color if not locked else "#4b5260"}" stroke-width="3"/>'
    s += f'<text x="{cx}" y="{cy - 4}" text-anchor="middle" font-size="16" font-weight="900" fill="#eef0f3">{hub_title}</text>'
    s += f'<text x="{cx}" y="{cy + 16}" text-anchor="middle" font-size="12" font-weight="700" fill="#a8b0bd">{hub_sub}</text>'
    for a in range(4):
        (dx, dy), (lx, ly) = DIRS[a]
        col = ARM[a] if not locked else "#4b5260"
        pts = [(cx + (dx * d + lx * l) * K, cy + (dy * d + ly * l) * K) for d, l, _, _ in ARM_NODES[a]]
        for i, (d, l, kind, par) in enumerate(ARM_NODES[a]):
            px, py = (cx + dx * 64, cy + dy * 64) if par < 0 else pts[par]
            done = states[a][i] in ("done", "now")
            s += f'<line x1="{px}" y1="{py}" x2="{pts[i][0]}" y2="{pts[i][1]}" stroke="{col if done else "rgba(255,255,255,.28)"}" stroke-width="{3 if done else 2}"/>'
        for i, (d, l, kind, par) in enumerate(ARM_NODES[a]):
            st = states[a][i]
            s += node(pts[i][0], pts[i][1], kind, st, col, sel == (a, i), days=5 if st == "now" else None)
    return s + "</svg>"


def ring(pct, color, size=44, label=""):
    r = size / 2 - 4
    c = 2 * math.pi * r
    return (f'<svg class="ring" width="{size}" height="{size}" viewBox="0 0 {size} {size}"><circle cx="{size / 2}" cy="{size / 2}" r="{r}" fill="none" stroke="rgba(120,130,150,.35)" stroke-width="4"/>'
            f'<circle cx="{size / 2}" cy="{size / 2}" r="{r}" fill="none" stroke="{color}" stroke-width="4" stroke-linecap="round" stroke-dasharray="{c * pct:.1f} {c:.1f}" transform="rotate(-90 {size / 2} {size / 2})"/>'
            f'<text x="{size / 2}" y="{size / 2 + 4}" text-anchor="middle" font-size="11" font-weight="900" fill="currentColor">{label}</text></svg>')


# ---------------------------------------------------------------- elementos comuns --------
def topbar(title, sub, chips, tabs=None):
    t = (f'<div class="seg2" style="margin-left:18px">{"".join(f"<span class=\"{c}\">{n}</span>" for n, c in tabs)}</div>' if tabs else "")
    cs = "".join(f'<div class="chipm"><div><small>{k}</small>{v}</div></div>' for k, v in chips)
    return (f'<div class="top"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span>'
            f'<svg width="46" height="46" viewBox="0 0 24 24"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/></svg>'
            f'<div class="tm"><b>{sub}</b><h1>{title}</h1></div>{t}<div style="margin-left:auto;display:flex;gap:10px">{cs}</div></div>')


def nav(on):
    items = ["Início", "Campeonatos", "Pilotos", "Carro", "Fábrica", "Finanças"]
    return '<div class="nav">' + "".join(f'<span class="{"on" if k == on else ""}">{i}</span>' for k, i in enumerate(items)) + "</div>"


def rail(active, locked=(0,)):
    deps = [("Motor", "Potência e consumo", "#ff6a5a"), ("Aerodinâmica", "Pressão e arrasto", "#ffd24a"), ("Chassi", "Mecânica e peso", "#5c93ea"), ("Durabilidade", "Confiabilidade", "#3c9d5d")]
    pct = [0, 0.30, 0.18, 0.40]
    out = ""
    for i, (n, d, c) in enumerate(deps):
        lock = i in locked
        cls = "dep" + (" on" if i == active else "") + (" off" if lock else "")
        r = ring(pct[i], c, 44, "" if lock else f"{round(pct[i] * 100)}") if not lock else ico("lock", 26, "#c3c9d3", 2.2)
        out += f'<div class="{cls}">{r}<div><b>{n}</b><small>{"Motor do fornecedor" if lock else d}</small></div></div>'
    return f'<div class="rail">{out}</div>'


LEGEND = f'''<div class="leg"><div class="lbl" style="margin:0 0 2px">LEGENDA</div>
<div><svg width="22" height="22"><polygon points="{hexagon(11, 11, 9)}" fill="none" stroke="#eef0f3" stroke-width="2"/></svg>Menor</div>
<div><svg width="22" height="22"><rect x="3" y="3" width="16" height="16" rx="4" fill="none" stroke="#eef0f3" stroke-width="2"/></svg>Importante</div>
<div><svg width="22" height="22"><rect x="2" y="2" width="18" height="18" rx="4" fill="none" stroke="#eef0f3" stroke-width="2"/><rect x="6" y="6" width="10" height="10" rx="2" fill="none" stroke="#eef0f3" stroke-width="1.4"/></svg>Definitiva</div></div>'''


def categories(names, done, tot, colors):
    out = ""
    for n, d, t, c in zip(names, done, tot, colors):
        out += f'<div class="cat">{ring(d / t, c, 30)}<span class="c">{n}</span><small>{d}/{t}</small></div>'
    return out


def slots(items):
    out = ""
    for it in items:
        if it is None:
            out += '<div class="slot free">+ Livre</div>'
        else:
            n, d, p, c = it
            out += f'<div class="slot"><b>{n}</b><small>{d}</small><i><s style="width:{p}%;background:{c}"></s></i></div>'
    return out


# ---------------------------------------------------------------- telas --------------------
def arvore():
    states = [
        ["done", "done", "done", "done", "now", "open", "lock"],
        ["done", "done", "open", "open", "lock", "lock"],
        ["done", "open", "lock", "lock", "lock"],
        ["open", "lock", "lock", "lock", "lock"],
    ]
    cats = categories(["Pressão aerodinâmica", "Arrasto", "Eficiência do departamento", "Controle de qualidade"], [4, 2, 1, 0], [7, 6, 5, 5], ARM)
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 55% at 40% 60%,{C1}44,transparent 70%)"></div>
{topbar("CARRO · DESENVOLVIMENTO", "AURORA RACING · 9 MAR", [("CAIXA", "US$ 176 mi"), ("PROJETOS", "2 / 3")], [("Carro 2026", "on"), ("Carro 2027", "")])}
{nav(3)}
<div style="position:absolute;right:44px;top:96px;width:384px;height:36px;display:flex;justify-content:flex-end"><div class="seg2" style="height:44px"><span>Essencial</span><span class="on">Avançado</span></div></div>
{rail(1)}{LEGEND}
{tree(545, 432, states, (0, 5), "AERODINÂMICA", "7 / 23 · 30%")}
<div class="rp" style="top:150px"><div class="dh"><h2>AERODINÂMICA</h2><p>Pressão = curvas mais rápidas · menos arrasto = retas mais rápidas.</p></div>
<div style="margin-top:8px">{cats}</div>
<div class="nodecard"><div class="k">NÓ IMPORTANTE · PRESSÃO AERODINÂMICA</div><h3>Assoalho com túneis v2</h3>
<p>Nova geometria do assoalho: +0,40 na nota do carro (cerca de 0,05 s por volta).</p>
<div class="facts"><div><b>US$ 18 mi</b>custo</div><div><b>7 dias</b>prazo (túnel −16%)</div><div><b>74%</b>chance de acerto</div></div>
<div style="display:flex;gap:10px"><div class="btn2 red" style="flex:1;height:48px;justify-content:center;margin:0">INICIAR PROJETO</div><div class="btn2 ghost" style="height:48px">Sugerir</div></div></div>
<div class="lbl" style="margin:8px 0 0">PROJETOS EM ANDAMENTO · 2 DE 3</div>
<div class="slots">{slots([("Assoalho v1", "Aero · 5 dias", 62, ARM[0]), ("Câmbio leve", "Chassi · 9 dias", 30, ARM[2]), None])}</div></div>
<div class="note" style="left:260px;bottom:6px;width:560px">EXEMPLO · VALORES PROVISÓRIOS · MOTOR APAGADO = MOTOR DO FORNECEDOR</div></div>'''
    return V.page("V9 · Carro · árvore de P&D", CSS, body)


def arvore_essencial():
    states = [
        ["done", "done", "done", "open", "lock", "lock", "lock"],
        ["done", "open", "open", "lock", "lock", "lock"],
        ["open", "open", "lock", "lock", "lock"],
        ["now", "lock", "lock", "lock", "lock"],
    ]
    cats = categories(["Aderência mecânica", "Peso e estrutura", "Eficiência do departamento", "Controle de qualidade"], [3, 1, 0, 0], [7, 6, 5, 5], ARM)
    focus = "".join(f'<span class="{c}">{n}</span>' for n, c in [("Equilibrado", "on"), ("Aero", ""), ("Chassi", ""), ("Durab.", "")])
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 55% at 40% 60%,{C1}44,transparent 70%)"></div>
{topbar("CARRO · DESENVOLVIMENTO", "AURORA RACING · 9 MAR", [("CAIXA", "US$ 176 mi"), ("PROJETOS", "1 / 3")], [("Carro 2026", ""), ("Carro 2027", "on")])}
{nav(3)}
<div style="position:absolute;right:44px;top:96px;width:384px;height:36px;display:flex;justify-content:flex-end"><div class="seg2" style="height:44px"><span class="on">Essencial</span><span>Avançado</span></div></div>
{rail(2)}{LEGEND}
{tree(545, 432, states, None, "CHASSI", "4 / 23 · 17%", hub_color="#5c93ea")}
<div class="rp" style="top:150px"><div class="dh"><h2>CHASSI · 2027</h2><p>Carro do ano seguinte: mesmo dinheiro e mesmos projetos do carro atual.</p></div>
<div style="margin-top:8px">{cats}</div>
<div class="nodecard" style="padding-bottom:14px"><div class="k">DIRETOR TÉCNICO DECIDE</div><h3>Foco do desenvolvimento</h3>
<p>O diretor escolhe e paga os projetos dentro do teto de gasto. Toque num nó para assumir.</p>
<div class="seg2" style="margin:10px 0;background:#e3e6eb;width:100%">{focus.replace('class="on"', 'class="on" style="background:#11141a;color:#fff"').replace('<span class="">', '<span style="color:#4b5260">')}</div>
<div class="facts" style="margin-bottom:0"><div><b>US$ 40 mi</b>teto por mês</div><div><b>30%</b>para o carro 2027</div><div><b>Auto</b>fila de projetos</div></div></div>
<div class="lbl" style="margin:8px 0 0">PROJETOS EM ANDAMENTO · 1 DE 3</div>
<div class="slots">{slots([("Rigidez", "Durab. · 11 dias", 18, ARM[3]), None, None])}</div></div>
<div class="note" style="left:260px;bottom:6px;width:560px">EXEMPLO · ESSENCIAL: O DIRETOR ESCOLHE OS PROJETOS (TROCÁVEL)</div></div>'''
    return V.page("V9 · Carro · modo Essencial / carro do ano seguinte", CSS, body)


def fabrica():
    def card(x, y, icon, color, name, sub, lv, building, now, nxt, cost, days, upkeep, btn):
        pips = "".join(f'<i class="{"f" if i < lv else ("b" if i == lv and building else "")}"></i>' for i in range(5))
        foot = (f'<div class="build"><div style="font-size:13px;color:#ffd24a;font-weight:900">EM OBRAS · NÍVEL {lv + 1} · {days} DIAS</div><div class="prog"><i style="width:40%;background:#ffd24a"></i></div></div>'
                if building else
                f'<div class="cost"><b>US$ {cost} mi</b> · {days} dias<br>manutenção +US$ {upkeep} mi por corrida</div><div class="btn2 {"red" if btn == "ok" else "dis"}">{"MELHORAR" if btn == "ok" else "NÍVEL MÁXIMO" if btn == "max" else "SEM CAIXA"}</div>')
        nx = "" if btn == "max" and not building else f'<div class="nx"><small>NÍVEL {lv + 1}</small>{nxt}</div>'
        return (f'<div class="fc" style="left:{x}px;top:{y}px"><div class="hd"><span class="ic" style="background:{color}33">{ico(icon, 28, color, 2.2)}</span>'
                f'<div><div class="sub">{sub}</div><h3>{name}</h3></div><div class="lv">{pips}</div></div>'
                f'<div class="cmp"><div class="now"><small>AGORA · NÍVEL {lv}</small>{now}</div>{nx}</div><div class="ft">{foot}</div></div>')

    cards = (card(44, 150, "bolt", "#5c93ea", "Túnel de vento e CFD", "AERODINÂMICA", 3, False,
                  "<b>−16%</b> nos dias dos nós de aero<br><b>74%</b> de chance de acerto", "<b>−24%</b> nos dias<br><b>79%</b> de acerto", "38", "45", "1,5", "ok")
             + card(662, 150, "clock", "#ffd24a", "Simulador e centro de dados", "TREINOS E PILOTOS", 2, False,
                    "<b>+10%</b> no acerto dos treinos<br>piloto se adapta em <b>3 dias</b>", "<b>+15%</b> no acerto<br>adaptação em <b>2 dias</b>", "26", "35", "1,0", "ok")
             + card(44, 414, "swap", "#3c9d5d", "Fábrica de peças e qualidade", "PROJETOS E CONFIABILIDADE", 4, False,
                    "<b>4</b> projetos ao mesmo tempo<br>peças com defeito: <b>6%</b>", "<b>5</b> projetos<br>defeito: <b>4%</b>", "190", "90", "3,5", "no")
             + card(662, 414, "flag", "#ff6a5a", "Marketing e patrocínios", "INFLUÊNCIA E RECEITA", 1, True,
                    "patrocínio <b>US$ 2,0 mi</b> por corrida<br>influência <b>1</b>", "patrocínio <b>US$ 2,6 mi</b><br>influência <b>2</b>", "30", "18", "0,8", "ok"))
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 50% 50% at 70% 40%,{C1}44,transparent 70%)"></div>
{topbar("FÁBRICA · ESTRUTURA", "AURORA RACING · NÍVEL GERAL 2,3", [("CAIXA", "US$ 176 mi"), ("CUSTO POR CORRIDA", "US$ 8,5 mi")])}
{nav(4)}
<div style="position:absolute;right:44px;top:100px;font-size:13px;color:#a8b0bd;max-width:560px;text-align:right;line-height:1.4">Uma obra por vez em cada estrutura. Estruturas melhores aceleram a árvore de P&amp;D e aumentam a chance de cada upgrade dar certo.</div>
{cards}
<div class="note" style="left:44px;bottom:6px">EXEMPLO: EQUIPE FICTÍCIA · NÍVEIS 1 A 5 · CUSTOS, PRAZOS E EFEITOS PROVISÓRIOS · NÍVEL 5 SEM CAIXA = BOTÃO CINZA</div></div>'''
    return V.page("V9 · Fábrica · investimento em estrutura", CSS, body)


if __name__ == "__main__":
    for name, fn in [("v9-1-carro-arvore", arvore), ("v9-2-carro-essencial", arvore_essencial), ("v9-3-fabrica", fabrica)]:
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
