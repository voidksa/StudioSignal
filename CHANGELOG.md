# Changelog

## v1.1

- Rebuilt Presence around one preview and activity card, with an icon selector and a visible version badge.
- Added 24 original action icons with antialiased artwork and removed overlapping button outlines.
- Prevent partial UI pages from appearing together if initialization fails; development previews no longer register toolbar buttons.
- Added up to 20 saved appearance profiles with custom text, activity and icon choices.
- Added preview-before-apply, separate save/apply actions and per-place profile pins.
- Added a public Roblox game-link override for development copies, with private-server links rejected.
- Added locally generated QR sign-in with the verification code prefilled, the copyable link/code and an expiry countdown.
- Added actionable connection diagnostics, retry countdowns and a safe support report.
- Show the rounded gold support-report outline only while its text is focused, without clipped edges. Added a Copy report action that selects the entire report for Ctrl+C or Cmd+C; reports are never sent automatically.
- Prevent repeated sign-in requests from bypassing Discord's rate limit.
- Reorganized profile editing into library, editor and preview views with softer spacing and subtle hover/focus transitions.
- Retained the v1.0.1 panel restoration fixes and existing direct-to-Discord transport.

## v1.0.1

- Fixed the panel opening automatically as a floating window when starting Play.
- Remember panel visibility separately for Edit and Play, including a closed panel.
- Preserve the existing widget identifier so Studio can restore its saved layout.
- Start new installations with the panel closed; open it from the toolbar.
- Added What's New under More tools.

## v1.0

Initial release with automatic and manual Discord activities, 15 activity icons,
private projects, focus sessions and idle controls.
