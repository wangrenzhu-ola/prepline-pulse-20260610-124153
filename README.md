# PrepLine Pulse

PrepLine Pulse is a compact prep-line photo and status app for kitchen service
handoffs. The product direction is intentionally narrow: keep one current batch,
one shared proof photo, one recent timeline, and one credit store.

## Core Surface

The visible app should stay focused on four primary destinations:

- Board: current batch, save-ready action, compact station state.
- Batch: selected batch details, blocker handling, recent state saves.
- Photos: uploaded proof image plus recent saved states.
- Store: prep credit balance, all 27 purchase options, and legal policy links.

Auxiliary compliance and legacy routes may remain available to preserve iOS,
IAP, protocol, and test coverage, but they should not compete with the primary
navigation surface.

## Photo Contract

User-uploaded album images are the only visible photo material. Uploading a
proof photo from any core photo surface promotes that image to the large hero
image on Board, Batch, and Photos. The save-to-album action belongs on that
large proof image, not in a secondary controls panel.

Built-in `assets/images` files must not be rendered as UI photos; before upload,
the large image area shows an upload empty state instead.

## Interaction Contract

- Keep copy short and operational.
- Avoid duplicate controls and secondary navigation drawers.
- Do not show a settings button on the Store page, but keep User Agreement and
  Privacy Policy reachable from Store and Settings.
- Keep IAP initialization lazy behind the Store flow.
- Persist media with relative paths and rebuild full paths at render/export time.
