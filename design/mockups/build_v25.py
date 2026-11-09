"""V25 · Missões do stint no lugar da bateria (decisões de 2026-11-09).
1) Corrida: cartão do piloto com a missão de base, a missão curta ativa e a bateria cuidada pelo piloto.
2) Folha de missões: base do stint + missões curtas com fim automático.
3) Rádio: o piloto discorda da missão (aceitar ou insistir).
Uso: python design/mockups/build_v25.py   (V25_FACES=<pasta> V25_OUT=<pasta>: versão local com rostos)
"""
import json
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ROOT = HERE.parent.parent
ico = V.ico
FACES = os.environ.get("V25_FACES")
TY = json.loads((ROOT / "game/data/tyres_2026.json").read_text(encoding="utf-8"))["compounds"]
COL = B.teams["williams"]["color"]

G = {
    "atk": '<path d="M4 12h12M12 6l6 6-6 6"/><path d="M3 6v12"/>',
    "def": '<path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z"/>',
    "tyre": '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/>',
    "gap": '<path d="M3 12h7M14 12h7M10 8l-3 4 3 4M14 8l3 4-3 4"/>',
    "safe": '<path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>',
    "bat": '<rect x="3" y="7" width="16" height="10" rx="2"/><path d="M21 10v4M6 10v4M9 10v4"/>',
    "radio": '<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="2" y="14" width="5" height="6" rx="2"/><rect x="17" y="14" width="5" height="6" rx="2"/>',
    "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/>',
    "check": '<path d="M5 12l5 5 9-10"/>',
}


def g(n, s=18, c="currentColor", w=2.3):
    return (f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" '
            f'stroke-linejoin="round" style="flex:none">{G[n]}</svg>')


def face(did, size):
    inner = f'<img src="file://{FACES}/{did}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES else ""
    return f'<span class="fc" style="width:{size}px;height:{size}px;background:{COL}">{inner}</span>'


def tyre(k, size=22):
    t = TY[k]
    return (f'<span class="ty" style="width:{size}px;height:{size}px;border-color:{t["color"]};font-size:{size * 0.45:.0f}px">{t["letter"]}</span>')


CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.track{position:absolute;inset:0;background:radial-gradient(ellipse 70% 60% at 55% 50%,#24304a,#0b0c0f 75%)}
.fc{border-radius:50%;overflow:hidden;display:block;flex:none}
.ty{border-radius:50%;border:3px solid;background:#15171c;color:#fff;font-weight:900;display:grid;place-items:center;flex:none}
.cap{font-size:11px;letter-spacing:2.5px;color:#8f98a7;font-weight:900}
.glass{position:absolute;border-radius:20px;background:rgba(11,13,18,.88);padding:12px 14px}
.cta{height:44px;background:#E10600;color:#fff;font-weight:900;font-size:14px;display:flex;align-items:center;justify-content:center;gap:8px;
 clip-path:polygon(0 0,calc(100% - 14px) 0,100% 14px,100% 100%,0 100%);border-radius:12px 0 12px 12px;padding:0 16px;white-space:nowrap}
.ghost{height:44px;border-radius:12px;background:rgba(255,255,255,.08);font-weight:900;font-size:12px;display:flex;align-items:center;justify-content:center;padding:0 12px;gap:6px}
.mis{border-radius:14px;background:rgba(255,255,255,.06);padding:8px 10px;margin-top:8px}
.mis b{font-size:14px;font-weight:900;display:flex;align-items:center;gap:6px}.mis small{display:block;font-size:11px;color:#a8b0bd;font-weight:800;margin-top:2px}
.bar{height:6px;border-radius:3px;background:rgba(255,255,255,.12);margin-top:6px;overflow:hidden}.bar i{display:block;height:100%}
.short{border-radius:14px;background:rgba(225,6,0,.18);border:1px solid rgba(225,6,0,.5)}
.dim{position:absolute;inset:0;background:rgba(0,0,0,.6)}
.sheet{position:absolute;left:80px;top:40px;width:1120px;border-radius:24px;background:#17191e;padding:20px 24px}
.sheet h2{font-size:28px;font-weight:900;line-height:1}
.opts{display:grid;grid-template-columns:repeat(5,1fr);gap:10px;margin-top:10px}
.opt{border-radius:16px;background:rgba(255,255,255,.05);padding:12px;min-height:150px}
.opt.on{background:#f3f4f6;color:#11141a}.opt b{display:flex;gap:8px;align-items:center;font-size:15px;font-weight:900}
.opt small{display:block;font-size:12px;color:#a8b0bd;font-weight:700;margin-top:6px;line-height:1.35}.opt.on small{color:#4b5260}
.eff{display:flex;gap:6px;margin-top:8px;flex-wrap:wrap}.eff span{font-size:11px;font-weight:900;border-radius:8px;padding:2px 6px;background:rgba(255,255,255,.08)}
.opt.on .eff span{background:#e3e6eb}
.step{width:40px;height:40px;border-radius:10px;background:rgba(255,255,255,.08);display:grid;place-items:center;font-size:20px;font-weight:900}
.seg{display:flex;border-radius:12px;background:rgba(255,255,255,.06);overflow:hidden}
.seg span{padding:10px 16px;font-size:13px;font-weight:900;color:#c3c9d3}.seg .on{background:#f3f4f6;color:#11141a}
.radio{position:absolute;left:300px;bottom:24px;width:640px;border-radius:20px;background:#f3f4f6;color:#11141a;padding:14px 16px;box-shadow:inset 6px 0 0 #E10600}
.radio p{font-size:17px;font-weight:800;line-height:1.35;margin-top:6px}
.btns{display:flex;gap:8px;margin-top:10px}.btns span{flex:1;height:46px;border-radius:12px;background:#e3e6eb;display:flex;align-items:center;justify-content:center;font-weight:900;font-size:13px}
.btns .pri{background:#11141a;color:#fff}
"""


def card(x, y, did, name, pos, base, base_sub, base_pct, base_col, short=None):
    sh = ""
    if short:
        sh = (f'<div class="mis short">{"" }<b>{g("atk", 16, "#ff8a80")}{short[0]}<span style="margin-left:auto;font-size:12px;color:#ffb4a8">{short[1]}</span></b>'
              f'<small>{short[2]}</small><div class="bar"><i style="width:{short[3]}%;background:#E10600"></i></div></div>')
    return (f'<div class="glass" style="left:{x}px;top:{y}px;width:250px"><div style="display:flex;gap:10px;align-items:center">{face(did, 42)}'
            f'<div><b style="font-size:17px;font-weight:900">{name}</b><div style="color:#E10600;font-weight:900">{pos}</div></div>'
            f'<span style="margin-left:auto;display:flex;gap:4px;align-items:center;font-size:11px;font-weight:900;color:#8f98a7">{g("bat", 16, "#7fe0b1")}piloto</span></div>'
            f'<div style="display:flex;align-items:center;gap:8px;margin-top:8px;font-size:12px;font-weight:800;color:#c3c9d3">{tyre("medium")}Médio · 14v'
            f'<div class="bar" style="flex:1;margin:0"><i style="width:68%;background:#ffd24a"></i></div>68%</div>'
            f'<div class="mis"><div class="cap">MISSÃO DE BASE</div><b>{g("tyre", 16, "#5c93ea")}{base}</b><small>{base_sub}</small>'
            f'<div class="bar"><i style="width:{base_pct}%;background:{base_col}"></i></div></div>{sh}'
            f'<div style="display:flex;gap:6px;margin-top:10px"><div class="ghost">EQUIPE</div><div class="ghost" style="flex:1;background:#f3f4f6;color:#11141a">MISSÃO</div>'
            f'<div class="cta">P/ BOX</div></div></div>')


def race():
    a = card(12, 78, "albon", "Albon", "P7", "Poupar pneus até a volta 30", "cumprindo · pneu chega à volta 31", 78, "#7fe0b1",
             ("Atacar Gasly · 3 voltas", "2 de 3", "a 0,6 s · bateria nas retas · pneu −4%/volta", 66))
    b = card(12, 400, "sainz", "Sainz", "P11", "Ritmo seguro", "sem riscos · trazendo o carro (asa danificada)", 100, "#8f98a7")
    note = ('<div class="glass" style="right:24px;top:24px;width:420px;font-size:13px;font-weight:800;color:#c3c9d3;line-height:1.45">'
            '<div class="cap">O QUE MUDA</div>Sai Poupar/Normal/Atacar e a bateria. Você dá a <b style="color:#fff">missão de base</b> do stint e, quando quiser, '
            'uma <b style="color:#fff">missão curta</b> com fim automático. O piloto dosa ritmo, bateria e pneus volta a volta, conforme as notas.</div>')
    return V.page("V25 · Corrida · missões", CSS, f'<div class="scene"><div class="track"></div>{note}{a}{b}</div>')


def sheet():
    opts = [("tyre", "Poupar pneus", "Fazer o pneu chegar até a volta escolhida.", ["pneu −35%", "ritmo −0,3 s", "risco baixo"], True),
            ("atk", "Atacar", "Pressionar o carro da frente: bateria nas retas, freadas no limite.", ["pneu +40%", "ritmo +0,3 s", "risco alto"], False),
            ("def", "Defender", "Segurar o carro de trás: bateria guardada para as zonas de ultrapassagem.", ["pneu +15%", "risco médio"], False),
            ("gap", "Abrir gap / undercut", "Voltas fortes no ar limpo antes (ou logo depois) da parada.", ["pneu +30%", "ritmo +0,4 s"], False),
            ("safe", "Ritmo seguro", "Sem riscos: proteger o carro, o pneu no fim ou os pontos.", ["pneu −20%", "risco mínimo"], False)]
    tiles = "".join(f'<div class="opt{" on" if on else ""}"><b>{g(i, 20, "#11141a" if on else "#fff")}{n}</b><small>{d}</small>'
                    f'<div class="eff">{"".join(f"<span>{e}</span>" for e in eff)}</div></div>' for i, n, d, eff, on in opts)
    body = (f'<div class="scene"><div class="track"></div><div class="dim"></div><div class="sheet">'
            f'<div style="display:flex;align-items:center;gap:12px">{face("albon", 46)}<div><div class="cap">VOLTA 18 DE 57 · P7 · MÉDIO 14V</div><h2>MISSÕES DE ALBON</h2></div>'
            f'<span style="margin-left:auto;width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;font-weight:900">✕</span></div>'
            f'<div class="cap" style="margin-top:16px">MISSÃO DE BASE · O STINT INTEIRO</div><div class="opts">{tiles}</div>'
            f'<div style="display:flex;align-items:center;gap:10px;margin-top:10px;font-size:14px;font-weight:800;color:#c3c9d3">Poupar até a volta '
            f'<span class="step">−</span><b style="font-size:22px;color:#fff;width:40px;text-align:center">30</b><span class="step">+</span>'
            f'<span style="color:#7fe0b1">{g("check", 16, "#7fe0b1")} o engenheiro calcula: pneu chega com 22% na volta 30</span></div>'
            f'<div class="cap" style="margin-top:18px">MISSÃO CURTA · TERMINA SOZINHA E VOLTA À BASE</div>'
            f'<div style="display:flex;gap:10px;margin-top:10px;align-items:center">'
            f'<div class="seg"><span class="on">Atacar Gasly (P6)</span><span>Defender de Ocon (P8)</span><span>Undercut</span></div>'
            f'<div class="seg"><span>2 voltas</span><span class="on">3 voltas</span><span>5 voltas</span><span>até a parada</span></div>'
            f'<div class="cta" style="margin-left:auto;height:52px;font-size:16px">DAR MISSÃO</div></div></div></div>')
    return V.page("V25 · Folha de missões", CSS, body)


def radio():
    a = card(12, 78, "albon", "Albon", "P7", "Poupar pneus até a volta 30", "cumprindo · pneu chega à volta 31", 78, "#7fe0b1")
    rc = (f'<div class="radio"><div style="display:flex;align-items:center;gap:8px">{g("radio", 18, "#11141a")}<span class="cap" style="color:#4b5260">RÁDIO · ALBON</span></div>'
          f'<p>"Se eu atacar agora o pneu não chega na volta 30. Deixa eu esperar 2 voltas, ele vai errar na freada da curva 1."</p>'
          f'<div class="btns"><span class="pri">ACEITAR · esperar 2 voltas e atacar</span><span>INSISTIR · ataque agora</span></div>'
          f'<div style="font-size:12px;font-weight:800;color:#4b5260;margin-top:8px">Sem resposta em 20 s, o piloto faz do jeito dele.</div></div>')
    return V.page("V25 · Rádio · piloto discorda", CSS, f'<div class="scene"><div class="track"></div>{a}{rc}</div>')


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V25_OUT"]) if os.environ.get("V25_OUT") else HERE
    if os.environ.get("V25_OUT"):
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
    for name, fn in {"v25-1-corrida-missoes": race, "v25-2-folha-missoes": sheet, "v25-3-radio-discorda": radio}.items():
        (out / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
