# Adicionar ícones ao DomWorld

1. Escolha os arquivos usando `docs/ICONS_NEEDED.md` e `docs/ICON_SOURCING_RULES.md`.
2. Solte `<id>.svg` ou `<id>.png` em `ativos/domworld/icones/entrada/` e preencha a linha em `docs/ICON_CREDITS.md`.
3. Na raiz, rode `python tools/build_icon_sheet.py`. O script valida créditos, converte SVG, gera `build/DomWorld-Icons.png` e atualiza `src/shared/UI/IconSpriteMap.luau`. Sem entradas, ele gera o atlas transparente e os slots indisponíveis.
4. Envie o atlas pelo Asset Manager na conta/grupo DomWorld. O `game_icon` gera também `build/DomWorld-Game-Icon.png` separado para o Creator Dashboard.
5. Cole o ID numérico do spritesheet em `Icons.SPRITESHEET_ID` em `src/shared/UI/Icons.luau`, registre em `docs/OWN_ASSET_IDS.txt` e confira no Studio.

PNG é processado com a biblioteca padrão. Para SVG, instale CairoSVG opcionalmente com `python -m pip install cairosvg`; essa instalação não altera as dependências do repositório. Sem CairoSVG, PNG continua funcionando e o script explica a instalação necessária ao encontrar SVG.

O atlas usa células 128×128, oito colunas e ordem estável conforme `ICONS_NEEDED.md`. Veja `docs/icon_slots.html` para uma folha de contato; ela exibe o fallback atual, pois as imagens finais ainda não foram escolhidas.
