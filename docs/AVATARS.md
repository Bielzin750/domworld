# Avatares de jogadores

## Onde são usados

| Tela/local | Estado anterior | Estado atual |
| --- | --- | --- |
| Rótulos de dono no mapa (`src/client/Map/NameLayer.luau`) | A versão anterior mostrava o rosto; a remoção de IDs em `d4c19e8` deixou só a inicial | Rosto `AvatarHeadShot` do próprio UserId, carregado uma vez e reaproveitado; inicial e cor do tema ficam como fallback |
| Placar (`src/client/UI/Leaderboard.luau`) | A versão anterior mostrava o rosto; depois da remoção de IDs só a inicial aparecia | Mesmo rosto do mapa para pessoas; avatar geométrico e inicial para bots |
| Faixa de entrada da partida (`src/client/UI/SpawnOverlay.luau`) | Histórico também mostra a faixa com rostos; estado atual tinha apenas marcas com iniciais | Rosto real restaurado, inicial como fallback e bots gerados por código; preserva o contorno de estado da colocação |
| Painel de ataques, feed, perfil, party e tela de fim | A busca atual e o histórico não encontraram exibição de rosto nesses componentes | Não são pontos de avatar no estado atual; nenhum layout foi alterado |

## Histórico e origem dos dados

Foi feita busca no código atual e no histórico por `GetUserThumbnailAsync`, `rbxthumb`, `AvatarHeadShot`, `Cosmetics.face_image` e ImageLabels. O commit `d4c19e8` removeu os IDs não verificados e o uso de `Cosmetics.face_image` nos três pontos listados. A partida multiplayer ainda envia o UserId de cada participante real por `OP.COSMETICS`.

O cliente monta `rbxthumb://type=AvatarHeadShot&id=<UserId>&w=150&h=150`. O `AvatarView` compartilha o estado de carregamento pelo UserId e tamanho, e deixa o círculo com inicial visível até receber sucesso. Erros de carregamento ficam dentro de `pcall` e mantêm o fallback sem emitir erro no Output.

O histórico do servidor tinha `BotFaces.luau`, que emprestava IDs de usuários reais aos bots. Esse arquivo e a seleção aleatória foram removidos. Bots não recebem nem carregam UserIds; o servidor marca sua entrada como `bot`, e o cliente escolhe cor estável a partir do nome e das cores do Theme, mostra iniciais e conserva a borda na cor do time.

## Verificação

- `tests/avatar_view.luau`: decisão entre rosto real e avatar gerado, chaves de cache e estabilidade da cor.
- `tests/arsenal_match.luau`: bots não recebem IDs nem imagens reais.
- Busca no histórico e no código atual: usos anteriores encontrados somente no mapa, placar e faixa de entrada.
- Carregamento visual final no Roblox Studio: **NÃO VERIFICADO** nesta revisão; requer executar a partida com acesso à rede de thumbnails.
