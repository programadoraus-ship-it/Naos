export const BACKGROUND_LIMIT = 5 * 1024 * 1024;
export const ELEMENT_LIMIT = 2 * 1024 * 1024;

export type AssetKind = "background" | "element";

export type InspectedImage = {
  extension: "png" | "jpg" | "webp";
  mimeType: "image/png" | "image/jpeg" | "image/webp";
  width: number;
  height: number;
  hasAlphaChannel: boolean;
};

export class ImageValidationError extends Error {}

const ascii = (bytes: Uint8Array, start: number, end: number) =>
  new TextDecoder("ascii").decode(bytes.subarray(start, end));

const u16be = (b: Uint8Array, p: number) => (b[p] << 8) | b[p + 1];
const u24le = (b: Uint8Array, p: number) =>
  b[p] | (b[p + 1] << 8) | (b[p + 2] << 16);
const u32be = (b: Uint8Array, p: number) =>
  new DataView(b.buffer, b.byteOffset + p, 4).getUint32(0);
const u32le = (b: Uint8Array, p: number) =>
  new DataView(b.buffer, b.byteOffset + p, 4).getUint32(0, true);

export function inspectStaticImage(
  bytes: Uint8Array,
  fileName: string,
  kind: AssetKind,
): InspectedImage {
  const limit = kind === "background" ? BACKGROUND_LIMIT : ELEMENT_LIMIT;
  if (bytes.length === 0 || bytes.length > limit) {
    throw new ImageValidationError(
      kind === "background"
        ? "Background files must be 5 MB or smaller."
        : "Decoration files must be 2 MB or smaller.",
    );
  }
  const lower = fileName.toLowerCase();
  const result = isPng(bytes)
    ? inspectPng(bytes)
    : isJpeg(bytes)
    ? inspectJpeg(bytes)
    : isWebP(bytes)
    ? inspectWebP(bytes)
    : null;
  if (!result) throw new ImageValidationError("Unsupported or falsified image type.");
  const acceptedExtension = result.extension === "jpg"
    ? lower.endsWith(".jpg") || lower.endsWith(".jpeg")
    : lower.endsWith(`.${result.extension}`);
  if (!acceptedExtension) {
    throw new ImageValidationError("The filename extension does not match the image bytes.");
  }
  if (kind === "element" &&
      (result.mimeType === "image/jpeg" || !result.hasAlphaChannel)) {
    throw new ImageValidationError(
      "Decorative elements must be PNG or WebP files with an alpha channel.",
    );
  }
  const min = kind === "background" ? 180 : 16;
  const max = kind === "background" ? 4096 : 2048;
  if (result.width < min || result.height < min ||
      result.width > max || result.height > max) {
    throw new ImageValidationError(
      kind === "background"
        ? "Background dimensions must be 180–4096 px on each side."
        : "Element dimensions must be 16–2048 px on each side.",
    );
  }
  return result;
}

function isPng(b: Uint8Array) {
  return b.length >= 24 && b[0] === 0x89 && b[1] === 0x50 &&
    b[2] === 0x4e && b[3] === 0x47 && b[4] === 0x0d && b[5] === 0x0a &&
    b[6] === 0x1a && b[7] === 0x0a;
}

function inspectPng(b: Uint8Array): InspectedImage {
  let p = 8;
  let width = 0;
  let height = 0;
  let alpha = false;
  while (p + 12 <= b.length) {
    const length = u32be(b, p);
    if (length > b.length - p - 12) throw new ImageValidationError("Damaged PNG file.");
    const type = ascii(b, p + 4, p + 8);
    if (type === "acTL") throw new ImageValidationError("Animated images are not supported.");
    if (type === "IHDR") {
      if (length !== 13) throw new ImageValidationError("Damaged PNG header.");
      width = u32be(b, p + 8);
      height = u32be(b, p + 12);
      alpha = b[p + 17] === 4 || b[p + 17] === 6;
    }
    if (type === "tRNS") alpha = true;
    if (type === "IEND") break;
    p += length + 12;
  }
  if (!width || !height) throw new ImageValidationError("PNG dimensions are missing.");
  return { extension: "png", mimeType: "image/png", width, height, hasAlphaChannel: alpha };
}

function isJpeg(b: Uint8Array) {
  return b.length >= 4 && b[0] === 0xff && b[1] === 0xd8 &&
    b[b.length - 2] === 0xff && b[b.length - 1] === 0xd9;
}

function inspectJpeg(b: Uint8Array): InspectedImage {
  let p = 2;
  while (p + 9 < b.length) {
    if (b[p] !== 0xff) throw new ImageValidationError("Damaged JPEG file.");
    while (p < b.length && b[p] === 0xff) p++;
    const marker = b[p++];
    if (marker === 0xd9 || marker === 0xda) break;
    if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (p + 2 > b.length) break;
    const length = u16be(b, p);
    if (length < 2 || p + length > b.length) throw new ImageValidationError("Damaged JPEG segment.");
    if (marker >= 0xc0 && marker <= 0xcf &&
        ![0xc4, 0xc8, 0xcc].includes(marker) && length >= 7) {
      return {
        extension: "jpg",
        mimeType: "image/jpeg",
        width: u16be(b, p + 5),
        height: u16be(b, p + 3),
        hasAlphaChannel: false,
      };
    }
    p += length;
  }
  throw new ImageValidationError("JPEG dimensions are missing.");
}

function isWebP(b: Uint8Array) {
  return b.length >= 20 && ascii(b, 0, 4) === "RIFF" && ascii(b, 8, 12) === "WEBP";
}

function inspectWebP(b: Uint8Array): InspectedImage {
  let p = 12;
  let width = 0;
  let height = 0;
  let alpha = false;
  while (p + 8 <= b.length) {
    const type = ascii(b, p, p + 4);
    const length = u32le(b, p + 4);
    if (length > b.length - p - 8) throw new ImageValidationError("Damaged WebP chunk.");
    const q = p + 8;
    if (type === "ANIM" || type === "ANMF") {
      throw new ImageValidationError("Animated images are not supported.");
    }
    if (type === "ALPH") alpha = true;
    if (type === "VP8X" && length >= 10) {
      if ((b[q] & 0x02) !== 0) throw new ImageValidationError("Animated images are not supported.");
      alpha = alpha || (b[q] & 0x10) !== 0;
      width = 1 + u24le(b, q + 4);
      height = 1 + u24le(b, q + 7);
    } else if (type === "VP8 " && length >= 10 &&
        b[q + 3] === 0x9d && b[q + 4] === 0x01 && b[q + 5] === 0x2a) {
      width = (b[q + 6] | (b[q + 7] << 8)) & 0x3fff;
      height = (b[q + 8] | (b[q + 9] << 8)) & 0x3fff;
    } else if (type === "VP8L" && length >= 5 && b[q] === 0x2f) {
      width = 1 + (((b[q + 2] & 0x3f) << 8) | b[q + 1]);
      height = 1 + (((b[q + 4] & 0x0f) << 10) | (b[q + 3] << 2) |
        ((b[q + 2] & 0xc0) >> 6));
      alpha = true;
    }
    p += 8 + length + (length % 2);
  }
  if (!width || !height) throw new ImageValidationError("WebP dimensions are missing.");
  return { extension: "webp", mimeType: "image/webp", width, height, hasAlphaChannel: alpha };
}
