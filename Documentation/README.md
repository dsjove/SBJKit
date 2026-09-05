# SBJKit Documents

SBJKit is currently a volatile higher-level application framework. This directory is reserved for
architecture and migration notes as its stable subsystems emerge.

## Shared localization design

The canonical localization/presentation-resource design is maintained in `SBJFoundation/Documentation/LOCALIZATION_AND_PRESENTATION_RESOURCES.md`. SBJKit should not grow a parallel localization design; its pre-localization audit is an inventory only.

## Current architectural notes

- `Sources/SBJKit/oldPDF (useSBJLayout)/` is legacy migration debt. New newspaper/print PDF work
  belongs in SBJLayout, and the old directory should be removed as older apps migrate.
- Low-level reusable platform/framework extensions should continue moving to SBJFoundation.
- SBJKit should retain higher-level application abstractions such as tags, attachments, photo/share
  workflows, persistence workflows, and similar composed application behavior.

No formal testing design is being established yet; the framework is intentionally too volatile to
freeze those APIs with broad tests.


- [Pre-localization audit](PRELOCALIZATION_AUDIT.md)
