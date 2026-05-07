"use strict";

const HOST_NAME        = "com.recepzgrmh.ccswitch";
const USAGE_CACHE_TTL  = 60_000; // ms

let port         = null;
let orgIdCache   = null;
let usageCache   = null;
let usageCacheTs = 0;

// ── Native messaging connection ───────────────────────────────────────────────

function connect() {
    try {
        port = chrome.runtime.connectNative(HOST_NAME);
        port.onMessage.addListener(onNativeMessage);
        port.onDisconnect.addListener(() => {
            const err = chrome.runtime.lastError;
            if (err) console.warn("[ccswitch]", err.message);
            port = null;
            setTimeout(connect, 5000);
        });
    } catch (err) {
        console.warn("[ccswitch] connectNative failed:", err);
        setTimeout(connect, 10000);
    }
}

// All messages from native host are requests relayed from ccswitch CLI
async function onNativeMessage(msg) {
    if (!msg || msg.type !== "get_usage") return;
    const resp = await handleGetUsage(msg);
    try { if (port) port.postMessage(resp); } catch (_) {}
}

// ── Claude.ai API ─────────────────────────────────────────────────────────────

async function resolveOrgId(hint) {
    if (hint) { orgIdCache = hint; return hint; }
    if (orgIdCache) return orgIdCache;
    try {
        const r = await fetch("https://claude.ai/api/account", {
            credentials: "include",
            headers: { Accept: "application/json" }
        });
        if (!r.ok) return null;
        const d = await r.json();
        orgIdCache = d?.memberships?.[0]?.organization?.id ?? null;
    } catch (e) {
        console.warn("[ccswitch] resolveOrgId:", e);
    }
    return orgIdCache;
}

async function fetchUsage(orgId) {
    const now = Date.now();
    if (usageCache && now - usageCacheTs < USAGE_CACHE_TTL) {
        return { ok: true, usage: usageCache, org_id: orgId, cached: true };
    }
    try {
        const r = await fetch(
            `https://claude.ai/api/organizations/${encodeURIComponent(orgId)}/usage`,
            { credentials: "include", headers: { Accept: "application/json" } }
        );
        if (!r.ok) {
            return { ok: false, status: r.status, error: (await r.text().catch(() => "")).slice(0, 200) };
        }
        const usage = await r.json();
        usageCache   = usage;
        usageCacheTs = now;
        return { ok: true, usage, org_id: orgId };
    } catch (e) {
        return { ok: false, error: String(e?.message ?? e) };
    }
}

async function handleGetUsage(msg) {
    const orgId = await resolveOrgId(msg.org_id || null);
    if (!orgId) return { id: msg.id, ok: false, error: "not_logged_into_claude_ai" };
    return { id: msg.id, ...(await fetchUsage(orgId)) };
}

// ── Boot ──────────────────────────────────────────────────────────────────────
connect();
