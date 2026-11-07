# DomWorld — instruções para agentes

## Projeto

DomWorld é um jogo Roblox de estratégia territorial em tempo real. A stack é Luau + Rojo, um serviço de lobbies TypeScript/Node e testes Luau/Node. Mantenha a estrutura atual `src/shared`, `src/server`, `src/client`, `services/lobbies` e `tests`.

## Commands

- Build de desenvolvimento: `.bin/rojo/rojo.exe build default.project.json -o build/DomWorld.rbxl`
- Build de release: `.bin/rojo/rojo.exe build release.project.json -o build/DomWorld-release.rbxl`
- Lint Luau: `.bin/selene/selene.exe --allow-warnings src` (warnings antigos são exibidos)
- Formatação Luau: `.bin/stylua/stylua.exe --check src`; correção local: `.bin/stylua/stylua.exe src`
- Testes Luau: `.bin/lune/lune.exe run tests/<arquivo>.luau` para cada teste aplicável
- Serviço lobby: em `services/lobbies/`, `npm ci`, `npm test`, `npm run build`, `npm start`

## Regras de licença e segurança

- Preserve `LICENSE` byte a byte e mantenha `© OpenFront and Contributors` visível no menu ou carregamento.
- Use DomWorld como nome do jogo; RoWorld e OpenFront só aparecem em crédito, atribuição ou textos legais.
- Nunca commite `.env`, chaves, cookies, tokens ou credenciais. Use `.env.example` sem valores reais.
- Não use assets de terceiros nem IDs Roblox sem comprovação de que pertencem à conta DomWorld.
- Não acesse nem reutilize serviços, IDs, bancos de dados ou endpoints da experiência de origem.
- O cliente envia intenções; o servidor valida estado, ownership, limites e cooldowns antes de qualquer ação.
- Leia `.agents/skills/roblox-luau-rojo/references/security.md` antes de alterar remotes, compras ou persistência.

## Convenções

- Preserve cabeçalhos e anotações de licença existentes. Em mudanças relevantes, acrescente `-- Modified for DomWorld, 2026 — see git history for details.`
- Use `--!strict` onde já estiver ativo; mantenha validação server-authoritative e nomes de remotes consistentes.
- Identificadores novos usam PascalCase para módulos/tipos, camelCase para variáveis e `DOMWORLD_` para constantes globais.
- Commits seguem Conventional Commits, por exemplo `chore(rename): aplica marca DomWorld` e `docs(license): adiciona avisos de atribuição`.

## Skills

- `license-audit`: antes de publicar, alterar créditos/licenças ou revisar conformidade.
- `asset-audit`: depois de substituir arte/áudio ou ao revisar IDs Roblox.
- `secret-scan`: antes de commit/push/release e após mexer em configuração ou serviço.
- `roblox-luau-rojo`: ao editar Luau, projetos Rojo, remotes, persistência ou lobby.
- `release`: somente quando o usuário pedir explicitamente uma release, tag ou publicação.

