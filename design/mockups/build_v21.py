"""V21 · Treinos sempre simulados + engenheiros de corrida (decisões de 2026-11-08). 1) Fim de semana: treino só simulado,
programa por piloto, engenheiro de corrida e a chance de bom acerto (diretor 35 / engenheiro 30 / piloto 15 / sorte 20).
2) Resultado do treino. Uso: python design/mockups/build_v21.py   (V21_FACES=<pasta> V21_OUT=<pasta>: versão local)
"""
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ROOT = HERE.parent.parent
ico = V.ico
FACES = os.environ.get("V21_FACES")
D = {d["id"]: d for d in V.DRIVERS}
COL = B.teams["williams"]["color"]

G = {
    "aero": '<path d="M2 7h20M4 12h16M7 17h10"/>', "mech": '<path d="M3 19L12 6l9 13M7 13h10"/>',
    "race": '<path d="M5 21V4h11l-2 4 2 4H5"/>', "quali": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/>',
    "dir": '<path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z"/>', "eng": '<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="2" y="14" width="5" height="6" rx="2"/><rect x="17" y="14" width="5" height="6" rx="2"/>',
    "drv": '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/>', "luck": '<rect x="4" y="4" width="16" height="16" rx="3"/><circle cx="9" cy="9" r="1.2"/><circle cx="15" cy="15" r="1.2"/><circle cx="15" cy="9" r="1.2"/><circle cx="9" cy="15" r="1.2"/>',
    "spin": '<path d="M20 12a8 8 0 1 1-3-6.3M20 4v5h-5"/>', "check": '<path d="M5 12l5 5 9-10"/>',
}


def g(n, s=18, c="currentColor", w=2.3):
    return f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" style="flex:none">{G[n]}</svg>'


def face(did, size):
    inner = (f'<img src="file://{FACES}/{did}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES else "")
    return f'<span class="fc" style="width:{size}px;height:{size}px;background:{COL}">{inner}</span>'


CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.bg{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 30% 30%,#1b2a55,#0b0c0f 72%)}
.hd{position:absolute;left:44px;top:22px;right:44px;display:flex;align-items:center;gap:14px}
.rb{width:52px;height:52px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center}
.hd h1{font-size:28px;font-weight:900;line-height:1}.hd small{display:block;font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.steps{position:absolute;left:44px;right:44px;top:100px;display:flex;align-items:center;gap:10px;font-weight:900;font-size:15px;color:#8f98a7}
.steps i{width:32px;height:32px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;font-style:normal;font-size:13px}
.steps .on i{background:#E10600;color:#fff}.steps .on{color:#fff}.steps .ln{flex:1;height:2px;background:rgba(255,255,255,.1)}
.hero{position:absolute;left:44px;top:150px;width:470px;border-radius:22px;background:#f3f4f6;color:#11141a;padding:18px 22px;box-shadow:inset 6px 0 0 #E10600}
.hero h2{font-size:34px;font-weight:900;line-height:1;margin:6px 0}.hero p{font-size:14px;color:#4b5260;font-weight:700;line-height:1.4}
.cta{height:56px;background:#E10600;color:#fff;font-weight:900;font-size:19px;display:flex;align-items:center;justify-content:center;gap:10px;margin-top:12px;
 clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,0 100%);border-radius:14px 0 14px 14px}
.cap{font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.dcard{position:absolute;width:350px;border-radius:22px;background:rgba(255,255,255,.06);padding:14px 16px}
.dh{display:flex;align-items:center;gap:10px}.dh strong{font-size:18px;font-weight:900}.dh small{display:block;font-size:12px;color:#a8b0bd;font-weight:800}
.fc{border-radius:50%;overflow:hidden;display:block;flex:none}
.eng{display:flex;align-items:center;gap:10px;border-radius:14px;background:rgba(0,0,0,.25);padding:8px 10px;margin-top:10px}
.eng .av{width:36px;height:36px;border-radius:50%;background:#5c93ea33;display:grid;place-items:center}
.eng strong{display:block;font-size:14px;font-weight:900}.eng small{display:block;font-size:11px;color:#a8b0bd;font-weight:700}
.eng b{margin-left:auto;font-size:22px;font-weight:900}
.prog{display:flex;gap:6px;margin-top:10px}
.blk{flex:1;border-radius:12px;background:rgba(255,255,255,.08);padding:8px 6px;display:flex;flex-direction:column;align-items:center;gap:3px;font-size:11px;font-weight:900;text-align:center}
.blk small{font-size:10px;color:#a8b0bd;font-weight:800}
.blk.add{background:none;border:2px dashed rgba(255,255,255,.15);color:#8f98a7}
.chance{margin-top:12px}
.meter{display:flex;height:12px;border-radius:6px;overflow:hidden;margin:6px 0}
.meter i{display:block;height:100%}
.leg{display:flex;justify-content:space-between;font-size:11px;font-weight:900;color:#c3c9d3}
.leg span{display:flex;align-items:center;gap:4px}
.big{font-size:26px;font-weight:900}
/* resultado */
.dim{position:absolute;inset:0;background:rgba(0,0,0,.6)}
.sheet{position:absolute;left:120px;top:60px;width:1040px;border-radius:24px;background:#17191e;padding:22px 26px}
.sheet h2{font-size:28px;font-weight:900}
.cols{display:flex;gap:16px;margin-top:12px}
.res{flex:1;border-radius:18px;background:rgba(255,255,255,.05);padding:14px}
.bar{display:flex;align-items:center;gap:10px;margin-top:8px;font-size:13px;font-weight:800}
.bar .t{flex:1;height:10px;border-radius:5px;background:rgba(255,255,255,.1);position:relative;overflow:hidden}
.bar .t i{position:absolute;top:0;bottom:0;left:0;border-radius:5px}
.bar b{width:120px;text-align:right;white-space:nowrap}
.up{color:#7fe0b1}.dn{color:#ff8a80}
.ev{display:flex;align-items:center;gap:8px;font-size:12px;font-weight:800;color:#c3c9d3;margin-top:8px}
.grade{display:flex;align-items:center;gap:12px;border-radius:14px;padding:10px 12px;margin-top:10px}
.grade b{font-size:30px;font-weight:900}.grade small{display:block;font-size:12px;font-weight:800;color:#c3c9d3}
.times{width:300px;border-radius:18px;background:rgba(255,255,255,.05);padding:14px}
.tr{display:flex;align-items:center;gap:8px;height:30px;font-size:13px;font-weight:900;border-top:1px solid rgba(255,255,255,.06)}
.tr.me{background:rgba(19,71,245,.25);border-radius:8px}
.tr span:last-child{margin-left:auto;color:#c3c9d3}
"""


def chance_box(director, engineer, driver):
    total = 0.35 * director + 0.30 * engineer + 0.15 * driver
    parts = [("dir", "#ffd24a", "Diretor 35", 0.35 * director), ("eng", "#5c93ea", "Engenheiro 30", 0.30 * engineer),
             ("drv", "#3c9d5d", "Piloto 15", 0.15 * driver), ("luck", "#8f98a7", "Sorte 20", 20 * 0.5)]
    meter = "".join(f'<i style="width:{v:.0f}%;background:{c}"></i>' for _, c, _, v in parts)
    leg = "".join(f'<span>{g(i, 13, c)}{n}</span>' for i, c, n, _ in parts)
    return (f'<div class="chance"><div style="display:flex;align-items:baseline;justify-content:space-between"><span class="cap">CHANCE DE BOM ACERTO</span>'
            f'<span class="big">{total + 10:.0f}%</span></div><div class="meter">{meter}</div><div class="leg">{leg}</div></div>')


def driver_card(did, eng, eskill, x, y, prog):
    d = D[did]
    blocks = "".join(f'<div class="blk">{g(b, 18)}{n}<small>{m} min</small></div>' for b, n, m in prog)
    return f'''<div class="dcard" style="left:{x}px;top:{y}px"><div class="dh">{face(did, 46)}<div><strong>{d["name"]}</strong><small>#{d["number"]} · acerto {d["attrs"]["consistency"] if d.get("attrs") else 80}</small></div></div>
<div class="eng"><span class="av">{g("eng", 20, "#5c93ea")}</span><div><strong>{eng}</strong><small>engenheiro de corrida</small></div><b>{eskill}</b></div>
<div class="prog">{blocks}<div class="blk add">+</div></div>{chance_box(77, eskill, 82)}</div>'''


def weekend():
    steps = '<div class="steps"><span class="on"><i>1</i> TL1</span><span class="ln"></span><span><i>2</i> TL2</span><span class="ln"></span><span><i>3</i> TL3</span><span class="ln"></span><span><i>Q</i> CLASS</span><span class="ln"></span><span><i>R</i> CORRIDA</span></div>'
    prog = [("aero", "Aero", 15), ("mech", "Mecânico", 15), ("race", "Corrida", 20), ("quali", "Volta", 10)]
    hero = f'''<div class="hero"><div class="cap" style="color:#4b5260">PRÓXIMA SESSÃO · AGORA</div><h2>TREINO LIVRE 1</h2>
<p>60 minutos, sempre simulados. Os pilotos seguem o programa; o acerto sai da capacidade do diretor de engenharia de pista, dos engenheiros de corrida e dos pilotos — e um pouco de sorte.</p>
<div style="display:flex;gap:10px;margin-top:12px"><div style="flex:1;border-radius:14px;background:#e3e6eb;padding:10px 12px">{g("dir", 20, "#11141a")}<b style="display:block;font-size:20px;font-weight:900">77</b><small style="font-size:12px;font-weight:800;color:#4b5260">Diretor de engenharia de pista · Rhys Calloway</small></div>
<div style="flex:1;border-radius:14px;background:#e3e6eb;padding:10px 12px">{g("luck", 20, "#11141a")}<b style="display:block;font-size:20px;font-weight:900">30%</b><small style="font-size:12px;font-weight:800;color:#4b5260">chance de chuva na sexta</small></div></div>
<div class="cta">SIMULAR TREINO LIVRE 1 {ico("chev", 20, "#fff", 3)}</div></div>'''
    body = f'''<div class="scene"><div class="bg"></div><div class="hd"><span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span><div><small>FIM DE SEMANA · WILLIAMS</small><h1>GP DE SÃO PAULO</h1></div></div>
{steps}{hero}{driver_card("albon", "James Urwin", 82, 530, 150, prog)}{driver_card("sainz", "Gaëtan Jago", 82, 890, 150, [("aero", "Aero", 15), ("aero", "Aero", 15), ("race", "Corrida", 30)])}</div>'''
    return V.page("V21 · Fim de semana · treino simulado", CSS, body)


def result():
    def bars(rows):
        return "".join(f'<div class="bar"><span style="width:96px">{n}</span><div class="t"><i style="width:{a}%;background:rgba(92,147,234,.45)"></i><i style="width:{b}%;background:#5c93ea"></i></div>'
                       f'<b>{a}% → {b}% <span class="{"up" if b >= a else "dn"}">{b - a:+d}</span></b></div>' for n, a, b in rows)
    def card(did, eng, grade, gcol, gtext, rows, evs):
        ev = "".join(f'<div class="ev">{g(i, 16, c)}{t}</div>' for i, c, t in evs)
        return f'''<div class="res"><div class="dh">{face(did, 44)}<div><strong>{D[did]["name"]}</strong><small>com {eng}</small></div></div>
<div class="grade" style="background:{gcol}22"><b style="color:{gcol}">{grade}</b><div><strong style="font-size:15px">{gtext}</strong><small>acerto sorteado: diretor + engenheiro + piloto + sorte</small></div></div>
{bars(rows)}{ev}</div>'''
    times = "".join(f'<div class="tr{" me" if n in ("ALB", "SAI") else ""}"><span style="width:24px">{i}</span>{n}<span>{t}</span></div>' for i, (n, t) in enumerate(
        [("NOR", "1:10.912"), ("ANT", "1:11.004"), ("PIA", "1:11.081"), ("RUS", "1:11.130"), ("VER", "1:11.244"), ("LEC", "1:11.301"), ("SAI", "1:11.420"),
         ("HAM", "1:11.455"), ("ALB", "1:11.497"), ("HAD", "1:11.530")], 1))
    body = f'''<div class="scene"><div class="bg"></div>{weekend().split('<div class="scene">', 1)[1].rsplit("</div>", 1)[0] if False else ""}
<div class="dim"></div><div class="sheet"><div style="display:flex;align-items:center"><div><div class="cap">TREINO LIVRE 1 · SIMULADO</div><h2>RESULTADO DO TREINO</h2></div>
<span class="rb" style="margin-left:auto">✕</span></div>
<div class="cols">{card("albon", "James Urwin", "A", "#3c9d5d", "Ótimo acerto", [("Aerodinâmica", 45, 78), ("Mecânico", 42, 71), ("Equilíbrio", 40, 66)], [("check", "#7fe0b1", "Simulação de corrida concluída: dados de pneus para domingo")])}
{card("sainz", "Gaëtan Jago", "C", "#ffd24a", "Acerto regular", [("Aerodinâmica", 47, 63), ("Mecânico", 48, 52), ("Equilíbrio", 40, 47)], [("spin", "#ff8a80", "Rodou na curva 4 e perdeu parte do bloco de aero")])}
<div class="times"><div class="cap">MELHORES VOLTAS</div>{times}</div></div>
<div class="cta" style="width:320px;margin-left:auto">PRÓXIMA SESSÃO {ico("chev", 20, "#fff", 3)}</div></div></div>'''
    return V.page("V21 · Resultado do treino", CSS, body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V21_OUT"]) if os.environ.get("V21_OUT") else HERE
    if os.environ.get("V21_OUT"):
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
    (out / "v21-1-fim-de-semana-treino.html").write_text(weekend(), encoding="utf-8")
    (out / "v21-2-resultado-treino.html").write_text(result(), encoding="utf-8")
    print("ok")
