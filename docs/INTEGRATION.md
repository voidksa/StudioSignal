# Discord integration

StudioSignal sends activity updates directly to Discord using device authorization and Headless Sessions. No application backend handles those updates.

## Permissions and credentials

The `sdk.social_layer_presence` authorization includes activity, friends, blocked-user and invite permissions. StudioSignal only uses sign-in and activity operations; it does not read or manage friends or blocked users, or send invitations. This grant is broader than the feature needs.

Credentials remain in memory. Restarting Studio requires reconnecting. Disconnect requests activity removal and authorization revocation. Application IDs and artwork IDs are public identifiers, not credentials.

The repository omits the official Discord application and artwork identifiers
from its default configuration. A fork must supply its own application and
artwork configuration. The public Roblox image references are UI artwork,
not credentials. The Creator Store distribution includes its working application
configuration; removing identifiers from this repository does not make those
public identifiers secret. Eligibility for the experimental transport may vary
by Discord application, so creating a new application alone is not a guarantee
that the same integration will be available.

Private project mode omits the project name and link. Script source, script names and file paths are not included in the activity payload.

## Profiles and previews

Up to 20 profiles are stored locally in Studio plugin settings. A profile contains
only its local name and appearance fields: first line, activity text, activity,
icon, timer, privacy, display name and public game link. It never contains account
credentials. Saving a draft does not apply it, and applying never connects an
account or enables sharing. A profile can be pinned by published place ID; local
files with place ID zero cannot have separate persistent pins. Profiles do not
sync to other devices.

Private mode suppresses the custom first line, display name and game link.
User-entered activity text is still shared. The preview shows these rules before
applying. Focus and Away override the activity text and icon while active. Link
overrides accept only public Roblox game URLs, with no query or fragment; links
containing private-server codes are rejected.

## QR sign-in and support reports

The QR code uses Discord's complete verification link at
`https://discord.com/activate?user_code=...`, so scanning fills in the temporary
verification code. The user still reviews and approves the connection on Discord.
The link is checked against the official host, path and current short code; it
never contains a device code, bearer token or refresh token. The QR is generated
locally as UI geometry, without an image service or upload. The link and code
remain selectable for manual use. Cancelling, expiry or finishing sign-in removes
the code and QR from the panel. Do not share an active sign-in QR or short code.

The support report exports a fixed set of diagnostic labels, booleans and numeric
status/timing values. It excludes authorization codes, credentials, account and
project identifiers, profile names, custom text, URLs and raw HTTP responses.

## Limitations

Headless Sessions is experimental. A crash or network loss can delay activity removal until Discord expires the session. Multi-window coordination is not implemented. Automatic detection follows play state and the active script; manual labels do not detect another plugin's active tool.

## References

- [Discord authentication](https://discord.com/developers/docs/social-sdk/authentication.html)
- [Roblox HttpService](https://create.roblox.com/docs/reference/engine/classes/HttpService)
