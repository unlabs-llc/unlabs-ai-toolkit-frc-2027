<!-- Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md -->

# Security

**Last verified: 2026-09-11**

## Reporting a vulnerability

Please don't open a public issue for a security problem. Report it privately through GitHub: on this
repository's page, open the **Security and quality** tab and click **Report a vulnerability**. Only
the maintainers can see the report.

Useful things to include: the toolkit version (the `version:` line near the top of
`.claude/frc-baseline-manifest.yml` in your robot project), your operating system, and the steps that
show the problem. Leave out anything secret, such as tokens, passwords or your team's private code.

## What to expect

Support for this toolkit is community-only and best effort, as the [README](README.md#support) says.
There is no response-time commitment and no timetable for fixes.

When a security fix ships, it is published as a GitHub Release with `[security]` in its title. The
session-start update check in projects installed with the supplied settings template uses the title
from its most recent successful check (cached up to 24 hours). When that title carries the marker,
students in a project with an older version are told to pause and ask a mentor to update before they
carry on.

## Which versions get fixes

Fixes, when there are any, go into a new release. Earlier releases are not patched.
