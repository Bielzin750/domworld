# Painel de administrador

O painel usa autorização do servidor. Pessoas sem confirmação do servidor não recebem a interface. Para as pessoas autorizadas, ele abre somente pelo atalho configurado (padrão `F10`); não há botão nem rótulo visível anunciando o painel.

`OwnerUserIds` em [AdminConfig.luau](../src/server/AdminConfig.luau) define o dono em código. O ID atual `33980672` veio da allowlist anterior e ainda precisa ser confirmado antes de publicar. O dono tem todas as permissões e não pode ser removido dentro do jogo. `AdminUserIds` mantém administradores estáticos; o dono pode gerenciar até 20 admins adicionais pela aba **Equipe**, informando nome de usuário ou UserId. A equipe dinâmica fica no DataStore `AdminRoster`; cada linha guarda data e autor da inclusão. Entradas estáticas são alteradas somente no código.

`StudioTestersAreAdmin = true` libera testers locais no Studio como admins comuns. Desative para não expor o painel a todos os colaboradores de uma sessão Team Create. Essa exceção vale somente quando `RunService:IsStudio()` é verdadeiro; servidores publicados sempre usam os IDs configurados e o roster persistido.

Cargo de grupo, nome digitado pelo cliente, atributo local e visibilidade do painel não concedem acesso. Os remotes validam o papel no servidor antes de olhar argumentos, aplicam o limite de 20 chamadas em 10 segundos e registram recusas no log. A aba Equipe só é entregue ao papel Owner.

## Ações disponíveis

| Aba | Ações | Limites e condições |
| --- | --- | --- |
| Conta | Ver perfil persistido; adicionar, remover ou definir Stars; ajustar o ouro da partida ativa; conceder/revogar cosméticos e desbloqueios do Arsenal; adicionar/remover caixas e créditos; resetar progressão | O perfil do alvo precisa estar carregado e conectado a este servidor. Stars e ouro aceitam add/remove/set até 1.000.000.000; atalhos +1K/+1M/+1B. Créditos por tipo: até 1.000. Remoções/definições de saldo têm confirmação visual; reset e alterações de inventário destrutivas também são confirmados no servidor. Escritas persistentes passam por `UpdateAsync`, `pcall` e `DsGate`, com retry. |
| Mapa | Definir tropas; adicionar, remover ou definir ouro; atribuir/retirar posse de tile; focar a câmera; eliminar jogador; adicionar/remover bot | Exige partida multiplayer ativa. Tropas e ouro limitados a 1.000.000.000; add/remove/set de ouro atualizam o snapshot da partida. O tile precisa ser terra contestável e o controlador precisa estar ativo. Adicionar bot só é permitido na fase de entrada; remover bot e eliminar jogador exigem confirmação. |
| Partida | Pausar, retomar e alterar velocidade | Exige partida multiplayer ativa. Velocidade de 0,5× a 5×. |
| Registro | Consultar ações da sessão | Até 100 registros em memória; ações e recusas também aparecem no Output do servidor. |
| Equipe | Adicionar/remover admins dinâmicos | Somente Owner; no máximo 20; nomes são resolvidos pelo servidor; alterações usam `UpdateAsync` com retry e entram no log. O dono e IDs estáticos não podem ser removidos pela interface. |

## Conta: dados, limites e restauração

- Stars é a única moeda persistida no perfil de compras. Ouro pertence ao estado de uma partida e o código não mantém saldo persistente de gemas. O projeto não tem campos persistentes de nível ou XP.
- O painel mostra saldo e Stars ganhas, créditos e caixas, cosméticos/equipamentos, desbloqueios do Arsenal, status de compra Roblox, recibos (somente a contagem), estado do tutorial e da oferta inicial. IDs de recibos não são enviados ao cliente.
- Cosméticos, bandeiras da loja e skins elegíveis vêm de `Cosmetics`; desbloqueios vêm de `Arsenal`; caixas e créditos vêm dos tipos consumíveis definidos em `Products`. Exclusivos só aparecem para o usuário a quem pertencem.
- Alvos de conta precisam estar conectados ao mesmo servidor e com o perfil carregado; não há edição offline.
- Stars são persistidas. Ouro pertence à partida multiplayer ativa e não sobrevive ao fim dela. Alterações em ambos atualizam as interfaces conectadas imediatamente.
- Em Studio, habilite **Game Settings → Security → Enable Studio Access to API Services** para persistir Stars e a equipe. Se o serviço não responder, Stars entram em memória e o painel mostra “Sem acesso ao DataStore: alteração válida só nesta sessão”; esse saldo é descartado quando o servidor fecha. A equipe fica somente leitura até o DataStore responder.
- O reset apaga Stars atuais e vitalícias, créditos, cosméticos, equipamentos, desbloqueios, caixas compradas e estados de tutorial/oferta. Itens exclusivos associados ao usuário voltam a ser concedidos pelo catálogo. Recibos e o indicador de compra Roblox são preservados para manter `ProcessReceipt` idempotente; preferências e estatísticas do `DomWorldSettings_v1` não são apagadas.
- Antes do reset, a gravação atômica em `DomWorldPurchases_v1` (ou `DomWorldPurchases_v1_studio`) guarda o registro anterior em `admin_backup = { created_at, data }` na mesma chave `u<UserId>`. O backup anterior é substituído pelo mais recente.

### Restaurar um snapshot manualmente

1. Retire o jogador do servidor e impeça que outra sessão altere o perfil durante a restauração.
2. No DataStore do ambiente correto, localize a chave `u<UserId>` em `DomWorldPurchases_v1` (produção) ou `DomWorldPurchases_v1_studio` (Studio).
3. Copie `admin_backup.data` antes de editar. Esse é o registro salvo imediatamente antes do último reset.
4. Restaure os campos do snapshot ao registro ativo usando uma ferramenta autorizada de DataStore/Studio. Preserve do registro atual os campos `receipts` e `paid`, pois novos recibos podem ter chegado depois do snapshot e precisam continuar idempotentes.
5. Mantenha `admin_backup` até confirmar que o jogador voltou a carregar o inventário e o saldo corretos. Se a ferramenta não permitir editar o DataStore com segurança, não rode um script improvisado em produção.

## Limitações atuais

- A partida solo é simulada no cliente e não aceita mutações do painel do servidor.
- Reinício de partida, alteração do relógio, fim forçado, concessão automática de bots durante a fase de jogo e revelação global do mapa não estão implementados. Eles não são anunciados como ações disponíveis.
- Alvos de conta precisam estar conectados ao mesmo servidor; não há edição offline de perfis.
- O log de ações continua em memória por sessão e no Output do servidor. A lista de equipe persiste separadamente em `AdminRoster`.
- A câmera do mapa e a leitura de coordenadas de tile são locais. O jogo não tem seleção geográfica de tiles no painel; use o ID de tile já conhecido.

As telas de confirmação são aplicadas a remoções/definições de Stars, revogações de itens/créditos, reset da conta, eliminações e remoções de bot. Na aba Registro, o botão seleciona o texto para copiar com Ctrl+C; a interface do jogo não grava diretamente na área de transferência. Autorização, limites, estado da partida e persistência continuam sendo verificados no servidor em toda chamada.
