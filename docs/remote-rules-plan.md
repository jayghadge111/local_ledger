# Plan: updatable matcher & parser rules ("Rules Pack")

**Goal.** Once NativeSpend is live, be able to change the strings that decide *what a message is* — bank sender codes, bank email domains, parser regexes, category keywords, merchant/brand names — **without shipping a new app version**.

**Status:** plan only, nothing implemented. Written 3 Oct 2026. Repo state when written: `main` at `492da39`, DB schema v7, 346 tests passing.

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

Counts are from the code at `492da39`.

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

### 3.1 A `ParserRules` object instead of top-level constants

Today the parser reads `final _strongDebit = RegExp(...)` etc. from file scope. Change to:

```
lib/core/rules/
  rules_pack.dart        // parsed + validated model of the JSON
  parser_rules.dart      // compiled RegExps and sets the parser needs
  rules_repository.dart  // load bundled / cached, fetch, verify, activate
  rules_providers.dart   // Riverpod: rulesProvider -> ParserRules
  rules_updater.dart     // the network part (small, isolated)
assets/rules/rules.bundled.json   // generated from today's constants
```

- `parseBankSms(body, rules)` (and `looksLikeBankSender`, `looksLikeBankEmail`, `defaultCategoryFor`, `normalizeMerchant`, `merchantBadgeFor`, `bankDisplayName`) take a `ParserRules`/`RulesSnapshot` argument.
- Keep a `ParserRules.bundled` constant for tests and for the very first frame before async loading finishes.
- The ingestor takes the snapshot once per `begin()`, so a single import run uses one consistent rule set even if an update lands mid-run.

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
| **P1 — Extract Tier 1 to JSON, no network** (2–3 days) | `rules/src/*` for lists; `RulesPack` model + `rules.bundled.json`; loader; switch sender codes, bank names, email domains, category keywords, brands, aliases to read from it | App behaves identically; parity test green |
| **P2 — Parser regexes into the pack** (3–4 days) | `ParserRules`; thread through `parseBankSms` and friends; move Tier 2 patterns to `parser.json`; canaries | Entire existing corpus passes on `ParserRules.bundled` |
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

**Suggested first step tomorrow:** settle §10, then start P1 with `bank_sender_codes.dart` → `rules/src/sender_codes.json` + loader + parity test, since it is the largest pure-data list and exercises the whole load path.
