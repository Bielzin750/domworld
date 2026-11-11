# Configuração do DomWorld

## 1. Criar a experiência Roblox

1. Crie uma nova experiência na sua conta Roblox e dê a ela o nome DomWorld.
2. Anote seu `YOUR_UNIVERSE_ID` e `YOUR_PLACE_ID`; não use IDs da experiência original.
3. Configure a experiência para permitir HTTP se for usar o serviço de lobbies. Publique inicialmente pelo Roblox Studio usando sua própria conta.
4. Envie assets originais pela conta DomWorld e substitua placeholders somente depois de registrar os IDs próprios em `docs/OWN_ASSET_IDS.txt` e `docs/ASSET_MAP.md`.

## 2. Rojo e Roblox Studio

Instale Roblox Studio, Rojo, Selene, StyLua e Lune. Na raiz do projeto:

```powershell
rojo build default.project.json -o build/DomWorld.rbxl
rojo build release.project.json -o build/DomWorld-release.rbxl
```

Abra o arquivo gerado no Roblox Studio. Para sincronização interativa, use o plugin Rojo e conecte-o ao projeto local. Os IDs do universo e place não são necessários para compilar.

Para sincronização em tempo real, em outro PowerShell na raiz do projeto rode:

```powershell
rojo serve default.project.json
```

No Roblox Studio, abra o plugin Rojo, escolha **Connect** e use `localhost:34872`. Depois pressione **Play**. O modo **Solo Easy** funciona localmente sem IDs de universo/place e sem o serviço de lobbies.

Para preparar a build de produção pelo publicador incluído, configure localmente
`build/publish.json` com `{"universe": 0, "place": 0}` (substitua os zeros pelos IDs da experiência
DomWorld) e salve a chave Open Cloud em `.secrets/roblox_api_key`. A chave precisa de
`universe-places:write`; `--meta` também requer `universe:write`. Ambos os caminhos são ignorados pelo
Git. Primeiro valide a build sem publicar:

```powershell
python tools/publish.py --build-only
```

Quando os IDs e a chave estiverem configurados, `python tools/publish.py` envia uma versão publicada;
`python tools/publish.py --saved` envia uma versão salva sem torná-la live. Não passe a chave na linha
de comando nem a inclua no repositório.

## 3. Serviço de lobbies local

Requisitos: Node.js 20 ou superior.

```powershell
Set-Location services/lobbies
npm ci
Copy-Item ../../.env.example .env
```

Edite `.env` e substitua `RL_SECRET` por um segredo aleatório próprio de pelo menos 32 caracteres. Não compartilhe esse segredo nem o coloque no código Roblox visível ao cliente. Depois rode:

```powershell
npm test
npm run build
npm start
```

O serviço escuta em `HOST` e `PORT` (padrão `0.0.0.0:3002`), valida requisições assinadas com `RL_SECRET`, mantém snapshots em `STATE_FILE` e registros JSONL de partidas/presença. Não usa banco externo.

## 4. Conectar o servidor Roblox ao lobby

Defina `LobbyHttp.BASE_URL` com o endereço HTTPS público do seu serviço, `LobbyHttp.ENABLED = true` e `ServerMain.PROD_UNIVERSE` com seu `YOUR_UNIVERSE_ID`. Crie localmente `src/server/Lobbies/Secret.luau` retornando o mesmo segredo de `RL_SECRET`; esse arquivo já é ignorado pelo Git. Nunca coloque a chave em `ReplicatedStorage`, módulos replicados ou arquivos `.rbxl` compartilháveis. Para testes no Studio, o atributo `AF_LOBBY_URL` no `Workspace` pode substituir o endereço.

## 5. Implantação em produção

Implante o serviço em uma máquina ou plataforma controlada por você, configure as variáveis de `.env.example` no painel seguro da plataforma e ative persistência para `STATE_FILE`, `starts.jsonl`, `presence.jsonl` e `perf.jsonl`. Exponha HTTPS por proxy reverso e encaminhe para a porta configurada. `docs/lobby-service.md` descreve os endpoints, autenticação, arquivos e variáveis. Não há scripts de implantação para hosts externos no repositório.

## 6. Verificações do projeto

```powershell
rojo build default.project.json -o build/DomWorld.rbxl
rojo build release.project.json -o build/DomWorld-release.rbxl
selene --allow-warnings src
stylua --check src
```

Selene ainda reporta avisos antigos do port; `--allow-warnings` retorna 0 somente quando não há erros. Os testes Luau usam Lune (`.bin/lune run tests/<arquivo>.luau`); rode cada arquivo de teste. Os testes do serviço são executados com `npm test` em `services/lobbies/`.
