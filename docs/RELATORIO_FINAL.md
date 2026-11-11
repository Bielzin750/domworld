# Relatório final — DomWorld
Data: 2026-11-07

## 1. Tarefas 1 a 5

| Tarefa | Resultado | Evidência |
| --- | --- | --- |
| 1 — revisão de tropas e secret-scan | ✅ Feita e verificada | git show 76d24f5 -- tests/gameplayfixer_ui.luau: a fixture passou a representar zero tropas reais, e docs/DECISIONS.md registra a comparação histórica. secret_scan.py --history saiu com 0 e aceitou apenas a fixture sintética documentada. Os fluxos de porcentagem estão listados abaixo. |
| 2 — aba Conta do Admin | ✅ Feita e verificada | Commits 63b73e8, 4ac1122 e f488882; docs/ADMIN.md descreve ações, limites, segurança, backup e configuração. Os testes Luau de admin passaram na suíte (admin_account, admin_auth, admin_match, admin_service e purchases). |
| 3 — UserId de produção | ✅ Feita e verificada | A API pública POST https://users.roblox.com/v1/usernames/users retornou uma correspondência exata: **falsity — UserId 33980672**. src/server/AdminConfig.luau contém o ID e o comentário de confirmação pedido. |
| 4 — visual e comparação de layout | ✅ Feita e verificada | Capturas reais do Roblox Studio em docs/screenshots/lobby.png e docs/screenshots/partida.png (1316×553). Commit 7efed22. |
| 5 — push, tag e release | ❌ Não publicado | O pré-requisito da suíte Luau falhou: 88/89 scripts passaram. O teste vote_start.luau terminou com exit 1; o caso esperado era #mid.players > 1, mas o valor observado foi 1. A etapa de publicação foi interrompida como o prompt exige: sem push, tag v0.1.0 ou release. |

### Tarefa 1.3 — fluxo → usa TroopMath.compute_send?

| Fluxo | Usa? | Evidência/comportamento |
| --- | --- | --- |
| Ataque terrestre do jogador | Sim | UICtx.troops_for_ratio, MatchServer.intent e Sim._apply_intent usam a função compartilhada. |
| Transporte por barco do jogador | Sim | A porcentagem é convertida para tropas pela função compartilhada antes de lançar o transporte. |
| Doação para aliado | Sim, para calcular a quantidade desejada | A prévia de doação usa troops_for_ratio; depois limita pelo espaço do aliado e envia uma quantidade absoluta. O servidor limita de novo o valor recebido. |
| Reforço | Não se aplica | Não usa seletor percentual; a regra é fixa em 20% da capacidade. |
| Ataques/barcos da IA | Não | Preservam a regra de reserva própria da IA, sem usar o seletor do jogador. |

Para tropas positivas, compute_send aplica floor(tropas × porcentagem / 100) com limite de 1 até o total; zero tropas produz zero. tests/troop_math.luau cobre zero, uma tropa, porcentagens inválidas e arredondamento de totais grandes.

### Tarefa 4 — elementos comparados com o primeiro commit

Base da comparação: commit inicial 9cf30dc3d496700f1e1c403da0e13009fb790cfc.

| Elemento | Igual ao original antes da tarefa? | Ação |
| --- | --- | --- |
| Party no lobby | Sim; painel desktop ficava no meio da lateral esquerda | Movido para o canto inferior esquerdo e tornado recolhível, com botão MINIMIZAR e acesso compacto para reabrir. |
| Ateliê de Bandeiras | Sim; modal centralizado | Painel encaixado à direita no desktop; continua centralizado em telas compactas. |
| Depósito (Arsenal) | Sim; modal centralizado | Painel encaixado à direita no desktop; continua centralizado em telas compactas. |
| Navegação e composição principal do lobby | Não; a estrutura de barra lateral e conteúdo principal já havia sido alterada antes | Nenhuma alteração adicional nesta tarefa. |
| Medidor de partida, doca de ações e faixa inferior | Não; a estrutura Atlas já diferia do primeiro commit | Nenhuma alteração adicional nesta tarefa. |

## 2. Desvios

Nenhum desvio de escopo. Não foram enviados assets ao Roblox, não houve alteração de mecânicas nesta etapa visual e nenhum histórico foi reescrito.

## 3. Arquivos alterados por tarefa

### Tarefa 1

- Porcentagem compartilhada (commit 06ede42): docs/DECISIONS.md; src/client/Dev/SessionDiag.luau; src/client/UI/Coach.luau, Tutorial.luau, UIAdvisor.luau, UICtx.luau, UIInteract.luau, UIRoot.luau, UIRules.luau; src/server/Dev/SessionDiag.luau, MatchServer.luau; src/shared/Core/Sim.luau, SimNaval.luau, TroopMath.luau; src/shared/Data/Tutorial.luau; src/shared/Net/Protocol.luau; tests/net_fakesim.luau, net_protocol.luau, net_session.luau, polishfix_server_donate.luau, spectate.luau, troop_math.luau, tutorial.luau, uiscreens_logic.luau.
- Fixture de doação e decisão (commits 76d24f5, ec92d9b): tests/gameplayfixer_ui.luau, docs/DECISIONS.md.
- Allowlist mínima (commit ccb92be): .agents/skills/secret-scan/SKILL.md, .agents/skills/secret-scan/scripts/secret_scan.py, .secret-scan-allow, docs/DECISIONS.md.

### Tarefa 2

Commits 63b73e8, 4ac1122, f488882: docs/ADMIN.md, docs/DECISIONS.md; src/client/Main.luau, src/client/UI/AdminPanel.luau, GlobeNotice.luau, UICtx.luau; src/server/AdminAuth.luau, AdminCheck.luau (removido), AdminConfig.luau, AdminService.luau, MatchServer.luau, Purchases.luau, ServerMain.luau; tests/admin_account.luau, admin_auth.luau, admin_check.luau (removido), admin_match.luau, admin_service.luau, purchases.luau.

A conta opera Stars e o inventário já existente. Stars é a única moeda persistente; ouro é da partida, e não foram encontrados saldos persistentes de gemas, nível ou XP. O reset salva snapshot em admin_backup via UpdateAsync, preservando recibos e o marcador paid. Limites e configuração estão em docs/ADMIN.md.

### Tarefa 3

- src/server/AdminConfig.luau

### Tarefa 4

- src/client/UI/Arsenal.luau
- src/client/UI/FlagShop.luau
- src/client/UI/PartyPanel.luau
- docs/screenshots/lobby.png
- docs/screenshots/partida.png

### Tarefa 5

- Nenhum arquivo alterado para publicação. O CHANGELOG.md não recebeu entrada de release porque o pré-requisito falhou.

### Tarefa 6

- docs/RELATORIO_FINAL.md (este relatório; criado após o gate de publicação).

## 4. Resultado de todas as verificações

| Verificação | Resultado observado |
| --- | --- |
| License audit | Exit 0; 19 verificações aprovadas, 0 falhas. |
| Asset audit | Exit 0; PASS: no third-party assets detected. |
| Secret scan da árvore | Exit 0; PASS: no secrets detected. |
| Secret scan do histórico | Exit 0; um falso positivo sintético exatamente allowlisted (services/lobbies/test/server.test.ts:10, commit 9cf30dc3d496700f1e1c403da0e13009fb790cfc, mascarado SECR...ef"); nenhum segredo detectado. |
| Rojo — desenvolvimento | Exit 0; build/DomWorld.rbxl gerado (3.815.955 bytes). |
| Rojo — release | Exit 0; build/DomWorld-release.rbxl gerado (3.732.042 bytes). |
| Lune — testes Luau | Exit 1; 89 scripts: 88 passaram, 1 falhou (tests/vote_start.luau). Falha: a few seconds in, some have joined: 1; vote_start: 1 FAILED. |
| Serviço de lobbies — testes | Exit 0; 45 testes passaram, 0 falharam. |
| Serviço de lobbies — build | Exit 0 (npm run build). |
| Instalação existente do serviço | npm ci instalou 3 pacotes; 0 vulnerabilidades relatadas. |
| StyLua | Exit 0; stylua --check src sem diferenças de formatação. |
| Selene | Exit 0; 0 erros, 42 avisos, 0 erros de parse com --allow-warnings. |
| git diff --check | Exit 0 após a alteração visual. |
| Árvore antes da etapa de publicação | git status --porcelain sem saída; a branch era main. |

O remoto configurado é https://github.com/Bielzin750/domworld.git. Não houve tentativa de push, pois a verificação Luau reprovou antes dessa etapa. O GitHub CLI não foi instalado nem autenticado, pois a sequência de publicação foi interrompida no primeiro pré-requisito.

## 5. Pendências que dependem de você

- Enviar o spritesheet ao Roblox e inserir o ID em docs/ICONS_UPLOAD.md.
- Confirmar o UserId **33980672** de falsity.
- Publicar o place no Roblox e colar o texto de docs/ROBLOX_DESCRIPTION.md.
- Não houve falha de autenticação nesta execução; a etapa de autenticação não foi alcançada.

## 6. Riscos conhecidos

- A release está bloqueada até corrigir ou explicar a falha observada em tests/vote_start.luau e repetir o gate completo.
- O Studio foi executado localmente em uma experiência não publicada; os avisos de fallback de DataStore/MemoryStore significam que a persistência de produção não foi validada.
- O serviço de lobbies foi testado localmente; sua operação em produção não foi verificada.
