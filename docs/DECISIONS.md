# Decisões do projeto

## 2026-11-06

- Repositório: `https://github.com/Bielzin750/domworld` (proprietário GitHub `Bielzin750`), ano de modificação `2026`, autor nos avisos `Bielzin750`.
- O destino GitHub foi criado como repositório público vazio, não como fork. O histórico original foi buscado e preservado localmente em `main`; não foi possível converter o destino em fork com as ações disponíveis no conector. Esta diferença fica registrada para transparência.
- O `LICENSE` original será preservado byte a byte. As artes novas serão CC BY-SA 4.0, com atribuição DomWorld.
- Toda arte e áudio do checkout de origem será removida do working tree por não haver autorização comprovada para esta cópia, inclusive itens descritos como próprios pelo autor. IDs Roblox antigos serão zerados até serem enviados pela conta DomWorld.
- IDs de produtos, assinatura, place e universe do autor serão zerados/substituídos. As ofertas ficam desativadas até o proprietário configurar IDs próprios.
- Os nomes originais de DataStores serão substituídos por namespaces DomWorld para evitar acesso acidental aos dados da experiência do autor.
- Os nomes internos de pastas e remotes também foram padronizados para DomWorld; as referências do cliente e do servidor foram alteradas juntas, antes de qualquer publicação da experiência.
- Endereços e scripts de deploy do serviço de produção original não serão usados. O serviço TypeScript existente será adaptado para implantação controlada pelo proprietário do DomWorld.
- `.mcp.json` continha apenas um caminho local de Roblox Studio para macOS; foi removido. `.DS_Store` foi removido e passou a ser ignorado.
- O scanner de histórico encontra uma atribuição genérica em `services/lobbies/test/server.test.ts:10`, no commit `9cf30dc3d496700f1e1c403da0e13009fb790cfc`. Era uma chave hexadecimal determinística usada exclusivamente nos testes locais de assinatura HTTP, não uma credencial de produção; a linha foi substituída por um placeholder explícito no commit `15c4f0ae78ffb776439efc8a5ba6027d6ea79d1a`. Como o histórico deve ser preservado, a ocorrência fica autorizada somente pela combinação exata de commit, arquivo, linha, regra e valor mascarado em `.secret-scan-allow`. A allowlist não se aplica ao working tree nem ao conteúdo staged.
- Campos de asset sem titularidade passaram de `rbxassetid://0` para vazio para que o jogo não tente carregar IDs inválidos. A interface essencial usa Frames, gradientes, UIStroke e textos/figuras de Gotham incluída no Roblox; botões de construção e a marca “DW” são desenhados em Luau. A trilha e os efeitos ficam silenciosos enquanto IDs próprios não forem enviados.
