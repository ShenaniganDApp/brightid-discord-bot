# BrightID Discord Bot Privacy Policy

Last updated: September 27, 2026

This policy describes how BrightID Discord Bot (the "bot") and its companion server-management dashboard process information to link Discord accounts to BrightID, check uniqueness verification, and manage verification roles. For privacy questions or requests, contact the BrightID team at [support@brightid.org](mailto:support@brightid.org).

## Information processed

The bot processes the following information:

- **Discord account and membership information:** Discord user IDs, usernames or server display names, server membership, roles, and permissions. The bot can request a server's member list to assign verification roles to members who are already verified, and receives member-join and member-update events to maintain those roles.
- **Server configuration:** Server IDs and names, the verification role's ID and name, and an invite link if an administrator provides one. Configuration can also include sponsorship addresses, sponsorship allocations and usage, transaction-related sponsorship records, and premium expiration information.
- **BrightID verification information:** A context identifier derived from a Discord user ID, the linked account's uniqueness status, and verification responses returned by BrightID, which can include linked context identifiers, timestamps, signatures, and public keys.
- **Command and button interactions:** The commands and buttons used, their submitted options, and the Discord account and server associated with the interaction.
- **Operational logs:** Command and button activity, verification outcomes, errors, and diagnostic information. These logs can contain server IDs and names, usernames or display names, and BrightID context identifiers.

The bot does not request Discord passwords or collect BrightID profile photos, personal connection lists, or private verification-party audio or video. Its implemented verification features use slash commands and buttons; they do not read or store ordinary chat message content or track online presence.

## How information is used

The bot uses this information to:

- Generate a QR code or link for connecting a Discord account to BrightID.
- Check whether the linked account meets BrightID's uniqueness verification requirements.
- Assign or remove the configured verification role, including for existing members and members joining a participating server.
- Maintain server settings and support sponsorship features.
- Diagnose operational problems and respond to support requests.

The bot does not use Discord API data for advertising, sell that data, or provide it to data brokers. A verification role indicates the result of a BrightID check; it does not disclose a person's real-world identity. Server administrators control what access or privileges that role provides.

## Context identifiers and BrightID

The bot creates a deterministic UUIDv5 context identifier from a Discord user ID and a configured namespace. It sends this identifier to BrightID services to retrieve verification information and includes it in the account-linking QR code or link.

The identifier is pseudonymous, not anonymous: the bot can derive it again from the same Discord user ID, and it can associate verification across participating servers. BrightID services process the account link and verification information under their own policies. The bot does not send a Discord username or display name as part of its verification lookup.

## Storage, sharing, and visibility

Server configuration is stored outside Discord in a GitHub Gist. The configured Gist may be publicly accessible; an unlisted or "secret" Gist is accessible to anyone with its URL. Server names and supplied invite links can also be displayed by the companion dashboard. Administrators should not submit confidential information in server configuration fields.

BrightID nodes receive the context identifiers needed for verification. The bot's hosting provider may retain application logs. Discord processes bot interactions and role changes through its platform. These services may process data in countries other than the user's country of residence.

Verification commands and button responses are marked as private (ephemeral) Discord replies. The assigned verification role is visible according to Discord's server permissions and interface. A private reply does not prevent the bot from recording the operational logs described above.

Third-party privacy information is available from [Discord](https://discord.com/privacy), [GitHub](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement), and [BrightID](https://www.brightid.org/privacy-policy-terms-of-use).

## Companion dashboard

Users who sign in to the dashboard authorize Discord OAuth access. The dashboard processes the Discord profile, OAuth access token, server list, and server membership or permission information needed for its features. Its configured OAuth scopes are `identify`, `guilds`, and `guilds.join`; Discord presents the requested access during authorization.

The dashboard uses a session cookie to maintain the signed-in session. The session contains the OAuth access token and profile information. Administrators can submit server settings and sponsorship information through the dashboard. Signing out clears the dashboard session; Discord authorization can also be revoked in Discord's Authorized Apps settings.

## Retention and deletion

Server configuration is retained while the bot serves the server. When the bot is removed from a server, it attempts to delete that server's entry from the current Gist contents. A failed cleanup may require manual removal. Updating or removing an entry does not automatically erase earlier Gist revisions, provider backups, or existing logs.

The bot does not maintain a separate persistent database of every member's verification status; it retrieves verification information from BrightID. BrightID retains account-linking and verification records independently. The current bot implementation does not impose an automatic expiration period on logs or Gist revision history.

For access, correction, or deletion requests concerning bot-controlled data, email [support@brightid.org](mailto:support@brightid.org) with the relevant Discord user ID or server ID and a description of the request. Do not include passwords, account tokens, or BrightID recovery material. The team may need to verify the requester's account ownership or server authority before acting. Requests concerning Discord, GitHub, or BrightID records outside the bot team's control may also require contacting the relevant service.

Removing a verification role or leaving a server does not erase the BrightID account link. While the bot remains installed, member events can cause it to recheck verification and restore a role. To stop server-wide bot processing, an administrator can remove the bot; to stop dashboard access, a user can sign out and revoke its Discord authorization. Contact support for assistance with account-linking or deletion requests.

## Security and age requirements

The bot uses configured credentials to access Discord and update GitHub configuration. No internet service can guarantee complete security. Users should keep account credentials, bot tokens, and BrightID recovery material private, and report suspected unauthorized access to [support@brightid.org](mailto:support@brightid.org).

The bot is intended for people who meet Discord's minimum age requirements, including any higher minimum required in their country. It is not directed at children under 13. Contact support if the bot has processed information about a child who does not meet those requirements.

## Changes and contact

Updates to this policy will be published in this file with a revised "Last updated" date. The bot's `/help` command links to this policy.

Privacy questions, data requests, and reports about the bot can be sent to [support@brightid.org](mailto:support@brightid.org).
