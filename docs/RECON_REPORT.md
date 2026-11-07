# Relatório de reconhecimento — DomWorld

Data: 2026-11-06  
Fonte examinada: `lukechatton/roworld`, branch `main`, commit `ae7a3505e6f3736aef85fffc1879c0476f819c59`.

## Repositório

`https://github.com/Bielzin750/domworld` foi criado como repositório público vazio e comum, não como fork. O checkout local preserva o histórico original: `main` parte do commit acima, `origin` aponta para DomWorld e `upstream` para o projeto de origem. O conector GitHub disponível não expõe ações para converter o repositório em fork ou alterar descrição/tópicos. Nenhum histórico foi reescrito.

## Estrutura inicial

O checkout tinha `assets/` (467 arquivos), `services/lobbies/` (TypeScript), `src/` (Luau), `tests/`, `tools/`, além de `default.project.json`, `release.project.json`, `selene.toml`, `.mcp.json`, `CLAUDE.md`, `README.md`, `LICENSE` e `.gitignore`. Havia um `.DS_Store` rastreado. O projeto inclui cinco skills de desenvolvimento e conformidade em `.agents/skills/`.

Após o inventário, os assets originais foram removidos do working tree, `.mcp.json` e `.DS_Store` foram retirados, e os scripts de deploy/upload ligados ao ambiente antigo foram removidos. O histórico original permanece no git, conforme solicitado.

## Nomes, IDs, domínios e contatos

- A interface e os metadados Rojo identificavam o produto como RoWorld/Rofront/Airfront. A identidade visível, as pastas de scripts e os remotes foram padronizados como DomWorld, com referências correspondentes no cliente, servidor e projetos Rojo.
- A varredura encontrou 274 usos de `rbxassetid://` e 271 IDs únicos em 23 arquivos Luau. Todos eram de titularidade não verificável para DomWorld; foram classificados conservadoramente como categoria (c) e substituídos por `rbxassetid://0`. O inventário por arquivo está em `docs/ASSET_MAP.md`.
- Havia IDs de place/universe, produtos pagos e assinatura em scripts Roblox e dados do jogo. Os valores antigos foram removidos do código ativo: placeholders/zero agora desativam publicação e compras até a conta DomWorld fornecer os próprios IDs.
- O código e scripts antigos continham um endpoint público de lobby, um IP direto de fallback e alvos SSH de produção. Esses valores foram removidos do working tree; nenhum destino foi contatado. A URL ativa agora é um placeholder `YOUR_LOBBY_SERVICE_URL`, e as rotas do lobby ficam desabilitadas até configuração própria.
- Domínios externos observados na inspeção inicial: endpoints Roblox (`apis.roblox.com`, `users.roblox.com`, `thumbnails.roblox.com`), `raw.githubusercontent.com`, `coastwatch.pfeg.noaa.gov`, `registry.npmjs.org`, `github.com`, `localhost`, `127.0.0.1` e `lobbies.invalid`. `evil.example` aparecia somente em teste. Não havia e-mail, webhook com valor, URL com credenciais, cookie Roblox ou chave privada no working tree. Um caminho local para webhook aparecia apenas em instruções antigas, que foram substituídas.

## Assets

Os 467 arquivos locais originais eram 266 SVG, 190 PNG, 6 GLB, 4 JSON e 1 TXT. Incluíam bandeiras, ícones, globo, sprites, modelos, efeitos, branding e áudio. Como as permissões/titularidade não podiam ser confirmadas item a item, todos foram tratados como categoria (c) e removidos. Os novos arquivos em `assets/domworld/` são formas geométricas originais, licenciadas sob CC BY-SA 4.0.

## Dependências

O serviço usa `typescript` 5.9.3 (Apache-2.0), `@types/node` 20.19.43 (MIT) e `undici-types` 6.21.0 (MIT), conforme `services/lobbies/package-lock.json`. Não há manifest Wally. Node/npm estão instalados. Para a validação local, Rojo 7.7.1, Selene 0.32.0, StyLua 2.6.0 e Lune 0.11.1 foram instalados em `.bin/`, pasta ignorada pelo Git; Python 3.13.7 está fora do repositório. Consulte `docs/DEPENDENCIES.md`.

## Serviço e configurações

`services/lobbies/` recebe `POST /v1/*` assinado com HMAC, valida timestamp/nonce e mantém estado de lobbies, reservas, locks, partidas, presença e desempenho em JSON/JSONL. Não usa banco externo. A configuração inclui `RL_SECRET` (mínimo 32 caracteres), rotação opcional, `PORT` (padrão 3002), `HOST`, `LOBBIES`, `CLOCK_SKEW`, `STATE_FILE`, `LOG_LEVEL`, `RL_DIR` e `STATS_PASSWORD`; detalhes e endpoints estão em `docs/lobby-service.md` e `.env.example`.

O `.gitignore` original não cobria `.env`, `*.key`, `secrets/` nem `.DS_Store`; essas regras agora existem, além de arquivos locais de configuração. `.mcp.json` só apontava para um caminho de Roblox Studio em macOS, então foi removido e ignorado.

## Licença e instruções de agente

`LICENSE` contém GNU AGPL v3 e `ADDITIONAL TERMS (AGPL v3 Section 7)`. Os termos exigem manter visível o texto exato `© OpenFront and Contributors`, não usar OpenFront como título principal e não sugerir endosso. `LICENSE` foi preservado byte a byte.

O `CLAUDE.md` original continha instruções operacionais do projeto de origem e caminho local de webhook; agora contém instruções neutras do DomWorld e está sincronizado com `AGENTS.md`. O aviso de copyright permanece no rodapé do menu e a tela Sobre / Licença mostra atribuição, termos, ausência de garantia e URL selecionável do código-fonte.
