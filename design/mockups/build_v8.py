"""Tela do box (direção Garagem): mockup antes do Godot. Gera v8-*.html.
Uso: python design/mockups/build_v8.py
A corrida segue rodando (1× ou 2×) enquanto a tela está aberta. Valores de exemplo; efeitos PROVISÓRIOS.
Rostos e logos pessoais só na versão local (FACES/EMB); no repositório ficam os emblemas originais.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v7 as M  # noqa: E402

HERE = B.HERE
ico = V.ico
TYRE = M.TYRE
NAMES = {"S": "Macio", "M": "Médio", "H": "Duro", "I": "Intermediário", "W": "Chuva"}
LIFE = {"S": "~14 voltas", "M": "~22 voltas", "H": "~32 voltas", "I": "pista úmida", "W": "pista molhada"}

CSS = M.CSS + """
.pbar{position:absolute;left:16px;right:16px;top:8px;height:52px;display:flex;align-items:center;gap:14px}
.pbar .id{display:flex;align-items:center;gap:10px}.pbar h1{font-size:24px;font-weight:900;line-height:1}.pbar small{display:block;font-size:12px;letter-spacing:2.5px;color:#8f98a7;font-weight:700;margin-top:3px}
.count{margin-left:auto;display:flex;align-items:center;gap:12px;background:rgba(225,6,0,.18);border:2px solid #E10600;border-radius:14px;padding:6px 14px}
.count b{font-size:26px;font-weight:900;font-variant-numeric:tabular-nums}.count small{margin:0;color:#ffb4a8}
.col{position:absolute;top:70px;bottom:14px}
.pn{border-radius:20px;background:rgba(255,255,255,.06);padding:14px 16px}
.mini{width:100%;height:210px;border-radius:16px;overflow:hidden;background:#000 var(--img) center/cover;position:relative}
.mini .chip{position:absolute;left:10px;bottom:10px;background:rgba(14,16,20,.88);border-radius:12px;padding:6px 10px;font-size:13px;font-weight:700}
.sets{display:flex;flex-direction:column;gap:8px}
.set{display:flex;align-items:center;gap:12px;height:62px;border-radius:16px;background:rgba(255,255,255,.07);padding:0 14px;position:relative}
.set .c{width:40px;height:40px;border-radius:50%;border:5px solid var(--t);background:#0b0c0f;color:#fff;font-weight:900;font-size:15px;display:grid;place-items:center;box-sizing:border-box;flex:none}
.set b{font-size:17px;font-weight:900;display:block;line-height:1.1}.set small{font-size:12px;color:#a8b0bd}
.set .st{margin-left:auto;display:flex;gap:14px;align-items:center}.set .grp{display:flex;flex-direction:column;align-items:flex-end;gap:3px}.set .grp span{font-size:10px;letter-spacing:1.5px;color:#8f98a7;font-weight:700}
.dots{display:flex;gap:5px}.dots i{width:14px;height:14px;border-radius:50%;background:rgba(255,255,255,.12);border:2px solid rgba(255,255,255,.28);box-sizing:border-box}.dots i.f{background:#f3f4f6;border-color:#f3f4f6}.dots i.u{background:transparent;border-color:#f3f4f6}
.set.on{background:#f3f4f6;color:#11141a}.set.on small,.set.on .grp span{color:#4b5260}.set.on .dots i{border-color:#9aa3b2}.set.on .dots i.f{background:#11141a;border-color:#11141a}.set.on .dots i.u{border-color:#11141a}
.set.off{opacity:.38}
.which{display:flex;gap:6px;margin-top:6px}.which span{flex:1;height:34px;border-radius:10px;background:rgba(255,255,255,.08);display:grid;place-items:center;font-size:13px;font-weight:700;color:#c3c9d3}.which span.on{background:#11141a;color:#fff}
.adj{display:flex;align-items:center;gap:12px;height:52px;border-bottom:1px solid rgba(255,255,255,.07)}.adj:last-child{border:none}
.adj b{font-size:16px;font-weight:900;display:block}.adj small{font-size:12px;color:#a8b0bd}.adj .cost{margin-left:auto;font-size:14px;font-weight:900;color:#ffd24a;white-space:nowrap}
.wing{display:flex;gap:4px;margin-left:auto}.wing span{width:38px;height:38px;border-radius:10px;background:rgba(255,255,255,.08);display:grid;place-items:center;font-size:14px;font-weight:900;color:#c3c9d3}.wing span.on{background:#f3f4f6;color:#11141a}
.tog{width:52px;height:30px;border-radius:15px;background:rgba(255,255,255,.14);position:relative;flex:none}.tog:after{content:"";position:absolute;left:3px;top:3px;width:24px;height:24px;border-radius:50%;background:#c3c9d3}
.tog.on{background:#3c9d5d}.tog.on:after{left:25px;background:#fff}
.time{font-size:54px;font-weight:900;line-height:.95}.time small{font-size:24px;color:#a8b0bd}
.bl{display:flex;justify-content:space-between;font-size:14px;padding:5px 0;border-bottom:1px solid rgba(255,255,255,.07)}.bl b{font-weight:900}.bl .p{color:#ffd24a}
.double{display:flex;gap:8px;margin-top:8px}.double div{flex:1;border-radius:14px;background:rgba(255,255,255,.07);padding:10px 12px;font-size:13px}.double div.me{background:rgba(24,104,219,.28)}.double b{display:block;font-size:15px;font-weight:900;margin-top:2px}
.btn{height:58px;border-radius:14px;display:flex;align-items:center;justify-content:center;font-size:16px;font-weight:900;letter-spacing:.5px;gap:10px}
.btn.ghost{background:rgba(255,255,255,.1)}
.tap{position:absolute;left:0;right:0;top:0;bottom:0;background:rgba(5,6,8,.78);display:flex;align-items:center;justify-content:center}
.tapbox{width:640px;border-radius:24px;background:#f3f4f6;color:#11141a;padding:26px 32px;text-align:center;border-left:9px solid #E10600}
.tapbox h2{font-size:34px;font-weight:900}.tapbox p{font-size:16px;color:#4b5260;margin:6px 0 18px}
.gauge{height:46px;border-radius:23px;background:#d6d9df;position:relative;overflow:hidden}.gauge .z1{position:absolute;left:42%;width:16%;top:0;bottom:0;background:#3c9d5d}.gauge .z2{position:absolute;left:34%;width:32%;top:0;bottom:0;background:rgba(60,157,93,.35)}
.gauge i{position:absolute;left:49%;top:-4px;bottom:-4px;width:6px;background:#11141a;border-radius:3px}
.tapbox .tapbtn{margin:20px auto 0;width:320px;height:68px;border-radius:16px;background:#E10600;color:#fff;font-size:24px;font-weight:900;display:grid;place-items:center;clip-path:polygon(0 0,calc(100% - 16px) 0,100% 16px,100% 100%,0 100%)}
"""


def sets_html():
    data = [("S", 1, 1, "Macio", False), ("M", 2, 0, "Médio", True), ("H", 1, 2, "Duro", False), ("I", 2, 0, "Intermediário", False), ("W", 1, 0, "Chuva", False)]
    out = ""
    for k, new, used, name, on in data:
        dots = "".join('<i class="f"></i>' for _ in range(new)) + "".join('<i class="u"></i>' for _ in range(used)) + "".join("<i></i>" for _ in range(max(0, 3 - new - used)))
        dim = " off" if k in "IW" else ""
        out += (f'<div class="set{" on" if on else ""}{dim}"><span class="c" style="--t:{TYRE[k]}">{k}</span><div><b>{name}</b><small>{LIFE[k]}</small></div>'
                f'<div class="st"><div class="grp"><span>NOVOS {new} · USADOS {used}</span><div class="dots">{dots}</div></div></div></div>')
    return out


def pit(mini_game=False):
    car = M.V.MY[0]
    body = f'''<div class="scene" style="--img:url(png/3d/clean_follow.png)">
<div class="pbar"><div class="id">{M.av(car["id"], 40) or ""}<div><h1>BOX · {car["name"].upper()}</h1><small>INTERLAGOS · VOLTA 6 DE 18 · P3</small></div></div>
<div class="seg" style="margin-left:18px"><span>1×</span><span class="on">2×</span></div>
<div class="count"><div><small class="cap">ENTRADA DO BOX EM</small><b>0:34</b></div></div><div class="pill" style="background:rgba(255,255,255,.1)">Voltar à corrida</div></div>
<div class="col" style="left:16px;width:360px"><div class="mini"><span class="chip">A corrida continua · 2×</span></div>
<div class="pn" style="margin-top:12px"><div class="cap">PARADA DUPLA</div>
<div class="double"><div class="me"><span class="cap">ALBON</span><b>Entra primeiro</b>pit em 0:34</div><div><span class="cap">SAINZ</span><b>Espera ~2,9 s</b>entra na volta 7</div></div>
<div class="which"><span class="on">Albon primeiro</span><span>Sainz primeiro</span><span>Sainz na volta 7</span></div>
<p style="font-size:13px;color:#a8b0bd;margin-top:10px;line-height:1.45">Se os dois entram na mesma volta, o segundo espera o primeiro sair do box. Segurar um carro por uma volta evita a fila, mas ele roda mais com o pneu velho.</p></div></div>
<div class="col pn" style="left:388px;width:470px"><div class="cap">PNEUS PARA A PARADA</div><div class="sets" style="margin-top:8px">{sets_html()}</div>
<div class="which"><span class="on">Jogo novo</span><span>Jogo usado</span></div>
<p style="font-size:12px;color:#8f98a7;margin-top:8px">O jogo usado já rodou na classificação e começa com ~15% de desgaste. O estoque acaba: pense na corrida inteira.</p></div>
<div class="col" style="left:870px;width:394px"><div class="pn" style="padding:12px 16px"><div class="cap" style="margin-bottom:2px">AJUSTES DO CARRO</div>
<div class="adj" style="height:60px"><div><b>Asa dianteira</b><small>mais asa: mais rápido, gasta mais pneu</small></div><div class="wing"><span>−1</span><span>0</span><span class="on">+1</span><span>+2</span></div></div>
<div class="adj"><div><b>Trocar a asa danificada</b><small>asa com −18% de eficiência</small></div><span class="tog on" style="margin-left:auto"></span></div>
<div class="adj"><div><b>Reparo parcial do assoalho</b><small>recupera metade do dano</small></div><span class="tog" style="margin-left:auto"></span></div>
<div class="adj"><div><b>Cumprir a punição de 5 s agora</b><small>se não cumprir, soma 5 s ao tempo final</small></div><span class="tog on" style="margin-left:auto"></span></div></div>
<div class="pn" style="margin-top:10px;padding:12px 16px"><div class="cap">TEMPO PARADO PREVISTO</div><div class="time">9,0<small> s</small></div>
<div class="bl"><span>Troca de pneus</span><b>2,4 s</b></div><div class="bl"><span>Asa dianteira +1</span><b class="p">+0,3 s</b></div><div class="bl"><span>Troca da asa danificada</span><b class="p">+1,3 s</b></div><div class="bl" style="border:none"><span>Punição de 5 s cumprida</span><b class="p">+5,0 s</b></div>
</div>
<div class="btn ghost" style="margin-top:8px;height:44px;font-size:14px">CANCELAR PARADA</div>
<div class="cta" style="height:54px;margin-top:8px;font-size:18px">CONFIRMAR BOX {ico("chev", 22, "#fff", 3)}</div></div>
{"" if not mini_game else TAP}</div>'''
    return V.page("V8 · Box", CSS, body)


TAP = '''<div class="tap"><div class="tapbox"><div class="cap" style="color:#4b5260">CARRO PARADO NO BOX · ALBON</div><h2>TOQUE QUANDO O MARCADOR ESTIVER NO VERDE</h2>
<p>Pneus novos Médios · asa +1 · parada prevista 9,0 s (com punição)</p><div class="gauge"><span class="z2"></span><span class="z1"></span><i></i></div>
<div style="display:flex;justify-content:space-between;font-size:12px;color:#4b5260;margin-top:6px"><span>−0,6 s</span><span style="color:#2a6b3f;font-weight:900">−0,3 s (perfeito)</span><span>−0,6 s</span></div>
<div class="tapbtn">SOLTAR O CARRO</div></div></div>'''


if __name__ == "__main__":
    (HERE / "v8-1-box.html").write_text(pit(False), encoding="utf-8")
    (HERE / "v8-2-box-toque.html").write_text(pit(True), encoding="utf-8")
    print("ok")
