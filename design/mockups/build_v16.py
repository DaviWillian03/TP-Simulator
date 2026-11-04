"""V16 · Menu principal só com o logo e os modos + escolha de equipe dentro de cada modo (pedido de 2026-11-04).
Padrão de tela "seleção de equipe" (nome gigante em contorno, carro em destaque, fileira de emblemas) com a identidade
visual do jogo — não é cópia de outro jogo. Acrescenta dados da equipe, objetivos e fotos/dados dos pilotos.
Uso: python design/mockups/build_v16.py   (V16_FACES=<pasta de fotos> V16_LOGOS=<pasta de logos> V16_OUT=<pasta>: versão local)
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
FACES = os.environ.get("V16_FACES")
LOGOS = os.environ.get("V16_LOGOS")
ORDER = ["mclaren", "mercedes", "ferrari", "redbull", "williams", "racingbulls", "astonmartin", "haas", "alpine", "audi", "cadillac"]
ORIGINS = json.loads((ROOT / "game/data/campaign_origins.json").read_text(encoding="utf-8"))


def logo(tid, w):
    if LOGOS:
        return f'<img src="file://{LOGOS}/{tid}.png" style="width:{w}px;height:{w}px;object-fit:contain">'
    return f'<img src="{V.EMB.format(tid)}" width="{w}">'


def face(d, size):
    col = B.teams[d["team"]]["color"]
    inner = (f'<img src="file://{FACES}/{d["id"]}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES
             else logo(d["team"], size // 2))
    return f'<span class="face" style="width:{size}px;height:{size}px;background:{col}">{inner}</span>'


CSS = V.G_CSS + """
.scene{background:#07080a}
.menu-bg{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 50% 45%,#1d2230,#07080a 72%)}
.menu-bg:before{content:"";position:absolute;inset:0;background:repeating-linear-gradient(180deg,rgba(255,255,255,.025) 0 1px,transparent 1px 46px)}
.beam{position:absolute;top:-40px;width:180px;height:820px;background:linear-gradient(rgba(255,255,255,.10),transparent 80%);transform:skewX(-14deg);filter:blur(6px)}
.logo-big{position:absolute;left:0;right:0;top:70px;display:flex;justify-content:center}
.modes{position:absolute;left:405px;top:290px;width:470px;display:flex;flex-direction:column;gap:10px}
.mode{height:74px;border-radius:18px;background:rgba(255,255,255,.06);display:flex;align-items:center;padding:0 18px 0 22px;gap:16px}
.mode .mi{width:44px;height:44px;border-radius:14px;background:rgba(255,255,255,.08);display:grid;place-items:center;flex:none}
.mode strong{display:block;font-size:24px;font-weight:900;letter-spacing:.5px}.mode small{display:block;font-size:13px;color:#a8b0bd;font-weight:700}
.mode .go{margin-left:auto}
.mode.on{background:#f3f4f6;color:#11141a;box-shadow:inset 7px 0 0 #E10600}.mode.on small{color:#4b5260}.mode.on .mi{background:#E10600}
.mode.off{opacity:.45}
.foot{position:absolute;left:44px;bottom:30px;display:flex;gap:10px}
.pill{height:44px;border-radius:22px;background:rgba(255,255,255,.08);display:flex;align-items:center;gap:8px;padding:0 18px;font-size:14px;font-weight:900}
.ver{position:absolute;right:44px;bottom:38px;font-size:12px;color:#6c7380;font-weight:700;letter-spacing:2px}
/* escolha de equipe */
.ts-bg{position:absolute;inset:0;background:radial-gradient(ellipse 80% 70% at 50% 48%,%TC%55,#07080a 72%)}
.ts-bg:before{content:"";position:absolute;inset:0;background:repeating-linear-gradient(105deg,rgba(255,255,255,.035) 0 2px,transparent 2px 70px)}
.ts-bg:after{content:"";position:absolute;left:0;right:0;bottom:0;height:300px;background:linear-gradient(transparent,rgba(0,0,0,.75))}
.slab{position:absolute;left:470px;top:0;width:360px;height:64px;background:%TC%;border-radius:0 0 26px 26px;opacity:.9}
.giant{position:absolute;left:0;right:0;top:128px;text-align:center;font-size:178px;line-height:1;font-weight:900;letter-spacing:6px;color:transparent;
 -webkit-text-stroke:2px rgba(255,255,255,.55);white-space:nowrap}
.tag{display:inline-block;background:#E10600;color:#fff;font-size:12px;letter-spacing:2px;font-weight:900;border-radius:6px;padding:4px 10px}
.ts-head{position:absolute;left:44px;top:30px}
.ts-head h1{font-size:40px;font-weight:900;line-height:1.05;margin-top:8px}
.ts-head small{display:block;font-size:13px;color:#c3c9d3;font-weight:700;margin-top:2px}
.car{position:absolute;left:300px;top:330px;width:680px}
.reflect{position:absolute;left:300px;top:518px;width:680px;transform:scaleY(-1);opacity:.18;filter:blur(1px);-webkit-mask-image:linear-gradient(transparent 40%,#000)}
.glass{position:absolute;border-radius:20px;background:rgba(8,9,12,.72);border:1px solid rgba(255,255,255,.08);padding:14px 16px}
.info{left:44px;top:330px;width:256px;padding:12px 14px}
.info .cap{font-size:11px}
.tr{display:flex;align-items:center;gap:8px;margin-top:5px;font-size:13px;font-weight:700;color:#c3c9d3}
.tr .bar{flex:1;height:7px;border-radius:4px;background:rgba(255,255,255,.12);overflow:hidden}.tr .bar i{display:block;height:100%}
.tr b{width:24px;text-align:right;color:#fff;font-weight:900}
.kv{display:flex;justify-content:space-between;font-size:12px;font-weight:700;color:#a8b0bd;margin-top:4px}.kv span:last-child{color:#fff;font-weight:900}
.big-r{display:flex;align-items:baseline;gap:8px;margin-top:0}.big-r b{font-size:32px;font-weight:900}.big-r small{font-size:12px;color:#a8b0bd;font-weight:700}
.drivers{right:44px;top:330px;width:268px;display:flex;flex-direction:column;gap:10px;padding:12px}
.dr{display:flex;align-items:center;gap:10px;border-radius:14px;background:rgba(255,255,255,.05);padding:10px}
.face{border-radius:50%;overflow:hidden;display:grid;place-items:center;flex:none}
.dr .num{font-size:30px;font-weight:900;color:transparent;-webkit-text-stroke:1.5px #fff;width:40px;text-align:center;flex:none}
.dr strong{display:block;font-size:17px;font-weight:900;line-height:1.1}.dr small{display:block;font-size:12px;color:#a8b0bd;font-weight:700}
.dr .dst{display:flex;gap:6px;margin-top:5px}.dr .dst span{white-space:nowrap;font-size:11px;font-weight:900;border-radius:6px;padding:2px 6px;background:rgba(255,255,255,.1)}
.goal{right:44px;top:30px;width:330px;text-align:right}
.goal b{display:block;font-size:20px;font-weight:900;margin-top:2px}.goal small{display:block;font-size:12px;color:#a8b0bd;font-weight:700;line-height:1.35;margin-top:3px}
.strip{position:absolute;left:44px;bottom:28px;display:flex;gap:6px}
.tl{width:64px;height:64px;border-radius:14px;background:rgba(18,20,26,.92);display:grid;place-items:center;border:2px solid transparent}
.tl.on{border-color:#fff;background:%TC%;box-shadow:0 0 0 4px rgba(255,255,255,.12),0 10px 30px rgba(0,0,0,.6);transform:translateY(-8px)}
.acts{position:absolute;right:44px;bottom:30px;display:flex;gap:10px;align-items:center}
.back{height:56px;border-radius:28px;background:rgba(255,255,255,.08);display:flex;align-items:center;gap:8px;padding:0 20px;font-weight:900;font-size:15px}
.cta2{height:60px;width:240px;background:#E10600;color:#fff;font-weight:900;font-size:20px;display:flex;align-items:center;justify-content:center;gap:10px;
 clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,0 100%);border-radius:14px 0 14px 14px}
"""


def menu():
    modes = [("Campanha", "Continuar: McLaren · rodada 22", "flag", "on"), ("Grande Prêmio", "Um fim de semana avulso", "globe", ""),
             ("Corrida rápida", "Escolha a pista e largue", "bolt", ""), ("Corrida caótica", "Em desenvolvimento", "lock", "off")]
    rows = "".join(f'<div class="mode {c}"><span class="mi">{ico(i, 22, "#fff" if c == "on" else "#eef0f3", 2.4)}</span><div><strong>{n.upper()}</strong><small>{s}</small></div>'
                   f'<span class="go">{ico("chev", 22, "#11141a" if c == "on" else "#a8b0bd", 3)}</span></div>' for n, s, i, c in modes)
    logo_svg = (ROOT / "game/assets/branding/logo.svg").read_text(encoding="utf-8")
    logo_svg = logo_svg.replace("<svg", '<svg style="width:420px;height:auto"', 1)
    body = f'''<div class="scene"><div class="menu-bg"></div><div class="beam" style="left:360px;opacity:.7"></div><div class="beam" style="left:760px;opacity:.7"></div>
<div class="logo-big">{logo_svg}</div>
<div class="modes">{rows}</div>
<div class="foot"><span class="pill">{ico("globe", 18)} Opções</span><span class="pill">{ico("flag", 18)} Créditos</span></div>
<div class="ver">TEMPORADA 2026 · v0.16</div></div>'''
    return V.page("V16 · Menu principal", CSS.replace("%TC%", "#E10600"), body)


def team_select(tid, mode="CAMPANHA · EQUIPE REAL"):
    t = B.teams[tid]
    tc = t["color"]
    tr = t.get("car_traits", {})
    base = float(t["car_rating"])
    drivers = [d for d in V.DRIVERS if d["team"] == tid]
    def trait(label, k, col):
        v = base + float(tr.get(k, 0)) if k != "rel" else float(tr.get("rel", 80))
        return f'<div class="tr"><span style="width:96px">{label}</span><div class="bar"><i style="width:{(v - 60) * 2.5:.0f}%;background:{col}"></i></div><b>{round(v)}</b></div>'
    info = f'''<div class="glass info"><div class="cap">CARRO 2026</div><div class="big-r"><b>{round(base)}</b><small>nota geral · {sorted(ORDER, key=lambda x: -float(B.teams[x]["car_rating"])).index(tid) + 1}º carro do grid</small></div>
{trait("Reta", "straight", "#ffd24a")}{trait("Curvas lentas", "slow", "#ff6a5a")}{trait("Curvas rápidas", "fast", "#5c93ea")}{trait("Confiabilidade", "rel", "#3c9d5d")}
<div style="height:4px"></div>
<div class="kv"><span>Chefe de equipe</span><span>{t.get("principal") or "—"}</span></div>
<div class="kv"><span>Motor</span><span>{t["power_unit"]}</span></div>
<div class="kv"><span>Títulos de construtores</span><span>{t.get("constructors_titles") if t.get("constructors_titles") is not None else "—"}</span></div></div>'''
    dr = ""
    for d in drivers:
        age = 2026 - int(d["birth"][:4])
        dr += (f'<div class="dr"><span class="num">{d["number"]}</span>{face(d, 56)}<div><strong>{d["name"]}</strong><small>{d["nationality"]} · {age} anos</small>'
               f'<div class="dst"><span>Nota {d["rating"]}</span><span>{d.get("titles", 0)} título{"s" if d.get("titles", 0) != 1 else ""}</span></div></div></div>')
    drivers_html = f'<div class="glass drivers"><div class="cap" style="padding:2px 4px">PILOTOS</div>{dr}</div>'
    rank = sorted(ORDER, key=lambda x: -float(B.teams[x]["car_rating"])).index(tid) + 1
    goal = (f'<div class="glass goal"><div class="cap">OBJETIVO DA DIRETORIA</div><b>Top {rank} dos construtores</b>'
            f'<small>{"Brigar pelo título" if rank <= 2 else ("Pódios regulares" if rank <= 4 else ("Pontos toda corrida" if rank <= 7 else "Sair do fundo do grid"))}'
            f' · paciência da diretoria: 3 temporadas</small></div>') if mode.startswith("CAMPANHA") else ""
    strip = "".join(f'<div class="tl{" on" if x == tid else ""}">{logo(x, 44)}</div>' for x in ORDER)
    name = t["name"].upper()
    body = f'''<div class="scene"><div class="ts-bg"></div><div class="slab"></div>
<div class="giant">{name}</div>
<div class="ts-head"><span class="tag">ESCOLHA DE EQUIPE</span><h1>{name}</h1><small>{mode}</small></div>
<img class="car" src="{'file://' + str(ROOT / 'game/assets/cars') if FACES else '../../game/assets/cars'}/{tid}.svg">
<img class="reflect" src="{'file://' + str(ROOT / 'game/assets/cars') if FACES else '../../game/assets/cars'}/{tid}.svg">
{info}{drivers_html}{goal}
<div class="strip">{strip}</div>
<div class="acts"><span class="back">{ico("back", 18)} Voltar</span><span class="cta2">CONFIRMAR {ico("chev", 20, "#fff", 3)}</span></div></div>'''
    return V.page("V16 · Escolha de equipe", CSS.replace("%TC%", tc), body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V16_OUT"]) if os.environ.get("V16_OUT") else HERE
    if FACES:
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
        V.EMB = "file://" + str((ROOT / "game/assets/emblems").resolve()) + "/{}.svg"
    (out / "v16-1-menu.html").write_text(menu(), encoding="utf-8")
    (out / "v16-2-escolha-equipe.html").write_text(team_select("ferrari"), encoding="utf-8")
    (out / "v16-3-escolha-equipe-gp.html").write_text(team_select("williams", "GRANDE PRÊMIO · GP DE MÔNACO"), encoding="utf-8")
    print("ok")
