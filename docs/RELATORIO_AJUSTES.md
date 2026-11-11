# Relatório de ajustes — DomWorld

## Estado das quatro tarefas

| Tarefa | Estado | Evidência e limite da verificação |
|---|---|---|
| 1. Avatares | ⚠️ Feito, visual não verificado no Studio | Retrato real via `AvatarHeadShot`, cache/fallback com iniciais para indisponibilidade e marca procedural para bots; usos mapeados em `docs/AVATARS.md`. Suite Luau completa: 94 arquivos passaram; builds Rojo dev e release passaram. A nova árvore de código não foi aberta em Play no Studio, então a apresentação real dos retratos está **NÃO VERIFICADO**. |
| 2. Admin oculto | ⚠️ Feito, visual não verificado no Studio | Autorização e papéis no servidor, roster persistido, gestão de equipe exclusiva do Owner e abertura por atalho sem botão visível. Suite Luau: 94 arquivos passaram. A interface e permissões da nova árvore ainda não foram exercitadas em uma sessão Studio; esse comportamento visual fica **NÃO VERIFICADO**. `OwnerUserIds` ainda precisa de confirmação do titular. |
| 3. Ícones | ⚠️ Fluxo implementado; assets reais pendentes | Inventário, regras de origem/crédito, créditos em branco, pasta de entrada, mapa de sprites e folha HTML criados. O gerador passou com entrada vazia e PNG de exemplo; `asset-audit` passou e a busca de `Icons.get` cobriu definição e consumidores. A folha de contato está em HTML e fica **NÃO VERIFICADO VISUALMENTE**; nenhum ícone foi enviado ao Roblox. |
| 4. Moedas admin | ⚠️ Código e teste ponta a ponta feitos; persistência real não verificada | Correções para Stars e Gold, adicionar/remover/definir, atalhos, atualização da interface e aviso de fallback em memória. Testes cliente→remote→servidor→dados→resposta passaram dentro da suite Luau (94 arquivos). A gravação e recarga reais no DataStore Roblox após a correção estão **NÃO VERIFICADO**. |

## Causa raiz da Tarefa 4

Na reprodução anterior à correção, Stars aceitava a mudança, mas o DataStore não estava disponível na sessão Studio não publicada. O servidor usava o fallback em memória; a resposta tratava esse caso como sucesso persistido e o painel mostrava “Balance updated” sem o aviso de que o saldo valia só durante a sessão. Para Gold, o caminho administrativo não oferecia o mesmo conjunto de operações: faltavam adicionar, remover, atalhos e confirmação/resincronização consistente do saldo. A correção preserva validação, autorização, limite, auditoria, `UpdateAsync` com retry e `pcall`, e informa claramente quando o fallback está ativo.

## Auditorias, builds e testes

| Verificação | Resultado |
|---|---|
| `license-audit` | Exit 0; 19 PASS, 0 falhas. `LICENSE` e `© OpenFront and Contributors` preservados. |
| `asset-audit` | Exit 0; nenhum asset de terceiros detectado. |
| `secret_scan.py --history` | Exit 0; um fixture determinístico histórico consta na allowlist justificada. Nenhum segredo novo detectado. |
| Secret scan da árvore de trabalho e mudanças staged | Exit 0. |
| Rojo dev e release | Ambos os builds terminaram com exit 0. |
| Testes Luau | 94/94 arquivos passaram. |
| Serviço de lobbies | `npm ci` e `npm run build` passaram; `npm test`: 45/45. |
| StyLua | `--check src` passou. |
| Selene | Exit 0; 0 erros e 0 erros de parse, com 42 avisos legados. |

Os testes de `vote_start` foram estabilizados com uma semente determinística no cenário de teste; nenhuma mecânica ou expectativa foi removida. As integrações Roblox que exigem Play, DataStore ativo ou assets enviados não foram declaradas verificadas.

## Commits locais

1. `6d27b9c` — `fix(avatars): restore player portraits and bot marks`
2. `0e1dd9e` — `feat(admin): authorize hidden panel and manage roster`
3. `2977749` — `feat(ui): inventory icons and build sprite atlas`
4. `9ae93d1` — `fix(admin): apply currency adjustments and report persistence`

Desvios de escopo: nenhum. Não houve upload ao Roblox, tag, release, force push ou alteração do `LICENSE`. O arquivo preexistente `docs/RELATORIO_FINAL.md` foi preservado.

## Push

O comando exigido foi tentado sem force:

```text
git push origin main
fatal: User cancelled dialog.
bash: line 1: /dev/tty: No such device or address
error: failed to execute prompt script (exit code 1)
fatal: could not read Username for 'https://github.com': No such file or directory
```

O GitHub plugin confirma acesso ao repositório, mas sua sessão não fornece credencial ao Git CLI. A alternativa SSH também não foi usada: o host ainda não está verificado. `git ls-remote --heads origin main` não encontrou uma branch `main`; portanto, os quatro commits permanecem somente no checkout local e o push está pendente de autenticação Git CLI. Nenhuma tentativa de force push ou reescrita foi feita.

## O que depende de você

- Buscar e soltar os ícones em `ativos/domworld/icones/entrada/`.
- Preencher `docs/ICON_CREDITS.md` com origem, autoria e licença.
- Enviar o spritesheet ao Roblox.
- Confirmar os `OwnerUserIds` em `AdminConfig`.

## Riscos conhecidos

- Em experiência não publicada ou sem “Enable Studio Access to API Services”, mudanças administrativas de moedas são temporárias na sessão e exibem o aviso correspondente.
- Retratos dependem da disponibilidade da miniatura Roblox; falhas usam iniciais como fallback.
- Sem arquivos e créditos dos ícones, a UI continua usando os fallbacks originais.
- O push dos quatro commits não foi publicado porque o Git CLI não obteve autenticação.
