# Dependências

## Dependências do serviço de lobbies

Versões verificadas no `services/lobbies/package-lock.json`:

| Pacote | Versão | Uso | Licença | Referência |
|---|---:|---|---|---|
| `typescript` | 5.9.3 | Compilar o serviço e os testes | Apache-2.0 | https://www.npmjs.com/package/typescript |
| `@types/node` | 20.19.43 | Tipos de desenvolvimento para Node.js | MIT | https://www.npmjs.com/package/@types/node |
| `undici-types` | 6.21.0 | Tipos usados por `@types/node` | MIT | https://www.npmjs.com/package/undici-types |

Todas estão marcadas como dependências de desenvolvimento no lockfile. Não foram encontrados manifests Wally, Python ou Rust no projeto.

## Ferramentas de desenvolvimento

O projeto usa Rojo para sincronização/build Roblox e Selene, StyLua e Lune para qualidade/testes Luau. Esses executáveis não estão fixados em um manifest neste checkout; consulte [docs/SETUP.md](SETUP.md) para instalação e comandos. Nenhuma dependência nova foi adicionada.
