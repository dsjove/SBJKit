# Pre-Localization Audit

## Formatting and locale

The new unit-conversion UI currently uses `.formatted(.number)` directly. That is an intentional placeholder; final numeric/unit presentation should come from SBJFoundation presentation-resource/formatting policy.

## Images and colors

Shared SwiftUI imagery is routed through `ImageName`. `HelpSheet` still rasterizes an SF Symbol with `UIImage(systemName:)` for HTML/WebKit output; that is a concrete rendering boundary, not SwiftUI presentation leakage.

The raw debug colors in `oldPDF (useSBJLayout)` belong to legacy code scheduled for removal and are not localization architecture.

## Alerts/accessibility

SBJKit has relatively little framework-owned copy. Reusable workflows should eventually accept semantic/localizable resources rather than plain presentation strings where the caller owns vocabulary.

## Public API

The public surface is intentionally application-level and volatile. No access-level tightening is recommended until the framework stabilizes. This is also why no new SBJKit test initiative is being started now.

## Dependency/platform boundary

SBJKit depends on SBJFoundation only. UIKit/Photos/SwiftData/WebKit imports correspond to the higher-level workflows this framework exists to provide.

## Dead/duplicate code

- `oldPDF (useSBJLayout)` remains explicit migration debt; add nothing new there.
- `View+navigationTitle.swift` is marked in source as apparently unused and is a deletion candidate after verifying downstream apps.
- SBJKit and SBJFoundation both extend `UIImage`, but with distinct responsibilities: Foundation provides generic loading/identity helpers; SBJKit provides photo-workflow normalization/resizing. No merge is required.

## Tests

No new tests are requested for SBJKit during this volatile phase.
