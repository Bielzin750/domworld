# Decisões técnicas

## Mapa quadriculado magenta/ciano (2026-11-10)

### Evidência e causa raiz

A imagem anexada mostra a partida na seleção de local: o tooltip informa terreno e vizinhos, mas a
superfície inteira é o padrão de textura quebrada. Reproduzi o problema no Studio local antes da
correção; o Output informou `EditableImage is not accessible` e também registrou a falha em
`MapView.surface.step`.

Antes da correção, `src/client/Map/MapSurface.luau` associava o `EditableImage` ao `ImageLabel` logo
após criá-lo. A primeira escrita de pixels ocorria depois, em `MapSurface.step`, e uma falha era
capturada pelo `guard` de `src/client/Map/MapView.luau`, que apenas avisava no Output. O rótulo que
já continha a imagem inválida continuava visível. A experiência podia, portanto, exibir a textura
quadriculada mesmo com os dados do mapa disponíveis.

H2 é a causa confirmada: o Roblox bloqueou a API `EditableImage` nesta configuração do Studio. A
documentação do Roblox explica que a API depende de permissão da experiência em jogos publicados e
que a criação também pode falhar pelo orçamento de memória do dispositivo. Fonte consultada:
[EditableImage — Roblox Creator Hub](https://create.roblox.com/docs/reference/engine/classes/EditableImage).

### Hipóteses avaliadas

- **H1 — remoção de assets/IDs em `081a016`: descartada como causa da superfície-base.** O commit
  removeu arte e referências de assets, inclusive elementos de overlays, mas não alterou
  `src/client/Map/MapSurface.luau`. `docs/ASSET_MAP.md` registra que o mapa de runtime continua a
  ser renderizado por código; os bytes do terreno são convertidos em cores no cliente.
- **H2 — permissão de `EditableImage`: confirmada.** O Output do Studio contém a mensagem de API
  inacessível; o código anterior só descobria a falha na escrita, já depois de exibir o rótulo.
- **H3 — regressão de UI (`Theme`, escala, cor, transparência, ZIndex): sem evidência.** A inspeção
  do histórico recente de `MapSurface.luau` não encontrou mudança correspondente nas propriedades
  visuais da imagem. O último commit que mostrava corretamente o mapa não pôde ser identificado:
  não há captura versionada nem registro visual associado a um commit.
- **H4 — dados inválidos: descartada como explicação para esta reprodução.** A tela já apresentava
  tooltip de terreno e vizinhança; o teste existente `map2d_render` cobre as cores do terreno. O
  caminho de terreno aloca `W * H * 4` bytes e gera cores RGBA por `terrain_pixel`.

### Decisão

Antes de criar ou exibir a imagem, testar criação, escrita e associação ao `ImageLabel` dentro de
`pcall`. Em caso de falha, gerar uma superfície de `Frame`s limitada a 2.048 células, que usa o mesmo
buffer composto e mantém a câmera, os tooltips e a interação existentes. Se ambos os caminhos
falharem, remover os visuais inválidos, mostrar fundo neutro, registrar a causa no Output e avisar
pela interface. Nenhuma mecânica ou dado persistido muda. A grade é de menor resolução que o
renderizador `EditableImage`; ela é um caminho de compatibilidade, não substitui o modo detalhado
quando a API está disponível.

## Avatares, equipe administrativa e moedas (2026-11-07)

### Avatares

`git grep` no pai de `d4c19e8` encontrou `Cosmetics.face_image` em `NameLayer`, `Leaderboard` e
`SpawnOverlay`; o commit `d4c19e8` retirou esses head shots junto dos IDs não verificados. O mapa e o
placar passaram a mostrar só iniciais; a faixa de entrada também perdeu a imagem. Os bots ainda recebiam
UserIds de terceiros por `BotFaces.luau`. A correção monta a URL oficial `rbxthumb` com o UserId do
próprio participante, mantém a inicial durante e após falhas de carregamento, e gera avatares de bots
com cor de Theme e iniciais. `tests/avatar_view.luau` e `tests/arsenal_match.luau` cobrem a escolha e a
ausência de IDs reais nos bots.

### Equipe e painel

A reprodução no Studio mostrou o botão visível `ADMIN F10`; o cliente já esperava confirmação por
`Admin.GetState`, mas o painel criava o botão e incluía o texto no título. A decisão é manter a criação
somente após `state.ok == true`, remover todos os controles/textos chamativos e abrir pelo atalho
configurado que o servidor devolve. A autorização é dividida entre Owner, admins estáticos, roster
persistido e testers locais do Studio; o roster dinâmico é alterável só pelo Owner e limitado a 20.
O ID `33980672` já constava na configuração anterior; permanece em `OwnerUserIds` como candidato até o
proprietário confirmar que é a conta correta.

### Moedas

Reprodução no Studio, place não publicado: a chamada `stars/add/1000` terminou com sucesso e o painel
mostrou saldo `1000 Stars`; o Output dizia `[Purchases] no DataStore here (an unpublished place):
purchases are kept for this session only`. A interface dizia `Balance updated` e não avisava que o
saldo seria perdido. A causa raiz foi o fallback em memória de `ServerMain` parecer uma escrita
persistente para `Purchases.admin_stars` e a resposta de `AdminService` não transportar o estado de
persistência. Agora o carregamento detecta falha de API no Studio, usa a mesma sessão em memória,
devolve `session_only`, atualiza `OP.INVENTORY` e expõe a mensagem “Sem acesso ao DataStore: alteração
válida só nesta sessão”. Em produção, falha de escrita continua sendo erro explícito.

O código anterior também oferecia apenas `set_gold`; não havia add/remove nem atalhos e o saldo não era
devolvido na resposta. A causa é a ação limitada a set nos três pontos do caminho (UI, `AdminService` e
`MatchServer`). Agora add/remove/set têm limite, retorno do saldo e resync de snapshot, então o HUD e a
loja recebem o novo estado da partida. `tests/admin_currency.luau` cobre a rota de moedas; `tests/admin_match.luau`
cobre o caminho autoritativo e o resync do MatchServer.

### Ícones

A busca na UI encontrou 50 nomes de fallback em `ICON_GLYPHS`, os aliases e nomes legados do módulo e
as ações que chegam dinamicamente de `UIRules`, `Defs` e `Arsenal`. O inventário registra 75 IDs visuais
únicos, incluindo o ícone separado da experiência Roblox. A decisão é manter um slot estável por ID e
retornar `nil` quando o mapa gerado marca um arquivo ausente; isso conserva o fallback de texto/forma e
evita uma requisição quebrada. O PNG do atlas é produzido com biblioteca padrão e o CairoSVG é opcional
somente para entrada SVG. A imagem quadrada da experiência é gerada em arquivo separado, pois não é
consumida pelo runtime do jogo. Nenhum ícone foi baixado, enviado ou creditado nesta revisão.

A primeira execução dos testes Luau encontrou `script.Parent` indisponível no carregador Lune (`attempt to
index nil with 'Parent'`). `Icons` agora carrega o mesmo mapa via ModuleScript no Roblox e por caminho
relativo no Lune; `tests/icons.luau` verifica que a ausência do atlas mantém o fallback sem erro.

Ao remover um membro da equipe por UserId, a listagem persistida já fornece o nome e dispensa uma
consulta externa ao Roblox; a consulta de nome para UserId continua obrigatória quando o dono adiciona
uma pessoa pelo ID e a resolução inversa continua protegida por `pcall`.

## 2026-11-07 — Porcentagem de tropas

A fórmula antiga limitava a porcentagem escolhida pela reserva de tropas dos primeiros jogos:

```text
porcentagemEfetiva = min(porcentagemSelecionada, (tropasAtuais - reserva * capacidade) / tropasAtuais)
tropasEnviadas = floor(tropasAtuais * porcentagemEfetiva)
```

Essa reserva usava uma parte da **capacidade máxima** do exército e podia reduzir o resultado sem
mudar o `75%` que aparecia no seletor. Com 268.000 tropas, 75% deveria mostrar e enviar 201.000; a
reserva antiga reduzia a parcela disponível e podia resultar em 124.000.

Ataques terrestres e invasões por transporte agora usam `TroopMath.compute_send` tanto na prévia
quanto na autoridade do servidor:

```text
tropasEnviadas = clamp(floor(tropasAtuais * porcentagem / 100), 1, floor(tropasAtuais))
```

Com 0 tropas, o resultado é 0. O servidor aceita apenas porcentagens inteiras de 1 a 100 e calcula
as tropas com o estado atual da partida; o cliente não fornece a quantidade final. O antigo piso
automático dos cinco primeiros jogos foi removido porque contradizia a porcentagem exibida. O
limite de até 50% da barra durante o tutorial continua ensinando o ritmo dos ataques.

Reforços continuam usando a regra própria de até 20% da capacidade e não passam pelo seletor de
porcentagem. Navios de guerra também não enviam tropas; suas ordens de movimento e combate seguem
inalteradas. Transportes humanos usavam a mesma reserva antiga e agora recebem a porcentagem inteira
selecionada; transporte e chegada continuam usando o número de tropas já embarcado.

## Falso positivo histórico do `secret-scan`

`secret-scan --history` confirma a entrada já registrada em `.secret-scan-allow`: o teste determinístico
`services/lobbies/test/server.test.ts:10` no commit `9cf30dc3d496700f1e1c403da0e13009fb790cfc` foi
classificado como atribuição genérica de segredo (`SECR...ef\"`). O fixture foi substituído por um
placeholder nesse commit e não é carregado pelo serviço de produção. A allowlist exige a justificativa,
o caminho, a linha, a regra, a forma mascarada e o hash exatos; o scan atual da árvore de trabalho segue
sem achados.
# Painel de administração — histórico anterior às alterações atuais (2026-11-07)

- A autorização antiga aceitava o dono da experiência e cargos altos no grupo. A revisão de 2026-11-07 substituiu a allowlist plana pelos papéis `OwnerUserIds`, `AdminUserIds` e roster em `AdminRoster`; a regra de tester do Studio ficou configurável.
- Os dois remotes `DomWorldNet.Admin.GetState` e `DomWorldNet.Admin.Action` passam primeiro por `AdminAuth` no servidor. Ações usam limite compartilhado de 20 chamadas por 10 segundos por jogador, validações tipadas e de estado, limites de valores e log em memória + Output.
- A conta Admin agora consulta o perfil persistido e altera Stars, itens de `Cosmetics`, desbloqueios de `Arsenal` e créditos consumíveis de `Products`. As escritas usam `UpdateAsync`, exigem perfil carregado e os limites documentados em `docs/ADMIN.md`.
- O motor suporta mutações multiplayer de tropas, ouro, posse de tile, eliminação, bots na fase de entrada, pausa e velocidade. A simulação solo roda no cliente, por isso não se expõe ao servidor administrativo.
- O reset de progressão guarda o registro anterior no campo `admin_backup` via `UpdateAsync`; mantém recibos e o marcador `paid` para preservar a idempotência de compras. Preferências e estatísticas ficam no DataStore separado e não são apagadas. A reinicialização de partida, fim forçado e alteração do relógio continuam fora até existir uma operação de motor com semântica de encerramento segura.
- Auditoria persistente em DataStore ficou fora; o log tem até 100 ações por sessão e cada tentativa é enviada ao Output do servidor. Isso evita criar retenção de dados de administrador sem necessidade operacional definida.
- O aviso de diagnóstico da renderização territorial deixou de consultar cargo de grupo no cliente. Ele usa o atributo `AF_Admin` que o servidor só define a partir de `AdminConfig`.

## Revisão da fixture de doação sem tropas (2026-11-07)

O teste original de `tests/gameplayfixer_ui.luau` dizia “No troops of my own”, mas carregava 100.000 tropas para o jogador e forçava diretamente `ctx.ratio = 0.0`. No histórico anterior à correção de porcentagem (`git show 06ede42^:src/client/UI/UICtx.luau`), `troops_for_ratio` multiplicava o total por `order_ratio`, então esse estado inválido produzia zero e a UI recusava a doação. A regra nova aceita porcentagens inteiras de 1 a 100, não tem stop de 0% (`UICtx.RATIO_STOPS` começa em 10%) e exige no mínimo 1 tropa quando o total é positivo; por isso 0% não é um envio válido a preservar.

O commit `76d24f5` ajustou a fixture para que o jogador realmente tenha zero tropas. Isso mantém a intenção descrita pelo teste: sem tropas próprias, a doação é recusada com “No troops to spare”. O caso positivo de 1 tropa e 10% resulta em 1; 100% envia o total. `tests/troop_math.luau` cobre esses limites e `tests/gameplayfixer_ui.luau` confirma a recusa com zero tropas. A doação continua calculando a prévia com a função compartilhada e limitando o total à capacidade livre do aliado; o remote continua recebendo uma quantidade absoluta, validada pela simulação, não uma porcentagem.

## Campos persistidos para a conta Admin (2026-11-07)

O perfil de compras em `src/server/Purchases.luau` (`DomWorldPurchases_v1`, chave `u<UserId>`) mantém
`stars`, `stars_earned`, `credits`, `owned`, `equipped`, `crates_bought`, `unlocks`, recibos e
marcadores de compras/tutorial/ofertas. A aba Conta edita Stars e o inventário já usado por `Purchases`:
cosméticos e bandeiras registrados em `Cosmetics`, desbloqueios em `Arsenal` e créditos consumíveis
catalogados em `Products` (incluindo caixas). Não foi criada uma moeda ou item sem entrada no catálogo.

Stars é a única moeda persistida no perfil de compras. Ouro é guardado em `Sim.o_gold` apenas na partida;
as buscas nos campos de `Purchases` e `SettingsStore` não encontraram saldo de gemas, nível ou XP.
`SettingsStore` salva preferências e contagem de partidas, não progressão de nível. Evidência reproduzível:

```text
rg -n 'Purchases\.STORE|STORE_NAME|stars =|stars_earned|credits =|gold|gem|level|xp|experience|Analytics\.STATS|"matches"' src/server/Purchases.luau src/server/SettingsStore.luau src/server/MatchServer.luau src/shared/Core/Sim.luau src/server/Analytics.luau src/shared/Data/Products.luau
```

O reset requer duas confirmações no cliente e no serviço, grava o registro anterior em `admin_backup`
na mesma chave via `UpdateAsync`, e limpa a progressão e o inventário. `receipts` e `paid` ficam
preservados para não reprocessar compras Roblox; cosméticos exclusivos continuam associados ao dono.
Revogar um item exclusivo usa o campo persistido `admin_revoked`, impedindo que a limpeza normal do
perfil o conceda novamente. O backup anterior é substituído pelo mais recente. Preferências e
estatísticas do `DomWorldSettings_v1` ficam preservadas porque não fazem parte do perfil de compras.
