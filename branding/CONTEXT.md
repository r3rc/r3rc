# r3 Branding — Contexto de sesiones

Archivo de tracking. Documenta decisiones tomadas, pendientes, y el estado actual del sistema de marca.

---

## Estado del directorio

```
branding/
├── tokens.css              ← fuente de verdad del sistema visual (light + dark)
├── index.html              ← brand guide completo (§01–§06)
├── pencil-prompt.md        ← prompt para pencil.dev (portfolio)
├── CONTEXT.md              ← este archivo
└── cv/
    └── RARR_CV_17_06_2026.html   ← versión actual
```

---

## Decisiones tomadas ✅

### Sistema visual
- **Paleta**: Warm Stone + Burgundy para light. Oscuro cálido + Near-white para dark.
  Implementado con `light-dark()` en `tokens.css` — responde a `prefers-color-scheme`.
- **Forzar modo en cada artefacto**: `html { color-scheme: light }` en CV y documentos de impresión.
  `html { color-scheme: dark }` en el website.
- **Token nuevo**: `--outline-mid` — borde intermedio, útil en ambos modos.
- **Tipografía**: Satoshi (display/body) + JetBrains Mono (técnico/mono)
- **Iconografía**: Lucide outline, stroke 1.5px
- **Tagline**: "Construyo lo que no existe — o no encaja." — en español, no traducir
- **Wordmark**: `r3rc` lowercase siempre, nunca `R3`
- **Scope npm**: `@r3rc/*` · **Scope JSR**: `@r3/*`
- **Org GitHub**: `@we-r3` (reservado para colaboraciones)

### Website (r3rc.dev)
- Dominio: `r3rc.dev`
- Deploy: Cloudflare Pages, HTML estático
- `color-scheme: dark` en el root — paleta oscura activada
- Sin tracking, sin analytics, sin newsletter
- El CV vive en `/cv` como archivo HTML separado
- Contenido V1: hero, now, proyectos (@r3rc/tinker + @r3rc/srce), contacto
- Proyectos excluidos de V1:
  - `@r3rc/ssh2` — no justificable aún
  - `@r3/clip` — deprecado en favor de citty (unjs)
  - `@r3/jarvis` — en diseño, no runnable

### pencil.dev
- Prompt generado y guardado en `pencil-prompt.md`
- Incluye: identidad, paleta dark, tipografía, personalidad, contenido
- Layout no restringido — lo define la IA

### CV (RARR_CV_17_06_2026.html)
- Fuerza light mode: `html { color-scheme: light }`
- `@r3/clip` eliminado (deprecado)
- `@r3rc/ssh2` eliminado (no justificable aún)
- Crypto de tinker: AES-256-GCM + PBKDF2-SHA256 (200k iterations) — confirmado
- Pendiente borrar el archivo viejo: `RARR_CV_26_04_2026.html`

---

## Decisiones pendientes ⏳

### CV — revisión de contenido (diferida)
- Skills: verificar si Zig y PHP siguen siendo relevantes para mostrar
- Verificar si agregar Go (Zenit backend usa Go + Fuego)
- Posibles adiciones de experiencia desde abril 2026
- Posibles proyectos freelance a incluir (Cheva, Zenit, Noos)

---

## Paleta dark (activa en tokens.css)

```
light-dark(light,         dark)
--surface:        #FAF8F5,  #0B0908
--surface-pure:   #FFFFFF,  #131110
--surface-2:      #F2EFE9,  #1C1916
--on-surface:     #1A1A1A,  #EDE8E0
--on-surface-muted:  #5C5853,  #706860
--on-surface-subtle: #A8A39C,  #362E28
--outline:        #E8E2D9,  #1E1A16
--outline-mid:    #CFC9BF,  #2C2620
--outline-strong: #1A1A1A,  #EDE8E0
--accent:         #8B1F2C,  #9E2535
--accent-soft:    8% opacity, 14% opacity
```

---

## Prototipos generados (en Linux `/home/r3rc/Development/Branding/`)
> No están en esta máquina. Son exploraciones, no artefactos canónicos.

- `prototype/concept-e.html` — Night (paleta oscura cálida)
- `prototype/v2.html` — sidebar fijo + hero full-width, dark ← el más avanzado
