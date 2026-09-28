import assert from "node:assert/strict";
import { inspectStaticImage, ImageValidationError } from "./image_validation.ts";

const png = (colorType: number, animated = false) => {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  const ihdr = [0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 1, 0, 0, 0, 1, 0, 8, colorType, 0, 0, 0, 0, 0, 0, 0];
  const actl = animated
    ? [0, 0, 0, 8, 97, 99, 84, 76, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]
    : [];
  const iend = [0, 0, 0, 0, 73, 69, 78, 68, 0, 0, 0, 0];
  return new Uint8Array([...signature, ...ihdr, ...actl, ...iend]);
};

const alpha = inspectStaticImage(png(6), "reef.png", "element");
assert.equal(alpha.width, 256);
assert.equal(alpha.height, 256);
assert.equal(alpha.hasAlphaChannel, true);
assert.throws(
  () => inspectStaticImage(png(2), "opaque.png", "element"),
  ImageValidationError,
);
assert.throws(
  () => inspectStaticImage(png(6, true), "animated.png", "element"),
  /Animated images/,
);
assert.throws(
  () => inspectStaticImage(png(6), "fake.webp", "element"),
  /extension does not match/,
);
console.log("PASS Edge image byte validation");
