"""V22 · Pneus do fim de semana, saída da classificação e estratégia (decisões de 2026-11-08, todos os modos).
1) Classificação: ao mandar o piloto para a pista, folha com todos os jogos disponíveis, atitude (2 níveis) e 1 ou 2 voltas.
2) Estratégia antes da largada: plano pronto dos engenheiros para os dois pilotos, que o jogador pode alterar.
3) Corrida: o plano só avisa (a parada acontece se o jogador confirmar no box); o cartão mantém o pneu só como informação.
Uso: python design/mockups/build_v22.py   (V22_FACES=<pasta> V22_OUT=<pasta>: versão local com rostos)
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
FACES = os.environ.get("V22_FACES")
D = {d["id"]: d for d in V.DRIVERS}
COL = B.teams["williams"]["color"]
TY = json.loads((ROOT / "game/data/tyres_2026.json").read_text(encoding="utf-8"))["compounds"]

G = {
    "shield": '<path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z"/>',
    "fire": '<path d="M12 3c1 4 6 6 6 11a6 6 0 0 1-12 0c0-3 2-4 2-7 2 1 3 3 3 5 1-2 1-6 1-9z"/>',
    "lap": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/>',
    "lock": '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
    "eng": '<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="2" y="14" width="5" height="6" rx="2"/><rect x="17" y="14" width="5" height="6" rx="2"/>',
    "edit": '<path d="M4 20h4L19 9l-4-4L4 16z"/>',
    "box": '<path d="M3 8l9-5 9 5v9l-9 5-9-5zM3 8l9 5 9-5M12 13v9"/>',
    "check": '<path d="M5 12l5 5 9-10"/>',
    "warn": '<path d="M12 3l10 18H2zM12 10v5M12 18v.5"/>',
}


def g(n, s=18, c="currentColor", w=2.3):
    return (f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" '
            f'stroke-linejoin="round" style="flex:none">{G[n]}</svg>')


def face(did, size):
    inner = f'<img src="file://{FACES}/{did}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES else ""
    return f'<span class="fc" style="width:{size}px;height:{size}px;background:{COL}">{inner}</span>'


def tyre(k, size=34):
    t = TY[k]
    return (f'<span class="ty" style="width:{size}px;height:{size}px;border-color:{t["color"]};font-size:{size * 0.45:.0f}px">'
            f'{t["letter"]}</span>')


CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.bg{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 30% 30%,#1b2a55,#0b0c0f 72%)}
.fc{border-radius:50%;overflow:hidden;display:block;flex:none}
.ty{border-radius:50%;border:4px solid;background:#15171c;color:#fff;font-weight:900;display:grid;place-items:center;flex:none}
.cap{font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.rb{width:48px;height:48px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;font-weight:900}
.cta{height:56px;background:#E10600;color:#fff;font-weight:900;font-size:19px;display:flex;align-items:center;justify-content:center;gap:10px;
 clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,0 100%);border-radius:14px 0 14px 14px;padding:0 26px}
.ghost{height:56px;border-radius:14px;background:rgba(255,255,255,.08);font-weight:900;font-size:16px;display:flex;align-items:center;justify-content:center;padding:0 22px;gap:8px}
.dim{position:absolute;inset:0;background:rgba(0,0,0,.62)}
.sheet{position:absolute;border-radius:24px;background:#17191e;padding:20px 24px}
.sheet h2{font-size:28px;font-weight:900;line-height:1}
/* 1: saída da classificação */
.sets{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-top:10px}
.set{border-radius:16px;background:rgba(255,255,255,.05);padding:10px 12px;display:flex;align-items:center;gap:10px;height:68px;border:2px solid transparent}
.set.on{background:#f3f4f6;color:#11141a;border-color:#f3f4f6}
.set.off{opacity:.4}
.set strong{display:block;font-size:15px;font-weight:900}.set small{display:block;font-size:12px;font-weight:800;color:#a8b0bd}
.set.on small{color:#4b5260}
.life{height:6px;border-radius:3px;background:rgba(255,255,255,.12);margin-top:4px;width:90px;overflow:hidden}.life i{display:block;height:100%;background:#7fe0b1}
.set.on .life{background:#d6d9df}
.opt{flex:1;border-radius:16px;background:rgba(255,255,255,.05);padding:12px 14px;border:2px solid transparent}
.opt.on{background:#f3f4f6;color:#11141a}
.opt strong{display:flex;align-items:center;gap:8px;font-size:17px;font-weight:900}.opt small{display:block;font-size:12px;font-weight:700;color:#a8b0bd;margin-top:4px;line-height:1.35}
.opt.on small{color:#4b5260}
.row{display:flex;gap:10px;margin-top:10px}
.sum{border-radius:18px;background:rgba(255,255,255,.05);padding:14px 16px}
.kv{display:flex;justify-content:space-between;font-size:14px;font-weight:800;color:#c3c9d3;margin-top:8px}.kv b{color:#fff;font-weight:900}
.alloc{display:flex;gap:14px;align-items:center;font-size:13px;font-weight:900;color:#c3c9d3}
.alloc span{display:flex;align-items:center;gap:6px}
/* 2: estratégia */
.hd{position:absolute;left:44px;top:22px;right:44px;display:flex;align-items:center;gap:14px}
.hd h1{font-size:28px;font-weight:900;line-height:1}.hd small{display:block;font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.col{position:absolute;top:104px;width:586px;border-radius:22px;background:rgba(255,255,255,.06);padding:14px 16px}
.dh{display:flex;align-items:center;gap:10px}.dh strong{font-size:19px;font-weight:900}.dh small{display:block;font-size:12px;color:#a8b0bd;font-weight:800}
.plans{display:flex;gap:8px;margin-top:10px}
.plan{flex:1;border-radius:14px;background:rgba(255,255,255,.06);padding:8px 10px;font-size:13px;font-weight:900}
.plan small{display:block;font-size:11px;color:#a8b0bd;font-weight:800;margin-top:2px}
.plan.on{background:#f3f4f6;color:#11141a}.plan.on small{color:#4b5260}
.tl{display:flex;height:30px;border-radius:8px;overflow:hidden;margin-top:12px;gap:2px}
.tl i{display:flex;align-items:center;justify-content:center;font-style:normal;font-size:12px;font-weight:900;color:#11141a}
.ticks{display:flex;justify-content:space-between;font-size:11px;font-weight:800;color:#8f98a7;margin-top:3px}
.stint{display:flex;align-items:center;gap:10px;border-radius:14px;background:rgba(0,0,0,.25);padding:8px 10px;margin-top:8px;height:58px}
.stint strong{font-size:15px;font-weight:900;display:block}.stint small{font-size:12px;color:#a8b0bd;font-weight:800;display:block}
.step{width:44px;height:44px;border-radius:12px;background:rgba(255,255,255,.08);display:grid;place-items:center;font-size:22px;font-weight:900}
.lapv{width:70px;text-align:center;font-size:20px;font-weight:900}.lapv small{font-size:10px;letter-spacing:2px;color:#8f98a7}
.chip{border-radius:999px;background:rgba(255,255,255,.08);padding:4px 10px;font-size:12px;font-weight:900;display:inline-flex;gap:6px;align-items:center}
.ok{color:#7fe0b1}.wa{color:#ffd24a}
.foot{position:absolute;left:44px;right:44px;bottom:24px;display:flex;align-items:center;gap:12px}
/* 3: corrida */
.track{position:absolute;inset:0;background:radial-gradient(ellipse 70% 60% at 55% 50%,#24304a,#0b0c0f 75%)}
.glass{position:absolute;border-radius:20px;background:rgba(11,13,18,.86);padding:12px 14px}
.seg{display:flex;border-radius:12px;background:rgba(255,255,255,.06);overflow:hidden;flex:1}
.seg span{flex:1;text-align:center;font-size:12px;font-weight:900;padding:8px 0;color:#c3c9d3}.seg .on{background:#f3f4f6;color:#11141a}
.banner{position:absolute;border-radius:18px;background:#f3f4f6;color:#11141a;padding:12px 16px;display:flex;align-items:center;gap:14px;box-shadow:inset 6px 0 0 #E10600}
.banner strong{font-size:18px;font-weight:900;display:block}.banner small{font-size:12px;font-weight:800;color:#4b5260;display:block}
"""


def sheet_quali():
    sets = [
        ("soft", "Macio novo", "0 voltas", 100, "on", ""), ("soft", "Macio novo", "0 voltas", 100, "", ""),
        ("soft", "Macio novo", "guardado para o Q3", 100, "off", "lock"), ("soft", "Macio usado", "3 voltas (TL3)", 74, "", ""),
        ("medium", "Médio novo", "0 voltas", 100, "", ""), ("hard", "Duro novo", "0 voltas", 100, "", ""),
    ]
    tiles = ""
    for k, n, sub, life, cls, extra in sets:
        tiles += (f'<div class="set {cls}">{tyre(k)}<div style="flex:1"><strong>{n}</strong><small>{sub}</small>'
                  f'<div class="life"><i style="width:{life}%"></i></div></div>{g(extra, 18, "#8f98a7") if extra else ""}</div>')
    attitude = (f'<div class="row"><div class="opt on"><strong>{g("shield", 20)}Garantir tempo</strong><small>Volta limpa, com margem nas zebras. '
                f'Menos chance de erro; cerca de 0,15 s mais lenta.</small></div>'
                f'<div class="opt"><strong>{g("fire", 20, "#ff8a80")}Buscar o limite</strong><small>Tudo na volta: mais rápida, mas com mais chance '
                f'de erro e volta apagada (limite de pista).</small></div></div>')
    laps = (f'<div class="row"><div class="opt"><strong>{g("lap", 20)}1 volta rápida</strong><small>Sai, faz a volta e volta para o box. Gasta pouco o jogo.</small></div>'
            f'<div class="opt on"><strong>{g("lap", 20)}2 voltas rápidas</strong><small>Volta de resfriamento entre as duas. Segunda chance, '
            f'mas o pneu cai um pouco.</small></div></div>')
    summary = ('<div class="sum"><div class="cap">ESTA SAÍDA</div>'
               f'<div style="display:flex;align-items:center;gap:10px;margin-top:8px">{tyre("soft", 40)}<div><b style="font-size:18px;font-weight:900">Macio novo</b>'
               '<small style="display:block;font-size:12px;color:#a8b0bd;font-weight:800">garantir tempo · 2 voltas</small></div></div>'
               '<div class="kv">Tempo previsto<b>1:10.6</b></div><div class="kv">Corte do Q1 (agora)<b>1:11.2</b></div>'
               '<div class="kv">Tempo de sessão<b>7:42</b></div><div class="kv">Volta no box em<b>~5 min</b></div></div>')
    alloc = (f'<div class="alloc"><span class="cap" style="letter-spacing:2px">FIM DE SEMANA</span>'
             f'<span>{tyre("soft", 22)}4 de 8</span><span>{tyre("medium", 22)}1 de 3</span><span>{tyre("hard", 22)}1 de 2</span>'
             f'<span style="color:#8f98a7">6 jogos devolvidos nos treinos</span></div>')
    return (f'<div class="dim"></div><div class="sheet" style="left:60px;top:40px;width:1160px">'
            f'<div style="display:flex;align-items:center;gap:12px">{face("albon", 48)}<div><div class="cap">Q1 · SAÍDA PARA A PISTA</div>'
            f'<h2>ALEXANDER ALBON</h2></div><span class="rb" style="margin-left:auto">✕</span></div>'
            f'<div style="display:flex;gap:18px;margin-top:12px"><div style="flex:1"><div class="cap">PNEUS DISPONÍVEIS</div><div class="sets">{tiles}</div>'
            f'<div class="cap" style="margin-top:16px">ATITUDE NA VOLTA</div>{attitude}'
            f'<div class="cap" style="margin-top:16px">VOLTAS NESTA SAÍDA</div>{laps}</div>'
            f'<div style="width:300px;display:flex;flex-direction:column;gap:12px">{summary}<div class="cta">MANDAR PARA A PISTA {ico("chev", 20, "#fff", 3)}</div></div></div>'
            f'<div style="margin-top:14px">{alloc}</div></div>')


def quali():
    body = (f'<div class="scene"><div class="track"></div>{sheet_quali()}</div>')
    return V.page("V22 · Classificação · saída para a pista", CSS, body)


def col(did, eng, x, plans, sel, stints, stock, warn):
    d = D[did]
    total = 71
    tl = "".join(f'<i style="width:{laps / total * 100:.1f}%;background:{TY[k]["color"]}">{TY[k]["letter"]} · {laps}</i>' for k, laps, _ in stints)
    pl = "".join(f'<div class="plan{" on" if i == sel else ""}">{n}<small>{s}</small></div>' for i, (n, s) in enumerate(plans))
    rows = ""
    lap = 1
    for i, (k, laps, cond) in enumerate(stints):
        end = lap + laps - 1
        title = "Largada" if i == 0 else f"Parada {i} · volta {lap - 1}"
        rows += (f'<div class="stint">{tyre(k, 38)}<div style="flex:1"><strong>{title}</strong><small>{TY[k]["name"]} {cond} · voltas {lap}–{end}</small></div>'
                 f'<span class="step">−</span><div class="lapv">{laps}<small><br>VOLTAS</small></div><span class="step">+</span></div>')
        lap = end + 1
    st = "".join(f'<span class="chip">{tyre(k, 20)}{n}</span>' for k, n in stock)
    w = (f'<div style="margin-top:10px;font-size:13px;font-weight:800" class="{"wa" if warn else "ok"}">{g("warn" if warn else "check", 16, "currentColor")} '
         f'{warn or "Usa dois compostos secos · pneus dentro do estoque"}</div>')
    return (f'<div class="col" style="left:{x}px"><div class="dh">{face(did, 46)}<div><strong>{d["name"]}</strong><small>larga em P9 · {eng}</small></div>'
            f'<span class="chip" style="margin-left:auto">{g("edit", 14)}alterado por você</span></div>'
            f'<div class="cap" style="margin-top:12px">PLANOS DOS ENGENHEIROS</div><div class="plans">{pl}</div>'
            f'<div class="tl">{tl}</div><div class="ticks"><span>1</span><span>20</span><span>40</span><span>60</span><span>71</span></div>'
            f'{rows}<div class="cap" style="margin-top:12px">ESTOQUE PARA A CORRIDA</div><div style="display:flex;gap:6px;margin-top:6px;flex-wrap:wrap">{st}</div>{w}</div>')


def strategy():
    plans = [("1 parada", "M → D · mais segura"), ("2 paradas", "M → D → M · +3 s"), ("2 paradas", "S → M → M · aposta")]
    a = col("albon", "James Urwin", 44, plans, 0, [("medium", 27, "novo"), ("hard", 44, "novo")],
            [("soft", "Macio usado ×4"), ("medium", "Médio novo ×1"), ("hard", "Duro novo ×2")], "")
    b = col("sainz", "Gaëtan Jago", 650, plans, 1, [("medium", 20, "novo"), ("hard", 26, "novo"), ("medium", 25, "novo")],
            [("soft", "Macio usado ×4"), ("medium", "Médio novo ×1"), ("hard", "Duro novo ×1")], "Só 1 médio novo no estoque: a última parada usa médio usado")
    body = (f'<div class="scene"><div class="bg"></div><div class="hd"><span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span>'
            f'<div><small>ANTES DA LARGADA · 71 VOLTAS · 25% CHUVA</small><h1>ESTRATÉGIA DA CORRIDA</h1></div>'
            f'<span class="chip" style="margin-left:auto;font-size:13px">{g("eng", 16, "#5c93ea")}Os engenheiros montaram os planos; toque para mudar</span></div>'
            f'{a}{b}<div class="foot"><div class="ghost">VOLTAR AO PLANO DOS ENGENHEIROS</div>'
            f'<div style="flex:1;font-size:13px;font-weight:800;color:#a8b0bd">Na corrida o plano só avisa: a parada acontece quando você confirma no box.</div>'
            f'<div class="cta">IR PARA O GRID {ico("chev", 20, "#fff", 3)}</div></div></div>')
    return V.page("V22 · Estratégia antes da largada", CSS, body)


def race():
    card = (f'<div class="glass" style="left:24px;bottom:24px;width:330px"><div class="dh">{face("albon", 40)}<div><strong>Albon</strong>'
            f'<small>P7 · +1,4 s do P6</small></div></div>'
            f'<div style="display:flex;align-items:center;gap:8px;margin-top:10px;font-size:13px;font-weight:800;color:#c3c9d3">{tyre("medium", 22)}Médio · 25v'
            f'<div class="life" style="flex:1;margin:0"><i style="width:38%;background:#ffd24a"></i></div>38%</div>'
            f'<div style="display:flex;gap:6px;margin-top:10px"><div class="seg"><span>Poupar</span><span class="on">Normal</span><span>Atacar</span></div></div>'
            f'<div style="display:flex;gap:6px;margin-top:6px"><div class="seg"><span>Carregar</span><span class="on">Equil.</span><span>Usar</span></div></div>'
            f'<div style="display:flex;gap:6px;margin-top:10px"><div class="ghost" style="height:44px;font-size:12px">EQUIPE</div>'
            f'<div class="cta" style="height:44px;flex:1;font-size:14px">P/ BOX {g("box", 16, "#fff")}</div></div></div>')
    banner = (f'<div class="banner" style="left:24px;bottom:320px;width:470px">{tyre("hard", 40)}<div style="flex:1"><div class="cap" style="color:#4b5260">'
              f'PLANO · VOLTA 27</div><strong>Albon: hora de parar</strong><small>Plano dos engenheiros: Duro novo. Toque em P/ BOX para decidir.</small></div>'
              f'<div class="ghost" style="height:44px;background:#e3e6eb;font-size:13px">DEPOIS</div></div>')
    note = ('<div class="glass" style="right:24px;top:24px;width:420px;font-size:13px;font-weight:800;color:#c3c9d3;line-height:1.45">'
            '<div class="cap">O QUE MUDA</div>O cartão continua mostrando o pneu em uso só como informação. O pneu novo se escolhe '
            'apenas na tela do box (que já abre com o pneu do plano marcado), junto com asa, reparos e punição.</div>')
    body = f'<div class="scene"><div class="track"></div>{note}{banner}{card}</div>'
    return V.page("V22 · Corrida · aviso do plano", CSS, body)


def grid():
    order = ["norris", "verstappen", "leclerc", "piastri", "russell", "hamilton", "antonelli", "hadjar", "albon", "sainz",
             "alonso", "gasly", "lawson", "bearman", "ocon", "hulkenberg", "bortoleto", "stroll", "colapinto", "lindblad", "perez", "bottas"]
    tiles = ""
    for i, did in enumerate(order):
        d = D.get(did, {"name": did.title(), "number": 0, "team": "williams"})
        row, side = divmod(i, 2)
        shown = row >= 4  # a animação já revelou das filas 11 até a 6; as filas 5 → 1 ainda vão aparecer
        cur = row == 4
        x = 300 + side * 360
        y = 560 - (10 - row) * 0 if False else 120 + (10 - row) * 0
        tc = B.teams[d["team"]]["color"]
        op = "1" if shown else ".12"
        tiles += (f'<div class="gt" style="opacity:{op};{"transform:scale(1.04);box-shadow:0 0 0 3px #E10600;" if cur else ""}">'
                  f'<span class="gp">{i + 1}</span>{face(did, 32) if shown else '<span class="fc" style="width:32px;height:32px;background:rgba(255,255,255,.08)"></span>'}'
                  f'<div style="flex:1"><strong>{d["name"] if shown else "—"}</strong><small style="color:{tc}">{B.teams[d["team"]]["name"] if shown else ""}</small></div>'
                  f'<span class="gn">{d["number"] if shown else ""}</span></div>')
    body = (f'<div class="scene"><div class="track"></div><div class="hd"><div><small>GP DE SÃO PAULO · GRID DE LARGADA</small><h1>DA ÚLTIMA FILA PARA A PRIMEIRA</h1></div>'
            f'<span class="ghost" style="margin-left:auto;height:48px">PULAR</span></div>'
            f'<div class="grid">{tiles}</div>'
            f'<div class="hero2">{face("albon", 120)}<div><div class="cap">FILA 5 · P9</div><div style="font-size:40px;font-weight:900;line-height:1">ALEXANDER ALBON</div>'
            f'<div style="font-size:15px;font-weight:800;color:#a8b0bd;margin-top:6px">Williams · 1:10.874 no Q3 · seu piloto</div></div></div></div>')
    css = CSS + """.grid{position:absolute;left:44px;top:96px;width:720px;display:grid;grid-template-columns:1fr 1fr;gap:4px 14px;direction:ltr}
.gt{display:flex;align-items:center;gap:10px;height:40px;border-radius:12px;background:rgba(255,255,255,.06);padding:0 10px}
.gt:nth-child(even){margin-top:20px;margin-bottom:-20px}
.gp{width:28px;font-size:16px;font-weight:900;color:#8f98a7}.gt strong{display:block;font-size:14px;font-weight:900}.gt small{display:block;font-size:11px;font-weight:900}
.gn{font-size:22px;font-weight:900;color:#c3c9d3}
.hero2{position:absolute;left:800px;top:250px;width:440px;display:flex;flex-direction:column;gap:14px;border-radius:24px;background:rgba(11,13,18,.86);padding:22px}"""
    return V.page("V22 · Grid de largada", css, body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V22_OUT"]) if os.environ.get("V22_OUT") else HERE
    if os.environ.get("V22_OUT"):
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
    (out / "v22-1-classificacao-saida.html").write_text(quali(), encoding="utf-8")
    (out / "v22-2-estrategia.html").write_text(strategy(), encoding="utf-8")
    (out / "v22-3-corrida-aviso.html").write_text(race(), encoding="utf-8")
    (out / "v22-4-grid-largada.html").write_text(grid(), encoding="utf-8")
    print("ok")
