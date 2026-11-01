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

### #2 — Modos de jogo (2026-11-01)

> Vamos agora aos modos de jogo.
>
> Quero que essa nossa primeira versão do jogo tenha os seguintes modos:
> - grande prêmio, o modo onde você escolhe uma equipe, e corre um final de semana completo da
>   Fórmula 1 até o fim.
> - modo campanha, o carro-chefe do jogo, onde você terá a opção de se juntar a uma das equipes
>   reais do grid, ou criar a sua própria equipe e desafiar as equipes já existentes.
> - corrida caótica, um modo divertido onde darei liberdade para você criar algo que me surpreenda,
>   que faça uma corrida totalmente livre para a bizarrice e o entretenimento.

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

### Modos de jogo (primeira versão)
- **Grande Prêmio**: escolher uma equipe e disputar um **fim de semana completo** de F1 até o
  fim. (#2)
- **Campanha** — o **carro-chefe** do jogo: entrar numa das **equipes do grid** ou **criar a
  própria equipe** e desafiar as existentes. (#2)
- **Corrida Caótica**: modo de diversão, livre para bizarrice e entretenimento; o usuário deu
  **liberdade criativa ao Claude** para surpreender (ver proposta P8). (#2)

---

## Dúvidas em aberto

> **Pedido do usuário (2026-11-01):** estas perguntas devem ser feitas em **formato de múltipla
> escolha** no momento de criar o projeto (não antes). Até lá, apenas acumular aqui.
> Ao perguntar, incluir também as propostas P1–P7 para aprovação.

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

Modos de jogo (#2):
11. **Equipes "reais do grid"** (#2) × licenças: equipes reais licenciadas não são viáveis para
    publicar; opções: equipes fictícias inspiradas nas reais, nomes editáveis pelo jogador, ou
    jogo sem publicação. (liga com a dúvida 5)
12. **Fim de semana do Grande Prêmio**: quais sessões? Treinos livres (para acertar o carro?),
    classificação em três partes (Q1/Q2/Q3), corrida — e fins de semana com **sprint**?
    O jogador pode **pular/simular** sessões?
13. **Grande Prêmio**: o jogador escolhe livremente circuito, clima e duração? O desempenho de
    cada equipe é fixo ou configurável?
14. **Campanha — duração**: número fixo de temporadas, ou carreira sem fim?
15. **Campanha — o que o jogador gerencia** entre corridas (desenvolvimento do carro, pilotos,
    funcionários, patrocinadores, finanças)? Pode ser tratado num próximo passo.
16. **Campanha — criar equipe**: o que é personalizável (nome, cores, logo, base, orçamento
    inicial)? Equipe nova começa mais fraca?
17. **Campanha — fracasso**: o jogador pode ser **demitido** (se entrou numa equipe existente)
    ou a equipe própria pode **falir**?
18. **Corrida Caótica**: aprovar ou ajustar o conceito da proposta P8.

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
- **Os três modos usam o mesmo "motor de corrida"** (#2). A simulação da corrida é construída
  uma vez e reaproveitada:
  - **Grande Prêmio** = um fim de semana avulso (classificação + corrida) sem a parte de gestão.
  - **Campanha** = vários fins de semana + gestão entre as corridas + salvar progresso.
  - **Corrida Caótica** = a mesma corrida com uma camada de **modificadores** que alteram as
    regras.
  Por isso a simulação deve aceitar regras configuráveis desde o início: número de voltas, regra
  de pneus, chance de chuva, dificuldade de ultrapassagem etc. Isso faz o modo caótico sair
  barato e já serve para testes.
- **Ordem natural de construção**: corrida → fim de semana (Grande Prêmio) → Corrida Caótica
  (modificadores) → Campanha (a maior, depende de gestão e de salvar progresso). O Grande
  Prêmio é a primeira versão jogável completa.
- **Campanha precisa salvar progresso** entre sessões. No Godot isso é simples (arquivo em
  `user://`), mas o formato dos dados deve ser pensado cedo, para não quebrar os saves quando o
  jogo for atualizado.

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

### P8 — Conceito para a Corrida Caótica (#2, liberdade criativa dada pelo usuário)

**Nome de trabalho: "Roleta do Caos".** É uma corrida normal que vai sendo sabotada pelo
próprio jogo e pelos jogadores. Duas mecânicas simples:

1. **A Roleta** — a cada poucas voltas, uma roleta gira na tela (sem pausar) e sorteia um evento
   que vale para todos por algumas voltas. Aparece um aviso 1 volta antes, para dar tempo de reagir.
2. **Cartas de Caos** — o jogador começa com 3 cartas e ganha mais ao ultrapassar ou completar
   voltas. Usa-as na hora certa, a seu favor ou contra rivais. As equipes da IA também têm
   cartas.

Exemplos de eventos e cartas (lista inicial, para escolher/cortar):

| Evento / carta | O que acontece |
|---|---|
| **Pista invertida** | Todos dão meia-volta e passam a correr no sentido contrário; o último vira o primeiro a chegar na "nova" freada. |
| **Tempestade num setor só** | Chove forte em metade da pista e faz sol na outra; nenhum pneu é perfeito. |
| **Roleta de pneus** | Todos os carros recebem, à força, um composto sorteado. |
| **Vácuo gigante** | Por 3 voltas ultrapassar fica fácil demais — festival de trocas de posição. |
| **Pit lane fechado** | Ninguém pode parar por algumas voltas (quem estava para trocar pneu sofre). |
| **Grid embaralhado** | Uma bandeira vermelha "maluca" reordena as posições aleatoriamente. |
| **Invasão de pista** | Animais típicos da região do circuito atravessam a pista (aproveita os cenários de cada pista). Carros desaceleram para desviar. |
| **Óleo na pista** | Carta: deixa uma mancha num ponto do circuito; quem passa por ela perde tempo. |
| **Escudo** | Carta: protege seu piloto do próximo evento negativo. |
| **Volta de pontos em dobro** | Quem estiver na frente ao fim da volta sorteada ganha bônus. |
| **Troca de pilotos** | Dois pilotos de equipes diferentes trocam de carro até o fim da corrida. |

Por que este formato:
- É **simples**: são as mesmas bolinhas e o mesmo pit stop, só que com regras malucas, então
  qualquer um entende em segundos.
- Reaproveita o motor de corrida e os cenários, então custa pouco para construir.
- Cada partida é diferente, e o modo vira um "lanche" rápido entre corridas sérias.
- Podem existir **variantes prontas** (ex.: "Só chuva", "Tudo invertido", "Caos total") e
  corridas curtas (5–10 voltas).
