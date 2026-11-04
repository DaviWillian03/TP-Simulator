"""Prepara fotos de pilotos para o APK PESSOAL do jogador (nunca vão para o repositório).
Uso: python tools/prepare_portraits.py <pasta_com_pngs_de_corpo_inteiro> [pasta_de_saida]
Padrão de saída: game/local/drivers (ignorada pelo git).

Para cada foto (nome_do_piloto.png, corpo inteiro, fundo transparente) gera só o ROSTO:
  <id_do_piloto>_face.png  (384x384, cabeça e pescoço, para avatares)
O id vem de game/data/drivers_2026.json, drivers_feeder_2026.json (F2/F3) ou free_agents.json: pelo nome ou pelo id
(nome do arquivo sem acentos; hífen = sublinhado). Procura nas subpastas (ex.: F2/Pilotos/<equipe>/<piloto>.png).
"""
import json
import pathlib
import sys
import unicodedata

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
FACE = 384
ALIASES = {"emerson_fittipaldi_jr": "emerson_fittipaldi", "michael_woohyun_shin": "michael_shin", "noah_stromsted": "noah_strmsted",
           "maciej_gladysz": "maciej_gadysz", "nico_varrone": "nico_varrone"}
FACE_FRAC = 0.175  # lado do recorte = 17,5% da altura do corpo (cabeça + pescoço)


def slug(name: str) -> str:
    s = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode().lower()
    return "".join(c if c.isalnum() else "_" for c in s).strip("_")


def main(src: pathlib.Path, dst: pathlib.Path) -> None:
    drivers = []
    for name in ("drivers_2026.json", "drivers_feeder_2026.json", "free_agents.json"):
        drivers += json.loads((ROOT / "game/data" / name).read_text(encoding="utf-8"))["drivers"]
    by_slug = {}
    for d in drivers:
        by_slug[slug(d["name"])] = d["id"]
        by_slug[d["id"]] = d["id"]
    by_slug.update(ALIASES)
    dst.mkdir(parents=True, exist_ok=True)
    done, unknown = [], []
    for f in sorted(src.rglob("*.png")):
        if "logo" in str(f.parent).lower():
            continue
        did = by_slug.get(slug(f.stem))
        if not did:
            unknown.append(f.name)
            continue
        im = Image.open(f).convert("RGBA")
        bb = im.getbbox()
        body = im.crop(bb)
        h = body.height
        # rosto: quadrado centrado na cabeça (centro de massa do alfa nos 8% de cima)
        top = body.crop((0, 0, body.width, max(1, int(h * 0.08)))).split()[3]
        xs = [x for x in range(top.width) for y in range(top.height) if top.getpixel((x, y)) > 128]
        cx = sum(xs) / len(xs) if xs else body.width / 2
        # fotos cortadas na cintura têm o corpo "curto": mede pelo quadro da foto (todas têm o mesmo enquadramento)
        side = int(max(h, im.height * 0.97) * FACE_FRAC)
        x0 = int(min(max(cx - side / 2, 0), body.width - side))
        face = body.crop((x0, 0, x0 + side, side)).resize((FACE, FACE), Image.LANCZOS)
        face.save(dst / f"{did}_face.png")
        done.append(did)
    print(f"{len(done)} pilotos em {dst}")
    if unknown:
        print("sem correspondência no jogo:", ", ".join(unknown))
    have = {p.name[:-9] for p in dst.glob("*_face.png")}
    missing = sorted({d["id"] for d in drivers} - have)
    if missing:
        print("pilotos do jogo ainda sem foto:", ", ".join(missing))


if __name__ == "__main__":
    s = pathlib.Path(sys.argv[1])
    d = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "game/local/drivers"
    main(s, d)
