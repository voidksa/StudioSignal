# Discord integration

StudioSignal sends activity updates directly to Discord using device authorization and Headless Sessions. No application backend handles those updates.

## Permissions and credentials

The `sdk.social_layer_presence` authorization includes activity, friends, blocked-user and invite permissions. StudioSignal only uses sign-in and activity operations; it does not read or manage friends or blocked users, or send invitations. This grant is broader than the feature needs.

Credentials remain in memory. Restarting Studio requires reconnecting. Disconnect requests activity removal and authorization revocation. Application IDs and artwork IDs are public identifiers, not credentials.

Private project mode omits the project name and link. Script source, script names and file paths are not included in the activity payload.

## Limitations

Headless Sessions is experimental. A crash or network loss can delay activity removal until Discord expires the session. Multi-window coordination is not implemented. Automatic detection follows play state and the active script; manual labels do not detect another plugin's active tool.

## References

- [Discord authentication](https://discord.com/developers/docs/social-sdk/authentication.html)
- [Roblox HttpService](https://create.roblox.com/docs/reference/engine/classes/HttpService)
