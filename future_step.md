# Future steps

What the shared CI/CD doesn't do yet, when to add each piece, and what is holding it back. How the current
pipeline works is in [CI.md](CI.md).

## 1. Deployment for the project repositories

- **What:** a reusable `deploy.yml` here. It deploys what passed `ci-ok`, such as the image that
  [`container.yml`](.github/workflows/container.yml) publishes on a `v*` tag. It uses one GitHub environment
  per target and logs in to the cloud with OIDC, so no keys are stored.
- **When:** when a repository first gets a hosting target and an owner for it.
- **Why:** a release would reach its target without manual steps, and only from `main` or a tag.
- **Holding it back:**
  - **No target.** No repository has one today:
    - GenAIFinOps lists deployment as out of scope;
    - MigrationFinOps runs locally;
    - teamWorkflowAutomation runs as a scheduled workflow from `main`;
    - team-vaults ships skills as releases (its own `release.yml`, still waiting for a pull request).
  - **No approval step before a deploy.** Required reviewers on an environment need GitHub Enterprise for
    private repositories. The SpeedB3 Team plan only limits an environment to certain branches.
  - **Logins change.** An environment changes the OIDC subject, so every federated credential must be
    recreated for it.

## 2. Environment for teamWorkflowAutomation

- **What:** a `production` environment limited to `main`. It holds the poll workflow's secrets.
- **When:** together with the Entra federated credential, when the secrets in its `docs/SETUP.md` are set.
- **Why:** a workflow on any other branch can't read the secrets.
- **Holding it back:** the OIDC subject changes from `...:ref:refs/heads/main` to `...:environment:production`.
  The federated credential must be created for the new subject at the same time, or the daily poll can't
  log in.

## 3. CI for client-VentureWorkflowAutomation

- **What:**
  - a `ci.yml` from the starter workflow;
  - a `CODEOWNERS` file;
  - [`rulesets/repo-default.json`](rulesets/repo-default.json);
  - a `.github/dependabot.yml`.
- **When:** with its first code. It has been empty since 2 November 2026.
- **Why:** until then, nothing checks it. Its reviews are enforced only once the organisation ruleset is
  applied.
- **Holding it back:** a client may have its own approvers or pipeline rules. Ask before copying ours.

## 4. Automatic updates of the hand-pinned tools

- **What:** Renovate with a regex custom manager for the six tool versions in `run:` lines (CI.md, "Versions").
- **When:** if a bump is missed for a quarter, or one of the tools has a security fix.
- **Why:** Dependabot can't see versions written in `run:` lines.
- **Holding it back:**
  - Renovate is another bot, and every pull request it opens emails the code owners.
  - The six tools change rarely, so checking them by hand once a quarter is enough for now.

## 5. Code scanning (CodeQL)

- **What:** a reusable `codeql.yml` for Python, TypeScript and the workflows themselves.
- **When:** if the team buys GitHub Code Security.
- **Why:** it traces how untrusted input flows through the code, which ruff, pyright and the audits don't.
- **Holding it back:** private repositories need the paid licence (per active committer). The only public
  repository is this one, and actionlint already covers its workflow YAML.

## Left out on purpose

| Option | Why not |
|---|---|
| Merge queue | Few pull requests, and they rarely conflict. Every `ci.yml` would also need a `merge_group` trigger. |
| Required signed commits | Every member would have to set up signing keys first. Code-owner review already shows who changed what. |
| Coverage threshold | A number invites tests written to hit it. Reviewers judge the tests instead. |
