"""V33 · Situação do carro, danos por peça e ordens de equipe em aba nova (pedido de 2026-11-10).
1) Corrida: o cartão do piloto perde o desgaste do pneu e as ordens de equipe; ganha o bloco "Situação do carro".
2) Folha "Situação do carro": desenho do carro da equipe, peças com exclamação, efeito no ritmo e pneu.
3) Folha de missões com a nova aba "Ordens de equipe".
5 peças (decisão do usuário): asa dianteira (a única trocável no box), asa traseira, assoalho, suspensão, motor/câmbio.
Uso: python design/mockups/build_v33.py   (V25_FACES=<pasta>: versão local com rostos)
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v25 as W  # noqa: E402

HERE = B.HERE
g, face, tyre = W.g, W.face, W.tyre
W.G["car"] = '<path d="M12 3v3M8 6h8M10 6l1 8M14 6l-1 8M7 14h10M9 14l-1 5M15 14l1 5M7 20h10"/>'
W.G["warn"] = '<path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17v.5"/>'
W.G["users"] = '<circle cx="9" cy="9" r="3.5"/><circle cx="17" cy="10" r="2.5"/><path d="M3 20c.5-4 3-6 6-6s5.5 2 6 6M15 15c3 0 5 1.5 6 5"/>'
W.G["wrench"] = '<path d="M14 6a4 4 0 0 0 5 5l-9 9a2.1 2.1 0 0 1-3-3l9-9a4 4 0 0 0-2-2z"/>'
RED, AMB, GRN, MUT = "#ff4d4d", "#ffb020", "#7fe0b1", "#8f98a7"
TEAM = B.teams["williams"]["color"]

CSS = W.CSS + """
.sheet{left:60px;top:36px;width:1160px;height:648px}
.tabs{display:flex;gap:8px;margin-top:14px}.tabs span{padding:10px 18px;border-radius:14px;background:rgba(255,255,255,.06);font-weight:900;font-size:14px;color:#c3c9d3;display:flex;gap:8px;align-items:center}
.tabs .on{background:#f3f4f6;color:#11141a}
.part{display:flex;align-items:center;gap:12px;border-radius:14px;background:rgba(255,255,255,.05);padding:6px 12px;margin-top:6px}
.part b{font-size:15px;font-weight:900}.part small{display:block;font-size:12px;color:#a8b0bd;font-weight:800;margin-top:1px}
.dot{width:30px;height:30px;border-radius:50%;display:grid;place-items:center;font-weight:900;font-size:16px;color:#11141a;flex:none}
.chip2{font-size:11px;font-weight:900;border-radius:8px;padding:3px 8px;white-space:nowrap}
.mini{position:relative;flex:none}
.ord{display:flex;gap:12px;margin-top:14px}.ord .o{flex:1;border-radius:18px;background:rgba(255,255,255,.05);padding:16px;min-height:150px}
.ord .o.on{background:#f3f4f6;color:#11141a}.ord b{font-size:18px;font-weight:900;display:block;margin-top:8px}.ord small{display:block;font-size:13px;font-weight:700;color:#a8b0bd;margin-top:6px;line-height:1.4}
.ord .o.on small{color:#4b5260}
"""

# peças: id, nome, posição (viewBox 300x420) do marcador
PARTS = {
    "fw": ("Asa dianteira", 150, 30),
    "su": ("Suspensão", 86, 104),
    "fl": ("Assoalho", 214, 228),
    "pu": ("Motor / câmbio", 150, 270),
    "rw": ("Asa traseira", 150, 392),
}


def car_svg(state, size=1.0, labels=True, color=TEAM, wear=0.32):
    """state: id -> 0 (ok) / 1 (desgaste leve) / 2 (danificado). Carro genérico visto de cima, sem marcas."""
    def tone(pid):
        return {0: "#2b3140", 1: "#4a3a17", 2: "#4a1c1c"}[state.get(pid, 0)]

    def ring(pid):
        return {0: "rgba(255,255,255,.18)", 1: AMB, 2: RED}[state.get(pid, 0)]

    wc = {"low": GRN, "mid": AMB, "hi": RED}["low" if wear < 0.5 else ("mid" if wear < 0.75 else "hi")]
    marks = ""
    for pid, (_, x, y) in PARTS.items():
        s = state.get(pid, 0)
        if s and labels:
            col = RED if s == 2 else AMB
            marks += (f'<circle cx="{x}" cy="{y}" r="15" fill="{col}" stroke="#0b0c0f" stroke-width="3"/>'
                      f'<text x="{x}" y="{y + 6}" text-anchor="middle" font-size="20" font-weight="900" fill="#11141a" font-family="Kanit,sans-serif">!</text>')
    wheels = "".join(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="9" fill="#15171c" stroke="{wc}" stroke-width="4"/>'
                     for x, y, w, h in [(14, 66, 46, 70), (240, 66, 46, 70), (10, 238, 50, 86), (240, 238, 50, 86)])
    arms = "".join(f'<path d="{d}" stroke="{ring("su")}" stroke-width="5" fill="none" stroke-linecap="round"/>' for d in
                   ["M60 92L128 112", "M60 120L128 126", "M240 92L172 112", "M240 120L172 126"])
    body = (f'<path d="M136 52h28l-2 66h-24z" fill="{color}"/>'  # bico
            f'<path d="M104 120h92l14 92-22 84h-76l-22-84z" fill="{color}" opacity=".95"/>'  # caixas laterais
            f'<rect x="132" y="150" width="36" height="150" rx="14" fill="#11141a" opacity=".55"/>'  # cobertura do motor
            f'<ellipse cx="150" cy="178" rx="13" ry="20" fill="#11141a"/>')  # cockpit
    floor = f'<path d="M78 150h30M222 150h-30M70 180l36 6M230 180l-36 6" stroke="{ring("fl")}" stroke-width="5" stroke-linecap="round" fill="none"/>' \
            f'<path d="M96 300l-14 22h136l-14-22" fill="{tone("fl")}" stroke="{ring("fl")}" stroke-width="3"/>'
    fw = f'<rect x="38" y="14" width="224" height="30" rx="8" fill="{tone("fw")}" stroke="{ring("fw")}" stroke-width="4"/>'
    rw = f'<rect x="52" y="376" width="196" height="34" rx="8" fill="{tone("rw")}" stroke="{ring("rw")}" stroke-width="4"/>'
    pu = f'<rect x="124" y="236" width="52" height="64" rx="12" fill="{tone("pu")}" stroke="{ring("pu")}" stroke-width="4"/>'
    return (f'<svg width="{300 * size:.0f}" height="{420 * size:.0f}" viewBox="0 0 300 420" style="flex:none">'
            f'{arms}{wheels}{body}{floor}{pu}{fw}{rw}{marks}</svg>')


def mini_car(state, color=TEAM, wear=0.32):
    return car_svg(state, 0.19, True, color, wear).replace('r="15"', 'r="26"').replace('font-size="20"', 'font-size="38"')


def card(x, y, did, name, pos, state, tyre_pct, tyre_k, alert=None, note=None):
    n_dmg = sum(1 for v in state.values() if v)
    tone = RED if any(v == 2 for v in state.values()) else (AMB if n_dmg else GRN)
    status = "Danos no carro" if n_dmg else "Carro 100%"
    sub = alert or ""
    return (f'<div class="glass" style="left:{x}px;top:{y}px;width:250px"><div style="display:flex;gap:10px;align-items:center">{face(did, 42)}'
            f'<div><b style="font-size:17px;font-weight:900">{name}</b><div style="color:#E10600;font-weight:900">{pos}</div></div>'
            f'<span style="margin-left:auto;display:flex;gap:4px;align-items:center;font-size:11px;font-weight:900;color:#8f98a7">{g("bat", 16, "#7fe0b1")}piloto</span></div>'
            f'<div class="mis" style="padding:6px 10px"><b>{g("tyre", 16, "#5c93ea")}Poupar pneus até a volta 30</b>'
            f'<div class="bar"><i style="width:78%;background:#7fe0b1"></i></div></div>'
            f'<div class="mis" style="display:flex;gap:10px;align-items:center;padding:8px 10px"><div class="mini" style="margin:-4px 0">{mini_car(state, wear=tyre_k)}</div>'
            f'<div style="flex:1;min-width:0">'
            f'<div style="display:flex;align-items:center;gap:6px">{tyre("medium", 22)}<div class="bar" style="flex:1;margin:0"><i style="width:{tyre_pct}%;background:#ffd24a"></i></div>'
            f'<span style="font-size:13px;font-weight:900">{tyre_pct}%</span></div>'
            f'{f"<b style=font-size:13px;color:{tone};display:block;margin-top:6px>{sub}</b>" if sub else ""}</div></div>'
            f'<div style="display:flex;gap:6px;margin-top:10px"><div class="ghost" style="flex:1">{g("atk", 20, "#fff")}</div>'
            f'<div class="ghost" style="flex:1">{g("car", 20, "#fff")}</div><div class="cta" style="flex:1.2">{g("wrench", 20, "#fff")}</div></div></div>')


def corrida():
    a = card(12, 70, "albon", "Albon", "P7", {"fw": 2, "fl": 1, "rw": 1}, 68, 0.32, "−1,1 s/volta")
    b = card(12, 378, "sainz", "Sainz", "P11", {}, 41, 0.59)
    note = ""
    return V.page("V33 · Corrida · cartão com situação do carro", CSS, f'<div class="scene"><div class="track"></div>{note}{a}{b}</div>')


def parts_list():
    rows = [("fw", "Asa dianteira", 2, "−0,6 s"), ("fl", "Assoalho", 1, "−0,35 s"), ("rw", "Asa traseira", 1, "−0,16 s")]
    out = ""
    for pid, name, lvl, eff in rows:
        out += (f'<div class="part"><span class="dot" style="background:{RED if lvl == 2 else AMB}">!</span>'
                f'<b style="flex:1">{name}</b><b style="font-size:16px;color:#c3c9d3">{eff}</b></div>')
    return out


def situacao():
    state = {"fw": 2, "fl": 1, "rw": 1}
    car = f'<div style="position:relative;display:flex;justify-content:center;width:330px">{car_svg(state, 1.3, wear=0.32)}</div>'
    tyre_blk = (f'<div class="part" style="margin-top:14px">{tyre("medium", 34)}'
                f'<div style="flex:1"><div class="bar" style="height:10px;margin:0"><i style="width:68%;background:#ffd24a"></i></div></div>'
                f'<b style="font-size:20px;width:58px;text-align:right">68%</b></div>')
    total = (f'<div class="part" style="margin-top:14px">{g("clock", 22, AMB)}<b style="flex:1;font-size:18px">−1,1 s</b>'
             f'<span style="display:flex;gap:8px;align-items:center">{g("warn", 22, AMB)}<b style="font-size:16px;color:{AMB}">média</b></span></div>')
    body = (f'<div class="scene"><div class="track"></div><div class="dim"></div><div class="sheet" style="height:620px;top:50px">'
            f'<div style="display:flex;align-items:center;gap:12px">{face("albon", 46)}<h2>ALBON</h2>'
            f'<span style="margin-left:auto;width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;font-weight:900">✕</span></div>'
            f'<div style="display:flex;gap:30px;margin-top:6px">{car}'
            f'<div style="flex:1;padding-top:10px">{parts_list()}{tyre_blk}{total}'
            f'<div class="cta" style="height:56px;margin-top:22px;font-size:16px;width:100%">{g("wrench", 22, "#fff")}TROCAR ASA</div></div></div></div></div>')
    return V.page("V33 · Carro", CSS, body)


def ordens():
    opts = [("users", "Briga liberada", True), ("def", "Não defender", False), ("atk", "Não atacar", False)]
    tiles = "".join(f'<div class="o{" on" if on else ""}" style="min-height:110px">{g(i, 30, "#11141a" if on else "#fff")}<b>{n}</b></div>' for i, n, on in opts)
    body = (f'<div class="scene"><div class="track"></div><div class="dim"></div><div class="sheet" style="height:auto;padding-bottom:26px">'
            f'<div style="display:flex;align-items:center;gap:12px">{face("albon", 46)}<h2>ALBON</h2>'
            f'<span style="margin-left:auto;width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;font-weight:900">✕</span></div>'
            f'<div class="tabs"><span>{g("tyre", 18)}Missão de base</span><span>{g("atk", 18)}Missão curta</span><span class="on">{g("users", 18, "#11141a")}Ordens de equipe</span></div>'
            f'<div class="ord">{tiles}</div>'
            f'<div style="display:flex;margin-top:16px"><div class="cta" style="margin-left:auto;height:52px;padding:0 26px;font-size:16px">CONFIRMAR</div></div></div></div>')
    return V.page("V33 · Missões e bases · ordens de equipe", CSS, body)


if __name__ == "__main__":
    for name, fn in {"v33-1-corrida": corrida, "v33-2-situacao": situacao, "v33-3-ordens": ordens}.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
