# Plan: updatable matcher & parser rules ("Rules Pack")

**Goal.** Once NativeSpend is live, be able to change the strings that decide *what a message is* — bank sender codes, bank email domains, parser regexes, category keywords, merchant/brand names — **without shipping a new app version**.

**Status (6 Oct 2026):** **Built.** P1–P5 are done: the app downloads one signed file, checks it, keeps the previous version, and can roll back. Everything below is the original plan; this block says what shipped.

## How to publish a rules fix (no app release)

1. Edit `rules/rules.bundled.json` and raise `"packVersion"`. Add a sample message for the new wording to `"canaries"` (the app refuses a pack that misreads its own samples).
2. `dart run tool/gen_bundled_rules.dart && flutter test test/rules_test.dart`
3. `dart run tool/sign_rules.dart` — signs with `rules/signing_key.private` (first time: `--generate-key`; already done once, public key is in `lib/core/rules/rules_config.dart`). It refuses to sign if a canary fails.
4. Commit `rules/rules.signed.json` and push to `main`. Installed apps fetch it from `kRulesUrl` (raw.githubusercontent.com) at most once a day.

**The private key** is `rules/signing_key.private` (git-ignored). Whoever holds it can change how every installed app reads messages — keep a backup somewhere private and never commit it. To rotate: add the new public key to `kTrustedRulesKeys` in an app update, then sign with the new key id (`--key-id`).

**What the app does with a downloaded pack** (`lib/core/rules/rules_manager.dart`): verifies the Ed25519 signature; requires a format version it understands; requires a `packVersion` newer than what is in force (no downgrades); runs every canary; only then installs it. The previous pack is kept. Verified again on every start. If the app fails to reach its first screen twice in a row with new rules, they are rolled back automatically. It is silent: there is no screen for it and no setting — the app checks at most once a day, on open or resume.

**Privacy:** the only request is an anonymous GET of the public file (the host sees the IP address and time). Describe this in the privacy policy.

---

---

## 0. The constraint that shapes everything

NativeSpend's promise is *"Your money, your device, zero cloud"*: no servers of ours, nothing leaves the phone. A normal "remote config" product breaks that promise, so the design has to be **download-only and anonymous**:

- The app only ever **GETs one small public file**. It sends no user data, no device/installation ID, no analytics.
- The rules are **data** (lists and regex strings), never code. Nothing is executed from the network.
- Every pack is **signed**; the app only trusts a pack whose signature checks out against a public key built into the app.
- The app always works with **no network at all**: a copy of the rules ships inside the app and is the permanent fallback.
- The user can **turn updates off**.

What we can't hide: the host that serves the file sees the phone's IP address and the time of the request. This must be said plainly in the privacy copy (see §9).

### Hosting options

| Option | Fits "zero cloud"? | Notes |
|---|---|---|
| **A. Static signed JSON on GitHub Pages / Releases / any CDN (recommended)** | Yes, with the caveats above | No SDK, no device ID, no account. Free. We own the format and the signing key. |
| B. Firebase Remote Config | **No** | Adds Google's SDK and a per-install ID that is sent with every fetch. Contradicts the privacy promise and the app-store "no data collected" story. Easier targeting/rollout, but that's exactly the tracking we avoid. |
| C. App-store updates only (today) | Yes | Slow: store review plus users must update. This is the problem we're solving. |

**Decision for now: A.** Everything below assumes it.

---

## 1. What moves — inventory

Counts are from the code at `492da39`. **Since P1/P2 these lists no longer live in the Dart files named below — they come from `rules/rules.bundled.json`** (the paths are kept to show where each one came from; `bank_sender_codes.dart` was deleted).

### Tier 1 — plain data lists (safe, move first)

| Rules-pack section | Today lives in | Size | Used by |
|---|---|---|---|
| `senderCodes` — SMS sender IDs that are banks | `lib/core/sms/bank_sender_codes.dart` (`knownBankSenderCodes`) | ~1,408 codes | `looksLikeBankSender` in `bank_sms_parser.dart` |
| `bankNames` — sender prefix → display name | `lib/core/sms/bank_names.dart` (`_bankNamePrefixes`) | 24 prefixes | `bankDisplayName`, account naming |
| `emailDomains` — bank email domains + `bank.in` rule | `lib/core/email/bank_email_matcher.dart` (`knownBankEmailDomains`, `bankInSuffix`) | ~90 domains | `looksLikeBankEmail`, Gmail search query |
| `categoryKeywords` — keyword → category | `lib/core/intelligence/default_category_rules.dart` (`_rules`, `_incomeWords`) | 10 categories | `defaultCategoryFor` |
| `brands` — keywords, display name, colour, initial, logo key | `lib/shared/widgets/merchant_badge.dart` (`_brands`) | ~125 brands | merchant avatars |
| `merchantAliases` — raw text → clean name; noise words; acronyms; generic labels | `lib/core/intelligence/merchant_normalizer.dart` (`_bundledAliases`, `_noiseWords`, `_acronyms`, `_genericLabels`) | ~43 aliases + small sets | `normalizeMerchant`, `isGenericMerchantLabel` |
| `nameTitles` — "mr/mrs/shri…" | `lib/core/intelligence/name_match.dart` (`_titles`) | tiny | self-transfer name matching |

### Tier 2 — regular expressions (high value, higher risk)

All in `lib/core/sms/bank_sms_parser.dart` (~46 `RegExp`s):

- amount patterns: `_prefixAmountPattern`, `_suffixAmountPattern`, `_verbAmountPattern`, `_currencyCodes`
- direction: `_strongDebit`, `_strongCredit`, `_weakDebit`, `_weakCredit`
- rejection: `_notTransaction` (OTP, promos, mandates…), `_failedWords`, `_balanceContext`, `_balanceClause`
- merchant extraction: `_merchantPatterns` (ordered list), `_creditFromPattern`, `_nameEnd`, `_notMerchant`, `_genericPhrase`
- flags and kinds: `_refundWords`, `_internationalKeywords`, `_forexWords`/`_prepaidWords`/`_creditCardWords`/`_debitCardWords`, `_last4Pattern`
- purpose labels: the `_purposeLabel` / `_loanLabel` word tests, `_loanKind`, `_loanWords`
- structured emails: `_structuredType`, `_structuredAmount`, `_structuredCurrency`, `_structuredStatus`, `_fieldLabels`
- email focus/footer: `_emailFooter`, `focusTransactionText` window rules

### Tier 3 — stays in code

Algorithms and thresholds, not strings: ordering of the pipeline, SMS↔email twin matching (30-minute window, last-4 agreement), refund and transfer detection, name-matching rules (`isSameName`), recurring detection, learned-template building (`template_learning.dart`). These change rarely and need a code review, not a config edit.

### Not part of this plan

- **User-learned data** (parser templates, aliases, category rules, the user's name): always local, never in the pack.
- **Logo images** (`assets/logos/`, ~80 files, ~660 KB): bundled. A downloadable logo pack is an optional later phase (§8, P5) because it means fetching binary files.

---

## 2. The Rules Pack format

One JSON document, versioned and signed.

```jsonc
{
  "format": "nativespend-rules",
  "schemaVersion": 1,          // bump only when the app must understand new structure
  "packVersion": 17,           // integer, strictly increasing; publishing = bumping this
  "minAppVersion": "1.0.0",    // older apps ignore the pack
  "publishedAt": "2026-10-10T08:00:00Z",
  "enabled": true,             // kill switch: false = everyone falls back to bundled rules

  "senderCodes": ["HDFCBK", "ICICIB", "..."],
  "bankNames":   { "HDFCBK": "HDFC Bank", "...": "..." },
  "emailDomains": { "suffix": "bank.in", "domains": ["hdfcbank.net", "..."] },

  "categoryKeywords": [
    { "category": "cat_food", "words": ["swiggy", "zomato", "..."] }
  ],
  "incomeWords": ["salary", "interest", "..."],

  "brands": [
    { "name": "Swiggy", "keywords": ["swiggy"], "color": "#FC8019", "initial": "S", "logo": "swiggy" }
  ],
  "merchantAliases": [{ "match": "amzn", "name": "Amazon" }],
  "merchantNoiseWords": ["upi", "imps", "..."],

  "parser": {
    "amountPrefix":  { "pattern": "...", "flags": "i" },
    "strongDebit":   { "pattern": "...", "flags": "i" },
    "notTransaction": { "pattern": "...", "flags": "i" },
    "merchantPatterns": [ { "pattern": "...", "flags": "i" } ]
  },

  "canaries": [
    {
      "text": "Rs.499.00 debited from A/c XX1234 to SWIGGY on 02-10-26",
      "expect": { "type": "debit", "amountMinor": 49900, "merchantContains": "swiggy" }
    }
  ]
}
```

Notes:

- `schemaVersion` is about **structure**; `packVersion` is about **content**. An app that sees a higher `schemaVersion` than it knows ignores the pack and keeps what it has.
- Unknown extra fields are ignored (forward compatible). Missing sections fall back to the bundled value for just that section.
- `canaries` are real messages with the expected result. They are the safety net in §4.

### Manifest and signature

Two files next to each other:

- `rules.json` — the pack
- `rules.json.sig` — detached **Ed25519** signature of the exact bytes of `rules.json`

Optionally a tiny `manifest.json` (`{ packVersion, sha256, url }`) so the app can check "anything new?" with a few hundred bytes before pulling the whole pack. ETag/`If-None-Match` does the same job with fewer moving parts — start with ETag.

The **public key is compiled into the app**. Plan for **two keys** (current + next) so a key can be rotated through a normal app release without ever stranding users.

---

## 3. Runtime design in the app

### 3.1 How rules are read today (implemented)

```
rules/rules.bundled.json            <- the source of truth. Edit this.
tool/gen_bundled_rules.dart         <- `dart run tool/gen_bundled_rules.dart` embeds it in the app
lib/core/rules/bundled_rules.g.dart <- GENERATED: `const kBundledRulesJson = r'''…'''`
lib/core/rules/parser_rules.dart    <- ParserRules / ParserPatterns: parses + compiles the JSON
```

- `ParserRules.current` is what the rest of the app reads. It starts as the built-in rules and is a synchronous static, so nothing awaits an asset load and tests need no setup. **`ParserRules.use(rules)` is the swap point** a remote pack would call (`use(null)` restores the built-in rules).
- The old top-level constants became thin getters over the current rules, e.g. `RegExp get _strongDebit => _p.strongDebit;` in `bank_sms_parser.dart`, so none of the parsing logic changed — only where the strings come from.
- A test (`test/rules_test.dart`) fails if the generated Dart file drifts from the JSON, so the two can't disagree.
- `ParserRules.fromJson` throws `RulesFormatException` on a wrong `format`, a missing section or an invalid regex — the same validation a downloaded pack would need.
- Brand glyphs are code, not data: JSON names a glyph (`"icon": "swiggy"`) and `lib/shared/widgets/brand_icons.dart` maps the name to a compile-time `IconData`. A brand that needs a **new** glyph needs a line there (an app release); everything else about a brand is data. Logo images (`assets/logos/`) are bundled; JSON only points at them.
- Differences from the original sketch below: `bankNames` is an ordered list (not an object) so order is explicit; the parser's repeated fragments are shared through `parser.vars` (`{currencyCodes}`, `{nameEnd}`, `{fieldLabels}`); purpose labels are an ordered list with a `{"special": "loan"}` marker for the loan/EMI check; `schemaVersion`/`packVersion`/`minAppVersion` exist but only `format` is enforced today.

**To change a rule today:** edit `rules/rules.bundled.json` → `dart run tool/gen_bundled_rules.dart` → `flutter test` → ship an app release.

Remaining work for a remote pack is now only the part in §3.2 onward (load a verified pack, call `ParserRules.use`).

### 3.2 Load order

1. **Active pack** from app storage (last pack that passed every check), else
2. **Bundled pack** (`assets/rules/rules.bundled.json`, always valid by construction).

A section missing from the active pack uses the bundled section. Nothing ever *requires* the network.

### 3.3 Update flow

```
app open  ->  if updates enabled AND last check > 24h ago:
              GET rules.json (If-None-Match: <stored ETag>), 8 s timeout, no cookies, no headers beyond defaults
              304 -> nothing to do
              200 -> size check (< 1 MB)
                  -> GET rules.json.sig
                  -> verify Ed25519 over the exact bytes        (fail -> discard, keep current)
                  -> parse + schema validate                     (fail -> discard)
                  -> packVersion > current                        (else discard)
                  -> minAppVersion <= this app                    (else ignore)
                  -> compile every regex in a try/catch           (see §4)
                  -> run canaries                                  (any failure -> discard)
                  -> atomically replace the stored pack, remember ETag + packVersion
                  -> new snapshot published to Riverpod; next import uses it
```

- Never blocks UI; failures are silent (logged locally only) and retried at the next 24 h boundary.
- Store the verified bytes + signature on disk (app support directory). Re-verify on load so a tampered file on a rooted device is rejected.
- Updates apply to the **next** import/parse. Already-stored transactions are not silently rewritten; a "Re-scan with updated rules" action in Settings (the existing hash-based repair path already corrects rows the user didn't edit) is the explicit way to re-apply.

### 3.4 Settings UI

- Switch: **"Update matching rules automatically"** (default decided in §10).
- Read-only row: "Rules version 17 · updated 3 Oct" (or "Built-in rules").
- Button: "Check now".
- Button: "Use built-in rules only" (clears the downloaded pack).

---

## 4. Safety: a bad pack must never brick parsing

Rules are the most sensitive input in the app — a wrong regex can silently drop or mis-sign every bank message. Defences, in order:

1. **Signature** — unsigned/tampered = ignored.
2. **Schema + size limits** — max 1 MB, max regex length 400 chars, max entries per list, known fields only.
3. **Per-entry compile guard** — each regex compiled in `try/catch`; an invalid one is dropped. If more than ~2% of entries fail, the whole pack is rejected.
4. **ReDoS guard**
   - Publish-time: CI rejects patterns with nested/ambiguous quantifiers (e.g. `(a+)+`, `(.*)*`) using a linter and a timing run against the corpus.
   - Run-time: the parser already works on a *focused* excerpt; additionally cap input at ~4 KB before matching, and wrap matching so one message can't block the UI (run import work off the main isolate if timing shows a need).
5. **Canaries** — the pack carries real messages with expected outcomes. After loading, the app runs them; **any** mismatch rejects the pack and keeps the current one. This catches "valid regex, wrong behaviour".
6. **Never go down a version** — `packVersion` must increase. Rollback = publish a *new* pack whose content equals the old good one.
7. **Kill switch** — `"enabled": false` makes every app fall back to bundled rules on its next check.
8. **Beta channel** — the app can read `rules.beta.json` when a hidden developer toggle is on (or in debug builds), so a pack can be exercised on our own devices before `rules.json` is overwritten.

Percentage rollouts are intentionally **not** offered: they need a stable per-device ID, which is the tracking we're avoiding.

---

## 5. Publishing pipeline

Source of truth in the repo:

```
rules/
  src/
    sender_codes.json
    email_domains.json
    categories.json
    brands.json
    merchant_aliases.json
    parser.json
    canaries.json
  build_pack.dart      // merges src/ into rules.json, bumps packVersion
  README.md            // runbook
```

CI (GitHub Actions) on every change under `rules/`:

1. Validate JSON against the schema.
2. Build `rules.json`.
3. Run the **full corpus**: `test/message_corpus_test.dart`, `bank_sms_parser_test.dart`, `email_parsing_test.dart`, `ingest_pipeline_test.dart`, `default_category_test.dart` — executed **against the built pack**, not just the bundled constants.
4. Run the canaries.
5. ReDoS lint + timing.
6. On merge to `main` + a manual approval step: sign with the Ed25519 private key, publish `rules.json` + `.sig` to the static host.

Signing key custody: private key never in the repo; stored as a CI secret (or signed offline from a laptop). Write down who holds it and the rotation procedure in `rules/README.md`.

A change goes live by editing a file in `rules/src/`, merging a PR, approving the publish job. No app release.

---

## 6. Code changes — checklist

New:
- `lib/core/rules/*` (model, compiled rules, repository, updater, providers) — see §3.1
- `assets/rules/rules.bundled.json` (+ a script that regenerates it from `rules/src/`)
- `rules/` source tree and `build_pack.dart`
- `.github/workflows/rules.yml`
- Settings card for rule updates

Refactor (behaviour-preserving first):
- `bank_sms_parser.dart` — thread a `ParserRules` argument; move regex literals to `rules/src/parser.json`
- `bank_sender_codes.dart`, `bank_names.dart`, `bank_email_matcher.dart` — read from rules
- `default_category_rules.dart`, `merchant_normalizer.dart`, `merchant_badge.dart`, `name_match.dart` — read from rules
- `transaction_ingestor.dart` — take a snapshot in `begin()`; `gmail_import_service.dart` — build the Gmail search query from the snapshot's email domains
- `pubspec.yaml` — add an Ed25519 verifier dependency (the `cryptography` package already used by the app supports Ed25519, so likely **no new dependency**); add `assets/rules/`
- Tests: pass `ParserRules.bundled` (or a pack built from `rules/src/`) wherever they call the parser

Privacy copy to update when this ships:
- Onboarding page 1 and the splash say "zero cloud" / "100% offline". Reword to something true, e.g. *"Your data never leaves your device. The app only downloads anonymous rule updates."*
- Store listings: Play "Data safety" — still *no data collected*; the app makes a request but sends no user data. Document that in the listing notes.
- Apple App Store guideline 2.5.2 forbids downloading **executable code**; downloading data/regex strings is fine. Keep the pack strictly data (no scripting, no expression language).

---

## 7. Testing strategy

| Test | Proves |
|---|---|
| **Parity**: bundled JSON vs. the current Dart constants (run once during the migration) | The extraction lost nothing |
| Existing corpus (≈90 message layouts, ≈346 tests overall) run through `ParserRules.bundled` | Behaviour unchanged after the refactor |
| Same corpus run against a pack built from `rules/src/` | CI gate for every publish |
| Tampered file, wrong signature, truncated download | Rejected, previous rules kept |
| `packVersion` equal/lower; `minAppVersion` too high; `schemaVersion` too high | Ignored cleanly |
| Invalid regex in the pack; over-size pack; >2% bad entries | Entry dropped / pack rejected |
| Failing canary | Pack rejected |
| Offline / timeout / 304 / 5xx | No crash, no UI change, retry later |
| Update lands mid-import | The running import keeps its snapshot |
| Updates switched off | No network request is made at all |
| ReDoS fixtures (`(a+)+$` style) | Rejected at publish time and guarded at run time |

---

## 8. Phases

| Phase | Work | Done when |
|---|---|---|
| **P0 — Decisions** (½ day) | Resolve §10 questions: host, default on/off, key custody, copy wording | Decisions written at the bottom of this file |
| **P1 — Extract Tier 1 to JSON, no network** ✅ done | `rules/src/*` for lists; `RulesPack` model + `rules.bundled.json`; loader; switch sender codes, bank names, email domains, category keywords, brands, aliases to read from it | App behaves identically; parity test green |
| **P2 — Parser regexes into the pack** ✅ done | `ParserRules`; thread through `parseBankSms` and friends; move Tier 2 patterns to `parser.json`; canaries | Entire existing corpus passes on `ParserRules.bundled` (it does: all 346 existing tests passed unchanged) |
| **P3 — Fetch, verify, cache** (3 days) | Updater, Ed25519 verify, atomic activation, 24 h schedule, ETag, Settings UI, beta channel | A signed pack published to the beta channel changes behaviour on a device; tampered pack is ignored |
| **P4 — Publishing pipeline** (2 days) | Build script, CI gates (schema, corpus, canaries, ReDoS), signing, host setup, runbook, key-rotation drill | A rule edit goes from PR to phones with no app release |
| **P5 — Optional** | Logo pack download; a privacy-preserving "this message was read wrong" action that lets the user copy a *redacted* message into a GitHub issue (no telemetry), feeding new rules back in | — |

P1 and P2 are valuable even if the network part is never built: rules become data, easier to review and test.

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| A bad pack mis-parses real bank messages | Signature + canaries + corpus gate + kill switch + no downgrade (§4) |
| Private signing key leaks | Two-key scheme; rotate via app release; keep key out of the repo |
| Host is blocked / down | Bundled rules always work; retry daily; user unaffected |
| The "zero cloud" brand promise is weakened | Update checks are optional, anonymous and disclosed; copy reworded honestly (§6) |
| Host sees IPs | Say so in the privacy policy; prefer a host with no access logs where possible |
| Regex semantics drift between Dart versions | Run the corpus in CI on the same Flutter version as the release build |
| Rules edited faster than they're tested | PR review + required CI + manual publish approval |
| App-store policy | Data only, no code (§6) |

---

## 10. Open decisions (answer these first)

- [ ] **Host:** GitHub Pages in this repo, GitHub Releases, or another static host?
- [ ] **Default:** automatic updates **on** by default (more useful) or **off** until the user opts in (closer to "zero cloud")? *Suggestion: on, with a clear line in onboarding and a visible switch.*
- [ ] **Check interval:** every 24 h on open (suggested) or less often?
- [ ] **Key custody:** CI secret vs. signing offline on a laptop; who else needs access?
- [ ] **Wording** of the new privacy copy for onboarding, splash and store listings.
- [ ] **Scope of v1 pack:** Tier 1 + Tier 2 together, or ship Tier 1 first (lowest risk) and add regexes once the pipeline is proven?

---

## 11. Picking this up on another device

```bash
git clone https://github.com/jayghadge111/local_ledger.git   # or: git pull
cd local_ledger
flutter pub get
dart run build_runner build --delete-conflicting-outputs      # Drift (.g.dart) files
flutter analyze && flutter test                               # expect clean + all passing
```

Context that isn't obvious from the code:

- The package/bundle id is still `com.localledger.*` on purpose (changing it breaks Google sign-in); the display name is **NativeSpend**.
- Database schema is **v7**. Add new tables via `MigrationStrategy.onUpgrade` in `lib/core/db/app_database.dart`.
- The parser has a large regression corpus: `test/message_corpus_test.dart`, `bank_sms_parser_test.dart`, `email_parsing_test.dart`. Any refactor in P2 must keep those green.
- `lib/core/sms/template_learning.dart` (user-taught message layouts) is a *separate, user-local* mechanism and must stay independent of the remote pack.
- Run on the iOS simulator with `flutter run -d <udid>`; the simulator's app sits behind a PIN the assistant never sees.

**Where things stand:** P1 and P2 are finished (see Appendix A). If remote config is ever revisited, start at §10 (decisions), then P3. Nothing in P3–P5 has been started.

---

## Appendix A — the real bundled JSON (as of this commit)

Source: [`rules/rules.bundled.json`](../rules/rules.bundled.json) (~62 KB). Long lists are shortened here with `… N more`; the file has all of them. Counts below are from the file.

| Section | Entries |
|---|---|
| `senderCodes` | 1408 |
| `bankNames` | 24 |
| `emailDomains.domains` | 89 |
| `categoryKeywords (groups)` | 10 |
| `categoryKeywords (words)` | 317 |
| `incomeWords` | 6 |
| `brands` | 124 |
| `merchantAliases` | 42 |
| `merchantNormalizer.noiseWords` | 31 |
| `merchantNormalizer.acronyms` | 17 |
| `merchantNormalizer.genericLabels` | 33 |
| `nameTitles` | 13 |
| `parser.merchantPatterns` | 8 |
| `parser.purposeLabels.debit` | 12 |
| `parser.purposeLabels.credit` | 8 |
| `canaries` | 6 |

### A.1 Header and the simple lists

```json
{
  "format": "nativespend-rules",
  "schemaVersion": 1,
  "packVersion": 1,
  "minAppVersion": "1.0.0",
  "publishedAt": "2026-10-03T00:00:00Z",
  "enabled": true,
  "senderCodes": [
    "ACBLBK",
    "ACBLHO",
    "ACCBNK",
    "ACEPLC",
    "ADARSH",
    "ADBCCB",
    "ADHBNK",
    "ADINBK",
    "ADRBNK",
    "AEITSM",
    "AGMITS",
    "AGRABK",
    "… 1396 more"
  ],
  "bankNames": [
    {
      "prefix": "HDFC",
      "name": "HDFC Bank"
    },
    {
      "prefix": "ICICI",
      "name": "ICICI Bank"
    },
    {
      "prefix": "ICIBNK",
      "name": "ICICI Bank"
    },
    {
      "prefix": "SBMIND",
      "name": "SBM Bank India"
    },
    {
      "prefix": "SBI",
      "name": "SBI"
    },
    {
      "prefix": "AXIS",
      "name": "Axis Bank"
    },
    {
      "prefix": "KOTAK",
      "name": "Kotak Bank"
    },
    {
      "prefix": "KBANK",
      "name": "Kotak Bank"
    },
    {
      "prefix": "SCBANK",
      "name": "Standard Chartered"
    },
    {
      "prefix": "EQUTAS",
      "name": "Equitas SFB"
    },
    {
      "prefix": "EQBANK",
      "name": "Equitas SFB"
    },
    {
      "prefix": "YESB",
      "name": "Yes Bank"
    },
    {
      "prefix": "IDFC",
      "name": "IDFC First Bank"
    },
    {
      "prefix": "PNB",
      "name": "PNB"
    },
    {
      "prefix": "BOB",
      "name": "Bank of Baroda"
    },
    {
      "prefix": "BOI",
      "name": "Bank of India"
    },
    {
      "prefix": "CANBNK",
      "name": "Canara Bank"
    },
    {
      "prefix": "UNIONB",
      "name": "Union Bank"
    },
    {
      "prefix": "INDUSB",
      "name": "IndusInd Bank"
    },
    {
      "prefix": "FEDBNK",
      "name": "Federal Bank"
    },
    {
      "prefix": "RBL",
      "name": "RBL Bank"
    },
    {
      "prefix": "JJSBNK",
      "name": "Jalgaon Janata Sahakari Bank"
    },
    {
      "prefix": "JPCBNK",
      "name": "Jalgaon Peoples Co-op Bank"
    },
    {
      "prefix": "PAYTMB",
      "name": "Paytm Payments Bank"
    }
  ],
  "emailDomains": {
    "suffix": "bank.in",
    "domains": [
      "sbi.co.in",
      "alerts.sbi.co.in",
      "pnb.co.in",
      "pnbindia.in",
      "bankofbaroda.in",
      "bankofbaroda.co.in",
      "canarabank.com",
      "unionbankofindia.co.in",
      "bankofindia.co.in",
      "centralbank.co.in",
      "… 79 more"
    ]
  },
  "incomeWords": [
    "salary",
    "interest",
    "dividend",
    "payroll",
    "bonus",
    "stipend"
  ],
  "nameTitles": [
    "mr",
    "mrs",
    "ms",
    "miss",
    "mx",
    "shri",
    "shree",
    "sri",
    "smt",
    "kumari",
    "dr",
    "prof",
    "late"
  ]
}
```

### A.2 Category keywords (first match wins; order matters)

```json
[
  {
    "category": "cat_groceries",
    "words": [
      "dunzo",
      "avenue supermarts",
      "nature basket",
      "reliance smart",
      "instamart",
      "blinkit",
      "zepto",
      "bigbasket",
      "grofers",
      "dmart",
      "… 13 more"
    ]
  },
  {
    "category": "cat_food",
    "words": [
      "eatsure",
      "faasos",
      "behrouz",
      "oven story",
      "box8",
      "chaayos",
      "haldiram",
      "ccd",
      "cafe coffee day",
      "barista",
      "… 37 more"
    ]
  },
  {
    "category": "cat_transport",
    "words": [
      "makemytrip",
      "goibibo",
      "ixigo",
      "cleartrip",
      "yatra",
      "indigo",
      "air india",
      "vistara",
      "spicejet",
      "akasa",
      "… 39 more"
    ]
  },
  {
    "category": "cat_entertainment",
    "words": [
      "jiohotstar",
      "disney",
      "amazon prime",
      "apple music",
      "apple tv",
      "youtube music",
      "audible",
      "pvr inox",
      "sony liv",
      "netflix",
      "… 19 more"
    ]
  },
  {
    "category": "cat_health",
    "words": [
      "apollo",
      "pharmeasy",
      "1mg",
      "netmeds",
      "practo",
      "cult.fit",
      "cultfit",
      "cult fit",
      "healthkart",
      "medplus",
      "… 28 more"
    ]
  },
  {
    "category": "cat_investment",
    "words": [
      "kuvera",
      "indmoney",
      "paytm money",
      "smallcase",
      "coin by zerodha",
      "sip",
      "mutual fund",
      "mutual funds",
      "zerodha",
      "groww",
      "… 21 more"
    ]
  },
  {
    "category": "cat_emi",
    "words": [
      "emi",
      "loan",
      "ecs",
      "nach",
      "bajaj finance",
      "bajaj finserv",
      "hdfc ltd",
      "tata capital",
      "home credit",
      "moneyview",
      "… 2 more"
    ]
  },
  {
    "category": "cat_bills",
    "words": [
      "jio",
      "vi prepaid",
      "vi postpaid",
      "vi recharge",
      "vodafone",
      "vodafone idea",
      "tata play",
      "tataplay",
      "tata sky",
      "dish tv",
      "… 32 more"
    ]
  },
  {
    "category": "cat_shopping",
    "words": [
      "flipkart",
      "myntra",
      "ajio",
      "nykaa",
      "meesho",
      "tata cliq",
      "croma",
      "firstcry",
      "pepperfry",
      "snapdeal",
      "… 29 more"
    ]
  },
  {
    "category": "cat_transfer",
    "words": [
      "phonepe",
      "google pay",
      "gpay",
      "paytm",
      "bhim",
      "mobikwik",
      "freecharge"
    ]
  }
]
```

### A.3 Brands (logos, colours, keywords)

`keywords` starting with `=` must be the **whole** merchant name (e.g. `=vi`). `icon` is a glyph key (see `brand_icons.dart`); `logo` points at a bundled image.

```json
[
  {
    "name": "Swiggy",
    "keywords": [
      "swiggy"
    ],
    "color": "#FC8019",
    "initial": "S",
    "icon": "swiggy",
    "logo": null
  },
  {
    "name": "Zepto",
    "keywords": [
      "zepto"
    ],
    "color": "#8025FB",
    "initial": "Z",
    "icon": null,
    "logo": {
      "asset": "assets/logos/zepto.png",
      "wordmark": false
    }
  },
  {
    "name": "Ola",
    "keywords": [
      "ola",
      "ola cabs",
      "ola electric"
    ],
    "color": "#1C1C1C",
    "initial": "O",
    "icon": null,
    "logo": {
      "asset": "assets/logos/ola.png",
      "wordmark": true
    }
  },
  {
    "name": "Vi",
    "keywords": [
      "vodafone idea",
      "vodafone",
      "vi prepaid",
      "vi postpaid",
      "vi recharge",
      "=vi"
    ],
    "color": "#E60000",
    "initial": "V",
    "icon": "vodafone",
    "logo": null
  },
  {
    "name": "HDFC Bank",
    "keywords": [
      "hdfc"
    ],
    "color": "#004B8D",
    "initial": "H",
    "icon": "hdfcbank",
    "logo": null
  }
]
```

All brand names, in match order: Swiggy Instamart, Swiggy, Zomato, EatSure, Domino's, Pizza Hut, KFC, McDonald's, Burger King, Subway, Starbucks, Cafe Coffee Day, Chaayos, Haldiram's, Barista, Zepto, Blinkit, BigBasket, Dunzo, JioMart, DMart, Reliance Fresh, Uber, Ola, Rapido, redBus, IRCTC, MakeMyTrip, Goibibo, ixigo, Cleartrip, IndiGo, Air India, Vistara, SpiceJet, Akasa Air, FASTag, Airbnb, OYO, Amazon Pay, Prime Video, Amazon, Flipkart, Myntra, Ajio, Nykaa, Meesho, Tata CLiQ, Croma, Lenskart, FirstCry, IKEA, Nike, Adidas, Puma, Decathlon, Apple Music, Apple, Google Play, Netflix, JioHotstar, Spotify, YouTube Music, YouTube, SonyLIV, ZEE5, JioCinema, BookMyShow, PVR INOX, Gaana, Airtel, Jio, Vi, BSNL, Tata Play, Dish TV, ACT Fibernet, Hathway, BESCOM, Tata Power, Adani Electricity, PhonePe, Google Pay, Paytm, CRED, BHIM, MobiKwik, Freecharge, Razorpay, PayPal, HDFC Bank, ICICI Bank, Axis Bank, SBI, Kotak, Standard Chartered, Yes Bank, IDFC FIRST, IndusInd, Bank of Baroda, PNB, Canara Bank, Union Bank, HSBC, Citi, American Express, Federal Bank, RBL Bank, AU Small Finance, Visa, Mastercard, Apollo, PharmEasy, Tata 1mg, Netmeds, Practo, cult.fit, HealthKart, Zerodha, Groww, Upstox, Kuvera, INDmoney, LIC.

### A.4 Merchant normalizer

```json
{
  "merchantAliases": [
    {
      "match": "swiggy",
      "name": "Swiggy"
    },
    {
      "match": "zomato",
      "name": "Zomato"
    },
    {
      "match": "zepto",
      "name": "Zepto"
    },
    {
      "match": "blinkit",
      "name": "Blinkit"
    },
    {
      "match": "bigbasket",
      "name": "BigBasket"
    },
    {
      "match": "amzn",
      "name": "Amazon"
    },
    {
      "match": "amazon",
      "name": "Amazon"
    },
    {
      "match": "flipkart",
      "name": "Flipkart"
    },
    "… 34 more"
  ],
  "merchantNormalizer": {
    "noiseWords": [
      "upi",
      "imps",
      "neft",
      "rtgs",
      "pymnt",
      "payment",
      "pay",
      "txn",
      "ref",
      "dr",
      "cr",
      "pos",
      "… 19 more"
    ],
    "acronyms": [
      "hdfc",
      "icici",
      "sbi",
      "lic",
      "irctc",
      "bsnl",
      "atm",
      "emi",
      "kfc",
      "dmart",
      "pnb",
      "bob",
      "tcs",
      "ibm",
      "hp",
      "ev",
      "ac"
    ],
    "genericLabels": [
      "upi payment",
      "card payment",
      "bank payment",
      "credit",
      "unknown merchant",
      "neft transfer",
      "imps transfer",
      "rtgs transfer",
      "mutual fund sip",
      "insurance premium",
      "atm withdrawal",
      "mobile recharge",
      "… 21 more"
    ],
    "loanEmiLabel": {
      "pattern": "^[a-z\\- ]+ loan emi$",
      "flags": ""
    }
  }
}
```

### A.5 Parser patterns (complete)

Every regex the SMS/email parser uses. `{currencyCodes}`, `{nameEnd}` and `{fieldLabels}` are replaced from `vars` before compiling; `flags` is any of `i` (ignore case), `m`, `s`.

```json
{
  "vars": {
    "currencyCodes": "usd|sar|eur|gbp|aed|sgd|aud|cad|jpy|cny|thb|myr|chf|qar|kwd|bhd|omr|hkd|nzd|idr|lkr|npr",
    "nameEnd": "(?:\\s+on\\b|\\s+ref(?:no)?\\b|\\s+upi\\b|\\s+from\\b|\\s+via\\b|\\s+using\\b|\\s+avl\\b|\\s+bal\\b|\\s+utr\\b|\\s*\\(|\\.\\s|\\.$|,|$)",
    "fieldLabels": "(?:upi\\s+ref(?:erence)?(?:\\.?\\s*no\\.?)?|from\\s+vpa|payer\\s+name|to\\s+vpa|payee\\s+name|currency|amount|remarks|transaction\\s+(?:date|status|type|id)|reason\\s+for\\s+failure|beneficiary|remitter)"
  },
  "senderCode": {
    "pattern": "^(?:[A-Z]{2}-)?([A-Z0-9]{4,8})(?:-[A-Z])?$"
  },
  "prefixAmount": {
    "pattern": "(?<![A-Za-z])(rs\\.?|inr|₹|{currencyCodes})\\s*[:.]?\\s*([\\d,]+(?:\\.\\d{1,2})?)",
    "flags": "i"
  },
  "suffixAmount": {
    "pattern": "([\\d,]+(?:\\.\\d{1,2})?)\\s*({currencyCodes})\\b",
    "flags": "i"
  },
  "verbAmount": {
    "pattern": "\\b(?:debited|credited|debit|credit)\\s+(?:by|for|with|of)\\s+([\\d,]+(?:\\.\\d{1,2})?)",
    "flags": "i"
  },
  "balanceContext": {
    "pattern": "(bal|avl|avail|limit|lmt|outstanding)",
    "flags": "i"
  },
  "balanceClause": {
    "pattern": "(?:temporary\\s+credit\\s+|avl\\.?\\s+|available\\s+|total\\s+)?(?:bal(?:ance)?|limit)\\b[:\\s]*(?:[A-Za-z]{2,3}\\.?\\s*|₹\\s*)?[\\d,]+(?:\\.\\d+)?",
    "flags": "i"
  },
  "strongDebit": {
    "pattern": "\\b(debited|spent|withdrawn|paid|purchase|purchased|sent|charged|used (?:at|for)|transacted|swiped)\\b",
    "flags": "i"
  },
  "strongCredit": {
    "pattern": "\\b(credited|received|deposited|refunded|refund|reversed|reversal|loaded|reloaded|topped up)\\b",
    "flags": "i"
  },
  "weakDebit": {
    "pattern": "\\b(debit|dr|txn of|transaction of|payment of|thank you for using)\\b",
    "flags": "i"
  },
  "weakCredit": {
    "pattern": "\\b(credit(?!\\s*card)|cr)\\b",
    "flags": "i"
  },
  "notTransaction": {
    "pattern": "\\botp\\b|one.?time.?password|do not share|never share|verification code|will be (?:debited|credited|charged)|is due\\b|(?:min(?:imum)?\\.?|total) (?:amt|amount) due|e-?mandate|pre-?approved|apply now|click here|upgrade|converted (?:in)?to (?:an )?emi|emi conversion",
    "flags": "i"
  },
  "failedWords": {
    "pattern": "\\b(failed|declined|unsuccessful|insufficient)\\b",
    "flags": "i"
  },
  "creditFrom": {
    "pattern": "\\bfrom\\s+([A-Za-z0-9@._\\-& ]{2,40}?)(?:\\s+in\\b|\\s+on\\b|\\s+ref(?:no)?\\b|\\s+upi\\b|\\s+via\\b|\\s+utr\\b|\\s*\\(|\\.\\s|\\.$|,|$)",
    "flags": "i"
  },
  "notMerchant": {
    "pattern": "^(?:a/c|acct|account|your|card|ac\\b|xx|\\*|bank|the account|sb\\b|savings|upi[- ]?ref|ref\\b|refno|utr|txn)",
    "flags": "i"
  },
  "genericPhrase": {
    "pattern": "^(?:all|any|every|this|that|these|those|no|our|us|you|me)\\b|\\btimes?$|\\bconvenience$|\\bearliest$|\\bbank(?: ltd\\.?| limited)?$",
    "flags": "i"
  },
  "refundWords": {
    "pattern": "\\b(refund(?:ed)?|revers(?:ed|al)|cancell?ed|returned|chargeback)\\b",
    "flags": "i"
  },
  "forexWords": {
    "pattern": "\\bforex\\b",
    "flags": "i"
  },
  "prepaidWords": {
    "pattern": "\\bprepaid\\b",
    "flags": "i"
  },
  "creditCardWords": {
    "pattern": "\\bcredit\\s+card\\b",
    "flags": "i"
  },
  "debitCardWords": {
    "pattern": "\\bdebit\\s+card\\b",
    "flags": "i"
  },
  "cardWords": {
    "pattern": "\\bcard\\b",
    "flags": "i"
  },
  "internationalKeywords": {
    "pattern": "\\b(intl|international|foreign currency|forex markup|cross.?currency)\\b",
    "flags": "i"
  },
  "last4": {
    "pattern": "(?:a/c|\\bac\\b|acct?\\.?|account|card|ending(?:\\s+with)?|ends\\s+with)\\s*(?:no\\.?|number)?\\s*[:\\-]?\\s*(?:x+|\\*+|\\.{2,}|#)?\\s*(\\d{4})\\b",
    "flags": "i"
  },
  "loanKind": {
    "pattern": "\\b(home|housing|personal|car|auto|vehicle|education|gold|business|two.?wheeler)\\s+loan\\b",
    "flags": "i"
  },
  "loanWords": {
    "pattern": "\\b(emi|loan|nach|ecs|instal?lment)\\b",
    "flags": "i"
  },
  "emailFooter": {
    "pattern": "click here|for additional assistance|do not share|never share|if you did not|if you have not|if this (?:transaction )?was not|in case you|please call|call us|unsubscribe|disclaimer|this is an auto",
    "flags": "i"
  },
  "merchantPatterns": [
    {
      "pattern": "\\b(?:sender|remitter)(?:\\s+name)?\\s*[:\\-]\\s*([A-Za-z][A-Za-z .'\\-]{1,50}?)(?=\\s*\\(|\\s+(?:vpa|upi|ref|utr|c\\.)\\b|\\s*[,;]|\\.\\s|\\.$|$)",
      "flags": "i"
    },
    {
      "pattern": "\\bvpa\\s+\\S+\\s+([A-Za-z0-9&.' \\-]{2,60}?)\\s+on\\s+\\d{1,2}[-/]\\d{1,2}[-/]\\d{2,4}",
      "flags": "i"
    },
    {
      "pattern": "\\bupi[/\\-](?:p2[map]|dr|cr)?[/\\-]?\\d*[/\\-]([A-Za-z0-9 ._@&]+?)(?=[/\\-]|\\s+(?:sms|bal|avl|not|if|call)\\b|$)",
      "flags": "i"
    },
    {
      "pattern": "\\b(?:to|at|by|vpa|towards)\\s+([A-Za-z0-9@._\\-& ]{2,40}?){nameEnd}",
      "flags": "i"
    },
    {
      "pattern": "\\binfo[:\\-]\\s*([A-Za-z0-9@._\\-&/ ]{2,40}?)(?:\\.\\s|\\.$|,|$)",
      "flags": "i"
    },
    {
      "pattern": ";\\s*([A-Za-z][A-Za-z0-9 .&' \\-]{1,40}?)\\s+credited\\b",
      "flags": "i"
    },
    {
      "pattern": "\\d{1,2}-[A-Za-z]{3}-\\d{2,4}\\s+on\\s+([A-Za-z][A-Za-z0-9 .&' \\-]{1,40}?)(?:\\.\\s|\\.$|,|\\s+avl\\b|$)",
      "flags": "i"
    },
    {
      "pattern": "\\bIST\\s+([A-Za-z][A-Za-z0-9 .&' \\-]{1,40}?)\\s+(?:avl|available)\\b",
      "flags": "i"
    }
  ],
  "merchantCleanup": {
    "stripVpa": {
      "pattern": "^vpa\\s+",
      "flags": "i"
    },
    "stripChannel": {
      "pattern": "^(?:imps|neft|rtgs|upi)\\s+(?:to|from)\\s+",
      "flags": "i"
    },
    "numericOnly": {
      "pattern": "^(?:rs\\.?|inr|₹)?\\s*[\\d/\\-:., ]+$",
      "flags": "i"
    }
  },
  "structured": {
    "type": {
      "pattern": "transaction\\s+type\\s*:\\s*(dr|debit|cr|credit)\\b",
      "flags": "i"
    },
    "amount": {
      "pattern": "\\bamount\\s*:\\s*(?:rs\\.?|inr|₹)?\\s*([\\d,]+(?:\\.\\d{1,2})?)",
      "flags": "i"
    },
    "currency": {
      "pattern": "\\bcurrency\\s*:\\s*([A-Za-z]{3})\\b",
      "flags": "i"
    },
    "status": {
      "pattern": "transaction\\s+status\\s*:\\s*([A-Za-z]+)",
      "flags": "i"
    },
    "okStatuses": [
      "completed",
      "success",
      "successful",
      "processed",
      "credited",
      "debited"
    ],
    "fieldTemplate": "{label}\\s*:\\s*(.+?)(?=\\s+{fieldLabels}\\s*:|\\s*$)",
    "debitPartyLabels": [
      "payee\\s+name",
      "to\\s+vpa"
    ],
    "creditPartyLabels": [
      "payer\\s+name",
      "from\\s+vpa"
    ],
    "partyTitle": {
      "pattern": "^(?:mr|mrs|ms|miss|shri|smt|dr)\\.?\\s+",
      "flags": "i"
    }
  },
  "purposeLabels": {
    "debit": [
      {
        "label": "Mutual fund SIP",
        "pattern": "\\bsip\\b|mutual fund"
      },
      {
        "label": "Insurance premium",
        "pattern": "insurance|premium"
      },
      {
        "special": "loan"
      },
      {
        "label": "ATM withdrawal",
        "pattern": "\\batm\\b|cash withdrawal"
      },
      {
        "label": "Mobile recharge",
        "pattern": "recharge"
      },
      {
        "label": "FASTag toll",
        "pattern": "fastag|\\btoll\\b"
      },
      {
        "label": "Bill payment",
        "pattern": "bill ?pay|bbps|\\bbill\\b"
      },
      {
        "label": "Cheque payment",
        "pattern": "cheque|\\bchq\\b"
      },
      {
        "label": "NEFT transfer",
        "pattern": "\\bneft\\b"
      },
      {
        "label": "IMPS transfer",
        "pattern": "\\bimps\\b"
      },
      {
        "label": "RTGS transfer",
        "pattern": "\\brtgs\\b"
      },
      {
        "label": "Bank charges",
        "pattern": "service charge|charges|\\bfee\\b|\\bgst\\b"
      }
    ],
    "credit": [
      {
        "label": "Interest",
        "pattern": "interest"
      },
      {
        "label": "Dividend",
        "pattern": "dividend"
      },
      {
        "label": "Cash deposit",
        "pattern": "cash deposit|\\bcdm\\b"
      },
      {
        "label": "Cheque deposit",
        "pattern": "cheque|\\bchq\\b"
      },
      {
        "label": "Card load",
        "pattern": "loaded|reloaded|top-?up|topped up"
      },
      {
        "label": "NEFT transfer",
        "pattern": "\\bneft\\b"
      },
      {
        "label": "IMPS transfer",
        "pattern": "\\bimps\\b"
      },
      {
        "label": "RTGS transfer",
        "pattern": "\\brtgs\\b"
      }
    ]
  }
}
```

### A.6 Canaries

Sample messages with the result they must produce (`type: null` = must not parse as a transaction). `test/rules_test.dart` runs them; a remote pack would run them before being accepted (§4).

```json
[
  {
    "text": "Sent Rs.500.00\nFrom HDFC Bank A/c *1234\nTo SUNRISE CAFE\nOn 02/10/26\nRef 600000000001\nNot You? Call 18002586161/SMS BLOCK UPI to 7308080808",
    "expect": {
      "type": "debit",
      "amountMinor": 50000,
      "merchantContains": "sunrise cafe"
    }
  },
  {
    "text": "UPDATE: INR 1,250.00 debited from HDFC Bank XX1234 on 02-OCT-26. Info: UPI/DR/600000000002/SUNRISE STORE/HDFC",
    "expect": {
      "type": "debit",
      "amountMinor": 125000,
      "merchantContains": "sunrise store"
    }
  },
  {
    "text": "Dear UPI user A/C X1234 debited by 150.0 on date 05Mar24 trf to SUNRISE FOODS Refno 600000000003. If not u? call 1800111109. -SBI",
    "expect": {
      "type": "debit",
      "amountMinor": 15000,
      "merchantContains": "sunrise foods"
    }
  },
  {
    "text": "Rs.2,000.00 credited to HDFC Bank A/c XX1234 on 03-10-26 from VPA riya@okaxis (UPI 600000000005)",
    "expect": {
      "type": "credit",
      "amountMinor": 200000
    }
  },
  {
    "text": "Your OTP is 482913. Do not share it with anyone. Rs 500 will be debited from your account.",
    "expect": {
      "type": null
    }
  },
  {
    "text": "SAR 3.00 using ICICI Bank Forex Prepaid Card XX1233 transacted at POS on 02-Oct-26. Bal SAR 733.42. Temporary Credit Bal SAR 0.",
    "expect": {
      "type": "debit"
    }
  }
]
```
