# Telta

Telta is a compact prep-line photo and status app for kitchen service
handoffs. The product direction is intentionally narrow: keep one current batch,
one shared proof photo, one recent timeline, and one credit store.

## Core Surface

The visible app should stay focused on four primary destinations:

- Board: current batch, save-ready action, compact station state.
- Batch: selected batch details, blocker handling, recent state saves.
- Photos: uploaded proof image plus recent saved states.
- Store: prep credit balance, all 25 purchase options, and legal policy links.

Auxiliary compliance and legacy routes may remain available to preserve iOS,
IAP, protocol, and test coverage, but they should not compete with the primary
navigation surface.

Initial batch and station values are seed data. After the first save, the app
writes the current batch, station, note, exception state, and linked proof photo
path to local app records so Batch and Photos read back the same saved update.
Board and Batch both expose the same current-batch setup fields, so station and
owner can be corrected before a save and then flow into saved records, history,
station cards, and proof-card export.

## Photo Contract

User-uploaded album images are the only visible photo material. Uploading a
proof photo from any core photo surface promotes that image to the large hero
image on Board, Batch, and Photos. The primary save action is the batch/state
save with the linked proof photo. Exporting from the large image generates a
new proof card image with the photo, batch, state, station, owner, time, and
note, then writes that generated card to the system Photos album named
`Telta`.

Built-in `assets/images` files must not be rendered as UI photos; before upload,
the large image area shows an upload empty state instead.

## Interaction Contract

- Keep copy short and operational.
- Avoid duplicate controls and secondary navigation drawers.
- Do not show a settings button on the Store page, but keep User Agreement and
  Privacy Policy reachable from Store and Settings.
- Keep IAP initialization lazy behind the Store flow.
- Keep all user-facing Store copy, product cards, purchase preparation,
  purchase success, and purchase failure feedback free of internal product IDs;
  product IDs belong only in the Dart catalog, StoreKit config, and tests.
- Treat the current batch setup as editable app state, not fixed sample copy:
  owner and station edits must update the selected batch before save/export.
- Persist media with relative paths and rebuild full paths at render/export time.
- Link the uploaded proof photo to each state-save record when a photo exists.
- Reserve a tall primary proof-photo area on Board, Batch, and Photos so
  uploaded images read as the main workflow, not a short banner.
- Make Photos proof records tappable so saved photo cards can open the related
  batch detail instead of behaving like static decoration.
- Keep proof-card export visually secondary to the state-save action, because
  export does not create an app record.
- Show the 10-credit cost and post-save balance directly before every
  credit-spending save button. A post-save confirmation alone is not enough.
