# Regras para buscar e creditar ícones

## Fontes recomendadas

Confira a licença do arquivo específico no momento do download e registre a URL exata da página daquele ícone. Uma licença do catálogo não comprova itens enviados por terceiros.

- [Material Symbols](https://developers.google.com/fonts/docs/material_symbols) e [Material Icons](https://github.com/google/material-design-icons): Apache License 2.0; mantenha a licença e avisos aplicáveis.
- [Lucide](https://github.com/lucide-icons/lucide): ISC; o repositório lista uma exceção MIT para ícones derivados de Feather, então confira se o item escolhido está nessa lista.
- [Tabler Icons](https://github.com/tabler/tabler-icons): MIT; preserve o aviso de copyright/licença ao redistribuir.
- [Phosphor Icons](https://github.com/phosphor-icons/core): MIT; preserve o aviso de copyright/licença ao redistribuir.
- [game-icons.net](https://game-icons.net/about.html): CC BY 3.0; exige crédito ao autor original.

## Evite

- Imagens sem licença clara, reuploads e resultados de “Google Imagens”.
- Logos, marcas, personagens ou ícones copiados de outros jogos e serviços.
- Arquivos sem autor ou licença verificáveis.

## Formato e registro

- UI: SVG ou PNG branco com fundo transparente, 128×128 px, um símbolo centralizado com margem uniforme.
- `game_icon`: SVG/PNG quadrado original, alvo 512×512; é arquivo separado do atlas para o Creator Dashboard.
- Use o ID de `ICONS_NEEDED.md` como nome-base, por exemplo `attack.svg`.
- Preencha arquivo, URL, autor, licença e crédito exigido em `ICON_CREDITS.md`. Para CC BY, registre a frase de atribuição e mantenha-a nos créditos do projeto.
- O código não baixa nada da internet durante o jogo; o tema tinge os símbolos do atlas.
