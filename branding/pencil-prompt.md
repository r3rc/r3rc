# Prompt — pencil.dev portfolio

> Generado en sesión de trabajo. Usarlo directamente en pencil.dev para construir el portfolio personal.

---

Build a personal portfolio website for Renzo A. Rosas — a Senior Frontend Engineer & Tech Lead based in Lima, Perú.

---

## IDENTITY

Name: Renzo A. Rosas
Handle: r3rc — wordmark is lowercase "r3rc"
Role: Senior Frontend Engineer · Tech Lead
Tagline: "Construyo lo que no existe — o no encaja."
Location: Lima, Perú · UTC−5 · Available for remote work (LatAm)
Links: github.com/r3rc · linkedin.com/in/r3rc · renzo.r3rc@gmail.com
CV: r3rc.dev/cv

---

## COLORS

Background: #0B0908
Surface elevated: #131110
Text primary: #EDE8E0
Text muted: #706860
Text subtle: #362E28
Border soft: #1E1A16
Border mid: #2C2620
Accent (Burgundy): #9E2535 — use SPARINGLY, max 3–4 places total
Accent background tint: rgba(158, 37, 53, 0.14)

---

## TYPOGRAPHY

Display / Body: Satoshi (from Fontshare: api.fontshare.com) — weights 400, 500, 700
Mono / Technical: JetBrains Mono (Google Fonts) — weights 400, 500

Usage rules:
- Satoshi for: tagline, body copy, descriptions, headings
- JetBrains Mono for: package names (@r3rc/srce), dates, labels, nav items, contact info, code snippets, section markers
- Section labels: JetBrains Mono, 10–11px, all-caps, letter-spacing 0.16–0.2em, muted color
- Code inline: JetBrains Mono, burgundy-tinted background, accent color text

---

## PERSONALITY

This is NOT a flat résumé translated to HTML. Renzo builds developer tools and libraries — private package registries, CLI toolkits, workspace automation — but his core is frontend. The site itself must demonstrate frontend craft.

That means: intentional interactions, purposeful hover states, transitions that feel engineered not decorative. The kind of site where you notice the details if you look for them, but they don't demand attention. It should feel alive.

Voice: direct, technical, no filler words. He doesn't say "passionate about", he says what he built and why it matters.

Avoid: gradients for the sake of gradients, icon-heavy sections, anything that looks like a Tailwind UI template, purple or blue accents.

---

## CONTENT

### Tagline (hero)
"Construyo lo que no existe — o no encaja."
"no encaja" should visually stand apart — it's the emotional core of the line.

### Now
What I'm building right now:
- @r3rc/srce: private package registry for Deno and Bun. JSR-style imports, scoped tokens per package, symlinks mode for local dev. Zero external services — SQLite + filesystem. Single binary. The self-hosted alternative when you don't want to pay or depend on anyone.
- At Arigroup: expanding the MCP server for the internal design system — now at 12 tools exposing the full technical catalog to the team.
- Next in queue: vpsctl — declarative TypeScript deployment tool for self-hosted VPS.

### Projects

@r3rc/tinker
Tagline: "Workspace toolkit. Secrets, profiles, SSH — no cloud."
Description: CLI for daily developer use. Secrets encrypted with Argon2id + AES-256-GCM. Environment profiles with inline secret resolution ($secret:NAME). SSH key management. Reference sources for study. Everything local. Zero external services.
Status: stable
Stack: Deno, TypeScript
Repo: github.com/r3rc/r3

@r3rc/srce
Tagline: "Private package registry for Deno and Bun."
Description: JSR-style imports (@scope/package@version/file.ts), scoped tokens per package, symlinks mode for local development. Zero external services — SQLite + filesystem. The self-hosted alternative when you don't want to pay or depend on anyone.
Status: in development
Stack: Deno, h3, SQLite
Repo: github.com/r3rc/srce

### Contact
Email: renzo.r3rc@gmail.com
GitHub: github.com/r3rc
LinkedIn: linkedin.com/in/r3rc
Location: Lima, Perú · UTC−5
Availability: Remote LatAm

---

## TECHNICAL
- Static HTML + CSS + minimal vanilla JS
- No framework required
- Fonts: Fontshare (Satoshi) + Google Fonts (JetBrains Mono)
- No tracking, no analytics, no newsletter
- Deployable to Cloudflare Pages
