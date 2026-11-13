# SpeedB3

This organisation holds the team's project repositories (the actual delivery work, whether for a client or for ourselves) and the team vaults, the shared repositories for everything reusable. Each project repo is scoped to one project and carries its own context, code, and documentation.

## Team vaults

The team vaults are the team's libraries of client-agnostic assets: things we build once and carry from one engagement to the next. There is one repository per kind of asset, all named `team-vault-<kind>`:

| Vault | What it holds |
|---|---|
| [team-vault-skills](https://github.com/SpeedB3/team-vault-skills) | Skills, standards and frameworks, in two folders. `tech/` holds tools, scripts, automation, Claude Code skills, configuration baselines and reference implementations. `tech/skills/custom/` has the skills we wrote: `deep-review` (an exhaustive multi-agent code review loop), `python-standards` (the house standard for Python tooling, with an audit script) and `vault-authoring` (the standard every skill and prompt in the vault follows). `tech/skills/public/` has third-party skills, vendored at a pinned commit with their licence. `strategy/` holds frameworks, analysis methods, playbooks, workshop formats and skills for strategy work. |
| [team-vault-templates](https://github.com/SpeedB3/team-vault-templates) | Project templates: reference pipelines, architectures and starter kits we generalise from one engagement and start the next one from. One top-level folder per template; the first is `document-case-pipeline` (sort, check and report on a package of documents for a case, then draft outputs for a person to approve). |

Conventions for the vaults:

- A new **kind** of asset that doesn't fit an existing vault gets its own `team-vault-<kind>` repository. A new asset of an existing kind goes into that vault.
- **Skills are split by origin.** `skills/custom/` is for ours, each with a `SKILL.md`, a `CHANGELOG.md` and evals. `skills/public/` is for copies of other people's skills, kept verbatim with their licence and the commit they were taken from.
- **Per-language standards are skills named `<stack>-standards`.** `python-standards` is the first; `typescript-standards`, `go-standards` and so on follow the same shape. `deep-review` picks up any of them that is installed.
- **Templates are one folder per template**, named after what they do, never after a client.
- **Nothing in a vault is client-specific.** If something built in a project turns out to be reusable, strip the project-specific parts and move it to the right vault.

## Naming convention

Every repository name starts with a prefix that says what it is:

| Prefix | Use for | Example |
|---|---|---|
| `internal-` | Internal projects: tools, accelerators, and R&D we build for ourselves | `internal-GenAIFinOps` |
| `client-` | Client projects: delivery work for a specific client engagement | `client-AcmeDataPlatform` |
| `team-vault-` | Team vaults: shared, client-agnostic libraries, one per kind of asset | `team-vault-skills` |

For projects, the prefix is followed by a short descriptive name in PascalCase, without spaces or extra hyphens. For vaults, it is followed by the kind of asset in lowercase kebab-case (`skills`, `templates`). `.github` is the only repository without a prefix: it is the organisation's profile and shared configuration.

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

## Repositories

| Repository | What it is |
|---|---|
| [team-vault-skills](https://github.com/SpeedB3/team-vault-skills) | Vault: skills, standards and frameworks (see above). |
| [team-vault-templates](https://github.com/SpeedB3/team-vault-templates) | Vault: project templates (see above). |
| [client-VentureWorkflowAutomation](https://github.com/SpeedB3/client-VentureWorkflowAutomation) | Venture: AI-assisted intake of customer RFQ packages. It unpacks, classifies into Venture's folders, links drawings to BOM lines, checks completeness and reports the gaps. |
| [client-MizuhoWorkflowAutomation](https://github.com/SpeedB3/client-MizuhoWorkflowAutomation) | Mizuho Bank: AI support for credit documentation. Triage of credit files with a gap report, then CP checklist, admin card, submission pack and agreement drafting. |
| [chilliclaw](https://github.com/SpeedB3/chilliclaw) | Fork of pragnition/chilliclaw for the NIPSEA Compliance Agent build. It keeps the upstream name, so it falls outside the prefix convention. |
| [internal-GenAIFinOps](https://github.com/SpeedB3/internal-GenAIFinOps) | AI Cost Optimizer: what a client pays for AI today and what a different LLM offering would save, ranked on cost, task fit, speed and uptime. |
| [internal-MigrationFinOps](https://github.com/SpeedB3/internal-MigrationFinOps) | `agent-migrate`: a platform for migrating AI agents between agentic platforms, mostly automatic, verified by evaluation, explicit about where a human must act. |
| [internal-teamWorkflowAutomation](https://github.com/SpeedB3/internal-teamWorkflowAutomation) | Files Teams meeting transcripts into Notion with a Claude-written summary and opens the Linear follow-up ticket. |
| [.github](https://github.com/SpeedB3/.github) | This profile, the README template, and the shared CI/CD and merge rules every repository uses ([CI.md](https://github.com/SpeedB3/.github/blob/main/CI.md)). |
