import { createClient } from "npm:@supabase/supabase-js@2";
import {
  AssetKind,
  ImageValidationError,
  inspectStaticImage,
} from "./image_validation.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};

const json = (status: number, body: unknown) => new Response(JSON.stringify(body), {
  status,
  headers: { ...cors, "Content-Type": "application/json" },
});

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  const authorization = request.headers.get("Authorization");
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!authorization || !url || !anonKey || !serviceKey) {
    return json(401, { error: "Authenticated Supabase session required." });
  }
  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { data: userResult, error: userError } = await caller.auth.getUser();
  if (userError || !userResult.user) return json(401, { error: "Invalid session." });

  try {
    const contentType = request.headers.get("content-type") ?? "";
    if (contentType.includes("multipart/form-data")) {
      if (request.method !== "POST") return json(405, { error: "POST required." });
      const form = await request.formData();
      const institutionId = String(form.get("institution_id") ?? "");
      const requestId = String(form.get("request_id") ?? "");
      const assetId = String(form.get("asset_id") ?? crypto.randomUUID());
      const kind = String(form.get("kind") ?? "") as AssetKind;
      const slot = Number(form.get("slot"));
      const file = form.get("file");
      if (!uuid.test(institutionId) || !uuid.test(requestId) || !uuid.test(assetId) ||
          !["background", "element"].includes(kind) || !Number.isInteger(slot) ||
          slot < 0 || slot > 4 || (kind === "background" && slot !== 0) ||
          !(file instanceof File)) {
        return json(400, { error: "Invalid upload request." });
      }
      const bytes = new Uint8Array(await file.arrayBuffer());
      const inspected = inspectStaticImage(bytes, file.name, kind);
      const digest = await crypto.subtle.digest("SHA-256", bytes);
      const checksum = [...new Uint8Array(digest)]
        .map((value) => value.toString(16).padStart(2, "0")).join("");
      const { data: manifest, error: manifestError } = await caller.rpc(
        "prepare_institution_appearance_asset",
        {
          p_institution_id: institutionId,
          p_request_id: requestId,
          p_asset_id: assetId,
          p_kind: kind,
          p_slot: slot,
          p_extension: inspected.extension,
          p_mime_type: inspected.mimeType,
          p_size_bytes: bytes.length,
          p_width: inspected.width,
          p_height: inspected.height,
          p_checksum_sha256: checksum,
        },
      );
      if (manifestError) return json(403, { error: manifestError.message });
      const storagePath = String(manifest.storage_path);
      const { error: uploadError } = await admin.storage
        .from("institution-appearance")
        .upload(storagePath, bytes, {
          contentType: inspected.mimeType,
          cacheControl: "3600",
          upsert: false,
        });
      if (uploadError && !uploadError.message.toLowerCase().includes("already exists")) {
        return json(502, {
          error: "The validated file could not be uploaded.",
          asset_id: assetId,
          cleanup_required: true,
        });
      }
      return json(200, {
        asset: {
          id: assetId,
          kind,
          slot,
          storage_path: storagePath,
          mime_type: inspected.mimeType,
          size_bytes: bytes.length,
          width: inspected.width,
          height: inspected.height,
          checksum_sha256: checksum,
          status: "pending",
        },
      });
    }

    if (!contentType.includes("application/json") || request.method !== "POST") {
      return json(415, { error: "Use multipart upload or a JSON cleanup request." });
    }
    const body = await request.json();
    if (body.action !== "cleanup" || !uuid.test(String(body.asset_id ?? ""))) {
      return json(400, { error: "Invalid cleanup request." });
    }
    const { data: authorized, error: authorizationError } = await caller.rpc(
      "authorize_institution_appearance_asset_cleanup",
      { p_asset_id: body.asset_id },
    );
    if (authorizationError) return json(403, { error: authorizationError.message });
    const path = String(authorized.storage_path);
    const { error: removeError } = await admin.storage
      .from("institution-appearance").remove([path]);
    if (removeError) return json(502, { error: "Storage cleanup failed; it remains retryable." });
    const { error: confirmError } = await caller.rpc(
      "confirm_institution_appearance_asset_cleanup",
      { p_asset_id: body.asset_id },
    );
    if (confirmError) return json(502, { error: "Cleanup confirmation failed; retry safely." });
    return json(200, { cleaned: true, asset_id: body.asset_id });
  } catch (error) {
    if (error instanceof ImageValidationError) return json(422, { error: error.message });
    return json(500, { error: "Appearance asset processing failed." });
  }
});
