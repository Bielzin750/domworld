# Painel de administrador

O painel usa autorização do servidor. Em produção, somente `UserIds` preenchidos em [AdminConfig.luau](../src/server/AdminConfig.luau) podem abrir o painel e chamar as operações `DomWorldNet.Admin`. A lista começa vazia. Em testes pelo Studio, qualquer jogador da sessão é admin.

Para habilitar um administrador, adicione o UserId numérico à lista `UserIds` e publique o código no place correto. Cargo de grupo, nome de usuário, atributo local e visibilidade do painel não concedem acesso. Os remotes validam autorização antes dos argumentos e registram tentativas recusadas.

## Ações disponíveis

| Aba | Ações | Limites e condições |
| --- | --- | --- |
| Conta | Ver perfil persistido; adicionar, remover ou definir Stars; conceder/revogar cosméticos e desbloqueios do Arsenal; adicionar/remover caixas e créditos; resetar progressão | O perfil do alvo precisa estar carregado e conectado a este servidor. Stars: saldo e ajuste até 1.000.000.000; atalhos +1K/+1M/+1B. Créditos por tipo: até 1.000. Remoções, definições e reset exigem confirmação dupla no painel e no servidor. Escritas passam por `UpdateAsync`, `pcall` e pelo `DsGate`, que repete erros de throttling com espera. |
| Mapa | Definir tropas e ouro; atribuir ou retirar posse de um tile; focar a câmera; eliminar um jogador; adicionar/remover bot | Exige partida multiplayer ativa. Tropas e ouro limitados a 1.000.000.000. O tile precisa ser terra contestável e o controlador precisa estar ativo. Adicionar bot só é permitido na fase de entrada; remover bot e eliminar jogador exigem confirmação na interface. |
| Partida | Pausar, retomar e alterar velocidade | Exige partida multiplayer ativa. Velocidade de 0,5× a 5×. |
| Registro | Consultar ações da sessão | Até 100 registros em memória; ações e recusas também aparecem no Output do servidor. |

## Conta: dados, limites e restauração

- Stars é a única moeda persistida no perfil de compras. Ouro pertence ao estado de uma partida e o código não mantém saldo persistente de gemas. O projeto não tem campos persistentes de nível ou XP.
- O painel mostra saldo e Stars ganhas, créditos e caixas, cosméticos/equipamentos, desbloqueios do Arsenal, status de compra Roblox, recibos (somente a contagem), estado do tutorial e da oferta inicial. IDs de recibos não são enviados ao cliente.
- Cosméticos, bandeiras da loja e skins elegíveis vêm de `Cosmetics`; desbloqueios vêm de `Arsenal`; caixas e créditos vêm dos tipos consumíveis definidos em `Products`. Exclusivos só aparecem para o usuário a quem pertencem.
- Alvos de conta precisam estar conectados ao mesmo servidor e com o perfil carregado; não há edição offline.
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
- O registro persistente em DataStore foi deixado de fora: guardar nomes e identificadores administrativos exige política de retenção e armazenamento adicionais. A auditoria atual cobre a sessão e o Output do servidor.
- A câmera do mapa e a leitura de coordenadas de tile são locais. O jogo não tem seleção geográfica de tiles no painel; use o ID de tile já conhecido.

As telas de confirmação são aplicadas a remoções/definições de Stars, revogações de itens/créditos, reset da conta, eliminações e remoções de bot. Na aba Registro, o botão seleciona o texto para copiar com Ctrl+C; a interface do jogo não grava diretamente na área de transferência. Autorização, limites, estado da partida e persistência continuam sendo verificados no servidor em toda chamada.
