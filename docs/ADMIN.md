# Painel de administrador

O painel usa autorização do servidor. Em produção, somente `UserIds` preenchidos em [AdminConfig.luau](../src/server/AdminConfig.luau) podem abrir o painel e chamar as operações `DomWorldNet.Admin`. A lista começa vazia. Em testes pelo Studio, qualquer jogador da sessão é admin.

Para habilitar um administrador, adicione o UserId numérico à lista `UserIds` e publique o código no place correto. Cargo de grupo, nome de usuário, atributo local e visibilidade do painel não concedem acesso. Os remotes validam autorização antes dos argumentos e registram tentativas recusadas.

## Ações disponíveis

| Aba | Ações | Limites e condições |
| --- | --- | --- |
| Conta | Consultar jogadores conectados; adicionar, remover ou definir Stars | O perfil do alvo precisa estar carregado e o alvo precisa estar neste servidor. Ajuste aditivo limitado a 1.000.000 por operação; saldo entre 0 e 1.000.000.000. Remoção e definição exigem confirmação dupla. A alteração usa `UpdateAsync` e preserva Stars vitalícias ganhas. |
| Mapa | Definir tropas e ouro; atribuir ou retirar posse de um tile; focar a câmera; eliminar um jogador; adicionar/remover bot | Exige partida multiplayer ativa. Tropas e ouro limitados a 1.000.000.000. O tile precisa ser terra contestável e o controlador precisa estar ativo. Adicionar bot só é permitido na fase de entrada; remover bot e eliminar jogador exigem confirmação na interface. |
| Partida | Pausar, retomar e alterar velocidade | Exige partida multiplayer ativa. Velocidade de 0,5× a 5×. |
| Registro | Consultar ações da sessão | Até 100 registros em memória; ações e recusas também aparecem no Output do servidor. |

## Limitações atuais

- A partida solo é simulada no cliente e não aceita mutações do painel do servidor.
- A aba Conta só edita Stars. Este projeto não tem nível/XP persistentes; inventário e cosméticos não são alterados pelo painel.
- Alvos de conta precisam estar conectados ao mesmo servidor; não há edição offline de perfis.
- Reset de conta, remoção de itens, reinício de partida, alteração do relógio, fim forçado, concessão automática de bots durante a fase de jogo e revelação global do mapa não estão implementados. Eles não são anunciados como ações disponíveis.
- O registro persistente em DataStore foi deixado de fora: guardar nomes e identificadores administrativos exige política de retenção e armazenamento adicionais. A auditoria atual cobre a sessão e o Output do servidor.
- A câmera do mapa e a leitura de coordenadas de tile são locais. O jogo não tem seleção geográfica de tiles no painel; use o ID de tile já conhecido.

As telas de confirmação são aplicadas a remoções/definições de Stars, eliminações e remoções de bot. Na aba Registro, o botão seleciona o texto para copiar com Ctrl+C; a interface do jogo não grava diretamente na área de transferência. Autorização, limites, estado da partida e persistência continuam sendo verificados no servidor em toda chamada.
