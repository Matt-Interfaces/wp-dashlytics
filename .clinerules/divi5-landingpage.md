# Divi 5 Landing Page Rules (matt-interfaces.ch)

## Scope boundary — read this first

This repository (`wp-dashlytics`) is a **Svelte 4 + PHP WordPress plugin project** (see root
`README.md` / `composer.json` / `app/`). The `divi5/` folder is a **self-contained, isolated
zone** for authoring Divi 5 landing/marketing pages on the agency site `matt-interfaces.ch` and
must **never** be treated as part of the plugin's build pipeline, Svelte app, or PHP codebase.

- Never import, require, or reference anything under `divi5/` from `app/`, `includes/`,
  `dashlytics-matomo.php`, or any Svelte component.
- Never run `npm run build` / `composer` tasks against `divi5/` content.
- `divi5/divi5-skill/` is a **vendored read-only reference** (cloned from
  `github.com/divilovewp/divi5-skill`, MIT licensed, `.git` stripped). Do not hand-edit its
  files — if the upstream skill updates, re-clone instead of patching in place.
- Keep all Divi JSON exports, page blueprints, and image-prep scripts inside `divi5/`
  (suggested subfolders: `divi5/pages/`, `divi5/exports/`, `divi5/showcase-optimized/`).

## Future plan (do not build yet — planning note only)

A **separate, standalone website** for the Dashlytics plugin itself (its own domain/property,
likely also Divi 5 or a dedicated landing framework) is planned for later. When that work starts:
- It gets its own repo or its own top-level folder — **not** nested inside `divi5/` here.
- This file's rules still apply for anything authored with the Divi 5 skill, but the content
  strategy (ICP, ruleset below) should be reused/ported, not duplicated ad hoc.

## Divi 5 authoring rules — always attach before generating/editing Divi JSON

Read `divi5/divi5-skill/DIVI5-BASE.md` + `DIVI5-DESIGN-PROCESS.md` first, every time. Core
non-negotiables condensed here so they're never skipped:

1. **Plan before JSON.** Discovery → Page Plan (intent, narrative, blueprint, design system,
   self-critique) before writing any markup (`DIVI5-DESIGN-PROCESS.md` §0b, §12).
2. **Tokens over literals.** Every color/size/spacing/radius references the site's existing
   `gcid-*` / `gvid-*` global variables (already extracted — see `design-system.md` in this
   folder). Never invent new token names; never hardcode hex values that already have a token.
3. **Structural correctness** (`DIVI5-BASE.md` §8 validation checklist):
   - `"context": "et_builder"` root, content wrapped in
     `<!-- wp:divi/placeholder -->...<!-- /wp:divi/placeholder -->`.
   - Every section → row → column chain closed correctly; self-closing modules end ` /-->`.
   - `"builderVersion": "5.12.1"` (matches the live site's active Divi version) on every module.
   - `syncVertical`/`syncHorizontal` are the strings `"on"`/`"off"`, never booleans.
   - Rich text (`divi/text`) is raw HTML, never pre-escaped; heading `innerContent` is plain text
     with `headingLevel` set separately.
   - Button styling lives on `button.decoration`, never on `module.decoration`.
4. **Authoring Self-Audit Gate** (`DIVI5-BASE.md` §9) before calling any page "done":
   - No `divi/code` fakery for real modules (icons, lists, cards).
   - No stray global `<style>` blocks — all styling via module `decoration` + tokens.
   - Copy is verbatim to what was agreed, not paraphrased mid-build.
   - Contrast checked on every text/icon against its actual background, incl. dark cards.
   - Every `gcid-*`/`gvid-*` token referenced actually exists in the site's design system.
5. **Landing-page heuristics** (`DIVI5-DESIGN-PROCESS.md` §8c):
   - Exactly **one H1**, no skipped heading levels.
   - **One primary CTA per section**, high-scent label (never "Learn more" / "Mehr erfahren").
   - Every image has real `alt` text (see SEO/image rules below).
   - ≤2 fonts / ≤3 core colours; no AI-design clichés (rainbow gradients, emoji-as-UI,
     left-border-card default, Inter-everywhere).

## AI-slop avoidance ruleset (copywriting — applies to ALL generated text)

Source: user-provided ruleset ("ai_slop_erkennungsmuster", Felix Beilharz pattern list). Applies
to headlines, body copy, CTAs, FAQ answers, meta descriptions — everywhere. Exclude all 7:

1. **No rhetorical-question-then-self-answer** ("Das Schönste an X? Wenn ...").
2. **No "Genau deshalb / Genau dafür" causal-transition filler.**
3. **No "Nicht X, sondern Y" antithesis split across sentences/paragraphs.**
4. **No staccato one-liner sentence chains** (vary sentence length; combine into real prose).
5. **No one-sentence-per-paragraph formatting** — group related sentences into real paragraphs.
6. **No generic engagement-CTA questions** ("Was denkst du dazu?").
7. **No hashtag clouds** (not applicable to Divi copy, but keep in mind for any social re-use).

Practical check before finalizing any copy block: read it aloud — if it sounds like a
LinkedIn-thought-leader post, rewrite it as normal written German/Swiss-German prose with
concrete nouns, real numbers, and varied sentence length.

## SEO / AIO / Rich Snippets / ARIA checklist (per page)

- **RankMath meta**: focus keyword, SEO title ≤60 chars, meta description ≤160 chars with a CTA,
  canonical URL, OG title/description/image, Twitter card — set via `wp post meta` /
  RankMath's own postmeta keys, never left empty.
- **Permalink**: short, keyword-first, hyphen-separated, matching the site's existing slug
  convention (see live page list in `design-system.md`).
- **Schema.org**: FAQPage schema for any FAQ/toggle-accordion section (Divi's native toggle
  module already supports this pattern on the reference page); SoftwareApplication/Product
  schema for the plugin itself via RankMath's schema generator or custom schema meta.
- **ARIA**: rely on Divi's native accessible modules (toggle, breadcrumbs, accordion) — they
  already ship correct ARIA attributes. Set `htmlAttributes.desktop.value.id` (breakpoint
  OUTERMOST — see `DIVI5-BASE.md` known caveat) for every in-page anchor target
  (`#beratung`, `#faq`, etc.).
- **Images**: WebP, SEO filename (keyword + hyphens, no stopwords), real `alt` (descriptive +
  keyword, ≤125 chars, never keyword-stuffed), `title` attribute distinct from `alt`, caption
  written as a benefit statement, not a feature label. Convert and rename BEFORE uploading to
  the WordPress media library — never rename after import (breaks existing URLs).

## Page creation via WP-CLI/SSH (matt-interfaces.ch on kasserver)

Required meta on every new Divi 5 page (see `DIVI5-WORDPRESS.md` §1) — use the **non-blank**
template combination so Theme Builder header/footer chrome is preserved:

```
_et_pb_use_builder   = on
_et_pb_use_divi_5    = on
_et_pb_page_layout   = et_full_width_page
```
`_wp_page_template` stays default/empty — **do not** use `page-template-blank.php` (it
suppresses the site's Theme Builder header/footer).

New pages are created as `post_status = draft` by default — the user reviews manually in
wp-admin before publishing (confirmed working agreement, do not auto-publish).
