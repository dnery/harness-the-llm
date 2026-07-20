import { mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { webkit } from "playwright";

function parseArgs(argv) {
  const args = new Map();

  for (let index = 0; index < argv.length; index += 1) {
    const key = argv[index];
    if (!key.startsWith("--")) {
      throw new Error(`Unexpected positional argument: ${key}`);
    }

    const value = argv[index + 1];
    if (value === undefined || value.startsWith("--")) {
      throw new Error(`Missing value for ${key}`);
    }

    args.set(key.slice(2), value);
    index += 1;
  }

  return args;
}

function required(args, key) {
  const value = args.get(key);
  if (!value) {
    throw new Error(`Missing required argument --${key}`);
  }

  return value;
}

function numberArg(args, key, fallback) {
  const rawValue = args.get(key);
  if (rawValue === undefined) {
    return fallback;
  }

  const value = Number(rawValue);
  if (!Number.isFinite(value)) {
    throw new Error(`--${key} must be numeric; got ${rawValue}`);
  }

  return value;
}

const args = parseArgs(process.argv.slice(2));
const targetId = required(args, "target-id");
const url = required(args, "url");
const output = required(args, "output");
const readySelector = required(args, "ready-selector");
const viewportWidth = numberArg(args, "viewport-width", 1676);
const viewportHeight = numberArg(args, "viewport-height", 1059);
const deviceScaleFactor = numberArg(args, "device-scale-factor", 2);
const cssZoom = numberArg(args, "css-zoom", 0.8);
const timeoutMs = numberArg(args, "timeout-ms", 45000);
const settleMs = numberArg(args, "settle-ms", 3000);

await mkdir(dirname(output), { recursive: true });

const browser = await webkit.launch({ headless: true });

try {
  const context = await browser.newContext({
    viewport: { width: viewportWidth, height: viewportHeight },
    deviceScaleFactor,
    colorScheme: "light"
  });
  const page = await context.newPage();

  await page.goto(url, { waitUntil: "domcontentloaded", timeout: timeoutMs });
  await page.waitForSelector(readySelector, { state: "visible", timeout: timeoutMs });
  await page.waitForLoadState("networkidle", { timeout: Math.min(timeoutMs, 10000) }).catch(() => {});

  await page.evaluate((zoom) => {
    document.documentElement.style.zoom = String(zoom);
    document.body.style.zoom = String(zoom);
  }, cssZoom);

  await page.waitForTimeout(settleMs);
  await page.screenshot({ path: output, fullPage: false });
  await context.close();

  console.log(JSON.stringify({
    target_id: targetId,
    url,
    output,
    viewport: { width: viewportWidth, height: viewportHeight },
    device_scale_factor: deviceScaleFactor,
    css_zoom: cssZoom,
    ready_selector: readySelector
  }));
} finally {
  await browser.close();
}

