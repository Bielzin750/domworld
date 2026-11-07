# Decisões técnicas

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
# Painel de administração (2026-11-07)

- A autorização antiga aceitava o dono da experiência e cargos altos no grupo. O painel novo usa apenas uma allowlist explícita de UserIds em `src/server/AdminConfig.luau`, vazia por padrão; o Studio libera o tester local. Isso evita que uma mudança no dono/grupo conceda poderes automaticamente.
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
