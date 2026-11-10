"""V32 · Acabamento (pedido de 2026-11-10): configurações, ajuda, dica de primeira vez, slots de save e abertura/ícone.
Uso: python design/mockups/build_v32.py"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v26 as W  # noqa: E402

HERE = B.HERE
g = W.g
GOLD = "#F5C542"
GREEN = "#7fe0b1"

CSS = W.CSS + """
.card{position:absolute;border-radius:22px;background:#171a21;box-shadow:0 10px 30px rgba(0,0,0,.35);padding:16px 20px}
.row{display:flex;align-items:center;gap:14px;height:62px;border-radius:16px;background:rgba(255,255,255,.05);padding:0 16px;margin-top:8px}
.row b{font-size:16px;font-weight:900;flex:1}.row small{display:block;font-size:12px;color:#a8b0bd;font-weight:800;margin-top:2px}
.sl{height:10px;border-radius:5px;background:rgba(255,255,255,.12);width:280px;position:relative}.sl u{display:block;height:100%;border-radius:5px;background:#F5C542}
.sl i{position:absolute;top:-6px;width:22px;height:22px;border-radius:50%;background:#fff;margin-left:-11px}
.sw{width:56px;height:32px;border-radius:16px;background:rgba(255,255,255,.14);position:relative}.sw.on{background:#2FD38A}.sw i{position:absolute;top:4px;left:4px;width:24px;height:24px;border-radius:50%;background:#fff}.sw.on i{left:28px}
.seg{display:inline-flex;border-radius:18px;background:rgba(255,255,255,.08);padding:3px}.seg b{padding:6px 14px;border-radius:15px;font-size:13px;color:#a8b0bd;flex:none}.seg b.on{background:#f3f4f6;color:#11141a}
.dim{position:absolute;inset:0;background:rgba(5,7,10,.7)}
.modal{position:absolute;border-radius:24px;background:#171a21;padding:22px 24px;box-shadow:0 20px 60px rgba(0,0,0,.6)}
.topic{border-radius:18px;background:rgba(255,255,255,.06);padding:14px 16px;flex:1;min-height:120px}
.topic.on{background:#f3f4f6;color:#11141a}.topic b{font-size:17px;font-weight:900;display:block;margin-top:10px}.topic small{display:block;font-size:12px;font-weight:800;color:#a8b0bd;margin-top:4px}.topic.on small{color:#4b5260}
.slot{position:absolute;width:360px;height:380px;border-radius:22px;background:#1b1e26;padding:18px}
.slot.empty{background:rgba(255,255,255,.04);border:2px dashed rgba(255,255,255,.18)}
.tip{position:absolute;border-radius:20px;background:rgba(11,13,18,.92);padding:14px 18px;box-shadow:0 14px 40px rgba(0,0,0,.6);border:2px solid #F5C542}
"""


def page(title, body):
    return V.page(f"V32 · {title}", CSS, f'<div class="scene"><div class="bgx"></div>{body}</div>')


def head(title, sub="OPÇÕES"):
    return (f'<div class="top"><span style="width:48px;height:48px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center">'
            f'{g("chev", 22).replace("M9 5l7 7-7 7", "M15 5l-7 7 7 7")}</span><div><div class="cap" style="font-size:12px">{sub}</div>'
            f'<div class="big" style="font-size:28px">{title}</div></div></div>')


def config():
    def slider(label, sub, pct):
        return f'<div class="row"><div style="flex:1"><b>{label}</b><small>{sub}</small></div><div class="sl"><u style="width:{pct}%"></u><i style="left:{pct}%"></i></div><b style="flex:none;width:46px;text-align:right">{pct}%</b></div>'

    def toggle(label, sub, on):
        return f'<div class="row"><div style="flex:1"><b>{label}</b><small>{sub}</small></div><div class="sw{" on" if on else ""}"><i></i></div></div>'

    left = (f'<div class="card" style="left:60px;top:100px;width:560px;height:580px"><div class="cap">SOM</div>'
            f'{slider("Volume geral", "tudo junto", 80)}{slider("Efeitos", "motores, rádio, pit stop", 90)}{slider("Música dos menus", "trilha leve de fundo", 40)}'
            f'{toggle("Sons de toque", "estalo curto ao tocar nos botões", True)}'
            f'<div class="cap" style="margin-top:20px">TEXTO</div>'
            f'<div class="row"><div style="flex:1"><b>Tamanho da letra</b><small>vale a partir da próxima tela</small></div><div class="seg"><b>PEQUENA</b><b class="on">NORMAL</b><b>GRANDE</b></div></div></div>')
    right = (f'<div class="card" style="left:640px;top:100px;width:580px;height:580px"><div class="cap">JOGO</div>'
             f'<div class="row"><div style="flex:1"><b>Velocidade inicial da corrida</b><small>ao começar cada sessão</small></div><div class="seg"><b>1×</b><b class="on">2×</b><b>4×</b></div></div>'
             f'{toggle("Reduzir a velocidade em decisões", "o rádio e o box pedem resposta com a corrida lenta", True)}'
             f'{toggle("Dicas na primeira vez", "um aviso curto na primeira vez que abrir cada tela", True)}'
             f'<div class="cap" style="margin-top:20px">AJUDA E DADOS</div>'
             f'<div class="row"><div style="flex:1"><b>Ajuda</b><small>como jogar: corrida, box, classificação, campanha</small></div>{g("chev", 22)}</div>'
             f'<div class="row"><div style="flex:1"><b>Ver as dicas de novo</b><small>zera as dicas já vistas</small></div>{g("chev", 22)}</div>'
             f'<div class="row"><div style="flex:1"><b>Saves e slots</b><small>3 slots de Campanha e do Mundial</small></div>{g("chev", 22)}</div>'
             f'<div style="font-size:12px;color:#8f98a7;font-weight:800;margin-top:16px">F1 GUIDELINES · VERSÃO 0.1-TESTE</div></div>')
    return page("Configurações", head("CONFIGURAÇÕES") + left + right)


def ajuda():
    topics = [("flag", "CORRIDA", "pista, cartões, ordens de equipe, missões", True), ("tyre", "BOX E PNEUS", "parada, composto, regra dos 2 compostos", False),
              ("timer", "CLASSIFICAÇÃO", "Q1, Q2, Q3, jogo de pneus, voltas", False), ("trophy", "CAMPEONATO", "pontos, tabela, estatísticas", False)]
    cards = "".join(f'<div class="topic{" on" if on else ""}">{g(i, 28, "#11141a" if on else "#a8b0bd")}<b>{t}</b><small>{s}</small></div>' for i, t, s, on in topics)
    body = (f'<div class="dim"></div><div class="modal" style="left:130px;top:70px;width:1020px;height:560px">'
            f'<div style="display:flex;align-items:center"><div class="big" style="font-size:30px">AJUDA</div><span style="flex:1"></span>{g("close", 24) if False else ""}<span class="chip">TOQUE NUM ASSUNTO</span></div>'
            f'<div style="display:flex;gap:12px;margin-top:16px">{cards}</div>'
            f'<div style="border-radius:18px;background:rgba(255,255,255,.05);padding:18px 22px;margin-top:16px;height:290px">'
            f'<div class="big" style="font-size:22px;color:{GOLD}">COMO LER OS CARTÕES DE PILOTO</div>'
            f'<div style="font-size:15px;font-weight:700;color:#c3c9d3;line-height:1.5;margin-top:12px">'
            f'• <b>Foto e nome</b>: toque para a câmera seguir o carro. A bandeira é o país do piloto.<br>'
            f'• <b>Pneu</b>: composto, voltas e a barra de vida; abaixo de 20% o risco de estouro sobe.<br>'
            f'• <b>Alvo</b>: define a missão de base e a missão curta, tudo na mesma janela.<br>'
            f'• <b>Chave</b>: chama o box. As três opções embaixo são as ordens de equipe.</div></div></div>')
    return page("Ajuda", head("CONFIGURAÇÕES") + body)


def dica():
    base = (f'<div style="position:absolute;left:30px;top:100px;width:260px;height:420px;border-radius:20px;background:rgba(11,13,18,.8)"></div>'
            f'<div style="position:absolute;right:30px;top:100px;width:290px;height:560px;border-radius:20px;background:rgba(11,13,18,.8)"></div>')
    tip = (f'<div class="tip" style="left:330px;top:150px;width:420px"><div style="display:flex;align-items:center;gap:10px"><span class="chip" style="background:{GOLD};color:#11141a">{g("bell", 14, "#11141a")}DICA</span>'
           f'<span style="flex:1"></span><span class="cap" style="font-size:11px">1 DE 3</span></div>'
           f'<div style="font-size:17px;font-weight:900;margin-top:10px;line-height:1.25">TOQUE NO CARTÃO DO PILOTO PARA A CÂMERA SEGUIR O CARRO DELE.</div>'
           f'<div style="display:flex;align-items:center;margin-top:12px"><span style="font-size:12px;color:#8f98a7;font-weight:800">NÃO MOSTRAR MAIS DICAS</span><span style="flex:1"></span>'
           f'<span class="cta" style="height:44px;font-size:16px;padding:0 20px">ENTENDI</span></div></div>')
    return page("Dica de primeira vez", base + tip + head("CORRIDA", "EXEMPLO") + '<div style="position:absolute;left:300px;top:330px;width:2px;height:2px"></div>')


def slots():
    def full(x, n, team, tc, line, sub, chips):
        return (f'<div class="slot" style="left:{x}px;top:160px;box-shadow:0 0 0 3px {tc} inset"><div class="cap">SLOT {n}</div>'
                f'<div style="display:flex;align-items:center;gap:12px;margin-top:12px"><img src="{W.EMB.format(team)}" style="width:54px;height:54px;border-radius:14px"><div><div class="big" style="font-size:26px">{B.teams[team]["name"].upper()}</div><div style="font-size:13px;color:#a8b0bd;font-weight:800;margin-top:4px">{line}</div></div></div>'
                f'<img src="{W.CAR.format(team)}" style="width:320px;margin-top:20px"><div style="display:flex;gap:8px;margin-top:10px">{chips}</div>'
                f'<div style="font-size:12px;color:#8f98a7;font-weight:800;margin-top:12px">{sub}</div>'
                f'<span class="cta" style="position:absolute;left:18px;right:98px;bottom:18px;height:50px;font-size:17px">CONTINUAR</span>'
                f'<span style="position:absolute;right:18px;bottom:18px;width:64px;height:50px;border-radius:14px;background:rgba(255,255,255,.08);display:grid;place-items:center">{g("lock", 22)}</span></div>')
    chips = lambda a, b: f'<span class="chip">{a}</span><span class="chip">{b}</span>'
    s1 = full(40, 1, "mercedes", "#27F4D2", "CAMPANHA · RD 9/22", "salvo hoje às 21:14 · versão 2", chips("1º", "140 MI"))
    s2 = full(440, 2, "williams", "#1347F5", "MUNDIAL F1 · RD 7/22", "salvo ontem · versão 2", chips("9º", "44 PTS"))
    s3 = (f'<div class="slot empty" style="left:840px;top:160px;display:grid;place-items:center;text-align:center"><div><span style="width:70px;height:70px;border-radius:50%;background:rgba(255,255,255,.1);display:inline-grid;place-items:center">{g("plus", 34)}</span>'
          f'<div class="big" style="font-size:24px;margin-top:16px">SLOT 3 VAZIO</div><div style="font-size:13px;color:#a8b0bd;font-weight:800;margin-top:8px">toque para começar uma<br>Campanha ou um Mundial</div></div></div>')
    top = (f'<div style="position:absolute;left:40px;top:90px"><div class="big" style="font-size:34px">ESCOLHA UM SLOT</div></div>'
           f'<span class="chip" style="position:absolute;right:40px;top:100px">{g("bell", 16)}os saves antigos entram no slot 1 automaticamente</span>')
    return page("Slots de save", top + s1 + s2 + s3)


def abertura():
    splash = (f'<div style="position:absolute;inset:0;display:grid;place-items:center;background:radial-gradient(ellipse 50% 40% at 50% 45%,rgba(225,6,0,.22),transparent 70%),#07090c">'
              f'<div style="text-align:center"><img src="../../game/assets/branding/logo.svg" style="height:150px" onerror="this.style.display=\'none\'">'
              f'<div class="cap" style="margin-top:26px;letter-spacing:6px">TEMPORADA 2026</div>'
              f'<div style="width:260px;height:6px;border-radius:3px;background:rgba(255,255,255,.12);margin:34px auto 0;overflow:hidden"><u style="display:block;width:64%;height:100%;background:#E10600"></u></div>'
              f'<div style="font-size:12px;color:#6c7380;font-weight:800;margin-top:12px">CARREGANDO PISTAS…</div></div></div>')
    icons = "".join(f'<div style="position:absolute;left:{x}px;top:{y}px;width:{s}px;height:{s}px;border-radius:{s * 0.22:.0f}px;background:{bg};display:grid;place-items:center;box-shadow:0 8px 24px rgba(0,0,0,.5)">'
                    f'<span style="font-weight:900;font-style:italic;font-size:{s * .5:.0f}px;color:#fff;letter-spacing:-2px;line-height:1">F1</span>'
                    f'<span style="position:absolute;bottom:{s * .12:.0f}px;left:18%;right:18%;height:{max(s * .05, 3):.0f}px;border-radius:3px;background:linear-gradient(90deg,#E10600,#F5C542)"></span></div>'
                    for x, y, s, bg in [(960, 60, 200, "linear-gradient(160deg,#1c2030,#07090c)"), (1190, 60, 56, "linear-gradient(160deg,#1c2030,#07090c)")])
    note = f'<div style="position:absolute;right:50px;top:290px;font-size:12px;color:#8f98a7;font-weight:800;text-align:right;width:300px">ÍCONE REFEITO: "F1" ITÁLICO COM FAIXA VERMELHA E DOURADA,<br>SEM LOGO OFICIAL</div>'
    return page("Abertura e ícone", splash + icons + note)


if __name__ == "__main__":
    for name, fn in {"v32-1-config": config, "v32-2-ajuda": ajuda, "v32-3-dica": dica, "v32-4-slots": slots, "v32-5-abertura": abertura}.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
