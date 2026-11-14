#!/usr/bin/env python3
"""Texturas reais da pista 3D (2026-11-14), do Poly Haven (polyhaven.com, licença CC0 — domínio público).

Baixa as texturas em 1k (cache em tools/.ph_cache, fora do git) e grava versões leves de 512 px em game/assets/textures/:
  asphalt.jpg / asphalt_nor.jpg   asfalto da pista (cor real + relevo)
  asphalt_pit.jpg                 asfalto do pit lane (mais claro)
  grass_d.jpg, gravel_d.jpg, concrete_d.jpg
                                  "grão" neutro (cinza com média ~0,8): o jogo multiplica pela cor de cada lugar, então a
                                  grama continua com o verde do mapa e a brita com o bege do circuito

Uso: python3 tools/prepare_textures.py
"""
import pathlib
import urllib.request

from PIL import Image, ImageOps, ImageStat

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools/.ph_cache"
OUT = ROOT / "game/assets/textures"
URL = "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/{id}/{id}_{map}_1k.jpg"
SIZE = 512

# saída: (id no Poly Haven, mapa, tipo)
TEXTURES = {
    "asphalt": ("asphalt_track", "diff", "color"),
    "asphalt_nor": ("asphalt_track", "nor_gl", "normal"),
    "asphalt_pit": ("asphalt_pit_lane", "diff", "color"),
    "grass_d": ("leafy_grass", "diff", "detail"),
    "gravel_d": ("sandy_gravel", "diff", "detail"),
    "concrete_d": ("concrete_floor_02", "diff", "detail"),
}


def fetch(pid, kind):
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / f"{pid}_{kind}.jpg"
    if not path.exists():
        req = urllib.request.Request(URL.format(id=pid, map=kind), headers={"User-Agent": "texture-prep/1.0"})
        path.write_bytes(urllib.request.urlopen(req, timeout=60).read())
    return path


def detail(img):
    """Cinza com média 0,8 e contraste moderado: multiplicado pela cor, dá textura sem mudar o tom."""
    g = ImageOps.grayscale(img)
    mean = ImageStat.Stat(g).mean[0] / 255.0
    lut = [max(0, min(255, int(((v / 255.0 - mean) * 1.4 + 0.8) * 255))) for v in range(256)]
    return g.point(lut).convert("RGB")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (pid, kind, mode) in TEXTURES.items():
        img = Image.open(fetch(pid, kind)).convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)
        if mode == "detail":
            img = detail(img)
        img.save(OUT / f"{name}.jpg", quality=88)
        print(name, "<-", pid, kind)


if __name__ == "__main__":
    main()
