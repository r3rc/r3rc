# Rule: Rust crate structure & idioms

Applies to **any Rust crate** — library or binary, standalone or in a Cargo workspace. Project-agnostic.

Distilled from Apollo's Rust Best Practices Handbook (skill `rust-best-practices`) and cross-checked against
two production multi-crate workspaces (OpenAI `codex-rs`, Microsoft `litebox`). Read the skill's chapters when a
point here needs depth. Verify any third-party API against its real source, never from memory.

> Assumes edition 2024 (both reference workspaces use it). `let-else`, `#[expect(...)]`, `LazyLock`/`OnceLock`
> are stable — use them.

---

## Crate layout

```
mycrate/
├── Cargo.toml
└── src/
    ├── lib.rs            //! crate-level docs + module decls + curated re-exports
    ├── error.rs          public error enum (thiserror)
    ├── <concept>.rs       one module per cohesive concept (types + their impls together)
    └── internal/         non-public implementation detail (not re-exported)
```

- **Organize by concept, not by technical role.** Do **not** create `domain/`, `infrastructure/`,
  `services/`, `repositories/` folders — that is application architecture, not a Rust crate. A type lives with
  its `impl` and its small helpers in one module, not split across a `models/` and a `logic/` tree.
- **Prefer `foo.rs` over `foo/mod.rs`** for single-file modules (both reference workspaces do); a single-file
  private module is `internal.rs`, not `internal/mod.rs`. Use a `foo/` directory only when the module genuinely
  has submodules.
- **`lib.rs` is the table of contents:** `//!` docs, `mod` declarations, and a curated set of `pub use`
  re-exports that form the public surface. No business logic in `lib.rs`.
- **`main.rs` stays thin.** A binary crate parses args, wires dependencies, and maps errors to exit codes;
  testable logic lives behind functions/modules (often a sibling `lib.rs`) so it can be unit-tested.
- Keep files to a readable size; when a module sprawls, split by concept rather than letting one file grow.

## Visibility & API surface

- Default to private. Make `pub` only what consumers need; prefer `pub(crate)` for cross-module internals.
- Re-export the public API from `lib.rs` with `pub use` so consumers import from the crate root, not deep paths.
- Keep foundational/shared crates dependency-light. A crate that every other crate depends on should not drag
  heavy transitive dependencies (DB drivers, async runtimes, ML frameworks) into otherwise-thin consumers.

## Workspace hygiene

- **Centralize versions in `[workspace.dependencies]`.** Declare every external dependency _and_ every internal
  path crate there once; members reference them with `dep.workspace = true`. This kills version drift across
  crates.
- **Members inherit package metadata:** `version.workspace = true`, `edition.workspace = true`,
  `license.workspace = true` from `[workspace.package]`.
- **Split crates by responsibility, with a consistent prefix naming scheme** (e.g. `myapp_core`,
  `myapp_platform_*`, `myapp_runner_*`). The split should mirror real boundaries (layer, platform, role), not
  be arbitrary. The name should tell you the crate's job.
- **`default-members`** excludes crates that need a special toolchain/target (e.g. nightly, cross-compile) so a
  plain `cargo build` at the root stays green for everyone.
- **Dev-only crates** (integration-test harnesses, benches) can be workspace members but should be named/marked
  so they are clearly **not published** (`publish = false`).
- Set `resolver = "2"` or `"3"` explicitly at the workspace root.

## Error handling (hard rules)

- **Fallible functions return `Result<T, E>`** — never `panic!` in library/production paths. `panic!`,
  `todo!()`, `unreachable!()`, `unimplemented!()` are for tests, provable invariants, or genuine bugs only.
- **No `.unwrap()` / `.expect()` outside `#[cfg(test)]`.** Use `?`, `let Ok(v) = … else { … }`,
  `unwrap_or_else`, `ok_or_else`, `map_err`, `inspect_err`. (codex denies both via clippy `unwrap_used` /
  `expect_used`.)
- **Libraries use `thiserror`; binaries/app crates may use `anyhow`.** `anyhow` erases type information — never
  in a crate meant to be a reusable library. One `thiserror` enum per crate (`error.rs`); compose lower-level
  errors with `#[from]`:

    ```rust
    #[derive(Debug, thiserror::Error)]
    pub enum StoreError {
        #[error("not found: {0}")]
        NotFound(String),
        #[error(transparent)]
        Io(#[from] std::io::Error),
    }
    ```

- Async error types crossing `.await` must be `Send + Sync + 'static`. Avoid `Box<dyn std::error::Error>` in
  libraries.
- Tests must exercise error paths, not just the happy path.

## Borrowing, cloning, performance

- **Prefer `&T` over `.clone()`.** Take `&str` not `String`, `&[T]` not `Vec<T>` in parameters. Don't clone a
  reference to gain ownership — change the signature to require ownership.
- **Never clone inside a loop.** Use `.cloned()` / `.copied()` at the end of an iterator chain if needed.
- Clone at the last possible moment. Use `Cow<'_, str>` / `Cow<'_, [T]>` when ownership is genuinely ambiguous.
- `Copy` only when every field is `Copy` and the type is small (≤ ~24 bytes / 3 words). Never `Copy` a type
  holding `String`/`Vec`/large arrays.
- Prefer iterators over manual loops; avoid an intermediate `.collect()` you immediately re-iterate. Don't reach
  for `#[inline]` or any micro-optimization without a `--release` benchmark proving a real (> ~5%) gain.

## Generics vs dispatch

- **Start with static dispatch** (`impl Trait`, `<T: Trait>`) — zero runtime cost; the default for trait seams.
- Reach for `dyn Trait` only for runtime polymorphism or heterogeneous collections. Prefer `&dyn Trait`, then
  `Arc<dyn Trait>` for thread-shared. **Box at API boundaries, not inside structs prematurely.**
- Keep trait-object traits object-safe (no generic methods, no `-> Self`).
- Type-state (`PhantomData<State>`) is allowed for state-heavy APIs (builders, protocol clients) where it
  removes runtime checks — not for trivial states where an enum is clearer.

## Concurrency / pointer cheat-sheet

- Ownership: `Box<T>` (single owner / recursive types), `Arc<T>` across threads, `Rc<T>` single-thread only.
  Shared **mutable** across threads: `Arc<Mutex<T>>`, or `Arc<RwLock<T>>` when read-heavy. `Rc`/`RefCell`/`Cell`
  are not `Send`/`Sync` — never across threads.
- Thread-safe lazy/once init for statics: `OnceLock` / `LazyLock` (not `lazy_static`).
- **Never hold a lock across an `.await`** (codex sets clippy `await_holding_lock = "deny"`).
- Raw pointers (`*const`/`*mut`) only behind `unsafe` for FFI/low-level work, each with a `// SAFETY:` comment
  (see Comments & documentation).

## Comments & documentation

- Comments explain **why**, not what. Prefix `// SAFETY:` above any `unsafe`, `// PERF:` for non-obvious
  performance choices (link the design note). Refactor obvious code into named functions instead of narrating it.
- **No orphan `// TODO:`** — link a tracked issue: `// TODO(#NN): …`. Update or delete stale comments on sight.
- Every public item gets a `///` doc: _what it does → `# Examples` → `# Errors`/`# Panics`/`# Safety`_ as
  applicable. Crate/module purpose goes in `//!` at the top of `lib.rs` / the module file.

## Testing

- Unit tests live in-module under `#[cfg(test)] mod tests`; integration tests in `tests/` hit only the public API.
- Name tests as sentences describing the behavior: `save_should_reject_when_key_has_three_levels`. **One behavior
  asserted per test**; split scenarios into separate tests (use `rstest` cases to avoid duplication).
- Doc examples are tests (`cargo test --doc`) — keep them compiling. Use `insta` for snapshotting structured
  output; redact unstable fields (UUIDs, timestamps); never snapshot bare primitives (use `assert_eq!`).

## Lints — workspace-enforced

Define lints **once** at the workspace root and inherit them in every member via `[lints] workspace = true`.
Two proven strategies (pick one and be consistent):

**A — explicit allowlist** (codex style): start from a curated set of specific lints at `deny`. Precise, no noise.

```toml
[workspace.lints.clippy]
unwrap_used        = "deny"
expect_used        = "deny"
redundant_clone    = "deny"
clone_on_copy      = "deny"
needless_collect   = "deny"
await_holding_lock = "deny"
uninlined_format_args        = "deny"
trivially_copy_pass_by_ref   = "deny"
manual_ok_or = "deny"        # + the manual_* family
large_enum_variant = "warn"
```

**B — group then carve out** (litebox style): opt into a broad group at lower priority, then `allow` the few
that are too noisy. The group **must** have `priority = -1` so specific lints override it.

```toml
[workspace.lints.clippy]
pedantic           = { level = "warn", priority = -1 }
missing_errors_doc = "allow"
must_use_candidate = "allow"
too_many_lines     = "allow"
```

Either way, in **each** member crate:

```toml
[lints]
workspace = true
```

- CI / pre-commit must run: `cargo clippy --all-targets --all-features --locked -- -D warnings`.
- Use `bacon` (`default_job = "clippy"`) for a continuous check/clippy loop during development.
- Use `cargo-shear` (or `cargo-machete`) to catch unused dependencies; silence false positives explicitly.
- Silence a lint only with `#[expect(clippy::lint_name)]` (never bare `#[allow]`) plus a one-line reason.
- For libraries, require docs across the three lint tables: `[workspace.lints.rust] missing_docs`,
  `[workspace.lints.clippy] missing_panics_doc` / `missing_safety_doc`, and
  `[workspace.lints.rustdoc] broken_intra_doc_links`.

## Imports

- Order: `std` → external crates → workspace crates → `crate::`/`super::`, enforced by
  `group_imports = "StdExternalCrate"`.
- **Use `imports_granularity = "Item"`** (one `use` per item): cleanest diffs and `git blame`. codex uses it;
  litebox leaves rustfmt at defaults. Both options are nightly-only rustfmt settings, applied via
  `cargo +nightly fmt`.

## What NOT to do

```
// Wrong — Clean-Architecture folders in a Rust crate
mycrate/src/
├── domain/
├── infrastructure/
├── repositories/
└── services/

// Wrong — panicking library code / needless ownership
let row = store.get(id).unwrap();      // forbidden outside tests
fn save(w: Widget) { ... }             // takes ownership it doesn't need → take &Widget

// Right — concept modules, Result-returning API, borrowing
mycrate/src/
├── lib.rs        // pub use of the public surface
├── error.rs      // thiserror StoreError
├── widget.rs
└── internal/

let row = store.get(id)?;              // propagate
fn render(w: &Widget) -> String { ... }
```
