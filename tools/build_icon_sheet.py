#!/usr/bin/env python3
"""Build DomWorld's white UI icon atlas and its Luau slot map (stdlib-only PNG path)."""
from __future__ import annotations

import argparse
import math
import re
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CELL = 128
COLUMNS = 8
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
ID_RE = re.compile(r"^[a-z0-9_]+$")
FILENAME_RE = re.compile(r"([a-z0-9_]+)\.(svg|png)", re.I)


def markdown_cells(line: str) -> list[str]:
    return [cell.strip().strip("`") for cell in line.strip().strip("|").split("|")]


def read_inventory(path: Path) -> list[str]:
    ids: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = markdown_cells(line)
        if len(cells) < 7 or cells[0] == "ID do ícone":
            continue
        icon_id = cells[0]
        if not ID_RE.fullmatch(icon_id):
            continue
        if icon_id not in ids:
            ids.append(icon_id)
    if not ids:
        raise ValueError(f"nenhum ID encontrado em {path}")
    return ids


def read_credit_rows(path: Path) -> dict[str, list[str]]:
    rows: dict[str, list[str]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = markdown_cells(line)
        if len(cells) < 6 or cells[0] == "ID do ícone":
            continue
        icon_id = cells[0]
        if ID_RE.fullmatch(icon_id):
            rows[icon_id] = cells[1:6]
    return rows


def validate_inputs(input_dir: Path, icon_ids: list[str], credit_path: Path) -> dict[str, Path]:
    credits = read_credit_rows(credit_path)
    allowed_ids = set(icon_ids)
    assets: dict[str, Path] = {}
    errors: list[str] = []
    if not input_dir.is_dir():
        input_dir.mkdir(parents=True, exist_ok=True)
    for path in sorted(input_dir.iterdir(), key=lambda item: item.name.lower()):
        if path.is_dir() or path.name == ".gitkeep":
            continue
        if path.suffix.lower() not in {".svg", ".png"}:
            errors.append(f"{path.name}: formato não aceito; use SVG ou PNG.")
            continue
        icon_id = path.stem.lower()
        if not ID_RE.fullmatch(icon_id) or icon_id not in allowed_ids:
            errors.append(f"{path.name}: ID não listado em docs/ICONS_NEEDED.md.")
            continue
        if icon_id in assets:
            errors.append(f"{icon_id}: existe mais de um arquivo; mantenha só SVG ou PNG.")
            continue
        credit = credits.get(icon_id)
        if credit is None:
            errors.append(f"{icon_id}: linha ausente em {credit_path}.")
            continue
        filename_field, source, author, license_name, attribution = [item.strip() for item in credit]
        expected_names = {match.group(0).lower() for match in FILENAME_RE.finditer(filename_field)}
        if path.name.lower() not in expected_names:
            errors.append(f"{icon_id}: coluna arquivo de ICON_CREDITS.md não lista {path.name}.")
        if not source or not author or not license_name or attribution.lower() not in {"sim", "não", "nao"}:
            errors.append(
                f"{icon_id}: preencha URL, autor, licença e crédito exigido "
                "(`Sim` ou `Não`) em ICON_CREDITS.md."
            )
            continue
        assets[icon_id] = path
    if errors:
        raise ValueError("\n".join(errors))
    return assets


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def decode_png(data: bytes) -> tuple[int, int, list[tuple[int, int, int, int]]]:
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("arquivo não é PNG válido")
    cursor = len(PNG_SIGNATURE)
    width = height = bit_depth = color_type = interlace = None
    compressed = bytearray()
    while cursor + 12 <= len(data):
        length = struct.unpack(">I", data[cursor : cursor + 4])[0]
        kind = data[cursor + 4 : cursor + 8]
        chunk = data[cursor + 8 : cursor + 8 + length]
        cursor += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", chunk)
        elif kind == b"IDAT":
            compressed.extend(chunk)
        elif kind == b"IEND":
            break
    if width is None or height is None or bit_depth != 8 or interlace != 0:
        raise ValueError("PNG precisa ser não interlaçado e ter 8 bits por canal")
    channels_by_type = {0: 1, 2: 3, 4: 2, 6: 4}
    channels = channels_by_type.get(color_type)
    if channels is None:
        raise ValueError("PNG deve ser grayscale, RGB, grayscale+alpha ou RGBA")
    raw = zlib.decompress(bytes(compressed))
    stride = width * channels
    bpp = channels
    previous = bytearray(stride)
    rgba: list[tuple[int, int, int, int]] = []
    offset = 0
    for _ in range(height):
        filter_type = raw[offset]
        offset += 1
        scan = bytearray(raw[offset : offset + stride])
        offset += stride
        for x in range(stride):
            left = scan[x - bpp] if x >= bpp else 0
            up = previous[x]
            upper_left = previous[x - bpp] if x >= bpp else 0
            if filter_type == 1:
                scan[x] = (scan[x] + left) & 255
            elif filter_type == 2:
                scan[x] = (scan[x] + up) & 255
            elif filter_type == 3:
                scan[x] = (scan[x] + ((left + up) // 2)) & 255
            elif filter_type == 4:
                scan[x] = (scan[x] + paeth(left, up, upper_left)) & 255
            elif filter_type != 0:
                raise ValueError(f"filtro PNG não suportado: {filter_type}")
        for x in range(width):
            base = x * channels
            if color_type == 0:
                shade = scan[base]
                rgba.append((shade, shade, shade, 255))
            elif color_type == 2:
                rgba.append((scan[base], scan[base + 1], scan[base + 2], 255))
            elif color_type == 4:
                shade, alpha = scan[base], scan[base + 1]
                rgba.append((shade, shade, shade, alpha))
            else:
                rgba.append((scan[base], scan[base + 1], scan[base + 2], scan[base + 3]))
        previous = scan
    return width, height, rgba


def encode_png(width: int, height: int, pixels: list[tuple[int, int, int, int]]) -> bytes:
    if len(pixels) != width * height:
        raise ValueError("quantidade de pixels inconsistente")
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for r, g, b, a in pixels[y * width : (y + 1) * width]:
            raw.extend((r, g, b, a))

    def chunk(kind: bytes, payload: bytes) -> bytes:
        body = kind + payload
        return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return PNG_SIGNATURE + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")


def source_pixels(path: Path, size: int) -> tuple[int, int, list[tuple[int, int, int, int]]]:
    if path.suffix.lower() == ".svg":
        try:
            import cairosvg  # type: ignore[import-not-found]
        except ImportError as exc:
            raise RuntimeError(
                "SVG encontrado, mas CairoSVG não está instalado. Rode "
                "`python -m pip install cairosvg` ou use PNG."
            ) from exc
        data = cairosvg.svg2png(url=str(path), output_width=size, output_height=size)
    else:
        data = path.read_bytes()
    return decode_png(data)


def resize_nearest(
    width: int,
    height: int,
    pixels: list[tuple[int, int, int, int]],
    target_width: int,
    target_height: int,
) -> list[tuple[int, int, int, int]]:
    resized: list[tuple[int, int, int, int]] = []
    for y in range(target_height):
        source_y = min(height - 1, (y * height) // target_height)
        for x in range(target_width):
            source_x = min(width - 1, (x * width) // target_width)
            resized.append(pixels[source_y * width + source_x])
    return resized


def white_icon(path: Path) -> list[tuple[int, int, int, int]]:
    width, height, pixels = source_pixels(path, CELL)
    if width < 1 or height < 1:
        raise ValueError(f"{path.name}: imagem vazia")
    scale = min((CELL - 8) / width, (CELL - 8) / height)
    out_width, out_height = max(1, round(width * scale)), max(1, round(height * scale))
    resized = resize_nearest(width, height, pixels, out_width, out_height)
    canvas = [(255, 255, 255, 0)] * (CELL * CELL)
    offset_x, offset_y = (CELL - out_width) // 2, (CELL - out_height) // 2
    has_alpha = path.suffix.lower() == ".svg" or any(alpha != 255 for _, _, _, alpha in pixels)
    for y in range(out_height):
        for x in range(out_width):
            red, green, blue, alpha = resized[y * out_width + x]
            if not has_alpha:
                alpha = 255 - ((red + green + blue) // 3)
            canvas[(offset_y + y) * CELL + offset_x + x] = (255, 255, 255, alpha)
    return canvas


def game_icon(path: Path) -> list[tuple[int, int, int, int]]:
    width, height, pixels = source_pixels(path, 512)
    if width != height:
        raise ValueError(f"{path.name}: game_icon precisa ser quadrado (512×512 recomendado)")
    if width != 512:
        pixels = resize_nearest(width, height, pixels, 512, 512)
    return pixels


def build_map(icon_ids: list[str], assets: dict[str, Path], out_path: Path) -> None:
    rows = [
        "-- GENERATED by tools/build_icon_sheet.py from docs/ICONS_NEEDED.md; do not edit by hand.",
        "-- Missing icons return nil so Widgets.Icon keeps its procedural/text fallback.",
        "-- Modified for DomWorld, 2026 — see git history for details.",
        "return {",
    ]
    index = 0
    for icon_id in icon_ids:
        if icon_id == "game_icon":
            continue
        available = "true" if icon_id in assets else "false"
        rows.append(f'\t["{icon_id}"] = {{ index = {index}, available = {available} }},')
        index += 1
    rows.append("}")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="\n") as output:
        output.write("\n".join(rows) + "\n")


def build_sheet(icon_ids: list[str], assets: dict[str, Path], out_path: Path, game_out: Path) -> None:
    sheet_ids = [icon_id for icon_id in icon_ids if icon_id != "game_icon"]
    rows = math.ceil(len(sheet_ids) / COLUMNS)
    sheet = [(255, 255, 255, 0)] * (COLUMNS * rows * CELL * CELL)
    for index, icon_id in enumerate(sheet_ids):
        path = assets.get(icon_id)
        if path is None:
            continue
        try:
            icon = white_icon(path)
        except Exception as exc:
            raise ValueError(f"{path.name}: {exc}") from exc
        cell_x, cell_y = (index % COLUMNS) * CELL, (index // COLUMNS) * CELL
        for y in range(CELL):
            start = y * CELL
            sheet_row = (cell_y + y) * (COLUMNS * CELL) + cell_x
            sheet[sheet_row : sheet_row + CELL] = icon[start : start + CELL]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(encode_png(COLUMNS * CELL, rows * CELL, sheet))
    if "game_icon" in assets:
        try:
            icon = game_icon(assets["game_icon"])
        except Exception as exc:
            raise ValueError(f"{assets['game_icon'].name}: {exc}") from exc
        game_out.parent.mkdir(parents=True, exist_ok=True)
        game_out.write_bytes(encode_png(512, 512, icon))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=ROOT / "ativos/domworld/icones/entrada")
    parser.add_argument("--inventory", type=Path, default=ROOT / "docs/ICONS_NEEDED.md")
    parser.add_argument("--credits", type=Path, default=ROOT / "docs/ICON_CREDITS.md")
    parser.add_argument("--map", type=Path, default=ROOT / "src/shared/UI/IconSpriteMap.luau")
    parser.add_argument("--output", type=Path, default=ROOT / "build/DomWorld-Icons.png")
    parser.add_argument("--game-output", type=Path, default=ROOT / "build/DomWorld-Game-Icon.png")
    args = parser.parse_args()
    try:
        icon_ids = read_inventory(args.inventory)
        assets = validate_inputs(args.input_dir, icon_ids, args.credits)
        build_map(icon_ids, assets, args.map)
        build_sheet(icon_ids, assets, args.output, args.game_output)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1
    count = sum(1 for icon_id in assets if icon_id != "game_icon")
    print(f"OK: atlas with {count} icons, {len(icon_ids) - 1} slots; map updated at {args.map}.")
    if "game_icon" in assets:
        print(f"OK: imagem da experiência gerada em {args.game_output}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
