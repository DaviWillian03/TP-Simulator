# Roadmap — F1 Guidelines

Ordem de construção: corrida → fim de semana (Grande Prêmio) → Corrida Caótica → Campanha.
Cada marco termina jogável e testado. Itens vêm de `docs/DECISIONS.md`.

## ✅ Marco 1 — Corrida rápida em Interlagos (2026-11-01)
- Projeto Godot, logo e ícone, tema visual, fonte Inter.
- Dados 2026: 11 equipes, 22 pilotos (nomes reais), compostos de pneu, Interlagos (traçado real).
- Simulação: desgaste de pneu com "penhasco", regra dos 2 compostos (DSQ se não cumprir),
  combustível, ar turbulento, ultrapassagem por zona e dificuldade da pista, modo de
  ultrapassagem com bateria (2026), pit stop com perda real do pit lane, IA de estratégia.
- Tela inicial (escolha de equipe e duração 25/50/100%) e tela de corrida: pista com 22
  bolinhas, tabela com pneu e desgaste, ordens de ritmo/energia/box para os 2 carros,
  tempo 1×/2×/4×/8× + pausa, avisos não intrusivos, resultado final.
- 28 testes GUT (unidade + integração da tela de corrida).

## ✅ Direção visual Paddock (2026-11-01)
- 8 mockups → escolha do usuário → tokens em `UiStyle`; menu, corrida e resultado refeitos.
- Tabela no formato da transmissão com emblemas originais + importação de logo pelo jogador.

## Marco 2 — Corrida completa (o que falta da gameplay de corrida)
- **Clima dinâmico** + pneus intermediário/chuva + **radar de chuva com incerteza (P3)**.
- **Safety car, VSC e bandeira vermelha (P6)**; incidentes, abandonos e quebras.
- **Punições**: 5 s / 10 s / drive-through, pontos na licença.
- **Ordens entre companheiros** (ceder posição), com chance de desobediência.
- **Rádio com personalidade (P1)**: sugestões e perguntas dos pilotos que pedem resposta.
- **Pista que evolui (P5)**: borracha acumulada; traçado secando após chuva.
- Pit stop com troca de asa e reparos (depende de danos).
- Menu dinâmico com dados completos de todos os pilotos, sem pausar.

## Marco 3 — Modo Grande Prêmio
- Fim de semana completo: treinos livres (acerto), classificação Q1/Q2/Q3, corrida, formato
  sprint nos GPs sprint; sessões puláveis.
- Configuração livre: circuito, equipe, duração, clima.
- **Mais circuitos do calendário 2026** (traçados via `tools/geojson_to_track.py`) e
  **cenários de fundo imersivos por pista e clima** (maior custo de arte).

## Marco 4 — Corrida Caótica ("Roleta do Caos", P8)
- Roleta de eventos + cartas de caos + variantes prontas, sobre o mesmo motor de corrida.

## Marco 5+ — Campanha (em camadas jogáveis)
Finanças e temporada → pessoal/pilotos e contratos → P&D (Essencial/Avançado) → fábrica →
patrocínios → estúdio de design (P9) → origens da equipe (P10) → academia de pilotos (P11) →
teto de gastos e restrição de túnel (P12) → conselho de regras (P13) → eventos (P14) →
F2/F3/F4 simuladas ao fundo → Modo Edição e importação (.zip).

## Pesquisa (antes de fixar atributos)
- Definir o modelo de atributos de pilotos e equipes; depois pesquisar dados reais de 2026
  para substituir os valores PROVISÓRIOS de `game/data/`.
- Confirmar o calendário 2026 completo (o dataset de traçados lista 23 GPs, sem Bahrein e
  Arábia Saudita — verificar), regulamento técnico 2026 (aero ativa, modo de ultrapassagem,
  compostos de pneu) e calibrar tempos de volta, desgaste e ultrapassagens por circuito.

## Android (depende do usuário)
- Instalar Android SDK (bloqueado na nuvem: `dl.google.com`) e criar o preset de exportação.
- No preset: excluir `addons/gut/*`, `test/*` e `tools/*`; conferir que `data/*.json` entra no APK.
- Primeiro teste em aparelho real: desempenho, toque e legibilidade da tela de corrida.
