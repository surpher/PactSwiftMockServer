# Known issues — broken or stale as of 2026-07-25

An audit of the repository as it stands on `main` (`89f3fc3`), before the move to the
`pact-foundation` organisation. Items are grouped by severity, not by file.

Scope: things that are **broken or stale right now**. Organisation-move tasks (renaming
owners, moving the XCFramework repo, recreating secrets, adding community health files) are
deliberately **not** listed here.

Legend: 🔴 blocker · 🟠 should fix before handover · 🟡 tidy-up

---

## 🔴 Blockers

### 1. Root `Package.swift` does not compile

`swift package dump-package` fails outright:

```
Package.swift:9:6: error: type 'SupportedPlatform' has no member 'linux'
```

Two independent problems:

- [`Package.swift:9`](../Package.swift#L9) — `platforms: [.linux]`. `SupportedPlatform` has no
  `.linux` case; Linux is implicit and cannot be declared. Any SwiftPM version will reject this.
- [`Package.swift:37`](../Package.swift#L37) — the `PactSwiftMockServerLinux` target depends on
  `"PactMockServer"`, which is **not declared anywhere** in the manifest. There is no
  `systemLibrary` target, no module map, and no `Sources/PactMockServer` directory. The Swift
  sources reference it under `#if SWIFT_PACKAGE` (e.g.
  [`Sources/MockServer.swift:11`](../Sources/MockServer.swift#L11)), so the module was clearly
  intended to exist at some point.

The Apple-platform build is driven entirely by `PactSwiftMockServer.xcodeproj`, so nothing in CI
or the release path touches this manifest — which is exactly why it rotted unnoticed.

**Decision needed:** is Linux support still a goal? If yes, this needs a `systemLibrary` target
plus a module map and a story for producing `libpact_ffi.a` on Linux. If no, delete the manifest
and the `#if SWIFT_PACKAGE` branches. Leaving a non-compiling manifest in the repository root is
the worst of the three options — anyone who opens the folder in Xcode or runs `swift build` hits
it first.

### 2. Pull requests are never built or tested

- [`.github/workflows/test.yml`](../.github/workflows/test.yml) triggers only on
  `workflow_dispatch` and `push` to `run-on-ci/**`. There is no `pull_request` trigger.
- [`.github/workflows/pr.yml`](../.github/workflows/pr.yml) fires on `pull_request: [closed]`
  and, if merged, **creates a GitHub release and tag**.

Net effect: a release can be cut from a PR that CI has never seen. The release-candidate branch
the `release` script creates is named `rc/<tag>`, which does not match `run-on-ci/**` either, so
the release path specifically is the one that goes untested.

**Suggested fix:** add a `pull_request` trigger to `test.yml`, and gate `pr.yml` on it.

---

## 🟠 Should fix before handover

### 3. Deployment targets disagree three ways

For each platform there are three different minimums, set in three places that never cross-check:

| Platform | `Configurations/*.xcconfig` | `build_rust_dependencies` | `XCFramework/Package.swift` |
|---|---|---|---|
| iOS | `13.0` | `15.0` | `.iOS(.v15)` |
| macOS | `12.0` | `14.0` | `.macOS(.v13)` |

Sources:
[`Target-iOS-Shared.xcconfig:3`](../Configurations/Target-iOS-Shared.xcconfig#L3),
[`Target-macOS-Shared.xcconfig:6`](../Configurations/Target-macOS-Shared.xcconfig#L6),
[`Config/config.sh:10-11`](../Support/Scripts/Config/config.sh#L10),
[`build_rust_dependencies:240-246`](../Support/Scripts/CI/build_rust_dependencies#L240),
[`XCFramework/Package.swift`](../XCFramework/Package.swift).

Note that `config.sh` declares `IPHONEOS_DEPLOYMENT_TARGET=13.0` / `MACOSX_DEPLOYMENT_TARGET=12.0`
and `build_xcframework` passes those to `xcodebuild`, while the Rust static libraries underneath
were compiled against 15.0 / 14.0. The framework therefore *claims* support for OS versions its
own dependency was not built for.

#### Upgraded 🟠 → 🔴 on 2026-07-25 — confirmed, not theoretical

Archiving both iOS schemes against `libpact_ffi` 0.5.4 emits **255 (device) + 256 (simulator)
linker warnings**, all of this form:

```
ld: warning: object file (…/iOS-simulator/libpact_ffi.a[10](…rcgu.o)) was built for
newer 'iOS-simulator' version (15.0) than being linked (13.0)
```

So this is not a cosmetic inconsistency: a released XCFramework advertises iOS 13 support while the
static library inside it requires iOS 15. A consumer deploying to iOS 13 or 14 gets undefined
behaviour at runtime rather than a clean build failure. The same warnings will appear for macOS
(12.0 linked vs 14.0 built) once the macOS archive runs.

**Suggested fix:** pick one number per platform, define it once in `config.sh`, and have the
xcconfigs and the published manifest derive from it. The published
`XCFramework/Package.swift` already declares `.iOS(.v15)`, so raising the xcconfigs to `15.0` is
strictly *more* honest than the status quo and breaks no SwiftPM consumer — it only stops the
project claiming support it never had. Worth calling out as a minimum-version bump in the changelog.

### 4. README build badge points at a workflow that does not exist

[`README.md:3`](../README.md#L3) references `actions/workflows/build_test.yml`. The file is
`test.yml`. The badge renders as "no status".

### 5. `configure_build_tools` misses two required tools

[`Support/Scripts/CI/configure_build_tools:43-48`](../Support/Scripts/CI/configure_build_tools#L43)
installs `cbindgen`, `doxygen`, `xcbeautify`, `swiftlint`. Missing:

- **`cmake`** — [`build_rust_dependencies:253`](../Support/Scripts/CI/build_rust_dependencies#L253)
  runs `cmake .. && cmake --build .`, and line 93 shells out to `cmake --version` while logging
  the build environment. Under `set -eu` that logging call fails the script before the real build.
- **`jq`** — [`version_numbers.sh:25`](../Support/Scripts/CI/version_numbers.sh#L25) pipes the
  GitHub tags API through `jq -r`. Without it, `latest_tag` returns empty and
  `generate_version_number` silently falls back to `v0.0.0`, so the next release would be
  computed as `v0.0.1` rather than a real bump.

CI happens to pass today because GitHub's macOS runners preinstall both. A fresh developer
machine following the documented setup will not.

Also undocumented as prerequisites, though not installable via this script: full Xcode (not just
Command Line Tools — [`build_rust_dependencies:142`](../Support/Scripts/CI/build_rust_dependencies#L142)
now checks), `gh`, and **a GPG signing key** — the release script commits with `-S`
([`release:150`](../Support/Scripts/release#L150), [`:187`](../Support/Scripts/release#L187),
[`:206`](../Support/Scripts/release#L206)) and will abort mid-release without one.

`doxygen` is installed but never used anywhere in the repository — safe to drop.

### 6. Contradictory iOS-device binary handling

[`build_rust_dependencies:266-271`](../Support/Scripts/CI/build_rust_dependencies#L266) copies the
`aarch64-apple-ios` binary into `Resources/iOS-device/`, then immediately prints:

```
warning: iOS device binary is not copied as it fails to build from Rust file...
```

Both cannot be true. The device build at line 243 does run. Either the warning is a leftover from
when the build was broken, or the copy is a leftover from before the warning. Related: the
`log_binary_validation` call at line 292 is commented out, and the function itself
(lines 108-137) has its iOS-device branches commented out too.

**Action:** confirm the device build works, then delete whichever half is dead.

### 7. `Resources/libpact_ffi.md` describes a build that no longer exists

[`Resources/libpact_ffi.md`](../Resources/libpact_ffi.md) says to commit **x86_64 slices only**
because of GitHub's 100 MB file limit, and closes with "Once the CI runners move to M1 machines,
we might reconsider and replace with arm64 slices."

Current reality: the build produces **arm64 only** (three targets, no x86_64 anywhere in
[`rust_config.sh:35-43`](../Support/Scripts/Config/rust_config.sh#L35)), the binaries are
gitignored rather than committed ([`.gitignore`](../.gitignore) — `Resources/**/*.a`), and CI
already runs on Apple Silicon. Its title also names the wrong library
(`libpact_mock_server.a` → `libpact_ffi.a`), and it points at `./Support/build_rust_dependencies`,
which has since moved to `./Support/Scripts/CI/build_rust_dependencies`.

This file is the most misleading document in the repository right now. Rewrite or delete it —
its useful content (the required folder layout) belongs in the new build docs.

### 8. `lint_project` references the wrong filename

[`Support/Scripts/BuildPhase/lint_project:9`](../Support/Scripts/BuildPhase/lint_project#L9)
invokes `"${SCRIPT_DIR}/SwiftLint"`; the file on disk is `swiftlint` (lowercase). This works only
because macOS APFS is case-insensitive by default. It breaks on a case-sensitive volume — which
some developers do use for exactly this class of bug, and which Linux CI would hit.

The script is wired into all three framework targets as a build phase
(`project.pbxproj:748`, `:767`, `:786`).

Secondary: the same line logs `$PROJECT_NAME`, which Xcode injects into build phases but which is
unset when the script is run by hand — under `set -eu` that is an immediate failure.

---

## 🟡 Tidy-up

### 9. `tmpl_test_macos15.yml` is labelled macOS 14

[`.github/workflows/tmpl_test_macos15.yml`](../.github/workflows/tmpl_test_macos15.yml): the
workflow `name` is `"macOS 14"` and the job id is `testMacOS14`, while it runs on `macos-15` with
Xcode 16.2 and an iPhone 16 Pro simulator. Copy-paste from the macOS 14 template. Makes the
Actions UI show two identically named workflows.

### 10. Duplicated assignment in `build_xcframework`

[`Support/Scripts/CI/build_xcframework:64,66`](../Support/Scripts/CI/build_xcframework#L64) —
`XCFRAMEWORK_VERSION="$1"` appears twice in a row. Harmless, but it is the kind of thing that
makes a reader wonder what they are missing.

### 11. Unused config value

[`Support/Scripts/Config/config.sh:17`](../Support/Scripts/Config/config.sh#L17) —
`XCFRAMEWORK_LOCATION="Framework"` is referenced nowhere in the repository.

### 12. Empty tracked file: `swiftlint.txt`

[`swiftlint.txt`](../swiftlint.txt) is 0 bytes and tracked in git. Presumably an old lint-output
artefact. Note that `.gitignore` already excludes `*.xcfilelist` and `.xcfilelist` for the same
reason; this one predates that.

### 13. Stray `TAG_MESSAGE_FILE.tmp` in the working tree

`TAG_MESSAGE_FILE.tmp` is present in the repository root, left behind by an interrupted release
run. It is untracked (`.gitignore` matches `**/*.tmp`) so git is clean, but the `release` script
appends to this file rather than truncating it
([`release:257`](../Support/Scripts/release#L257) uses `>` for the first write, then `>>`), so a
leftover file can leak into the next release's notes if the flow is re-entered. Delete it, and
consider having the script remove it on exit.

### 14. Release tags may contain spaces

`release -d "some description"` produces a tag like `v1.2.3 - some description`
([`version_numbers.sh:77-79`](../Support/Scripts/CI/version_numbers.sh#L77)). Git permits it, and
`release:386` compensates by substituting `_` when deriving the branch name, but the tag itself,
the release title, and the `.zip` filename all carry the spaces. Recommend dropping `-d`, or
slugifying the description.

### 15. `check_xcode` version comparison is inverted-by-design

[`Support/Scripts/utils.sh:83-104`](../Support/Scripts/utils.sh#L83) —
`__check_xcode_version_number` returns `1` (shell failure) when the version **is** acceptable,
because it returns the arithmetic value of a boolean expression. `check_xcode` then relies on that
inversion in its `elif`. The logic is correct, but it reads as a bug and will be "fixed" into a
real bug by the next person. Worth a comment at minimum, or an explicit `if ... then return 0`.

Related: `MIN_XCODE_VERSION="16.1"` and `XCODE_VERSION_MIN_SUGGESTED="16.1"` in
[`config.sh:6-8`](../Support/Scripts/Config/config.sh#L6) are duplicates of each other, and only
the *major* component of `XCODE_VERSION_MIN_SUGGESTED` is ever compared — so in practice any
Xcode 16.x passes, and 17.x passes trivially. This machine currently has Xcode 26.6.

---

## 🟠 Release script: stash handling

Numbered separately so the item numbers above stay stable. Severity is 🟠 for the group, but
16.1 was a hard blocker until it was fixed.

The `release` script uses **the git stash as a variable**. `stash_changelog` pushes the generated
`CHANGELOG.md`, `stash_apply` immediately restores it, and the entry is then deliberately left in
the stash list so that `cleanup()` can re-apply it after `git checkout --force` has discarded the
working tree. Everything below follows from that one design choice.

### 16.1 `stash{0}` typo — FIXED 2026-07-25

[`release:159`](../Support/Scripts/release#L159) read `git stash apply stash{$stashIndex}`; the
valid ref syntax is `stash@{0}`. Every release run aborted here with
`error: stash{0} is not a valid reference`.

Introduced in `cba0426` ("Improvements to release script"), which lands **after** `b03c7b2` — the
last release that completed. The function therefore never ran successfully once, and the two
release attempts that followed it (v1.1.0, v1.1.1) are precisely the ones left half-finished with
their tags stranded on unmerged `rc/` branches.

Now `git stash apply "stash@{$stashIndex}"` — quoted, because the command is passed through `eval`
inside `executeCommand`.

### 16.2 The stash index is hardcoded and never verified

`stash_changelog` pushes, then `stash_apply 0` and later `cleanup()`'s `stash_apply 0`
([`release:318`](../Support/Scripts/release#L318)) both assume the script's own stash is still at
index `0`. Nothing verifies that. Anything that stashes concurrently — a second terminal, a git
GUI, Xcode's source-control integration — shifts the index, and the script will then apply an
unrelated stash on top of the release and commit the result.

**Suggested fix:** capture the ref by SHA immediately after pushing and use that everywhere:

```bash
git stash push -m "..." -- "$CHANGE_LOG"
STASH_SHA=$(git rev-parse "stash@{0}")   # capture once
...
git stash apply "$STASH_SHA"             # index-independent
```

### 16.3 Stashes accumulate without bound

`git stash apply` intentionally does not drop the entry, and nothing ever drops it afterwards. Each
release run therefore leaves one stash behind permanently. The list is currently **25 deep**,
including two entries both labelled `Updated CHANGELOG.md for v1.1.1` from the abandoned attempts,
plus `WIP on rc/v1.0.0` entries going back to 2021.

**Suggested fix:** `git stash drop` the captured SHA once `cleanup()` has consumed it.

### 16.4 The stash is the wrong mechanism for this

The push/apply pair is a no-op in isolation — it stashes content and immediately puts it back. Its
only purpose is to survive the `git checkout --force` in `cleanup()`. That intent is documented
nowhere in the script, which is why the pair reads as dead code.

**Suggested fix:** write the generated changelog to a file outside the work tree (`.tmp/`, already
gitignored) and copy it back in `cleanup()`. No stash, no index, no accumulation, and the failure
mode becomes a missing file rather than a silently wrong `git apply`.

### 16.5 `cleanup()` commits indiscriminately, then destroys untracked state

[`release:318-322`](../Support/Scripts/release#L318) runs, in order:

```bash
stash_apply 0
git add . && git commit -m "Update CHANGELOG.md and submodules for $VERSION_TAG release"
git clean -fdx
```

Three problems:

- **`git add .` stages everything**, not just the changelog and submodule ref. Any unrelated
  untracked or modified file in the tree at that moment gets committed straight onto `main`. As of
  writing, an unrelated `docs/` directory would have been swept into the v1.2.0 release commit.
- **`git clean -fdx`** — note the `-x`, which ignores `.gitignore`. This deletes
  `Resources/**/*.a` (forcing a full Rust rebuild on the next run, ~1 hour) and `.build/`. It runs
  unconditionally at the end of every release, including a successful one.
- **This commit is not signed.** The other three release commits use `-S`
  ([`:150`](../Support/Scripts/release#L150), [`:187`](../Support/Scripts/release#L187),
  [`:206`](../Support/Scripts/release#L206)); this one does not. If the repository ever requires
  signed commits on `main`, the release will fail at its very last step.

**Suggested fix:** replace `git add .` with explicit pathspecs (`"$CHANGE_LOG"
"$SUBMODULE_XCFRAMEWORK"`), add `-S`, and drop the `-x` from `git clean` — or drop the clean
entirely and let the caller decide.

### 16.6 No trap, so a mid-flight failure strands the stash

There is no `trap ... EXIT`/`ERR` handler. When the script dies between the push and the apply —
which is exactly what 16.1 caused — the generated changelog exists **only** in the stash, and the
only clue about which run produced it is the free-text stash message. The working tree looks clean,
so the state is easy to miss entirely.

**Suggested fix:** a trap that either restores the stash or prints the captured SHA and tells the
operator how to recover.

---

## 🔴 17. iOS targets did not link UIKit — FIXED 2026-07-25

Archiving either iOS scheme against `libpact_ffi` 0.5.4 failed at the link step:

```
Undefined symbols for architecture arm64
  "_UIApplicationMain", referenced from:
      …objc2_ui_kit…UIApplication6___main in libpact_ffi.a[357](objc2_ui_kit-….rcgu.o)
ld: symbol(s) not found for architecture arm64
** ARCHIVE FAILED **
```

### Cause

The 0.5.4 bump introduced a new transitive dependency:

```
pact_ffi 0.5.4 → pact-plugin-driver 0.7.5 → os_info 3.14.0 → objc2-ui-kit 0.3.2
```

`os_info` reads the OS version from `UIDevice` on iOS, so `objc2-ui-kit` emits a `___main` shim
referencing `_UIApplicationMain`. Once the linker pulls that object in to satisfy `os_info`, every
undefined symbol in it must resolve — dead-stripping does not help, because symbol resolution
happens first. Nothing in the project linked UIKit, and on 0.4.25 nothing needed to.

Not feature-gateable: `os_info` is a hard dependency of `pact-plugin-driver`, which `pact_ffi`
requires.

### Scope

Verified by inspecting the built archives:

| Slice | `objc2_ui_kit` object | `_UIApplicationMain` ref |
|---|---|---|
| `iOS-device` | 1 | yes |
| `iOS-simulator` | 1 | yes |
| `darwin` | 0 | no |

Both iOS targets were affected — the device target merely failed first, because
`build_xcframework` archives it first. macOS is unaffected (no `objc2_app_kit`, no
`_NSApplicationMain`), so its xcconfig was deliberately left alone.

`_UIApplicationMain` was the **only** unresolved framework symbol. The ~8,000 `CF*` symbols each
slice references resolve via CoreFoundation, which Swift links implicitly — which is why this
never surfaced before.

### Fix

`-framework UIKit` appended to `OTHER_LDFLAGS` in
[`Target-iPhone-iOS-Shared.xcconfig`](../Configurations/Target-iPhone-iOS-Shared.xcconfig) and
[`Target-iOS-Shared.xcconfig`](../Configurations/Target-iOS-Shared.xcconfig), with a comment
recording the dependency chain. Hard-linked rather than `-weak_framework` (the treatment XCTest
gets) because UIKit is always present on iOS.

Confirmed: both schemes now archive, and `otool -L` shows
`/System/Library/Frameworks/UIKit.framework/UIKit` in the output binary.

### Follow-up

This class of breakage arrives silently with any `libpact_ffi` bump — a new transitive Rust crate
can reference any system framework, and the only signal is a link failure late in the release.
Consider a CI check that archives all three schemes on every `libpact_ffi.version` change, which
would have caught this before a release was attempted. Related: issue 2 (PRs are never built).

---

## Open questions

1. **Linux support** (issue 1) — keep and fix, or drop? This is the only item that changes the
   shape of the repository rather than just correcting it.
2. **Is the `libpact_ffi` 0.5.4 bump finished?** The last three commits are `WIP: Bumps
   pact-reference and libpact_ffi to 0.5.4`, the `pactffi_verifier_*` handle-API migration, and a
   `libbz2`/`liblzma` linking fix. No release has been cut since `v1.1.1`, which still pins
   `libpact_ffi-v0.4.25`. If 0.5.4 is settled, the next release is a `minor` at minimum.
3. **Does the iOS-device build actually work** (issue 6)? That determines whether the XCFramework
   currently ships a usable device slice.
