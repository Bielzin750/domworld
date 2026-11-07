# Serviço de lobbies do DomWorld

O serviço coordena partidas públicas Roblox por HTTP assinado. Ele valida e mantém registros de lobby, reserva/consulta de servidores, leases curtos, estatísticas de início e amostras de presença/desempenho. Se não estiver habilitado, o jogo usa o fluxo local/MemoryStore disponível.

## Configuração

O serviço exige Node.js 20 ou superior. Copie o `.env.example` da raiz para `.env` dentro de `services/lobbies/` e gere seu próprio `RL_SECRET` aleatório com pelo menos 32 caracteres. Os arquivos de estado JSON e JSONL ficam no diretório de execução; não há banco de dados externo.

| Variável | Obrigatória | Uso |
|---|---|---|
| `RL_SECRET` | Sim | Segredo HMAC de requisições; mínimo de 32 caracteres. |
| `RL_SECRET_OLD` | Não | Chave anterior durante rotação. |
| `RL_SECRET_OLD_UNTIL` | Não | Prazo Unix em segundos para aceitar a chave anterior. |
| `PORT` | Não | Porta HTTP; padrão `3002`. |
| `HOST` | Não | Interface de escuta; padrão `0.0.0.0`. |
| `LOBBIES` | Não | `0` desativa o serviço e retorna ao armazenamento interno. |
| `CLOCK_SKEW` | Não | Tolerância de relógio em segundos; padrão `120`. |
| `STATE_FILE` | Não | Snapshot JSON; `off` desativa snapshots. |
| `LOG_LEVEL` | Não | `debug`, `info` ou `warn`. |
| `RL_DIR` | Não | Diretório de execução e persistência; padrão do processo. |
| `STATS_PASSWORD` | Não | Protege as páginas de estatísticas quando habilitadas. |

As chamadas do jogo usam `POST /v1/*` com timestamp, nonce e assinatura HMAC nos cabeçalhos. O serviço confere assinatura, janela de relógio, tamanho e formato dos corpos.

## Endpoints

### Serviço de jogo

- `GET /health` — status reduzido; informações completas só são mostradas a acesso local, autenticado ou assinado.
- `POST /v1/lobbies/list`, `/get`, `/put`, `/cas`, `/take`, `/release` e `/remove` — listar, consultar e alterar lobbies, fazer compare-and-set, obter assentos e liberar partidas.
- `POST /v1/locks/acquire` — obter lock temporário.
- `POST /v1/psid/bind` e `/lookup` — relacionar e localizar servidor reservado.
- `POST /v1/perf` — registrar amostra de desempenho.
- `POST /v1/status` — consultar estado e métricas do serviço.

### Estatísticas

- `GET /` redireciona para `/stats`.
- `GET /login` e `POST /login`; `GET /logout`.
- `GET /stats` — página; `GET /stats.json` ou `/stats/stats.json` — dados agregados; `GET /stats/events` ou `/stats.events` — eventos recentes. Exigem login.

## Execução local

Na pasta `services/lobbies/`, rode `npm ci`, `npm test`, `npm run build` e `npm start`. Por padrão, o serviço escuta em `0.0.0.0:3002`. Para implantação, use uma máquina ou plataforma controlada pelo proprietário, configure as variáveis no cofre de segredos do provedor, mantenha volume persistente para os arquivos JSON/JSONL e exponha HTTPS por proxy reverso. O repositório não contém endpoint de produção nem script que acesse um host externo.

## Conectar a experiência Roblox

1. Configure `LobbyHttp.BASE_URL` em `src/server/Lobbies/LobbyHttp.luau` com o endereço HTTPS do seu serviço e habilite `LobbyHttp.ENABLED`.
2. Configure `ServerMain.PROD_UNIVERSE` em `src/server/ServerMain.luau` com o universe ID da experiência DomWorld.
3. Crie localmente `src/server/Lobbies/Secret.luau` retornando a chave HMAC do serviço. Esse arquivo é ignorado pelo Git; nunca o coloque em `ReplicatedStorage`.
4. Se preferir testar com outro endereço no Studio, defina o atributo `AF_LOBBY_URL` no `Workspace`.

## Persistência

O serviço mantém `state.json`, `starts.jsonl`, `presence.jsonl` e `perf.jsonl` no diretório configurado. Para preservar dados entre reinícios, monte armazenamento persistente. O jogo também usa DataStores Roblox próprios, com namespaces DomWorld separados dos nomes da experiência de origem.
