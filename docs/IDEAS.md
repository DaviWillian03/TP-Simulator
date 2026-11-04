# Ideias do jogo (fase de coleta)

Status: **implementação autorizada em #6** (2026-11-01). Dúvidas sendo respondidas em múltipla escolha.

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

### #3 — Dados reais, modo edição e importação (2026-11-01)

> Informações práticas sobre como serão os modos de jogo:
>
> Eu não sei se é possível você utilizar nomes, fotos etc de pilotos e equipes reais da Fórmula 1,
> mas se for possível quero isso, com eles tendo habilidades, potencial e qualidade de estrutura,
> equipamento etc baseados na vida real, com informações realistas de conquistas até hoje, idade,
> peso, altura etc, faça pesquisa profunda em sites especializados, opiniões de especialistas sobre
> automobilismo para fazer esse aspecto bem realista.
> Caso não seja possível usar essas informações reais, quero que você faça nomes e fotos totalmente
> parecidos com a vida real.
> Aí que entraria o modo edição do jogo, onde seria possível para o usuário em si trocar os nomes
> dos pilotos, fotos oficiais, e até imagem dos carros para que tenha menus interativos com essas
> informações de forma mais imersiva, para burlar os direitos de imagem, você até poderia fazer o
> jogo com essas informações genéricas que pedi antes, mas dar a opção de importar depois com dados
> e imagens reais por cima como se fosse um option file.

### #4 — Modo Campanha em detalhe (2026-11-01)

> Agora detalhando melhor como será o modo campanha.
> Quero que seja gerenciável as seguintes coisas:
>
> - edição total sobre o design do carro (dentro do regulamento atual), podendo ter várias formas
>   de pintura diferentes, alocação de patrocínios, tipo de tinta etc. quero que essa parte seja bem
>   elaborada, pode criar coisas que acredite que fique legal e não tenha dito. o mesmo vale para
>   logo da equipe criada caso você opte por isso.
> - Ao escolher uma equipe real, as informações sobre dirigentes técnicos, engenheiros, pilotos,
>   história da equipe, nível da equipe etc também tem que ser as informações da vida real da
>   temporada 2026.
> - Ao criar uma equipe, as informações serão genéricas e terá esses cargos fictícios, menos
>   pilotos, porque quero pegar pilotos de outras categorias na vida real.
> - Também adicione elementos e escolhas para que ao criar sua equipe, possa ter caminhos e
>   objetivos diferentes para seguir em termos de o quão complexa ou difícil será a sua campanha.
>
> Já com o modo campanha iniciado, quero que tenha as seguintes coisas como possível para gerenciar:
> - árvore de pesquisa e desenvolvimento do carro atual e do carro do ano seguinte, quero que essa
>   parte seja bem completa, sendo possível desenvolver motor (caso seja o caso da sua equipe ter
>   motor próprio e não adquirido de outra), chassi, aerodinâmica, confiabilidade etc. quero que
>   essa parte seja bem completa, para que o jogador indique em qual direção quer que o
>   desenvolvimento aconteça, e quanto mais estruturada sua fábrica for, melhor serão seus
>   upgrades, ou pelo menos terá uma porcentagem maior de que isso aconteça.
> - desenvolvimento de fábrica, se inspire em jogos do mesmo estilo para dar opções de desenvolver
>   a estrutura da sua equipe, o que afetará diretamente no avanço que sua equipe terá na mídia,
>   marketing, influência, patrocínios, criação de peças etc.
> - Aba de patrocínios, onde você poderá negociar para adquirir os melhores baseado na influência
>   que sua equipe tem, se puder usar nomes e logos de marcas reais ótimo, se não puder, use nomes
>   bem parecidos inspirados.
> - gerenciamento de pessoal, onde você poderá negociar contratos dos cargos da sua equipe,
>   negociar com agentes livres e de outras equipes, além de poder também negociar com novos
>   pilotos para a sua equipe.
> - Se quiser criar mais uma coisa legal que seja possível gerenciar pode, nada que seja tão
>   complexo.

### #5 — Campanha: mudanças de regras e eventos inesperados (2026-11-01)

> Complementando o modo campanha.
>
> - ao longo dos anos serão tomadas decisões sobre mudanças de regras como pontuação, tipo dos
>   carros, se serão motores V8, V6 etc, tipo de chassi, tipos de pneus.
> - teremos eventos inesperados que podem alterar o campeonato, como corridas sendo canceladas por
>   motivos de o país estar em problemas, piloto sofrer acidente e ficar fora de corrida, piloto ter
>   problemas emocionais e perder desempenho entre outras coisas que você pode inventar etc.
>   dependendo do acontecimento, você pode tomar decisões para ajudar na gestão de pessoal.

### #6 — Regulamento 2026, nome e início do projeto (2026-11-01)

> Quero que os circuitos, as regras, os mapas da pista sejam todos baseados no regulamento oficial
> da F1 2026. Agora pode começar o projeto do jogo que terá o nome de F1 Guidelines, faça uma logo
> bonita para o jogo, e pode começar o projeto.
>
> Me pergunte caso sinta que faltou informação ou sobre as dúvidas que você teve anteriormente,
> sempre em múltipla escolha para eu escolher.

Consequências registradas:
- **Implementação autorizada** a partir deste ponto.
- Nome do jogo: **F1 Guidelines**. Logo a ser criada pelo Claude.
- Circuitos, regras e traçados baseados na **F1 2026** (calendário e regulamento oficiais).
  Grid de 2026 tem 11 equipes / 22 carros (resolve a dúvida 6).

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

### Campanha — início (#4)
- **Duas formas de começar**:
  - **Equipe real**: dirigentes, engenheiros, pilotos, história e nível da equipe com dados
    reais da **temporada 2026**.
  - **Equipe criada**: cargos com pessoas **fictícias/genéricas**, **exceto os pilotos**, que o
    usuário quer contratar de **outras categorias reais** (ver licenças em #3).
- Ao criar uma equipe: **caminhos e objetivos diferentes** que definem quão **complexa ou
  difícil** será a campanha (ver proposta P10).

### Campanha — design do carro e identidade (#4)
- **Edição total do design do carro**, dentro do **regulamento atual**.
- **Várias pinturas diferentes**, **posição dos patrocinadores** no carro, **tipo de tinta** etc.
- Deve ser **bem elaborado**; o Claude pode criar recursos extras (ver proposta P9).
- **Logo da equipe criada**: mesma liberdade criativa (ver P9).

### Campanha — gestão durante a temporada (#4)
- **Pesquisa e desenvolvimento** em árvore, para o **carro atual e o do ano seguinte**; deve
  ser **bem completa**:
  - áreas: **motor** (só se a equipe fabrica o próprio motor, e não o compra), **chassi**,
    **aerodinâmica**, **confiabilidade** etc.;
  - o jogador **escolhe a direção** do desenvolvimento;
  - **fábrica mais estruturada = upgrades melhores**, ou pelo menos **maior chance** de sucesso.
- **Desenvolvimento da fábrica/estrutura** — inspirado em jogos do gênero — afetando **mídia,
  marketing, influência, patrocínios e criação de peças**.
- **Patrocínios**: negociar os melhores conforme a **influência** da equipe. Marcas reais se
  possível; senão, nomes "bem parecidos inspirados" (ver licenças).
- **Pessoal**: negociar contratos dos cargos; contratar **agentes livres** e profissionais de
  **outras equipes**; negociar com **novos pilotos**.
- O Claude pode propor **mais uma coisa gerenciável, sem ser complexa** (ver P11).

### Campanha — regulamento que muda com os anos (#5)
- Ao longo das temporadas, **decisões mudam as regras**:
  - **sistema de pontuação**;
  - **tipo dos carros**;
  - **motor** (V8, V6 etc.);
  - **tipo de chassi**;
  - **tipos de pneus**.
- (Quem decide e como o jogador participa: dúvida 35 e proposta P13.)

### Campanha — eventos inesperados (#5)
- Eventos que **alteram o campeonato**, por exemplo:
  - **corrida cancelada** por problemas no país;
  - **piloto acidentado**, fora de corridas;
  - **piloto com problemas emocionais**, perdendo desempenho;
  - outros inventados pelo Claude (ver P14).
- Conforme o evento, o jogador **toma decisões** para ajudar na **gestão de pessoal**.

### Pilotos, equipes e dados (#3)
- Desejo do usuário, em ordem de preferência:
  1. Nomes, fotos e dados **reais** de pilotos e equipes, **se for possível**.
  2. Se não for possível: nomes e fotos **"totalmente parecidos"** com os reais.
- Atributos baseados na vida real: **habilidades, potencial**, qualidade da **estrutura e
  equipamento** das equipes.
- Dados biográficos realistas: **conquistas até hoje, idade, peso, altura** etc.
- Base dos atributos: **pesquisa profunda** em sites especializados e opinião de especialistas.

### Modo Edição e importação (#3)
- **Modo Edição** no jogo: o usuário troca **nomes dos pilotos, fotos e imagem dos carros**.
- Os menus mostram essas informações de forma **interativa e imersiva**.
- O jogo pode vir com **dados genéricos** e permitir **importar depois** dados e imagens reais
  por cima, **como um "option file"**.

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

Dados reais, edição e importação (#3) — absorve as dúvidas 5 e 11:
19. **Intenção de publicação**: publicar na Play Store, distribuir de graça fora da loja, ou
    projeto pessoal/de estudo? Isso muda o nível de risco aceitável com nomes e imagens.
20. **Nomes no jogo base**: (a) fictícios e claramente diferentes, inspirados em perfis reais;
    (b) "quase iguais" aos reais (o usuário pediu, mas o risco jurídico é o mesmo de usar o nome
    real — ver observações); (c) outra opção.
21. **Retratos no jogo base**: ilustrações estilizadas de pessoas fictícias, gerador de rostos
    combinando partes, silhuetas/capacetes, ou outra opção.
22. **O que o Modo Edição pode mudar**: só nomes, fotos e pinturas dos carros, ou também
    atributos, equipes, cores, logos e nomes de circuitos?
23. **Compartilhar o arquivo de importação**: deve ser um arquivo único fácil de passar entre
    jogadores (como os option files de PES)?
24. ~~Temporada de referência~~ → **respondida em #4: temporada 2026.** (Confirmar só se, ao
    começar o projeto, a temporada 2027 já tiver começado.)

Campanha (#4):
25. **Nomes reais nas equipes reais** (dirigentes, engenheiros) e **pilotos reais de outras
    categorias** na equipe criada: mesma questão de licença de #3. Proposta: no jogo base, todos
    fictícios com perfis inspirados nos reais; nomes reais só via arquivo de importação. Confirmar.
26. **Patrocinadores**: marcas fictícias **claramente diferentes** (recomendado) ou "bem
    parecidas"? Marcas quase iguais às reais têm o mesmo problema de marca registrada de #3.
    Logos de marcas reais só via importação pessoal.
27. **Quais categorias** fornecem pilotos para a equipe criada: F2, F3, IndyCar, endurance
    (WEC), Super Fórmula, kart? E essas categorias são simuladas (resultados ao fundo) ou só
    funcionam como "mercado de pilotos"?
28. **Tinta e acabamento**: afetam só o visual ou têm efeito de desempenho (ex.: tinta pesa;
    carbono exposto é mais leve)? Ver P9.
29. **Regras financeiras e técnicas reais**: incluir **teto de gastos** e **restrição de túnel
    de vento** (quem termina melhor no campeonato tem menos tempo de túnel)? Ver P12.
30. **Motor da equipe criada**: pode começar fabricando o próprio motor ou precisa comprar
    de um fornecedor e só mais tarde virar fabricante?
31. **Profundidade da P&D × jogo "simples e divertido"** (#1): o usuário quer a P&D "bem
    completa". Proposta: modo **Essencial/Avançado** ou um diretor técnico que pode receber a
    função de decidir sozinho. Confirmar.
32. **Ritmo entre corridas**: a P&D e a fábrica avançam por **dias/semanas de calendário**
    (tempo passa entre GPs) ou por "turnos" de uma corrida?
33. **Negociação de contratos**: simples (oferta → aceita/recusa/contraproposta) ou com
    cláusulas (duração, bônus por resultado, multa rescisória, papel de 1º/2º piloto)?
34. Aprovar/ajustar as propostas **P9 a P12**.

Regras e eventos (#5):
35. **Quem decide as mudanças de regras**:
    - (a) uma federação fictícia decide sozinha;
    - (b) as equipes votam e o jogador vota e faz lobby com sua influência (P13);
    - (c) o jogador escolhe livremente no início de cada temporada, como opção de personalização.
36. **Antecedência e frequência**: mudanças anunciadas com 1 temporada de antecedência (motor,
    2 temporadas)? Quantas por temporada, no máximo?
37. **Outras regras mutáveis** além das citadas: reabastecimento, corridas sprint, asa móvel,
    peso mínimo, número de corridas no calendário?
38. **Frequência dos eventos** configurável (desligados / raros / normais / frequentes)?
39. **Tom dos temas sensíveis**:
    - cancelamentos com motivos genéricos e fictícios ("instabilidade no país-sede", "desastre
      natural"), sem citar crises reais;
    - saúde mental tratada com respeito, com opções de apoio ao piloto (psicólogo, folga) e não
      como punição.
    Confirmar.
40. Aprovar/ajustar as propostas **P13 e P14**.

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

### Direitos de nome e imagem (#3) — não é parecer jurídico, é o panorama geral
- **Nomes reais de pilotos** são protegidos pelo direito de imagem/personalidade. Jogos oficiais
  pagam licença ao piloto ou à associação de pilotos. **Nomes de equipes, logos e
  "Fórmula 1/F1"** são marcas registradas.
- **Fotos oficiais** têm direito autoral do fotógrafo ou agência, além do direito de imagem da
  pessoa. Não podem ir dentro do jogo nem ser baixadas pelo Claude para o projeto.
- **Nomes "quase iguais" e rostos parecidos** (ex.: trocar uma letra do sobrenome, gerar um
  rosto que imita o piloto) **não resolvem o problema**. A lei protege a identidade
  reconhecível da pessoa, não só a grafia exata. Por isso o Claude não vai gerar retratos
  realistas que imitem pessoas reais.
- **Fatos não têm dono**: idade, altura, número de vitórias e títulos são informação pública e
  podem ser pesquisados. Eles podem orientar a criação de pilotos fictícios ("um bicampeão
  holandês de 29 anos") ou preencher um arquivo de importação feito pelo usuário.
- **O modelo "option file" é o caminho viável**, e foi o que o usuário sugeriu: o jogo traz só
  conteúdo fictício e um importador genérico. Quem importa dados e imagens reais é o próprio
  jogador, para uso pessoal. Cuidados:
  - o jogo **não deve trazer nem divulgar** pacotes com dados ou fotos reais;
  - a página da loja **não deve anunciar** "importe a F1 real" (a Play Store tem regras contra
    apps que incentivam violação de propriedade intelectual).

### Modo Edição / importação — implicações técnicas (#3)
- O jogo precisa ser **orientado a dados** desde o início: pilotos, equipes, carros e circuitos
  vêm de arquivos de dados (ex.: JSON) e não ficam escritos no código. Isso também facilita
  balancear o jogo e testar.
- Imagens importadas são carregadas **em tempo de execução** a partir de `user://` (pasta do app
  no celular). O Godot consegue carregar PNG/JPG de fora do projeto (`Image.load_from_file`).
- **Formato do pacote** (sugestão): um `.zip` com um `manifest.json` (versão do formato,
  nome do pacote) e pastas `pilotos/`, `equipes/`, `carros/`. Assim fica um arquivo único fácil
  de compartilhar (dúvida 23).
- **Validação** na importação: tamanho máximo das imagens, campos obrigatórios e versão do
  formato. Um pacote ruim não pode travar o jogo nem corromper o save.
- No Android, o usuário escolhe o arquivo pelo seletor do sistema. Precisa ser testado em
  aparelho real (acesso a arquivos muda entre versões do Android).
- **Pinturas dos carros importadas**: as "bolinhas" da corrida usam as cores da equipe. A imagem
  importada do carro aparece nos menus (garagem, perfil da equipe).

### Pesquisa de dados reais — planejamento (#3)
- O usuário pediu **pesquisa profunda**. Ela será feita, mas **só depois de definirmos os
  atributos** dos pilotos e das equipes (o usuário disse em #1 que isso será tratado mais
  tarde). Sem saber quais notas existem (ex.: ritmo, consistência, chuva, ultrapassagem,
  gestão de pneus), não há o que medir, e a pesquisa teria de ser refeita.
- Plano quando chegar a hora:
  - fatos (idade, altura, peso, vitórias, títulos, pódios) em bancos de resultados e estatísticas;
  - avaliações qualitativas a partir de análises de especialistas e de comparações com
    companheiros de equipe (o principal dado objetivo na F1);
  - estrutura das equipes a partir de resultados recentes, investimento e notícias técnicas.
- Saídas possíveis, conforme a dúvida 20:
  - perfis para pilotos fictícios inspirados nos reais;
  - um arquivo de exemplo com dados reais para o usuário importar por conta própria — **sem
    fotos e fora do jogo distribuído**.
- Limitação conhecida: na nuvem, vários sites estão bloqueados pela rede. A pesquisa pode
  exigir liberar domínios ou ser feita localmente.

---

### Campanha — implicações técnicas (#4)
- **A Campanha é, de longe, o maior sistema do jogo.** Tem editor, P&D, fábrica, finanças,
  patrocínio, mercado de pessoal e IA das equipes rivais. Vale construir em camadas, cada uma
  jogável: base de finanças e temporada → pessoal/pilotos → P&D → fábrica → patrocínios →
  editor completo.
- **Editor de pintura em 2D, guardado como dados**: a pintura é salva como lista de camadas
  (forma, cor, acabamento, posição), não como imagem. Ocupa pouco espaço no save, pode ser
  redesenhada em qualquer tamanho e editada depois. Acabamentos (metálico, fosco, cromado) saem
  com *shaders* simples do Godot. "Dentro do regulamento" vira peças pré-definidas (bicos,
  laterais, asas compatíveis com as regras de 2026), não modelagem livre.
  - Ponto de atenção: um editor rico em **tela de celular** (toque, zoom, camadas) é o trabalho
    de interface mais pesado do jogo. Precisa de protótipo e teste com o usuário no aparelho.
- **P&D orientada a dados**: cada nó da árvore (área, custo, tempo, pré-requisitos, faixa de
  ganho) fica num arquivo. A chance de sucesso combina nível da fábrica e qualidade dos
  engenheiros. O resultado varia, como na F1 real, onde upgrades às vezes decepcionam. Com
  semente aleatória fixa, os testes GUT verificam as probabilidades.
- **Carro atual × carro do ano seguinte**: recursos divididos entre os dois. É a decisão
  clássica da F1 (abandonar a temporada para mirar a próxima) e combina com o pedido do usuário.
- **As equipes da IA precisam jogar o mesmo jogo**: desenvolver o carro, contratar pessoal e
  fechar patrocínios com as mesmas regras. Senão o jogador domina em poucas temporadas, ou nunca
  alcança ninguém.
- **Equilíbrio da economia**: é preciso simular várias temporadas automaticamente (headless,
  sem gráficos) para conferir se o dinheiro não explode nem acaba. Isso usa o mesmo motor
  separado da tela citado em #1 e #2.
- **Regulamento de 2026**: o design "dentro do regulamento atual" e as áreas de P&D (ex.: motor
  com divisão maior entre combustão e parte elétrica, aerodinâmica ativa) dependem de pesquisa
  para confirmar o que vale em 2026. Entra no plano de pesquisa de #3.

### Regras e eventos — implicações técnicas (#5)
- **O regulamento vira um objeto de dados** que a simulação lê: tabela de pontos, compostos de
  pneu disponíveis, fórmula do motor, limites de chassi. Isso confirma a recomendação de #2
  (motor de corrida com regras configuráveis desde o início). Mudar uma regra é trocar dados, sem
  reescrever código.
- **Tipo de motor muda o "perfil" do carro**, não só um número de potência. Um V8 aspirado, por
  exemplo, pode ter mais velocidade final e menos eficiência que um V6 híbrido. Também muda
  confiabilidade e custo de desenvolvimento. O som do motor nas corridas pode acompanhar (P7).
- **Mudança de regra afeta a P&D**: parte das melhorias perde validade, o que liga direto à
  árvore de P&D e ao carro do ano seguinte (#4, P12).
- **Sistema de eventos orientado a dados**: cada evento tem condições, chance, intervalo mínimo
  entre repetições, opções e efeitos. Assim dá para adicionar eventos sem mexer no código e
  testar com semente fixa.
  - **As equipes da IA também sofrem eventos**, para ser justo.
  - Os eventos aparecem pelo sistema de pop-ups de #1.
- **Exigências que surgem daqui**:
  - **piloto reserva** no contrato (para substituir o acidentado);
  - atributo de **moral/estado emocional** dos pilotos, a definir junto com os atributos (#1, #3).
- **Histórico da campanha**: guardar campeões, regras de cada ano e eventos marcantes. Serve aos
  menus (história da equipe, citada em #4) e precisa entrar no formato do save desde o início.

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

### P9 — Estúdio de design: pintura, patrocínio e identidade (#4, liberdade criativa dada pelo usuário)

- **Camadas de pintura**: cor base, faixas, degradês, padrões geométricos, número do carro.
  Cada camada pode ser movida, girada, espelhada e recolorida.
- **Acabamentos de tinta**: brilhante, fosco, metálico, perolado, cromado, fluorescente e
  **carbono exposto**.
- **Zonas de patrocínio com valor**: asa traseira, laterais, bico, halo, asa dianteira, espelhos.
  Cada patrocinador exige uma zona e um tamanho, e paga mais pelas zonas mais visíveis. Assim a
  pintura e a aba de patrocínios ficam ligadas: um carro "limpo e bonito" pode render menos que
  um "cheio de marcas".
- **Pinturas especiais**: até 3 alternativas por temporada (ex.: corrida em casa, comemoração).
  Usá-las gera mídia/fãs.
- **Lançamento do carro**: no início de cada temporada, um evento de apresentação do carro novo.
  Uma pintura ousada ou elegante rende repercussão na mídia, conforme a nota da "crítica".
- **Capacete dos pilotos** com as mesmas ferramentas (opcional, aparece nos perfis).
- **Editor de logo** da equipe criada: formas, símbolos, iniciais, tipografias e cores, com
  modelos prontos para quem não quer perder tempo.
- **Atalho para quem não gosta de editar**: botão "gerar pintura" com combinações automáticas
  a partir das cores da equipe.

### P10 — Origens da equipe criada (#4: caminhos, objetivos e dificuldade)

Ao fundar a equipe, o jogador escolhe uma **origem**. Ela define o começo e o tipo de desafio:

| Origem | Começo | Desafio | Dificuldade / complexidade |
|---|---|---|---|
| **Equipe de garagem** | Pouco dinheiro, fábrica mínima, motor comprado | Crescer devagar; diretoria paciente | Difícil, pouco complexa |
| **Projeto de investidor** | Muito dinheiro, fábrica média | Metas agressivas e pouca paciência: pode ser demitido | Média, pressão alta |
| **Montadora estreante** | Dinheiro alto, **motor próprio** desde o início | P&D de motor completa; a marca exige resultado rápido | Média, **mais complexa** |
| **Resgate de equipe falida** | Estrutura razoável, **dívidas** e pessoal desmotivado | Recuperar finanças e moral antes de pensar em vencer | Difícil, complexa |

Escolhas adicionais na criação:
- **Objetivo de longo prazo**: ser campeão em X temporadas, vencer uma corrida, chegar ao
  top 5, ou "só sobreviver".
- **Nível de detalhe**: Essencial (o diretor técnico decide os detalhes da P&D) ou Avançado
  (o jogador decide tudo). Resolve a tensão entre "bem completo" (#4) e "simples e divertido" (#1).
- **Dificuldade da IA rival**: independente da origem.

### P11 — Mais uma coisa para gerenciar, simples (#4)

**Coletiva de imprensa e redes sociais.** Depois de cada GP, 1 ou 2 perguntas rápidas de
jornalistas, com 3 respostas possíveis (diplomática, confiante, provocadora). Elas afetam a moral
dos pilotos, a base de fãs, a satisfação dos patrocinadores e rivalidades com outras equipes.
Leva menos de 30 segundos e dá personalidade à campanha.

Alternativa, se preferir: **Academia de pilotos** — até 2 jovens de categorias de base que
evoluem com o tempo e podem ser promovidos ou emprestados. Combina com a vontade do usuário de
trazer pilotos de outras categorias.

### P12 — Regras reais da F1 como mecânica de equilíbrio (#4)

- **Teto de gastos**: limite de gasto anual igual para todos. Gastar bem vale mais que ter
  muito dinheiro, e equipes ricas não fogem tanto das pequenas. (Na F1 real, salários de
  pilotos e parte das obras ficam de fora do teto.)
- **Restrição de túnel de vento/simulação**: quem termina melhor no campeonato tem menos tempo
  de pesquisa aerodinâmica no ano seguinte. Isso ajuda quem está atrás, de forma realista.
- **Anos de mudança de regulamento**: de tempos em tempos as regras mudam e parte do
  desenvolvimento "zera". Isso premia quem investiu cedo no carro do ano seguinte.

### P13 — Conselho de Regras com votação e lobby (#5)

- No meio de cada temporada, uma **federação fictícia** apresenta 1 a 3 propostas para o futuro.
  Exemplos: "motores V8 aspirados a partir de 2029", "pontos até o 12º colocado", "pneus de
  dois compostos apenas".
- **Todas as equipes votam**, incluindo as da IA, que votam conforme o próprio interesse: quem
  é forte em motor quer manter a regra de motor. O voto do jogador tem peso fixo, mas ele pode
  **gastar influência para fazer lobby** e convencer equipes indecisas.
- **Antecedência**: regras de pontuação e pneus valem na temporada seguinte; motor e chassi em
  2 temporadas. Dá tempo de planejar a P&D do carro futuro.
- **Mudanças grandes geram "anos de virada"** (P12), em que o grid pode embaralhar. É a melhor
  chance para uma equipe pequena subir.
- Simples na prática: um pop-up com a proposta, quem apoia e quem é contra, e botões
  "a favor / contra / fazer lobby".

### P14 — Eventos inesperados com escolhas (#5, liberdade criativa dada pelo usuário)

Cada evento chega como pop-up, com 2 ou 3 escolhas e consequências. Exemplos:

| Evento | Escolhas do jogador (exemplos) |
|---|---|
| **Piloto acidentado**, fora por 1–4 corridas | Promover o reserva · contratar alguém de outra categoria · antecipar a volta (risco de piorar a lesão) |
| **Piloto em fase emocional difícil** (desempenho e consistência caem) | Contratar psicólogo esportivo (custo) · liberar de compromissos de mídia (patrocinador reclama) · conversa individual (resultado depende da relação com o piloto) |
| **Corrida cancelada** (instabilidade no país-sede, desastre natural) | Calendário menor (menos receita de prêmios para todos) — às vezes surge uma pista substituta |
| **Funcionário-chave recebe proposta de rival** | Contraproposta · deixar sair e promover alguém · cláusula de "jardinagem" (fica parado, sem trabalhar para o rival, por um tempo) |
| **Protesto técnico**: rival questiona a legalidade de uma peça | Retirar a peça (perde desempenho) · defender na federação (risco de punição) |
| **Peças presas na alfândega/logística** antes de um GP | Frete aéreo urgente (caro) · correr com peças antigas |
| **Patrocinador envolvido em escândalo** | Romper (perde dinheiro) · manter (perde influência e fãs) |
| **Briga entre companheiros de equipe** | Definir 1º e 2º piloto · deixar livre (risco de toque na pista) · reunião conjunta |
| **Pane no túnel de vento ou simulador** | Reparo emergencial (caro) · esperar (P&D aerodinâmica fica mais lenta) |
| **Prodígio disponível** de repente numa categoria de base | Contratar para a academia/reserva · ignorar (um rival pode pegar) |
| **Onda de calor ou tempestade no fim de semana** | Ajustar refrigeração (menos ritmo, mais confiabilidade) · arriscar |

Regras para não ficar maçante:
- poucos eventos por temporada e frequência configurável (dúvida 38);
- nenhum evento se repete em seguida;
- eventos negativos e positivos equilibrados.

## Pedidos após testar o APK (2026-11-02)
"o jogo precisa ter som, coloque barulhos de carro de F1 alternados no fundo, com efeitos sonoros da torcida…; poder aproximar
a visão da pista…; bolas coloridas com a cor de cada equipe…; aumente as fontes…; arrastar tela para cima, baixo ou lados…"
→ implementado (ver DECISIONS, "Ajustes de jogabilidade pedidos após testar o APK").

## Análise externa (ChatGPT) trazida pelo usuário — 2026-11-03
Princípio: cada intervenção precisa de benefício, custo e uma situação em que vale a pena; poucos botões, consequências ricas.
- **Classificação**: janela de saída com previsão de tráfego; plano de 1 ou 2 voltas rápidas; pneu novo × usado; objetivo da volta
  (garantir tempo × buscar o limite); vácuo entre companheiros; reagir a volta comprometida (continuar / nova tentativa / box).
- **Corrida**: ordens com objetivo e duração ("atacar por 2 voltas, encerrar se os pneus aquecerem"); escolher batalhas (defender ×
  priorizar ritmo × deixar passar); reagir à parada do rival (cobrir × estender × manter) com previsão de onde volta à pista;
  "preparar ataque" (recupera energia para o próximo ponto bom); acordos entre companheiros; clima com informação imperfeita;
  decisões no safety car e em problemas mecânicos; engenheiro explicando a consequência depois.
- **Anti-cansaço**: avisos agrupados; se o jogador não responder, segue o plano; desacelerar/pausar em momentos importantes
  (opcional); IA com as mesmas informações. Meta de protótipo: 3–5 decisões na classificação e 8–12 numa corrida de 10–15 min.
→ Decidido em 2026-11-03 (ver DECISIONS, "Decisões a partir da análise externa").

## Campanha em 3 categorias (pedido do usuário, 2026-11-04)
> "a partir de agora seria possível começar a campanha pela F3, F2 ou F1, tendo os nomes oficiais dos pilotos, com as logos
> oficiais das equipes também ... sua equipe criada poderia ir evoluindo de categoria ... mesmo que você escolhesse uma equipe real
> pra começar na F2 ou F3, ela poderia ir subindo ... cada categoria teria que ter um limite de equipes ... pra subir uma equipe nova,
> talvez outra tenha que descer ... a campanha terá os 3 campeonatos com os resultados da tabela atual ... uma tabela bem bonitona
> de pilotos e construtores ... inovar no design ... quando um piloto trocar de equipe, mudar o fundo da foto dele"
→ Decidido (ver DECISIONS, "Campanha em 3 categorias"). Fazer DEPOIS de regras técnicas, dinheiro e pessoas e estúdio de design.

## Prompt mestre da campanha (ChatGPT, trazido pelo usuário — 2026-11-04)
Referência: modo carreira do F1 Manager adaptado a sessões curtas no celular. Pontos: (1) ritmo próprio (pós-GP → preparar →
avançar; sede com próximo GP e até 3 assuntos, separando NOTÍCIA de DECISÃO; preparação recomendada); (2) P&D → especificação →
fabricar unidades → instalar por carro → efeito na pista; motor/chassi/aero/confiabilidade com papéis distintos; aero com
compromisso por circuito; poucas melhorias com utilidade clara; (3) fábrica = capacidade, prazo e custo; (4) quatro profissionais
com papéis e efeitos visíveis, sem efeitos duplicados; (5) mercado vivo para jogador e IA, contratos futuros, perfis de equipe,
movimentação em cadeia F1→F2→F3; (6) F1/F2/F3 na mesma carreira; (7) finanças: saldo, compromissos, receitas condicionadas,
patrocínio garantido × por meta, projeção, prêmio pelo resultado oficial; (8) componentes, desgaste, limites e punições, com
preparação automática e confirmação; (9) simplicidade no Android; (10) entregas por ciclos completos com cenários de aceitação.
→ Decidido (ver DECISIONS, "Campanha reestruturada a partir do prompt mestre").

## Peças, P&D e menus (usuário, 2026-11-04)
- "na parte das peças, monte um menu muito mais bonito ... um carro da categoria ... a parte das peças apontará para cada parte
  especifica, clicando nela irá abrir as opções do que fazer com cada peça" (uso e desenvolvimento).
- P&D com ligação direta à qualidade dos funcionários técnicos e à estrutura da fábrica; upgrade nem sempre é bom (a equipe e a
  IA podem errar), deixando a relação de forças dinâmica na temporada.
- Todos os menus: os mais bonitos e interativos possíveis, símbolos em vez de muito texto, criativos e simples.

## Histórico na campanha (usuário, 2026-11-04) — fazer depois dos pedidos atuais
- Nova aba **Histórico** na campanha, com três sub-telas:
  - **Lendas**: estatísticas dos maiores campeões da história da F1 (fotos se possível); pilotos em atividade que se
    aposentarem na campanha entram ali.
  - **Pilotos atuais**: histórico dos pilotos do grid com números até o fim de 2025 (a campanha começa no início de 2026);
    corridas e temporadas da campanha vão somando a esses números.
  - **Campeonatos**: resultado de cada temporada concluída (2026, 2027...), com destaque para os campeões de pilotos e
    de construtores.
- Fotos de pessoas reais: só na pasta local ignorada pelo git (`game/local/`), como já é feito com os pilotos.

## Animação de campeão (usuário, 2026-11-04) — fazer depois dos pedidos atuais
- Animação especial, inovadora e criativa no fim da corrida em que um piloto ou uma equipe garante o título (por
  antecipação ou na última corrida), para dar ênfase e empolgação à conquista. Mockup/storyboard primeiro.
