# Ícones do DomWorld

O jogo usa Material Icons Outlined, em traço consistente e peso visual regular, com arquivos-fonte SVG e um PNG branco transparente em células de 128 × 128 px. A biblioteca vem do repositório oficial [google/material-design-icons](https://github.com/google/material-design-icons), revisão `10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7`, sob Apache License 2.0. Os nomes abaixo seguem os nomes de ícones Google; apelidos do jogo são mantidos no módulo compartilhado.

| Nome no DomWorld | Ícone Google | Uso |
| --- | --- | --- |
| `play` | `play_arrow` | Iniciar partida solo e entrar na fila |
| `matches` | `leaderboard` | Partidas públicas |
| `shop` | `storefront` | Ateliê de Bandeiras e loja |
| `inventory` | `inventory_2` | Inventário e Suprimentos |
| `profile` | `person` | Perfil local |
| `settings` | `settings` | Configurações |
| `globe` | `public` | Mapa e Domínio do Mapa |
| `group` | `groups` | Party e participantes |
| `help` | `help` | Ajuda |
| `schedule` | `schedule` | Tempo da partida |
| `flag` | `flag` | Bandeiras |
| `rank` | `military_tech` | Posição e liderança |
| `shield` | `shield` | Defesa e proteção |
| `attack` | `north_east` | Ataque |
| `wallet` | `account_balance_wallet` | Ouro e saldo |
| `star` | `star_rate` | Estrelas |
| `close` | `close` | Fechar |
| `check` | `check` | Confirmação |
| `info` | `info` | Créditos e informações |
| `map` | `map` | Seletor de mapa |

O atlas gerado está em `assets/domworld/icons/material-icons-outlined.png`, com os SVGs correspondentes em `assets/domworld/icons/svg/`. A ordem e as coordenadas são mantidas em `src/shared/UI/Icons.luau`; `Widgets.Icon` usa o PNG somente quando `Icons.SPRITESHEET_ID` contém um ID numérico. Até esse upload, cada componente mostra o glifo de reserva existente, sem solicitar um asset remoto.

Para regenerar a imagem com Node.js e as dependências locais:

```powershell
cd tools/icons
npm ci
npm run build
```

Não há imagens Google carregadas durante a execução do jogo. O PNG é um artefato de upload que o proprietário da experiência pode enviar à própria conta Roblox depois de revisar a moderação e o direito de uso. O crédito e a licença estão em `NOTICE.md`, `docs/THIRD_PARTY_LICENSES.md` e `LICENSES/Apache-2.0-Material-Design-Icons.txt`.
