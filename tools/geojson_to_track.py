"""Converte o traçado de um circuito (GeoJSON LineString, lon/lat) em pontos em metros
para o jogo.

Fonte dos traçados: https://github.com/bacinger/f1-circuits (licença MIT).

Uso:
    python tools/geojson_to_track.py <arquivo.geojson> [comprimento_oficial_m]

Saída (stdout): JSON com "points" em metros, eixo x = leste, eixo y = sul (coordenadas de
tela do Godot), já no sentido de corrida e escalado para o comprimento oficial, se informado.
Os pontos são colados no campo "points" do arquivo do circuito em game/data/circuits/.
"""
import json
import math
import sys

EARTH_R = 6371000.0


def main() -> None:
    path = sys.argv[1]
    official = float(sys.argv[2]) if len(sys.argv) > 2 else None
    with open(path, encoding="utf-8") as f:
        geo = json.load(f)
    coords = geo["features"][0]["geometry"]["coordinates"]
    lat0 = sum(c[1] for c in coords) / len(coords)
    lon0 = sum(c[0] for c in coords) / len(coords)
    k = math.pi / 180 * EARTH_R
    # projeção equiretangular local; y invertido (sul positivo) para coordenadas de tela
    pts = [((c[0] - lon0) * math.cos(math.radians(lat0)) * k, -(c[1] - lat0) * k) for c in coords]
    if math.dist(pts[0], pts[-1]) < 0.5:
        pts = pts[:-1]  # o circuito é fechado; o último ponto repete o primeiro
    length = sum(math.dist(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts)))
    scale = official / length if official else 1.0
    pts = [(x * scale, y * scale) for x, y in pts]
    out = {
        "source_length_m": round(length, 1),
        "scale_applied": round(scale, 5),
        "points": [[round(x, 1), round(y, 1)] for x, y in pts],
    }
    json.dump(out, sys.stdout)


if __name__ == "__main__":
    main()
