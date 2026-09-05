# SBJKit

`SBJKit` contains **higher-level reusable application abstractions** shared by SBJ apps.
It sits above `SBJFoundation`: the latter extends Apple's platform frameworks with low-level
primitives and UI vocabulary, while SBJKit composes those primitives into application workflows
and domain-adjacent components.

SBJKit used to be the catch-all location for shared code. That is no longer its intended role.
Low-level platform extensions, Codable bridges, generic SwiftUI chrome, observation helpers, and
SBJStructure now belong in `SBJFoundation`. Newspaper/print-style PDF layout belongs in
`SBJLayout`.

## Intended layer

```text
Apple platform frameworks
        ↓
SBJFoundation
platform extensions, UIVocabulary,
SBJStructure / SubjectEditor
        ↓
SBJKit
higher-level application abstractions
        ↓
applications
```

`SBJLayout` is a sibling specialized framework for paginated newspaper/print PDF composition;
it is not a general SBJKit subsystem.

## What belongs here

Current code falls into several useful higher-level areas:

- **Attachments** — attachment models/protocols and attachment editing/presentation.
- **Tags** — tagging contracts, tag controls/sheets, and SwiftData-backed tag bags.
- **SwiftData/application persistence** — helpers around persistent models, seed/sync behavior,
  teardown, and application persistence representations.
- **Photos** — camera/photo picking, import, display, editing, cropping, markup, thumbnails, and
  slideshow workflows.
- **Sharing/document handoff** — activity/share sheets, export/open/preview flows, and data/photo
  attachment handoff.
- **Application UI/workflows** — help presentation, action/delete controls, selection views, and
  application-level modifiers.
- **Application services** — small services such as app information and sound playback when they
  are more than simple platform extensions.

A useful ownership test is:

> Is this a broadly reusable extension of a system framework/type, or is it a reusable piece of
> application behavior assembled from system/framework primitives?

The former generally belongs in `SBJFoundation`; the latter belongs here.

## What should move out

### Legacy PDF

`Sources/SBJKit/oldPDF (useSBJLayout)/` is legacy support for applications written before
`SBJLayout` existed. It is migration debt, not part of SBJKit's intended architecture.

Do not add new functionality there. New paginated/print PDF work belongs in `SBJLayout`. Remove
legacy files as the remaining older applications migrate.

### Low-level utilities

When code in SBJKit proves to be a generally useful extension of Foundation, SwiftUI, UIKit,
Observation, or another Apple platform framework, prefer moving it down into `SBJFoundation`
rather than growing another utility bucket here.

## Dependencies

SBJKit depends on `SBJFoundation`. It should use Foundation's shared presentation vocabulary,
platform helpers, and structural-model facilities instead of duplicating them.

SBJKit should depend on `SBJLayout` only if a surviving higher-level workflow genuinely needs the
new print-layout framework. The legacy `oldPDF` directory should not be used as justification for
new layout dependencies or APIs.

## Stability and testing

SBJKit is still intentionally volatile while responsibilities continue to move into
`SBJFoundation` and `SBJLayout` and higher-level abstractions settle.

**There is no requirement to build a test suite for SBJKit yet.** During this phase, favor clear
ownership, source organization, and application usage over tests that would simply freeze unstable
APIs. Add focused tests later when a subsystem becomes stable enough that its behavior is intended
to persist across refactors.


## Unit conversion

SBJKit hosts the higher-level reusable conversion workflow (`UnitConversionModel`, `UnitConversionView`, and `UnitConversionToolView`). Physical unit identity, Codable `UnitValue`, conversion math, and generic unit editing remain in SBJFoundation. Apps supply domain-specific preferred units and editing-step policy.

## Presentation/localization boundary

SBJKit does not define a parallel localization architecture. Reusable workflows consume SBJFoundation presentation resources and should accept semantic/localizable resources when the workflow owns reusable copy, while application-owned vocabulary remains supplied by the caller.

The completed source audit leaves these concrete seams:

- `UnitConversionView` currently uses direct number formatting as a temporary presentation path; final numeric/unit presentation belongs to SBJFoundation's shared formatting/resource context.
- `HelpSheet` uses `UIImage(systemName:)` only at an HTML/WebKit rasterization boundary; this is a concrete rendering operation rather than SwiftUI semantic-image leakage.
- Alerts and accessibility copy in reusable tag/photo/attachment/delete/selection workflows are eventual clients of SBJFoundation presentation resources.
- `oldPDF (useSBJLayout)` is legacy migration debt. Add no localization or presentation-resource architecture there.
- `View+navigationTitle.swift` remains a deletion candidate after downstream-use verification.

The former `Documentation/PRELOCALIZATION_AUDIT.md` and documentation-index file were removed after these durable findings were incorporated here. SBJKit currently has no separate design-document tree because there is no additional stable subsystem design to justify one.

