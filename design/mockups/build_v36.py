"""V36 · Missões reformuladas (pedido de 2026-11-12): RITMO (5 modos) e ABORDAGEM NA DIREÇÃO (3 níveis), com símbolo em cada
opção e na cor da equipe. Uso: python design/mockups/build_v36.py"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v25 as W  # noqa: E402
import build_v33 as P  # noqa: E402

HERE = B.HERE
g, face = W.g, W.face
TC = B.teams["williams"]["color"]
W.G.update({
    "home": '<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/><path d="M10 20v-6h4v6"/>',
    "leaf": '<path d="M5 19c0-8 6-14 15-14 0 9-6 15-14 15"/><path d="M5 19l8-8"/>',
    "gauge": '<path d="M4 16a8 8 0 1 1 16 0"/><path d="M12 16l3-5"/>',
    "chev2": '<path d="M5 6l6 6-6 6M12 6l6 6-6 6"/>',
    "bolt": '<path d="M13 3L5 14h6l-1 7 8-11h-6z"/>',
    "shield2": '<path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z"/>',
    "dot": '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="2.5"/>',
    "flame": '<path d="M12 3c1 4 6 6 6 11a6 6 0 0 1-12 0c0-3 2-4 2-7 2 1 3 3 3 5 1-2 1-6 1-9z"/>',
})
CSS = P.CSS + """
.m6h{font-size:12px;letter-spacing:2.5px;color:#8f98a7;font-weight:900;margin-top:16px}
.m6g{display:grid;gap:10px;margin-top:10px}
.m6t{border-radius:18px;background:rgba(255,255,255,.06);padding:14px 10px 12px;display:flex;flex-direction:column;align-items:center;gap:10px;text-align:center}
.m6t b{font-size:15px;font-weight:900;line-height:1.1}
.m6t.on{background:%s;color:#fff;box-shadow:0 0 0 2px rgba(255,255,255,.25) inset}
.m6i{width:54px;height:54px;border-radius:50%%;background:rgba(255,255,255,.08);display:grid;place-items:center}
.m6t.on .m6i{background:rgba(255,255,255,.2)}
.m6m{display:flex;gap:3px}.m6m i{width:14px;height:6px;border-radius:3px;background:rgba(255,255,255,.15)}.m6m i.f{background:#ffd24a}
.m6t.on .m6m i.f{background:#fff}
.m6v{font-size:12px;font-weight:900;border-radius:8px;padding:3px 8px;background:rgba(255,255,255,.1)}
.m6t svg,.m6i svg{position:static;opacity:1}
""" % TC

RITMO = [("home", "Trazendo pra casa", 1), ("leaf", "Conservador", 2), ("gauge", "Ritmo normal", 3), ("chev2", "Agressivo", 4), ("bolt", "Potência máxima", 5)]
ABORD = [("shield2", "Sem riscos", 1), ("dot", "Normal", 2), ("flame", "Agressivo", 3)]


def tile(icon, name, extra, on):
    return (f'<div class="m6t{" on" if on else ""}"><span class="m6i">{g(icon, 28, "#fff")}</span><b>{name}</b>{extra}</div>')


def folha():
    meter = lambda n: '<span class="m6m">' + "".join(f'<i class="{"f" if k < n else ""}"></i>' for k in range(5)) + "</span>"
    rit = "".join(tile(i, n, meter(lvl), n == "Ritmo normal") for i, n, lvl in RITMO)
    meter3 = lambda n: '<span class="m6m">' + "".join(f'<i class="{"f" if k < n else ""}"></i>' for k in range(3)) + "</span>"
    abd = "".join(tile(i, n, meter3(v), n == "Normal") for i, n, v in ABORD)
    body = (f'<div class="scene"><div class="track"></div><div class="dim"></div>'
            f'<div class="sheet" style="height:auto;padding-bottom:24px;background:#141a2e;box-shadow:inset 6px 0 0 {TC}">'
            f'<div style="display:flex;align-items:center;gap:12px">{face("albon", 46)}<h2>ALBON</h2>'
            f'<span style="margin-left:auto;width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;font-weight:900">✕</span></div>'
            f'<div class="tabs"><span class="on" style="background:{TC};color:#fff">MISSÕES</span><span>ORDENS DE EQUIPE</span></div>'
            f'<div class="m6h">RITMO</div><div class="m6g" style="grid-template-columns:repeat(5,1fr)">{rit}</div>'
            f'<div style="display:flex;align-items:center;gap:10px;margin-top:10px;font-weight:900;color:#c3c9d3">{g("leaf", 18, "#7fe0b1")} ATÉ A VOLTA '
            f'<span class="step">−</span><b style="font-size:22px;color:#fff;width:40px;text-align:center">30</b><span class="step">+</span>'
            f'<span style="color:#7fe0b1">pneu chega com 24%</span></div>'
            f'<div class="m6h">ABORDAGEM NA DIREÇÃO</div><div class="m6g" style="grid-template-columns:repeat(3,1fr);width:60%">{abd}</div>'
            f'<div style="display:flex;margin-top:14px"><div class="cta" style="margin-left:auto;height:52px;padding:0 26px;font-size:16px;background:{TC}">CONFIRMAR</div></div></div></div>')
    return V.page("V36 · Ritmo e abordagem", CSS, body)


if __name__ == "__main__":
    (HERE / "v36-1-missoes.html").write_text(folha(), encoding="utf-8")
    print("ok")
