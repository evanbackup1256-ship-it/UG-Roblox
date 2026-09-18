import { readFileSync } from "node:fs";

const source = readFileSync(new URL("../game/Config.luau", import.meta.url), "utf8");
const contentSections = ["Tiers", "Research", "Contracts", "Achievements", "ShopOffers"];
const keysBySection = new Map<string, string[]>();
let activeSection = "unscoped";

for (const line of source.split(/\r?\n/)) {
    const section = line.match(/Config\.([A-Za-z]+)\s*=\s*\{/);
    if (section) {
        activeSection = contentSections.includes(section[1]) ? section[1] : "unscoped";
    }

    const key = line.match(/key\s*=\s*"([^"]+)"/);
    if (key && activeSection !== "unscoped") {
        keysBySection.set(activeSection, [...(keysBySection.get(activeSection) ?? []), key[1]]);
    }
}

const duplicates = [...keysBySection.entries()].flatMap(([section, keys]) =>
    keys.filter((key, index) => keys.indexOf(key) !== index).map((key) => `${section}.${key}`),
);
const keys = [...keysBySection.values()].flat();
const baseTierCount = keysBySection.get("Tiers")?.length ?? 0;
const generatedTierCount = Number(source.match(/for i\s*=\s*1\s*,\s*(\d+)\s*do/)?.[1] ?? 0);
const tierCount = baseTierCount + generatedTierCount;

if (duplicates.length > 0) {
    throw new Error(`Duplicate content keys: ${[...new Set(duplicates)].join(", ")}`);
}

if (tierCount < 60) {
    throw new Error(`Expected at least 60 tiers, found ${tierCount}`);
}

console.log(`Content validation passed: ${keys.length} scoped keys, ${tierCount} tiers.`);
