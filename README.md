# DomWorld

DomWorld é um jogo de estratégia territorial em tempo real para Roblox. Expanda seu território, administre recursos, forme alianças e dispute partidas em mapas compartilhados.

## Aviso de origem

DomWorld é uma obra derivada de RoWorld (Luke Chatton) e do projeto OpenFront, licenciada sob AGPL v3. Não é afiliado nem endossado por eles.

## Como jogar

Escolha uma partida solo ou pública, conquiste territórios próximos, equilibre crescimento e defesa e use estruturas e unidades para disputar o mapa. Alianças ajudam a coordenar a expansão; a vitória depende das regras e do modo da partida.

## Como rodar

1. Instale Roblox Studio, Rojo, Selene, StyLua e Lune.
2. Gere o place localmente com `rojo build default.project.json -o build/DomWorld.rbxl` e abra o arquivo no Studio.
3. Para executar o serviço de lobbies, use Node.js 20 ou superior, copie `.env.example` para `.env`, gere um valor próprio para `RL_SECRET` com pelo menos 32 caracteres e rode `npm ci`, `npm test`, `npm run build` e `npm start` dentro de `services/lobbies/`.
4. Configure no servidor Roblox o endereço HTTPS do seu serviço de lobbies e a chave correspondente em configuração somente de servidor. Nunca coloque a chave em módulos replicados ao cliente.

O passo a passo, inclusive placeholders dos IDs Roblox, está em [docs/SETUP.md](docs/SETUP.md).

## Estrutura do projeto

- `src/shared/`, `src/server/` e `src/client/`: módulos Luau do jogo.
- `services/lobbies/`: serviço TypeScript para salas públicas, presença e estatísticas.
- `tests/`: testes Luau; `services/lobbies/test/`: testes Node.
- `assets/domworld/`: arte original do DomWorld.
- `tools/`: ferramentas de desenvolvimento e geração.
- `.agents/skills/`: auditorias de licença, assets, segredos, desenvolvimento Roblox e release.

## Licença e código-fonte

O código é distribuído sob GNU AGPL v3 junto com os termos adicionais preservados no [LICENSE](LICENSE). Veja também [NOTICE.md](NOTICE.md). O código-fonte está em [github.com/Bielzin750/domworld](https://github.com/Bielzin750/domworld).

## Créditos

DomWorld deriva de [RoWorld, de Luke Chatton](https://github.com/lukechatton/roworld), que por sua vez inclui os termos adicionais relacionados ao OpenFront. O aviso `© OpenFront and Contributors` é mantido conforme esses termos.

## Como contribuir

Contribuições ao código são distribuídas sob AGPL v3, com os termos adicionais do `LICENSE`. Arte nova deve ser original e é distribuída sob Creative Commons BY-SA 4.0, com atribuição a DomWorld.
