# Renderização do mapa

## Superfície de terreno e territórios

`src/client/Map/MapView.luau` cria as camadas de tela, a câmera e `MapSurface`; a superfície recebe
`WorldMap.shared()` no início da partida. Os módulos de dados e decodificação ficam em
`src/shared/Core/WorldMap.luau`, `src/shared/Data/Maps/World.luau` e `src/shared/Net/MapFetch.luau`.
Para mapas atuais, `MapSurface.set_map` lê `map.tile_bytes`. O formato codifica classe de terreno,
beira de costa e magnitude por tile. O caminho legado deriva esses bytes dos dados de terreno.

`src/client/Map/MapSurface.luau` transforma cada byte em uma cor RGBA em
`MapSurface.terrain_pixel`; as cores base de oceano, areia, planície, altitude e montanha estão em
código. O buffer `terrain` é copiado para `comp`; ownership, fronteiras, defesa e efeitos de chão são
combinados nesse buffer por código. Não há imagem-base de continente.

O renderizador principal cria `EditableImage` por tile (cada lado limitado a 1024 pixels), tenta
escrever um pixel e associá-lo a um `ImageLabel.ImageContent`, e depois envia bandas sujas com
`WritePixelsBuffer`. Os `ImageLabel`s usam `ResampleMode.Pixelated` e `MapSurface.layout` acompanha a
câmera. Isso não usa `ImageRectOffset` nem um `rbxassetid` para pintar o terreno.

Se a criação, escrita ou associação do `EditableImage` falhar, `MapSurface` escolhe uma grade de até
2.048 `Frame`s. Cada célula usa a média de uma amostragem 4×4 do buffer composto; até 256 células
alteradas são atualizadas por passo de renderização. A câmera redimensiona e posiciona a grade como
uma superfície única. Se essa alternativa também falhar, os dois renderizadores são removidos, o
fundo fica neutro, o Output recebe a causa e `MapView` publica o estado para `GlobeNotice` mostrar
uma mensagem curta.

## Outras camadas visuais

`MapView` mantém as camadas de estrada, alcance, estruturas, unidades, efeitos, nomes e frentes em
módulos próprios dentro de `src/client/Map/`. `FalloutGlow.luau` também usa `EditableImage`, mas é
uma camada de brilho de fallout, não a superfície do terreno. Esses overlays não mudam a origem dos
pixels descrita acima. Outros `ImageLabel`s de ícones ou imagens não são a textura-base do mapa.

## Permissões

A documentação atual do Roblox descreve as permissões e os limites de memória para `EditableImage`;
em experiências publicadas, o acesso precisa ser habilitado nas configurações de segurança da
experiência. A alternativa de `Frame` não depende dessa permissão nem de upload de asset. Fonte:
[EditableImage — Roblox Creator Hub](https://create.roblox.com/docs/reference/engine/classes/EditableImage)
(consultada em 2026-11-10).

## Verificação

O teste `tests/map2d_render.luau` cobre a conversão e composição do mapa. O teste
`tests/map_render_fallback.luau` cobre o limite da grade, as cores amostradas, a seleção do caminho
alternativo e o estado neutro quando ambos os renderizadores falham. A correção requer teste visual
no Studio com a API permitida e bloqueada, além de teste publicado; o relatório correspondente
registra o que foi ou não possível verificar nesta execução.
