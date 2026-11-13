"""V38 · Nova tela de clima na corrida + previsão do fim de semana (decisões de 2026-11-13).
Folha grande aberta pelo selo do clima: opinião do engenheiro (faixa de voltas + confiança, depende do pessoal),
linha do tempo das próximas voltas (chance e intensidade, estimativa da equipe), pista e pneu agora (estado da pista,
pneu mais rápido, troca prevista). Segundo quadro: previsão do fim de semana no mesmo estilo.
Uso: python design/mockups/build_v38.py"""
import pathlib

HERE = pathlib.Path(__file__).parent
TC = "#1868DB"  # cor da equipe (Williams no exemplo)

ICON = {
    "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
    "cloud": '<path d="M7 18h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 9.5 4.3 4.3 0 0 0 7 18z"/>',
    "drizzle": '<path d="M7 15h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 6.5 4.3 4.3 0 0 0 7 15z"/><path d="M9 18v1M13 18v1M17 18v1"/>',
    "rain": '<path d="M7 14h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 5.5 4.3 4.3 0 0 0 7 14z"/><path d="M8 17l-1 3M12 17l-1 3M16 17l-1 3"/>',
    "storm": '<path d="M7 13h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 4.5 4.3 4.3 0 0 0 7 13z"/><path d="M12 14l-2 4h3l-2 4"/>',
    "headset": '<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="3" y="14" width="4" height="6" rx="1.5"/><rect x="17" y="14" width="4" height="6" rx="1.5"/>',
    "close": '<path d="M6 6l12 12M18 6L6 18"/>',
    "drop": '<path d="M12 3c3 5 6 8 6 11a6 6 0 0 1-12 0c0-3 3-6 6-11z"/>',
}


def ic(name, size=20, color="#fff", sw=2):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="{sw}" '
            f'stroke-linecap="round" stroke-linejoin="round" style="position:static;flex:none">{ICON[name]}</svg>')


CSS = """
*{box-sizing:border-box;margin:0;padding:0}
body{background:#0b0d12;font-family:Kanit,system-ui,sans-serif;color:#fff;text-transform:uppercase;padding:24px;display:flex;flex-direction:column;gap:28px;align-items:center}
.cap{color:#8f98a7;font-weight:800;letter-spacing:2px;font-size:13px;align-self:flex-start;margin-left:calc(50% - 640px)}
.f{width:1280px;height:720px;position:relative;overflow:hidden;border-radius:6px;background:linear-gradient(160deg,#3d6b45,#24432b 60%,#1b2e20)}
.dim{position:absolute;inset:0;background:rgba(5,7,10,.55)}
.top{position:absolute;left:0;right:0;top:0;height:64px;background:linear-gradient(#0b0d12,rgba(11,13,18,0));display:flex;align-items:center;gap:12px;padding:0 16px}
.chip{height:44px;border-radius:22px;background:rgba(255,255,255,.1);display:flex;align-items:center;gap:8px;padding:0 16px;font-weight:900;font-size:15px}
.chip.on{background:#fff;color:#111}
.sheet{position:absolute;left:150px;right:150px;top:70px;bottom:24px;border-radius:26px;background:#141a24;box-shadow:inset 0 6px 0 """ + TC + """,0 20px 60px rgba(0,0,0,.6);padding:22px 26px}
.h{color:#8f98a7;font-weight:900;letter-spacing:2.5px;font-size:12px}
.row{display:flex;gap:16px}
.box{background:rgba(255,255,255,.05);border-radius:18px;padding:16px}
.eng{display:flex;gap:14px;align-items:flex-start}
.av{width:56px;height:56px;border-radius:50%;background:""" + TC + """;display:grid;place-items:center;flex:none}
.quote{font-size:21px;font-weight:900;line-height:1.15;text-transform:none}
.quote b{color:#7fc3ff}
.conf{display:flex;gap:4px;margin-top:8px;align-items:center}
.conf i{width:22px;height:8px;border-radius:4px;background:rgba(255,255,255,.14)}
.conf i.f{background:#ffd24a}
.tl{position:relative;height:150px;margin-top:10px}
.lap{position:absolute;bottom:22px;width:34px;display:flex;flex-direction:column;align-items:center;gap:4px}
.bar{width:22px;border-radius:6px 6px 2px 2px;background:linear-gradient(#5fb0ff,#2f6fd6)}
.lapn{position:absolute;bottom:0;width:34px;text-align:center;font-size:12px;color:#8f98a7;font-weight:800}
.win{position:absolute;bottom:20px;top:6px;border-radius:12px;background:rgba(95,176,255,.12);border:2px dashed rgba(127,195,255,.55)}
.now{position:absolute;bottom:18px;top:0;width:3px;background:#fff;border-radius:2px}
.meter{height:14px;border-radius:7px;background:linear-gradient(90deg,#c9b27a,#7fa7d6 45%,#2f6fd6 75%,#163e8c);position:relative;margin-top:12px}
.meter .k{position:absolute;top:-6px;width:6px;height:26px;border-radius:3px;background:#fff;box-shadow:0 0 0 2px #141a24}
.lbls{display:flex;justify-content:space-between;font-size:12px;color:#8f98a7;font-weight:800;margin-top:6px}
.tyre{width:46px;height:46px;border-radius:50%;border:5px solid;display:grid;place-items:center;font-weight:900;font-size:17px;background:#1e2430;flex:none}
.big{font-size:30px;font-weight:900}
.day{flex:1;border-radius:18px;background:rgba(255,255,255,.05);padding:16px;display:flex;flex-direction:column;gap:8px;align-items:center}
.wk{position:absolute;inset:0;background:radial-gradient(ellipse at 50% 30%,#3a2b1a,#1a130c 70%)}
"""


def timeline():
    # (volta, chance %, intensidade) — estimativa da equipe; janela prevista de chuva 12–16
    data = [(9, 5, "sun"), (10, 10, "cloud"), (11, 25, "cloud"), (12, 45, "drizzle"), (13, 60, "rain"), (14, 70, "rain"),
            (15, 65, "rain"), (16, 45, "drizzle"), (17, 30, "drizzle"), (18, 20, "cloud"), (19, 10, "cloud"), (20, 5, "sun")]
    out = ['<div class="tl">']
    x0, step = 40, 74
    out.append(f'<div class="win" style="left:{x0 + 3 * step - 14}px;width:{5 * step - 6}px"></div>')
    out.append(f'<div class="now" style="left:{x0 - 22}px"></div>')
    for i, (lap, p, kind) in enumerate(data):
        x = x0 + i * step
        out.append(f'<div class="lap" style="left:{x}px">{ic(kind, 22, "#cfe6ff")}'
                   f'<div class="bar" style="height:{max(4, p)}px;opacity:{0.35 + p / 140:.2f}"></div>'
                   f'<span style="font-size:12px;font-weight:900;color:#cfe6ff">{p}%</span></div>'
                   f'<div class="lapn" style="left:{x}px">{lap}</div>')
    out.append('</div>')
    return "".join(out)


def race_frame():
    conf = '<span class="conf">' + "".join(f'<i class="{"f" if k < 3 else ""}"></i>' for k in range(5)) + \
           '<span style="font-size:13px;font-weight:900;color:#ffd24a;margin-left:6px">CONFIANÇA 60%</span></span>'
    return f"""<div class="f"><div class="dim"></div>
<div class="top"><span class="chip">‹</span><span class="chip">GP DE SÃO PAULO · VOLTA 8/40</span><span class="chip">1×</span><span class="chip on">2×</span>
<span class="chip" style="margin-left:auto;background:#fff;color:#111">{ic('drizzle',20,'#111')} CHUVA À VISTA</span><span class="chip">DADOS</span></div>
<div class="sheet">
 <div style="display:flex;align-items:center;gap:12px"><span style="font-size:26px;font-weight:900">CLIMA</span>
  <span class="h" style="margin-top:4px">· PREVISÃO DA SUA EQUIPE</span>
  <span style="margin-left:auto;width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center">{ic('close',20)}</span></div>
 <div class="row" style="margin-top:14px">
  <div class="box eng" style="flex:1.35">
   <span class="av">{ic('headset',28)}</span>
   <div><div class="h">James Urwin · engenheiro de corrida</div>
    <div class="quote" style="margin-top:6px">"Chuva deve chegar entre as voltas <b>12 e 16</b>. Fraca no começo, apertando depois."</div>
    {conf}</div></div>
  <div class="box" style="flex:1">
   <div class="h">Pista e pneu agora</div>
   <div style="display:flex;align-items:center;gap:12px;margin-top:10px">
    <span class="tyre" style="border-color:#F5C400">M</span>
    <div><div class="big">SECA</div><div style="font-size:13px;color:#8f98a7;font-weight:800">MÉDIO É O MAIS RÁPIDO</div></div></div>
   <div class="meter"><span class="k" style="left:6%"></span></div>
   <div class="lbls"><span>seca</span><span>úmida</span><span>molhada</span><span>encharcada</span></div>
  </div></div>
 <div class="box" style="margin-top:14px">
  <div style="display:flex;align-items:center"><span class="h">Próximas voltas · chance de chuva</span>
   <span style="margin-left:auto;font-size:13px;font-weight:900;color:#7fc3ff">╌ janela prevista</span></div>
  {timeline()}
 </div>
 <div class="box" style="margin-top:14px;display:flex;align-items:center;gap:14px">
  <span class="tyre" style="border-color:#2DB34A">I</span>
  <div style="flex:1"><div style="font-size:19px;font-weight:900">INTERMEDIÁRIO PASSA A VALER A PARTIR DA VOLTA ~14</div>
  <div style="font-size:13px;color:#8f98a7;font-weight:800">SE A CHUVA VIER COMO PREVISTO · A EQUIPE AVISA PELO RÁDIO</div></div>
  {ic('drop',30,'#7fc3ff')}
 </div>
</div></div>"""


def weekend_frame():
    days = [("SEXTA", "TL1 · TL2", "sun", "seca", 10, 4), ("SÁBADO", "TL3 · CLASSIFICAÇÃO", "drizzle", "pancadas à tarde", 45, 3),
            ("DOMINGO", "CORRIDA", "rain", "chuva provável", 65, 2)]
    cards = ""
    for d, ses, kind, txt, p, c in days:
        bars = "".join(f'<i class="{"f" if k < c else ""}"></i>' for k in range(5))
        cards += (f'<div class="day"><div class="h">{d}</div><div style="font-size:12px;color:#8f98a7;font-weight:800">{ses}</div>'
                  f'{ic(kind, 64, "#cfe6ff", 1.6)}<div class="big">{p}%</div><div style="font-size:14px;font-weight:900">{txt}</div>'
                  f'<span class="conf">{bars}</span></div>')
    return f"""<div class="f"><div class="wk"></div>
<div class="sheet" style="left:120px;right:120px;top:90px;bottom:90px">
 <div style="display:flex;align-items:center;gap:12px"><span style="font-size:26px;font-weight:900">PREVISÃO DO FIM DE SEMANA</span></div>
 <div class="box eng" style="margin-top:14px">
  <span class="av">{ic('headset',28)}</span>
  <div><div class="h">Engenharia de pista</div>
  <div class="quote" style="margin-top:6px">"Domingo tem cara de chuva, mas ainda é cedo: a <b>confiança cresce</b> a cada dia."</div></div></div>
 <div class="row" style="margin-top:14px">{cards}</div>
</div></div>"""


def main():
    html = (f'<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>V38 · Clima</title><style>{CSS}</style><body>'
            f'<div class="cap">1 · Corrida: folha do clima (selo do topo). Tudo é estimativa da SUA equipe; a confiança depende do pessoal</div>{race_frame()}'
            f'<div class="cap">2 · Painel do fim de semana: previsão por dia no mesmo estilo (pode errar)</div>{weekend_frame()}</body></html>')
    (HERE / "v38-clima.html").write_text(html, encoding="utf-8")
    print("ok")


if __name__ == "__main__":
    main()
