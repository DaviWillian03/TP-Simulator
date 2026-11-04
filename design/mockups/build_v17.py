"""V17 · Pop-ups do campeonato mundial durante a corrida (pedido #1 do usuário, fila de 2026-11-04).
Fundo: captura real da tela de corrida (não versionada: tem logos/fotos locais) passada em V17_BASE.
Uso: V17_BASE=<png> V17_FACES=<pasta> V17_LOGOS=<pasta> V17_OUT=<pasta> python design/mockups/build_v17.py
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
BASE = os.environ.get("V17_BASE", "")
FACES = os.environ.get("V17_FACES")
LOGOS = os.environ.get("V17_LOGOS")
D = {d["id"]: d for d in V.DRIVERS}


def face(did, size):
    d = D[did]
    col = B.teams[d["team"]]["color"]
    inner = (f'<img src="file://{FACES}/{did}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES else "")
    return f'<span class="fc" style="width:{size}px;height:{size}px;background:{col}">{inner}</span>'


def logo(tid, w):
    src = f"file://{LOGOS}/{tid}.png" if LOGOS else V.EMB.format(tid)
    return f'<img src="{src}" style="width:{w}px;height:{w}px;object-fit:contain;border-radius:6px">'


TROPHY = '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0zM7 6H4v1a3 3 0 0 0 3 3M17 6h3v1a3 3 0 0 1-3 3"/>'

CSS = V.G_CSS + """
.base{position:absolute;inset:0;background-size:cover}
.champ{position:absolute;left:300px;top:86px;width:500px;border-radius:18px;background:rgba(8,9,12,.9);border:1px solid rgba(255,255,255,.1);
 box-shadow:0 14px 40px rgba(0,0,0,.55);overflow:hidden}
.champ .hd{display:flex;align-items:center;gap:10px;padding:10px 14px;background:linear-gradient(90deg,#E10600,#8f0400)}
.champ .hd b{font-size:13px;letter-spacing:2px;font-weight:900}.champ .hd small{margin-left:auto;font-size:12px;font-weight:800;opacity:.9}
.champ .bd{padding:10px 14px 12px}
.rw{display:flex;align-items:center;gap:10px;padding:5px 0}
.rw .p{width:26px;font-size:16px;font-weight:900;text-align:center}
.fc{border-radius:50%;overflow:hidden;display:block;flex:none}
.rw .n{font-size:15px;font-weight:900;flex:1}.rw .n small{display:block;font-size:11px;color:#a8b0bd;font-weight:700}
.rw .pts{font-size:13px;color:#a8b0bd;font-weight:800;width:110px;text-align:right}.rw .pts b{color:#fff;font-size:17px;font-weight:900}
.rw .mv{width:34px;text-align:center;font-size:13px;font-weight:900}
.up{color:#7fe0b1}.dn{color:#ff8a80}
.rw.me{background:rgba(39,244,210,.12);border-radius:10px;padding:5px 6px;margin:0 -6px}
.msg{display:flex;align-items:center;gap:8px;margin-top:8px;border-top:1px solid rgba(255,255,255,.08);padding-top:8px;font-size:13px;font-weight:800;color:#c3c9d3}
.champ.gold .hd{background:linear-gradient(90deg,#d4a017,#7a5a00)}
.big{display:flex;align-items:center;gap:14px;padding:6px 0}
.big strong{display:block;font-size:24px;font-weight:900;line-height:1.05}.big small{display:block;font-size:13px;color:#c3c9d3;font-weight:800}
.bar2{height:8px;border-radius:4px;background:rgba(255,255,255,.12);overflow:hidden;margin-top:8px}.bar2 i{display:block;height:100%;background:#d4a017}
"""


def card(kind):
    if kind == "drivers":
        rows = [("1", "antonelli", "Mercedes", 380, 382, ""), ("2", "verstappen", "Red Bull · FORA", 261, 261, ""),
                ("3", "leclerc", "Ferrari", 255, 280, "▲1"), ("4", "hamilton", "Ferrari", 259, 259, "▼1")]
        body = "".join(f'<div class="rw{" me" if did == "antonelli" else ""}"><span class="p">{p}</span>{face(did, 34)}<div class="n">{D[did]["name"]}<small>{sub}</small></div>'
                       f'<span class="pts">{a} → <b>{b}</b></span><span class="mv {"up" if mv.startswith("▲") else "dn"}">{mv}</span></div>' for p, did, sub, a, b, mv in rows)
        return f'''<div class="champ"><div class="hd">{ico("flag", 18, "#fff", 2.4)}<b>CAMPEONATO AO VIVO</b><small>se terminar assim</small></div>
<div class="bd">{body}<div class="msg"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ffd24a" stroke-width="2.2" stroke-linecap="round">{TROPHY}</svg>
Antonelli abre 121 pontos · faltam 2 corridas (50 pontos)</div></div></div>'''
    if kind == "teams":
        rows = [("1", "mercedes", 630, 632, ""), ("2", "ferrari", 504, 529, ""), ("3", "redbull", 382, 382, ""), ("4", "mclaren", 360, 378, "")]
        body = "".join(f'<div class="rw{" me" if tid == "mercedes" else ""}"><span class="p">{p}</span>{logo(tid, 32)}<div class="n">{B.teams[tid]["name"]}</div>'
                       f'<span class="pts">{a} → <b>{b}</b></span><span class="mv up">{"+%d" % (b - a) if b > a else ""}</span></div>' for p, tid, a, b, _ in rows)
        return f'''<div class="champ"><div class="hd">{ico("flag", 18, "#fff", 2.4)}<b>CONSTRUTORES AO VIVO</b><small>se terminar assim</small></div>
<div class="bd">{body}<div class="msg">{ico("bolt", 18, "#ff8a80", 2.4)} Ferrari tira 23 pontos da Mercedes nesta corrida</div></div></div>'''
    return f'''<div class="champ gold"><div class="hd"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round">{TROPHY}</svg>
<b>TÍTULO EM JOGO</b><small>volta 12 de 18</small></div>
<div class="bd"><div class="big">{face("antonelli", 64)}<div><strong>SE TERMINAR ASSIM, ANTONELLI É CAMPEÃO</strong><small>Precisa terminar à frente de Verstappen ou até 6 posições atrás</small></div></div>
<div class="bar2"><i style="width:88%"></i></div><div class="msg">{ico("clock", 18, "#ffd24a", 2.4)} Verstappen fora da corrida: só um milagre muda a história</div></div></div>'''


def page(kind):
    body = f'<div class="scene"><div class="base" style="background-image:url(file://{BASE})"></div>{card(kind)}</div>'
    return V.page("V17 · Campeonato ao vivo", CSS, body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V17_OUT"]) if os.environ.get("V17_OUT") else HERE
    B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
    V.EMB = "file://" + str((ROOT / "game/assets/emblems").resolve()) + "/{}.svg"
    for i, k in enumerate(["drivers", "teams", "title"], 1):
        (out / f"v17-{i}-campeonato-{k}.html").write_text(page(k), encoding="utf-8")
    print("ok")
