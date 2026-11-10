# Código, dados e assets de terceiros

Tudo que vem de fora do projeto, com origem e licença. Atualizar ao adicionar qualquer item.

| Item | Onde está | Origem | Licença | Observação |
|---|---|---|---|---|
| GUT 9.7.1 | `game/addons/gut/` | https://github.com/bitwes/Gut (tag `v9.7.1`) | MIT (`game/addons/gut/LICENSE.md`) | Só para testes; não precisa ir no APK |
| Kanit (Bold, SemiBold, Medium) | `game/assets/fonts/Kanit-*.ttf` | https://github.com/google/fonts/tree/main/ofl/kanit | SIL OFL 1.1 (`game/assets/fonts/OFL-Kanit.txt`) | Fonte de todo o jogo (substituiu Titillium Web e Archivo) |
| Fontes dos mockups (Titillium Web, Saira Condensed, Barlow, Chakra Petch, Oxanium, Archivo, Bebas Neue, Space Mono, IBM Plex Mono, Russo One, Kanit) | `design/mockups/fonts/` | https://github.com/google/fonts (pasta `ofl/`) | SIL OFL 1.1 (arquivos `OFL-*.txt` na pasta) | Só para os mockups; não vão no jogo |
| Traçado de Interlagos | `game/data/circuits/interlagos.json` (`points`) | https://github.com/bacinger/f1-circuits, `circuits/br-1940.geojson` | MIT (`game/data/circuits/LICENSE-f1-circuits.md`) | Convertido para metros e escalado para 4.309 m |

## Criados para o projeto
- **Logo e ícone** (`game/assets/branding/logo.svg`, `logo-light.svg`, `game/icon.svg`): originais,
  gerados por `tools/make_logo.py`. As letras são contornos da fonte Inter 4.0 (OFL; licença em
  `game/assets/fonts/OFL-Inter.txt` — o OFL não restringe obras criadas com a fonte).
- **Emblemas das equipes** (`game/assets/emblems/`): originais (forma + sigla), gerados por
  `tools/make_emblems.py`. **Não** são os logos reais das equipes.

## Dados factuais
- Grid de 2026 (nomes, números, equipes, motores) confirmado por busca na web em 2026-11-01.
  Fatos não têm direito autoral; nomes reais usados por decisão do usuário (`docs/DECISIONS.md`).
- Sem logos oficiais nem fotos: cores das equipes são só valores hexadecimais aproximados.

Arte própria (sem terceiros): carro ilustrado `game/assets/cars/*.svg` (tools/make_car_art.py) e
ícones `game/assets/icons/*.svg` (tools/make_icons.py) e sons da corrida `game/assets/audio/*.wav`
(síntese em tools/make_sounds.py, sem gravações de terceiros).

Logos pessoais das equipes: o usuário forneceu um zip (formula1.com/en/teams, versões brancas dos
símbolos, 02/11/2026) para uso no **próprio celular**. As imagens ficam em `game/local/emblems/`
(ignorada pelo git) e **não entram no repositório**; `tools/prepare_logos.py` as padroniza e
`TeamEmblems` as compõe sobre um quadrado na cor da equipe.

## Bandeiras dos países (game/assets/flags/)
- **flag-icons** 7.2.3 — https://github.com/lipis/flag-icons (via cdn.jsdelivr.net/npm/flag-icons@7.2.3/flags/4x3/).
  Licença **MIT** (texto em `game/assets/flags/LICENSE-flag-icons.txt`). Usadas como fundo translúcido do nome do GP e na nacionalidade dos pilotos (cartão da corrida).

## Dados de resultados reais (data/real_form_2026.json)
- Posições de chegada de 2026 (fatos esportivos) levantadas por busca na web em 2026-11-10 (planetf1, the-race, crash.net, sky sports, formula1.com) e resumidas em `tools/real_results_2026.json`; só fatos (posições), nenhum texto ou imagem copiado. Parcial e sem checagem contra a classificação oficial.
