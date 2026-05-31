---
name: porting-red-alert-to-zig-linux
description: Use when incrementally porting this Red Alert codebase toward Zig/Linux compatibility, especially when replaying zig_minimal into zig_inc, grouping repo-wide source changes, or reviewing legacy C++ datatype, template, pointer, CRC, SHA, INI, mix-file, and compatibility hunks.
---

# Porting Red Alert to Zig/Linux

## Overview

Port this codebase as readable, reviewable source slices. Treat `zig_minimal` as a clue, not an oracle: copy the intent, then re-read every hunk for 32-bit assumptions, legacy compiler behavior, and accidental behavior changes.

## Branch and PR Discipline

1. Sync first: `git fetch origin zig_inc zig_minimal`, then fast-forward local `zig_inc`.
2. Create one temp branch per reviewable slice, based on `zig_inc`.
3. Group changes by pattern, not by single line. Good groups: `uintptr_t` pointer alignment fixes, enum width pins, explicit template instantiations.
4. Keep net-new files at the end unless asked otherwise. Avoid mixing build files, Linux stubs, compatibility shims, or large new modules into simple source-change PRs.
5. Create PRs against `hughobrien/battlecontrol_ra`, base `zig_inc`. Use real Markdown newlines in PR bodies.

## Selecting a Slice

Prefer source-only changes with a single reason:

| Pattern | Include | Exclude |
| --- | --- | --- |
| Datatype width | enum backing types, `COORDINATE`, arithmetic word sizes | byte-buffer rewrites that need separate review |
| Pointer arithmetic | casts through `uintptr_t`, alignment math | unrelated allocation or layout changes |
| Template portability | `template<>`, explicit instantiations, `this->` dependent lookup | unrelated loop-scope or data-layout edits in same files |
| Legacy compiler cleanup | invalid static member definitions, nonstandard forward declarations | behavior changes hidden nearby |
| Wrapper temporaries | named `FileStraw`/`FilePipe` objects | API redesign |

If a file has mixed hunks, apply only the matching hunks. Do not copy the whole file diff from `zig_minimal`.

## Review Heuristics

Re-read every hunk with these questions:

- Is this preserving legacy binary or file-format behavior?
- Does `char` mean byte/object storage here, or does the value need signed or unsigned numeric behavior?
- Is a typed pointer being used to read unaligned bytes? Prefer `memcpy` for object-byte assembly.
- Is pointer math routed through `long` or `int`? Use `uintptr_t` for address-sized alignment and masking.
- Is a temporary passed to a non-const reference or long-lived adapter? Name the object.
- Is a standard library replacement behavior-compatible? For this repo, the `CRCEngine` rolling hash is not standard CRC-32.

## Known Decisions

- `CRCEngine` is a legacy rolling hash: rotate left one bit, add staged 32-bit words. Do not replace it with a standard CRC library unless the persisted IDs and file lookups are intentionally migrated.
- SHA and CRC byte staging should avoid typed bulk reads. Use byte buffers plus `memcpy`/explicit assembly so alignment and aliasing are not hidden footguns.
- Use fixed-width names for numeric storage. Prefer `uint8_t`/`int8_t` over raw `char` for numeric values and enum backing stores.
- Keep `char` acceptable for legacy byte cursors and object-representation buffers. Do not introduce `std::byte` unless the language level is intentionally raised.
- For pointer alignment, preserve the original alignment target but remove truncation: `(uintptr_t)(ptr + 3) & ~(uintptr_t)3`.
- For slot clearing, size by the pointed-to element: `frames * sizeof(slots[0])`, not by assumed pointer width.

## Verification

Always run:

```bash
git diff --check zig_inc..HEAD
```

Then run the narrowest useful source check available. In this repo, full compiler checks may be blocked before the current slice by missing legacy headers, case-sensitive includes, or unrelated old C++ template issues. If blocked, report the exact blocker and do not imply the code compiles.

For review questions, say whether the change is directly from `zig_minimal` or an intentional safer deviation.

## Common Mistakes

- Making commits too small after the reviewer asks for grouped pattern changes.
- Copying net-new files early because they are present in `zig_minimal`.
- Treating `zig_minimal` as correct when it contains obvious syntax or formatting footguns.
- Replacing legacy algorithms with modern libraries without proving wire/file compatibility.
- Saying a build passes when only whitespace or a partial syntax check ran.
- Using raw `char` everywhere after deciding fixed-width names are clearer.
