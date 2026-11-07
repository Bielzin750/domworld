import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../..");
const sourceDir = path.join(root, "assets/domworld/icons/svg");
const output = path.join(root, "assets/domworld/icons/material-icons-outlined.png");
const cell = 128;
const columns = 5;
const icons = [
	"play",
	"matches",
	"shop",
	"inventory",
	"profile",
	"settings",
	"globe",
	"group",
	"help",
	"schedule",
	"flag",
	"rank",
	"shield",
	"attack",
	"wallet",
	"star",
	"close",
	"check",
	"info",
	"map",
];

const composites = [];
for (const [index, name] of icons.entries()) {
	const svg = await fs.readFile(path.join(sourceDir, `${name}.svg`), "utf8");
	const whiteSvg = svg.replace("<svg ", '<svg fill="#ffffff" ');
	const png = await sharp(Buffer.from(whiteSvg)).resize(cell, cell, { fit: "contain" }).png().toBuffer();
	composites.push({ input: png, left: (index % columns) * cell, top: Math.floor(index / columns) * cell });
}

await fs.mkdir(path.dirname(output), { recursive: true });
await sharp({
	create: {
		width: columns * cell,
		height: Math.ceil(icons.length / columns) * cell,
		channels: 4,
		background: { r: 0, g: 0, b: 0, alpha: 0 },
	},
})
	.composite(composites)
	.png()
	.toFile(output);
console.log(`Built ${icons.length} icons: ${path.relative(root, output)}`);
