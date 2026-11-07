# Website recipe extraction (#66)

This is the non-UI foundation for website imports. No third-party library,
Foundation Models, SwiftData mutation, credentials, API key or backend is used.
The review/save interface and persisted source URL belong to #68; AI fallback
belongs to #67. Extraction does not download images or import cooking steps.

## Entry point and boundaries

`WebsiteRecipeExtractor.extract(from:)` returns a `WebsiteRecipeExtraction` with
the submitted source URL, final redirect URL, and recipe candidates. It does not
choose or save a recipe. `WebsiteHTMLFetcher` owns retrieval; `WebsiteJSONLDScanner`
finds inline JSON-LD scripts; `WebsiteRecipeParser` maps JSON into value drafts.
All live under `Sources/Helpers/`, independent of SwiftUI and persistence.

Candidates contain a required trimmed name, optional description, ordered raw
ingredient lines, explicit vegan/vegetarian classification when present, and an
optional image URL. Ambiguous ingredient amounts are not guessed, split, converted
or lost; downstream review can reuse existing amount/normalization helpers when
the fields are unambiguous. Unsupported dietary information remains unspecified.
Descriptions are source text, never interpreted as instructions or rendered HTML.
`recipeInstructions`, nutrition, timings and mutable cook history are not mapped.

Arrays preserve their order. Object keys are visited in sorted order for stable
nested traversal. Identical mapped drafts are deduplicated in first-seen order;
distinct candidates remain available to a future chooser. Only explicit Recipe
types in JSON-LD scripts count; page titles and ordinary JavaScript are not
fallback sources. JSON decoding uses Foundation and nesting traversal stops at
64 levels. A named Recipe with no ingredient metadata is still a usable draft.

## Network contract

- Accept HTTP(S) public website URLs without embedded credentials. Reject local
  names, noncanonical numeric IPv4, private, loopback, link-local, multicast,
  documentation and other excluded address ranges. All DNS answers must pass.
- Check the destination before the first request and every redirect. Automatic
  URLSession redirects are disabled; at most five redirects are followed.
- Use an ephemeral session with no cookie storage, credential storage or cache.
- Require a successful HTTP response with `text/html` or `application/xhtml+xml`.
  Redirect and error bodies are not read. No anti-bot bypass or login is attempted.
- Enforce a 2 MiB HTML body limit while streaming, not after an unbounded download.
  Declared oversized bodies are rejected before reading. Parsing is also bounded
  to 2 MiB of decoded UTF-8 HTML.
- Allow 20 seconds of request inactivity and 60 seconds overall, including DNS
  waiting and redirects. Cancellation propagates. A cancelled DNS wait releases
  the caller immediately; the system lookup may finish later and frees its own
  resources, but its result can no longer continue the request.
- Preserve App Transport Security. Plain HTTP can be rejected by iOS; report an
  HTTPS suggestion rather than weaken the app's transport policy.

DNS is preflight validation, **not connection address pinning**: URLSession
performs its own connection resolution, so a malicious DNS rebinding race is not
eliminated by these checks. No server-side proxy is involved. A future requirement
for connection-level pinning needs a separately reviewed transport design.
Image metadata receives syntactic URL checks only because it is not fetched;
any future image downloader must apply its own destination checks.

## Scanner and encoding limits

The scanner handles HTML comments, quoted/unquoted attributes, case differences,
attribute ordering, MIME parameters, duplicate attributes (first value wins),
and raw-text elements so script-like text in common inert contexts is ignored.
It neither builds a DOM nor executes scripts. Script contents remain raw JSON;
HTML entity decoding would corrupt valid JSON text. Malformed JSON blocks are
skipped independently so later valid blocks can be used. An unclosed script or
quoted tag is conservatively ignored to the end of the input.

Supported encodings are UTF-8 (including BOM), ASCII, ISO-8859-1 and Windows-1252
when declared by the HTTP Content-Type. Without a charset, UTF-8 is required.
There is no HTML meta-charset sniffing, arbitrary entity/namespace processing,
remote JSON-LD context expansion, DOM recovery or full browser parsing. JSON-LD
generated only after JavaScript execution, login/anti-bot walls, social/video
sites and non-JSON-LD recipe formats are unsupported.

## Fixture matrix and validation

These small, original HTML fixtures model common public Schema.org publishing
patterns. They do not contain copied site pages, personal data or live network
dependencies, and do not certify compatibility with an entire named website.

| Fixture | Pattern exercised |
| --- | --- |
| `single-recipe.html` | A direct Recipe object, common to recipe-plugin output; ordered ingredient strings, explicit diet and ImageObject metadata |
| `graph-recipes.html` | SEO-style `@graph`, nested WebPage/mainEntity, type arrays, multiple candidates/scripts and malformed neighboring data |
| `scanner-traps.html` | Comments, quoted script-like text, raw-text elements, duplicate attributes, external scripts and closing-tag boundaries |

Swift Testing covers extraction and mapping, address classes and DNS answers,
redirect policy, HTTP/content-type errors, encoding, cancellation and timeout.
URLProtocol fixtures additionally exercise the real URLSession streaming client,
automatic redirect blocking and both declared/streamed body limits without the
internet. Run the Mac `buildForTesting` and full `runUnitTests` lanes for the
exact implementation commit before claiming validation. Live-site compatibility
and the user-facing import experience remain follow-up work (#68–#69).
