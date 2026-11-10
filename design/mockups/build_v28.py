"""V28 · Resultado entre as partes da classificação (pedido de 2026-11-10): a sessão para e mostra o resultado,
com destaque para os eliminados (Q1/Q2) e para a pole (fim do Q3); sempre pede confirmação para continuar.
Uso: python design/mockups/build_v28.py  (V26_FACES=<pasta> para a versão local com rostos)."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v26 as W  # noqa: E402

HERE = B.HERE
g = W.g
EMB = W.EMB
PLAYER = "mercedes"

CSS = W.CSS + """
.dim{position:absolute;inset:0;background:rgba(5,7,10,.66)}
.sheet{position:absolute;left:60px;right:60px;top:34px;bottom:34px;border-radius:26px;background:rgba(17,19,25,.96);box-shadow:0 20px 60px rgba(0,0,0,.6);padding:22px 26px}
.h1{font-size:34px;font-weight:900;letter-spacing:.5px}
.cols{display:flex;gap:22px;margin-top:16px}
.lst{display:grid;grid-template-columns:1fr 1fr;gap:6px 14px;flex:1}
.row{display:flex;align-items:center;gap:10px;height:40px;border-radius:12px;background:rgba(255,255,255,.05);padding:0 12px;font-weight:900;font-size:15px}
.row .p{width:26px;text-align:center;color:#a8b0bd}.row .t{margin-left:auto;font-variant-numeric:tabular-nums}.row .d{width:62px;text-align:right;color:#8f98a7;font-size:13px}
.row.me{background:rgba(39,244,210,.16);box-shadow:inset 4px 0 0 #27F4D2}
.out{width:372px;border-radius:20px;background:linear-gradient(rgba(225,6,0,.2),rgba(225,6,0,.08));border:2px solid rgba(225,6,0,.55);padding:14px}
.orow{display:flex;align-items:center;gap:12px;margin-top:10px;font-weight:900}
.orow .n{font-size:18px;line-height:1}.orow small{display:block;font-size:12px;color:#ffb4a8;font-weight:800;margin-top:3px}
.cut{display:flex;align-items:center;gap:10px;margin:10px 0 2px;font-size:12px;font-weight:900;letter-spacing:2px;color:#ff8a80}
.cut i{flex:1;height:0;border-top:2px dashed rgba(255,138,128,.6)}
.foot{position:absolute;left:26px;right:26px;bottom:20px;display:flex;align-items:center;gap:14px;color:#a8b0bd;font-size:14px;font-weight:800}
.hero{width:470px;border-radius:24px;position:relative;overflow:hidden;height:470px;background:linear-gradient(160deg,%s,#10131a 75%%)}
.hero .num{right:14px;top:30px;font-size:250px;color:rgba(255,255,255,.12)}
.poletag{display:inline-flex;align-items:center;gap:8px;height:36px;border-radius:18px;padding:0 16px;background:#F5C542;color:#11141a;font-weight:900;font-size:15px;letter-spacing:1.5px}
""" % B.teams[PLAYER]["color"]


def emb(t, s=26):
    return f'<img src="{EMB.format(t)}" style="width:{s}px;height:{s}px;border-radius:{s // 4}px;flex:none">'


def tm(sec):
    m = int(sec // 60)
    return f"{m}:{sec - 60 * m:06.3f}".replace(".", ",")


ORDER = ["VER", "HAD", "NOR", "PIA", "LEC", "RUS", "HAM", "ANT", "ALB", "SAI", "LAW", "LIN", "ALO", "STR", "GAS", "COL",
         "OCO", "BEA", "HUL", "BOR", "PER", "BOT"]


def times(base, step=0.11):
    return [base + i * step + (i % 3) * 0.02 for i in range(len(ORDER))]


def row(i, code, t, lead):
    d = B.drivers[code]
    me = " me" if d["team"] == PLAYER else ""
    gap = "—" if i == 0 else "+" + f"{t - lead:.3f}".replace(".", ",")
    return (f'<div class="row{me}"><span class="p">{i + 1}</span>{emb(d["team"])}<span>{code}</span>'
            f'<span class="t">{tm(t)}</span><span class="d">{gap}</span></div>')


def shell(inner):
    return V.page("V28 · Resultado da classificação", CSS, f'<div class="scene"><div class="bgx"></div><div class="dim"></div>{inner}</div>')


def fim_q(seg, n_pass, label_next, base):
    ts = times(base)
    passed = "".join(row(i, c, ts[i], ts[0]) for i, c in enumerate(ORDER[:n_pass]))
    cutt = ts[n_pass - 1]
    outs = ""
    for i in range(n_pass, len(ORDER)):
        c = ORDER[i]
        d = B.drivers[c]
        outs += (f'<div class="orow">{W.face(c, 46, "#E10600")}<div style="flex:1"><div class="n">{d["name"].split()[-1].upper()}</div>'
                 f'<small>P{i + 1} · {tm(ts[i])} · +{ts[i] - cutt:.3f} do corte'.replace(".", ",") + f'</small></div>{emb(d["team"], 30)}</div>')
    n_out = len(ORDER) - n_pass
    inner = (f'<div class="sheet"><div style="display:flex;align-items:center;gap:14px"><div class="h1">FIM DO {seg}</div>'
             f'<span class="chip" style="background:#3c9d5d">{n_pass} PASSAM PARA O {label_next}</span>'
             f'<span class="chip" style="background:rgba(225,6,0,.3);color:#ffb4a8">{n_out} ELIMINADOS</span>'
             f'<span style="flex:1"></span><span class="chip">{g("timer", 16)}{seg} · GP DE SÃO PAULO</span></div>'
             f'<div class="cols"><div class="lst" style="grid-auto-flow:column;grid-template-rows:repeat({(n_pass + 1) // 2},40px)">{passed}</div>'
             f'<div class="out"><div class="cap" style="color:#ff8a80">ELIMINADOS · LARGAM DE P{n_pass + 1} A P{len(ORDER)}</div>{outs}</div></div>'
             f'<div class="foot">{g("bell", 16)}O {label_next} só começa quando você confirmar.<span style="flex:1"></span>'
             f'<div class="cta" style="height:58px;font-size:22px;min-width:300px">CONTINUAR · {label_next}{g("chev", 22, "#fff")}</div></div></div>')
    return shell(inner)


def pole():
    ts = times(68.912, 0.09)
    d = B.drivers["RUS"]
    hero = (f'<div class="hero"><div class="num">{d["number"]}</div>'
            f'<div style="position:absolute;left:22px;top:22px"><span class="poletag">{g("trophy", 18, "#11141a")}POLE POSITION</span></div>'
            f'<div style="position:absolute;left:22px;top:84px">{W.face("RUS", 190, "#F5C542")}</div>'
            f'<div style="position:absolute;left:22px;bottom:22px;right:22px"><div class="big" style="font-size:50px">{d["name"].split()[-1].upper()}</div>'
            f'<div style="display:flex;align-items:center;gap:12px;margin-top:10px">{emb(d["team"], 34)}<span class="big" style="font-size:36px;font-variant-numeric:tabular-nums">{tm(ts[0])}</span>'
            f'<span class="chip" style="background:rgba(245,197,66,.25);color:#F5C542">+0,110 SOBRE O 2º</span></div></div></div>')
    order = ["RUS", "VER", "NOR", "HAD", "PIA", "LEC", "HAM", "ANT", "ALB", "SAI"]
    rows = ""
    for i, c in enumerate(order[1:], start=1):
        dd = B.drivers[c]
        me = " me" if dd["team"] == PLAYER else ""
        gap = "+" + f"{ts[i] - ts[0]:.3f}".replace(".", ",")
        front = ' style="height:46px;font-size:17px;box-shadow:inset 4px 0 0 #F5C542"' if i == 1 else ""
        rows += (f'<div class="row{me}"{front}><span class="p">{i + 1}</span>{emb(dd["team"])}<span>{c}</span>'
                 f'<span class="t">{tm(ts[i])}</span><span class="d">{gap}</span></div>')
    inner = (f'<div class="sheet"><div style="display:flex;align-items:center;gap:14px"><div class="h1">FIM DO Q3</div>'
             f'<span style="flex:1"></span><span class="chip">{g("timer", 16)}GP DE SÃO PAULO</span></div>'
             f'<div class="cols">{hero}<div style="flex:1;display:flex;flex-direction:column;gap:6px"><div class="cap" style="margin-bottom:4px">GRID · DO 2º AO 10º</div>{rows}</div></div>'
             f'<div class="foot">{g("flag", 16)}A tabela vira o grid de largada.<span style="flex:1"></span>'
             f'<div class="cta" style="height:58px;font-size:22px;min-width:300px">CONTINUAR{g("chev", 22, "#fff")}</div></div></div>')
    return shell(inner)


if __name__ == "__main__":
    pages = {"v28-1-fim-do-q1": lambda: fim_q("Q1", 16, "Q2", 69.35),
             "v28-2-fim-do-q2": lambda: fim_q("Q2", 10, "Q3", 68.95),
             "v28-3-pole": pole}
    for name, fn in pages.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
