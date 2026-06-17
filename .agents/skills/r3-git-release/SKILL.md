---
name: r3-git-release
description: >
    Create a versioned release: analyzes commits since the last tag to suggest the right
    bump (patch/minor/major), proposes a release candidate (-rc.N) when applicable, updates
    the repo's version file per language (package.json, Directory.Build.props or .csproj,
    Cargo.toml, pyproject.toml, pubspec.yaml, VERSION), always creates the
    `chore(release): vX.Y.Z` commit and the git tag. Use when the user says "create a
    release", "crea un release", "tagea la versión", "bump de versión", "quiero publicar",
    or asks what version the next release should be.
allowed-tools: [Bash, Read, Edit]
user-invocable: true
---

# r3-git-release — Versioned release

Reads the repo's current state, suggests the next version, and creates the release commit +
tag after user confirmation.

## Steps

### Step 0 — Artifact audit (r3 workspace only)

If the repo being released is the r3 workspace (`AGENTS.md` and `.agents/skills/` exist at
the root), run the `r3-artifact-audit` skill first:

- If the audit reports **errors**, stop the release and show them. Do not continue until resolved.
- If it only reports **warnings**, show them and ask the user whether to continue.
- In any other repo, skip this step.

### Step 1 — Verify environment and read current version

Detect the repo's version file by probing in this order — the first that exists and contains
a version wins:

| Order | Type       | Version file                              | Read version                                                           |
| ----- | ---------- | ----------------------------------------- | ---------------------------------------------------------------------- |
| 1     | `node`     | `package.json`                            | `jq -r '.version' package.json`                                        |
| 2     | `dotnet`   | `Directory.Build.props` with `<Version>`  | `sed -n 's/.*<Version>\(.*\)<\/Version>.*/\1/p' Directory.Build.props` |
| 3     | `dotnet`   | fallback: any `*.csproj` with `<Version>` | same `sed` on the found `.csproj`                                      |
| 4     | `rust`     | `Cargo.toml` (`[package]` section)        | `sed -n 's/^version *= *"\(.*\)"/\1/p' Cargo.toml \| head -1`          |
| 5     | `python`   | `pyproject.toml` (`[project]` section)    | `sed -n 's/^version *= *"\(.*\)"/\1/p' pyproject.toml \| head -1`      |
| 6     | `dart`     | `pubspec.yaml` (`version:` field)         | `sed -n 's/^version: *\(.*\)/\1/p' pubspec.yaml \| head -1`            |
| 7     | `go`       | `VERSION` (plain text file)               | `cat VERSION`                                                          |
| 8     | `tag-only` | none of the above                         | use git tags only                                                      |

For **Go** (order 7): the presence of `go.mod` identifies the project as Go, but `go.mod`
does not contain the module version. Look for a `VERSION` file at the root:

```bash
[ -f VERSION ] && cat VERSION
```

If `VERSION` does not exist, treat the repo as `tag-only`. Do not modify `go.mod`.

For the .NET fallback (order 3):

```bash
find . -name "*.csproj" -not -path "*/bin/*" -not -path "*/obj/*" -exec grep -l "<Version>" {} +
```

If more than one `.csproj` declares `<Version>`, ask the user which one is canonical before
continuing.

- **tag-only** → no version file: skip steps 5a/5b and inform the user. The
  `chore(release)` commit is created anyway — it always exists as a separator (see step 5c).

```bash
# Latest version tag
git describe --tags --abbrev=0 2>/dev/null || echo "(no tags)"

# Commits since the last tag (or from the beginning if no tags)
git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --oneline
```

### Step 2 — Determine the bump type

Analyze the commit types present since the last tag:

| Commits found                               | Suggested bump |
| ------------------------------------------- | -------------- |
| At least one with `!` or `BREAKING CHANGE`  | **major**      |
| At least one `feat:` (non-breaking)         | **minor**      |
| Only `fix:`, `refactor:`, `perf:`, `chore:` | **patch**      |
| Only `chore:` / `docs:` / `style:`          | **patch**      |

Compute the new semver version from the current version.

### Step 3 — Evaluate whether a release candidate applies

Suggest `-rc.N` if any of these conditions holds:

- The current version is already an RC (e.g. `2.1.0-rc.2` → suggest `2.1.0-rc.3` or `2.1.0`)
- The suggested bump is **major** or **minor** and there are `feat` commits not fully
  validated (the model may infer this from context or ask the user)
- The user explicitly mentions "rc", "release candidate", "pre-release", or wanting to test
  before publishing

If the previous RC already exists as a tag, increment the number (`-rc.1` → `-rc.2`).

### Step 4 — Present the proposal

**⏸ Release proposal** — show the analysis and wait for confirmation:

```
Current version:  2.0.1
Latest tag:       v2.0.1
New commits:      8 commits since the tag

Analysis:
  feat(products): add bulk edit modal         → minor
  feat(finance):  add receivables export      → minor
  fix(auth):      handle token refresh race   → patch
  chore(deps):    update @aricore to 3.1.4    → patch

Suggested bump: minor (2 feat commits, no breaking changes)

Proposal:
  New version:  2.1.0
  Commit:       chore(release): v2.1.0
  Tag:          v2.1.0

Alternatives:
  • 2.1.0-rc.1  → if you want a release candidate first
  • 2.0.2       → if you prefer to patch only (ignore the feats)

Proceed with 2.1.0? Or do you prefer another option?
```

If the user picks an alternative or writes a custom version, use that.

### Step 5 — Execute the release

Once the version is confirmed:

**5a. Update the version file** (per the type detected in step 1):

- **node** → edit the `"version"` line in `package.json`.
- **dotnet** → edit the `<Version>` value in `Directory.Build.props` or the detected `.csproj`.
- **rust** → edit `version` in the `[package]` section of `Cargo.toml`.
- **python** → edit `version` in the `[project]` section of `pyproject.toml`.
- **dart** → edit the `version:` line in `pubspec.yaml`.
- **go** → overwrite the contents of `VERSION` with the new version (number only, no `v`).
- **tag-only** → skip this step.

**5b. Update the lockfile** (only if the lockfile includes the package's own version):

- **node** → `package-lock.json`: edit the root `"version"` and the package's entry in `"packages"`, both with the same version.
- **rust** → `Cargo.lock`: edit the crate's own `[[package]]` entry.
- **others** → not applicable.

**5c. Create the release commit** — **always**, whether or not a version file exists; the
`chore(release)` commit is the release separator in the history:

```bash
git add <modified-version-files>
git commit -m "chore(release): v<version>"
```

If the repo is **tag-only** (no version file), create the empty separator commit:

```bash
git commit --allow-empty -m "chore(release): v<version>"
```

**5d. Create the tag**:

```bash
git tag -a v<version> -m "v<version>"
```

**5e. Confirm**:

```bash
git log --oneline -3
git tag --list "v*" | sort -V | tail -5
```

Show the latest commits and tags so the user sees the result.

## Constraints

- The tag is **local** until the user runs `git push --follow-tags`. Do not push
  automatically. The `--follow-tags` flag pushes the release commit and its annotated tag in
  a single command.
- The tag format is always `v{major}.{minor}.{patch}` (lowercase `v`).
- Do not add `Co-Authored-By` or a body to the release commit.
- If the current branch is not `main` or `dev`, warn before proceeding — it could be
  intentional (releasing from a release branch) but it is worth confirming.
