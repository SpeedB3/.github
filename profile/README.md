# SpeedB3

This organisation holds the team's project repositories, the actual delivery work, whether for a client or for ourselves, and one shared repository, `team-vaults`, for everything reusable. Each project repo is scoped to one project and carries its own context, code, and documentation.

## team-vaults

[team-vaults](https://github.com/SpeedB3/team-vaults) is the team's library of client-agnostic assets: things we build once and carry from one engagement to the next. One repository, one folder per vault:

| Folder | What it holds |
|---|---|
| `tech/` | Technical assets: tools, scripts, automation, Claude Code skills, configuration baselines, reference implementations. `tech/skills/custom/` holds the skills we wrote (`deep-review`, an exhaustive multi-agent code review loop; `python-standards`, the house standard for Python tooling with an audit script; `vault-authoring`, the standard every skill and prompt in the vault follows); `tech/skills/public/` holds third-party skills we use, vendored at a pinned commit with their licence. |
| `strategy/` | Strategy and advisory assets: frameworks, analysis methods, playbooks, templates, workshop formats, and skills for strategy work. |

Conventions inside `team-vaults`:

- A vault is a top-level folder with its own README saying what belongs in it; the root README lists the vaults. A new kind of asset gets a folder inside the vault it serves, never a new repository.
- Skills are split by origin: `skills/custom/` for ours (each with a `SKILL.md`, a `CHANGELOG.md` and evals), `skills/public/` for copies of other people's, kept verbatim with their licence and the commit they were taken from.
- Per-language standards are skills named `<stack>-standards` (`python-standards` first; `typescript-standards`, `go-standards` and so on follow the same shape), and `deep-review` picks up any of them that is installed.
- Nothing in a vault is client-specific. If something built in a project here turns out to be reusable, strip the project-specific parts and move it to the vault.

## Naming convention

Every repository name starts with a prefix that says who the project is for:

| Prefix | Use for | Example |
|---|---|---|
| `internal-` | Internal projects: tools, accelerators, and R&D we build for ourselves | `internal-GenAIFinOps` |
| `client-` | Client projects: delivery work for a specific client engagement | `client-AcmeDataPlatform` |

After the prefix, use a short descriptive name in PascalCase, without spaces or extra hyphens. `team-vaults` is the one repository without a prefix: it is shared infrastructure, not a project, and there is only one of it.

## README requirements

Every project repository has a README that starts with these sections, in this order:

| Section | Required for | What goes in it |
|---|---|---|
| **Description** | all projects | What the project is, the problem it solves, and who it is for, in a few sentences |
| **Scope** | all projects | What is in scope and what is explicitly out of scope, so the boundaries are clear to anyone picking it up |
| **Ownership** | client projects | The client organisation, the client-side owner or sponsor, and the SB3 owner accountable for the engagement |
| **Collaborators** | client projects | Who works on the project, on both sides, with their role |

Setup instructions, documentation maps, and anything else follow after these. A template is in [README-TEMPLATE.md](https://github.com/SpeedB3/.github/blob/main/README-TEMPLATE.md).

## Ground rules

- One project per repository. Do not mix client work and internal work in the same repo.
- Client repos must be private and contain nothing from another client.
- No credentials, tokens, or secrets in any repo. Use `.env` files that are gitignored.
- Every repo has a README that meets the requirements above and explains how to set the project up and where the documentation lives.
