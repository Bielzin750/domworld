# Enviar o atlas de ícones ao Roblox

O ID é criado na conta Roblox do proprietário da experiência. O repositório não contém um ID de upload.

1. Gere `assets/domworld/icons/material-icons-outlined.png` seguindo `docs/ICONS.md`.
2. Abra a experiência DomWorld no Roblox Studio conectado à conta ou ao grupo que será titular do jogo.
3. Abra o Asset Manager pelo menu **Window** ou pela aba **Home**.
4. Na categoria **Images**, use **Import** e selecione o PNG. Confirme que o criador indicado é a conta ou grupo do DomWorld.
5. Quando o envio terminar, clique com o botão direito no asset e escolha **Copy Asset ID**. Se o botão não estiver disponível no Asset Manager, use **File → Import**, habilite o envio para o Roblox e copie o ID no asset importado.
6. Substitua `YOUR_SPRITESHEET_ID` em `src/shared/UI/Icons.luau` pelo ID numérico, sem prefixo. O módulo monta `rbxassetid://` e o recorte do sprite.
7. Adicione o ID, uma por linha, a `docs/OWN_ASSET_IDS.txt`; depois rode a auditoria de assets.
8. Abra o jogo em Play e confira ícones do lobby, HUD e painel de créditos. Se o asset estiver aguardando moderação, o fallback textual continua disponível.

O fluxo do Importer e a cópia do ID seguem a [documentação oficial do Roblox Creator Hub](https://create.roblox.com/docs/studio/importer). O Asset Manager importa e armazena imagens da experiência atual, conforme [Asset Manager e ferramentas de assets](https://create.roblox.com/docs/studio/overview#asset-manager).
