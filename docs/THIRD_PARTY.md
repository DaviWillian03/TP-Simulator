# Código, dados e assets de terceiros

Tudo que vem de fora do projeto, com origem e licença. Atualizar ao adicionar qualquer item.

| Item | Onde está | Origem | Licença | Observação |
|---|---|---|---|---|
| GUT 9.7.1 | `game/addons/gut/` | https://github.com/bitwes/Gut (tag `v9.7.1`) | MIT (`game/addons/gut/LICENSE.md`) | Só para testes; não precisa ir no APK |
| Fonte Inter 4.0 (SemiBold, ExtraBold) | `game/assets/fonts/` | https://github.com/rsms/inter (pacote Debian `fonts-inter` 4.0) | SIL OFL 1.1 (`game/assets/fonts/OFL.txt`) | Fonte da interface |
| Traçado de Interlagos | `game/data/circuits/interlagos.json` (`points`) | https://github.com/bacinger/f1-circuits, `circuits/br-1940.geojson` | MIT (`game/data/circuits/LICENSE-f1-circuits.md`) | Convertido para metros e escalado para 4.309 m |

## Criados para o projeto
- **Logo e ícone** (`game/assets/branding/logo.svg`, `game/icon.svg`): originais, gerados por
  `tools/make_logo.py`. As letras são contornos da fonte Inter (o OFL não restringe obras
  criadas com a fonte).

## Dados factuais
- Grid de 2026 (nomes, números, equipes, motores) confirmado por busca na web em 2026-11-01.
  Fatos não têm direito autoral; nomes reais usados por decisão do usuário (`docs/DECISIONS.md`).
- Sem logos oficiais nem fotos: cores das equipes são só valores hexadecimais aproximados.
