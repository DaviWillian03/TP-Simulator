# Ideias do jogo (fase de coleta)

Status: **coletando ideias — implementação NÃO autorizada** até o usuário dizer explicitamente
para começar o jogo.

Como este arquivo funciona:
- **Registro**: cada mensagem do usuário entra aqui, fiel ao que foi dito (sem acrescentar requisitos).
- **Ideias por tema**: resumo organizado do que o usuário pediu, com referência ao registro (#n).
- **Dúvidas / Observações técnicas / Propostas do Claude**: análise separada. Propostas só viram
  requisito se o usuário aprovar.

---

## Registro (ordem de chegada)

### #1 — Gameplay da corrida (2026-11-01)

> Vamos focar primeiro no que é mais importante, a gameplay.
> A gameplay pura será simples, quero que seja basicamente igual a como é jogado o Motorsport
> Manager 3 Mobile, ao fundo terá o mapa do circuito de corrida, e dentro da pista terá bolinhas
> representando cada piloto e equipe, rodando pelo circuito durante as voltas até acabar a corrida,
> a velocidade das bolinhas estará representando a velocidade de cada carro e piloto que será
> definido por outros aspectos que trataremos mais tarde.
>
> Os elementos que serão possíveis de alterar o prosseguimento padrão da corrida, por input do
> jogador serão os seguintes:
> - estratégia de pneus, seguindo o regulamento da Fórmula 1 oficial, teremos trocas de pneus, onde
>   teremos pneus mais rápidos, e também mais duráveis, em que será possível e obrigatória fazer
>   trocas na corrida (a não ser que esteja chovendo na corrida).
> - Como team principal da equipe, também será possível gerenciar os pilotos na pista, em termos de
>   mandar um piloto ceder a posição para o outro entre outras coisas, o que não necessariamente
>   será sempre obedecido pelo piloto.
> - Quero que as ultrapassagens não sejam facilitadas apenas porque não é um jogo onde elas serão
>   mostradas, a dificuldade em ultrapassar é um fator importante na Fórmula 1, e isso também será
>   decidido pela dificuldade de ultrapassagem especificamente de cada circuito.
> - Os pilotos poderão dar sugestão do que querem que seja feito na corrida deles por parte de nossa
>   gerência de prova, e eles podem perguntar coisas que irão depender da nossa resposta para
>   funcionar da melhor forma possível.
> - Quero que no background do circuito, tenha um ambiente bonito e imersivo, que mude de acordo
>   com o clima, e que tenha elementos que tenham na vida real de cada uma das pistas, para deixar a
>   experiência bem legal.
> - Também quero que um pop-up surja na tela de forma que não atrapalhe a gerência de corrida do
>   jogador, a respeito de acontecimentos importantes da corrida, e também para o campeonato mundial.
> - A tela de corrida também terá a informação da tabela atual da corrida, com a informação do pneu
>   utilizado e do quão gasto ele está ao lado, também será possível acessar um menu dinâmico que
>   conte com outras informações mais completas sobre a corrida dos seus pilotos e de todos pilotos
>   da corrida, sem precisar pausar o GP para mexer nisso.
> - A parte das peças do carro também será importante, no pit stop será possível trocar asa,
>   consertar coisas possíveis, pagar punições por incidentes dos pilotos etc.
> - Também tente inovar e fazer algo criativo e legal que adicione a imersão da corrida, mesmo que
>   eu não tenha citado aqui, mas que não mude a proposta do jogo ser na prática simples e
>   divertido, sem deixar pesado e maçante demais.

---

## Ideias por tema

### Princípio geral
- Gameplay de corrida **simples e divertida**, sem ficar pesada ou maçante. (#1)
- Referência de estilo de jogo: Motorsport Manager 3 Mobile. (#1)
- Fidelidade à F1 real onde importa: regras de pneus, dificuldade de ultrapassar. (#1)

### Visualização da corrida
- Mapa do circuito ao fundo; cada carro é uma **bolinha** identificando piloto e equipe. (#1)
- Bolinhas percorrem a pista volta a volta até o fim; a **velocidade da bolinha = ritmo real** do
  carro/piloto (atributos definidos depois). (#1)
- Cenário de fundo **bonito e imersivo**, que **muda com o clima** e tem **elementos reais de cada
  pista**. (#1)

### Decisões do jogador durante a corrida
- **Pneus**: compostos mais rápidos × mais duráveis; troca obrigatória pela regra da F1, exceto
  em corrida com chuva. (#1)
- **Ordens aos pilotos** como chefe de equipe (ex.: ceder posição ao companheiro, "entre outras
  coisas"); o piloto **pode desobedecer**. (#1)
- **Pit stop**: pneus, troca de asa, reparos possíveis, cumprir punições por incidentes. (#1)
- **Pilotos sugerem e perguntam** pelo rádio; a resposta do jogador afeta o desempenho. (#1)

### Simulação
- Ultrapassar é **difícil**, como na F1, e a dificuldade **varia por circuito**. (#1)
- Peças do carro importam (desgaste/danos reparáveis no pit). (#1)

### Interface da corrida
- **Tabela de posições** sempre visível com pneu atual e **nível de desgaste**. (#1)
- **Menu dinâmico** com dados completos dos seus pilotos e de todos os pilotos, **sem pausar**. (#1)
- **Pop-ups não intrusivos** para eventos importantes da corrida e do campeonato. (#1)

---

## Dúvidas em aberto

Prioritárias (afetam a base da simulação):
1. **Regra de pneus**: seguir a regra atual da F1 — usar **pelo menos dois compostos de pista
   seca diferentes** — ou só "uma parada obrigatória"? Haverá pneus intermediários e de chuva?
2. **Outras ordens aos pilotos** além de "ceder posição": ritmo (atacar / poupar pneus),
   poupar combustível/motor, defender posição, segurar quem vem atrás?
3. **Controle do tempo**: a corrida terá aceleração (1×, 2×, 4×…)? Existe pausa, ou nunca pausa?
4. **Duração da corrida**: número real de voltas ou corrida encurtada (ex.: 25%/50%)?
5. **Circuitos, equipes e pilotos reais ou fictícios?** (ver observação sobre licenças abaixo)

Para depois:
6. Quantos carros no grid (20 como a F1 atual)?
7. O clima pode **mudar durante** a corrida (começar seco e chover)?
8. Safety car / bandeira vermelha fazem parte?
9. "Pagar punições": cumprir punição de tempo no pit (como na F1) ou também multa em dinheiro?
10. Orientação da tela: paisagem (deitado) ou retrato (em pé)?

---

## Observações técnicas (análise do Claude, não são requisitos)

- **Identidade própria**: o MM3 Mobile é referência de *gênero* (gestão com visão de cima e
  bolinhas na pista). O jogo terá nomes, interface, arte e regras de simulação próprios — além de
  ser mais interessante, evita problemas de direito autoral se o jogo for publicado.
- **Licenças**: "Fórmula 1", nomes de equipes, pilotos, logos e nomes oficiais de circuitos são
  marcas registradas. Para publicar na Play Store, o caminho comum é usar campeonato, equipes e
  pilotos fictícios e circuitos *inspirados* nos reais (traçado e paisagem parecidos, nome
  diferente). As regras de pneus podem seguir a F1 sem problema. Decisão do usuário (dúvida 5).
- **Bolinhas na pista** se encaixam bem no Godot: o traçado vira uma curva (`Path2D`) e cada
  carro avança sobre ela. Recomendação: a **simulação** (posição, ritmo, desgaste, ultrapassagens)
  roda separada do **desenho**. Assim dá para acelerar o tempo, testar as regras com GUT e
  reproduzir uma corrida igual com a mesma "semente" aleatória.
- **Dificuldade de ultrapassagem por pista**: cada circuito guarda um índice geral mais
  **zonas de ultrapassagem** (retas e freadas). Ultrapassar depende da diferença de ritmo,
  pneus, pilotos e da zona. Sem diferença real de ritmo, quem está atrás fica preso, como na F1.
- **Desobediência dos pilotos**: depende de atributos ainda não definidos (personalidade,
  relação com a equipe, situação no campeonato). Fica para quando tratarmos dos pilotos.
- **Cenários imersivos por pista e clima**: é a parte que mais custa em **arte**, não em código.
  Camadas 2D, partículas de chuva e mudança de luz/cor são leves no celular. Cada circuito novo
  exige um cenário próprio — vale começar com poucas pistas bem feitas.
- **Interface sem pausa no celular**: tela pequena com tabela, mapa, menu e pop-ups ao mesmo tempo.
  Isso pede painéis recolhíveis e pop-ups em fila por prioridade. Provavelmente favorece a tela
  deitada (dúvida 10).

---

## Propostas do Claude (aguardando aprovação do usuário)

Atendem ao pedido de inovar (#1) sem deixar o jogo pesado. Cada uma pode ser aceita, ajustada
ou descartada.

| # | Proposta | Por que ajuda | Custo |
|---|---|---|---|
| P1 | **Rádio da equipe com personalidade**: mensagens curtas dos pilotos em balões (reclamações, comemorações, pedidos). Usa o mesmo sistema das sugestões e perguntas. | Os pilotos parecem pessoas, sem tela extra. | Baixo |
| P2 | **Prévia de retorno do pit**: ao pensar em parar, uma bolinha "fantasma" mostra onde o piloto voltaria à pista e atrás de quem. | Deixa o undercut/overcut visível e fácil de entender. | Baixo |
| P3 | **Radar de chuva com incerteza**: previsão como "60% de chuva em 8–12 voltas", que fica mais precisa com o tempo. | Decisões de pneu viram aposta calculada, não sorteio. | Médio |
| P4 | **Batalhas em destaque**: quando dois carros ficam colados por várias voltas, um indicador mostra a disputa e a chance de ultrapassagem na próxima zona. | Dá emoção às ultrapassagens que não são mostradas em vídeo. | Baixo |
| P5 | **Pista que evolui**: borracha acumulada deixa a pista mais rápida; depois da chuva surge um traçado seco aos poucos. | Mais realismo; muda o melhor momento de trocar pneu. | Médio |
| P6 | **Safety car e VSC**: eventos que "barateiam" o pit stop e embaralham a estratégia. | Momentos de virada, muito típicos da F1. | Médio |
| P7 | **Som ambiente reativo**: torcida, chuva e motores que reagem aos eventos (mais alto numa ultrapassagem, numa corrida "em casa"). | Imersão grande com pouco código. | Baixo (depende de áudio) |
