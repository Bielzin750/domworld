# Relatório — correção do mapa quadriculado

**Data:** 2026-11-10

**Escopo:** renderização do mapa; sem alterações de mecânica, rede ou dados persistidos.

## Causa raiz

O Studio local exibiu `EditableImage is not accessible` no Output e a falha foi registrada em
`MapView.surface.step`. Antes da correção, `MapSurface` atribuía o `EditableImage` ao `ImageLabel`
antes de testar a escrita de pixels. Quando a primeira chamada a `WritePixelsBuffer` falhava, o
`guard` de `MapView` só registrava o erro e deixava a imagem inválida visível. Isso corresponde ao
quadriculado mostrado na captura, embora a partida já tivesse dados suficientes para preencher o
tooltip de terreno e vizinhança.

O Roblox documenta a permissão da API `EditableImage` para experiências e o limite de memória que
pode impedir sua criação. Ver [EditableImage — Roblox Creator Hub](https://create.roblox.com/docs/reference/engine/classes/EditableImage).

## Hipóteses

- **H1, assets removidos:** descartada como causa da superfície-base. O commit `081a016` removeu
  recursos visuais, inclusive alguns de overlays, mas não alterou `MapSurface`; os pixels da
  superfície-base são derivados dos bytes de terreno no código.
- **H2, permissão da API:** confirmada pelo erro do Output no Studio. O renderizador anterior só
  encontrava a falha ao escrever no primeiro passo.
- **H3, regressão de UI:** sem evidência nas mudanças recentes de `MapSurface`; não foi encontrada
  alteração correspondente em tintas, transparência, escala ou ordem visual.
- **H4, dados inválidos:** descartada para a reprodução observada. O tooltip tinha terreno e
  vizinhos, os buffers são dimensionados por `W * H`, e `map2d_render` cobre as cores geradas.

O último commit visualmente conhecido como bom **não pôde ser identificado**: não há captura
versionada ou registro visual ligado a um commit.

## Alterações

- `src/client/Map/MapSurface.luau`: testa criação, escrita e associação da imagem antes de exibi-la;
  usa até 2.048 `Frame`s de baixa resolução se a API falhar; se os dois caminhos falharem, remove
  imagens inválidas, mostra fundo neutro e registra ambos os erros. A grade usa o mesmo buffer
  composto e acompanha a câmera.
- `src/client/Map/MapView.luau`: encaminha falhas do mapa ao estado de interface e sincroniza o
  estado de disponibilidade depois de cada passo.
- `src/client/UI/GlobeNotice.luau`: informa quando o fundo neutro foi necessário.
- `tests/map_render_fallback.luau`: cobre a grade limitada, as cores RGBA, seleção do fallback e a
  falha simultânea dos renderizadores.
- `docs/MAP_RENDER.md` e `docs/DECISIONS.md`: registram o caminho de desenho, a evidência e as
  hipóteses.

Não foram adicionados assets, IDs Roblox, dependências ou permissões obrigatórias. Quando a API
estiver bloqueada, o mapa continua visível com menos detalhe; quando disponível, mantém o
renderizador `EditableImage` em resolução integral.

## Verificações executadas

| Verificação | Resultado |
|---|---|
| Rojo, projeto de desenvolvimento | PASS — build concluído |
| Rojo, projeto de release | PASS — build concluído |
| Testes Luau | PASS — 95/95 scripts executados; 0 falhas |
| Serviço de lobby (`npm ci`, `npm test`, `npm run build`) | PASS — 45 testes, build TypeScript concluído, 0 vulnerabilidades reportadas |
| StyLua (`--check src`) | PASS |
| Selene (`--allow-warnings src`) | PASS — 0 erros, 42 avisos |
| `license-audit` | PASS — 0 falhas |
| `asset-audit` | PASS — nenhum asset de terceiros detectado |
| `secret-scan` (working tree) | PASS — nenhum segredo detectado |
| `secret-scan --history` | PASS — um fixture histórico determinístico corresponde à allowlist justificada existente; nenhum segredo detectado |

## Verificação visual e passos manuais

**Reproduzido antes da correção:** sim, no Studio local. A captura do usuário e o Output mostraram
o quadriculado e a mensagem de API inacessível.

**Correção visual no Studio: NÃO VERIFICADA.** A instância de Studio disponível estava carregada
com uma versão antiga do place (sua interface ainda mostrava `ADMIN F10`, ausente do checkout
atual). Não sincronizei nem salvei sobre esse place. O teste unitário força uma falha de API no
seletor e confirma a escolha do caminho `Frame`, mas não substitui uma inspeção visual em Roblox.

**Jogo publicado: NÃO VERIFICADO.** Esta correção ainda não foi publicada na experiência Roblox.

Para confirmar no Studio:

1. Abra `C:\Users\gabri\Desktop\DomWorld` no Rojo (`rojo serve`) e conecte o plugin ao place de
   teste correto; confira que é o checkout atual antes de iniciar Play.
2. Com `Allow Mesh / Image APIs` bloqueado em **Game Settings → Security**, entre numa partida e
   escolha um local. Confirme que aparece um mapa de baixa resolução sem quadriculado, que o
   tooltip continua funcionando e que é possível clicar para colocar a capital.
3. Ative a permissão e repita. O terreno deverá usar `EditableImage` em resolução integral.
4. Confirme no Output que a indisponibilidade da API não produz a textura quebrada; só deve haver
   o aviso informativo sobre o fallback.

Para confirmar no jogo publicado, publique primeiro o código validado pelo Rojo na experiência
DomWorld e repita a seleção de local. Teste a permissão desligada (fallback de Frames) e ligada
(renderizador integral) nas configurações da experiência. Nenhum upload de asset é necessário.

## Riscos conhecidos

- O fallback limita o mapa a 2.048 células e tem menos detalhe que `EditableImage`.
- A grade tem mais instâncias de UI que o renderizador integral; desempenho visual em dispositivos
  móveis ainda precisa ser confirmado no Studio e no jogo publicado.
- A inspeção visual pós-correção e a experiência publicada dependem do teste manual acima.
