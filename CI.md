# Shared CI/CD

Every SpeedB3 repository runs the same pipeline. The pipeline lives here as
[reusable workflows](https://docs.github.com/actions/using-workflows/reusing-workflows). Each repository
has only a short `.github/workflows/ci.yml` that calls them. A fix made here reaches every repository on
its next run. What isn't built yet, and why, is in [future_step.md](future_step.md).

This repository is public, and so are its commit messages, branch names, pull requests and comments. Keep
client names, client repository names, engagement details and how a client repository is protected out of all
of them (profile, "Ground rules"). The `public-content` job checks pull requests into `main` (again when the title or
description is edited): the files and file names, what every new commit adds, commit
messages, and the title, description and branch name. It fails on any `client-<Name>` and on the names in
the `PUBLIC_DENYLIST` secret, a case-insensitive extended regular expression kept as a secret so the list
isn't published, and its log never shows a matched name. It can't see comments, and it runs only after a
branch is pushed, so check before pushing. A pull request into another branch is checked only once it merges
(`ci-merged.yml`), but its commits are public from the first push, merged or not, so check those too.
Add each new client to the secret, for both Actions and Dependabot (whose pull requests can't read Actions
secrets); `gh` asks for the value:

```
gh secret set PUBLIC_DENYLIST --repo SpeedB3/.github --app actions
gh secret set PUBLIC_DENYLIST --repo SpeedB3/.github --app dependabot
```

| Workflow | Language | What it does |
|---|---|---|
| [`python-uv.yml`](.github/workflows/python-uv.yml) | Python (uv projects) | `uv sync --locked`, pip-audit of the runtime dependencies (`audit: false` turns it off), ruff lint and format check, pyright, pytest. It can start PostgreSQL and create the test databases. ruff and pytest must be dev dependencies, and pyright too unless `pyright: false`. It can read dependencies from private repositories of this organisation ([below](#private-dependencies)). |
| [`node.yml`](.github/workflows/node.yml) | TypeScript / JavaScript (npm) | `npm ci`, `npm audit` of runtime dependencies (high and above), then the package.json scripts you list. |
| [`bun.yml`](.github/workflows/bun.yml) | TypeScript / JavaScript (Bun) | `bun install --frozen-lockfile`, optional just, Python, OPA and OpenTofu, then the commands you list (each runs; the job fails if any failed) and an optional report into the job summary. |
| [`container.yml`](.github/workflows/container.yml) | Dockerfile | hadolint, then the image build. With `publish: true` (the default), pushes to the default branch (`main`) and `v*` tags publish it to `ghcr.io/speedb3/<image>` with an SBOM and provenance. Pull requests only build it, so a `ci.yml` (pull requests only) never publishes: that takes a release workflow. |
| [`scripts.yml`](.github/workflows/scripts.yml) | Loose Python, shell, PowerShell | One job per language: py_compile + ruff bug rules + listed self-tests, shellcheck (all severities), PSScriptAnalyzer (errors and parse errors). It checks every such file in the repository, so list a uv project's Python files in `exclude` (e.g. `backend/*.py`), because Ruff runs with `--isolated` and ignores the project's config. |
| [`actionlint.yml`](.github/workflows/actionlint.yml) | GitHub Actions YAML | actionlint, with shellcheck on `run:` blocks, and a check that `ci-ok` needs every job and runs with `if: always()`. |
| [`secrets.yml`](.github/workflows/secrets.yml) | Any | gitleaks over the history of the checked-out commit (other branches are not scanned). A root `.gitleaks.toml` allowlists fake keys in fixtures. |

Each file's header shows how to call it, its `inputs` list every option, and it names the status checks it
reports.

## Tests of the pipeline

Each shared workflow has its own test. The [CI](.github/workflows/ci.yml) of this repository runs every
workflow from the current commit against a fixture project in [`tests/`](tests) (actionlint and gitleaks
run over this repository itself):

| Job | Fixture | Proves |
|---|---|---|
| `workflows` | this repository | actionlint over every workflow in `.github/workflows` and the starter workflow in `workflow-templates/`, and the ci-ok `needs`/`if:` check on both, and that it found a ci-ok job to check (count asserted by `ci-ok`) |
| `python` | `tests/python` | lock check, pip-audit of a runtime dependency (`packaging`; `extra-commands` fails if the export did not list it), ruff, strict pyright, pytest, the `env` input |
| `python-postgres` | `tests/python` | the PostgreSQL service, two created databases, `extra-commands`, and that the job passes with `format-check: false`, `pyright: false` and `audit: false` (their skip expressions are evaluated; a skipped step shows as skipped in the run log) |
| `node` | `tests/node` (no dependencies) | `npm ci`, the audit step runs (no dependencies, so it has nothing to find), the four scripts |
| `bun` | `tests/bun` (no dependencies) | every optional tool, the environment, preparation and report inputs, a test and a build |
| `container` | `tests/container` | hadolint and a build; `publish: false`, so nothing is pushed |
| `scripts` | `tests/scripts` | shellcheck, PSScriptAnalyzer, py_compile and ruff on the fixture files, the self-test under a non-default `python-version`, and that `exclude` skips a deliberately broken file (each job's log lists the files it checked), and each job's file count (asserted by `ci-ok`) |
| `scripts-none` | none (`exclude: "*"`) | a repository with no loose scripts passes and checks nothing (its three file counts, asserted by `ci-ok`, are 0) |
| `secrets` | this repository | gitleaks over the history of the checked-out commit |
| `public-content` | this repository | no client named in its files, file names, commit messages, or a pull request's title, description or branch name (above) |
| `ci-ok` | none | fails when any job above failed, was cancelled or was skipped, when the `scripts` job reported a missing or zero file count, when `scripts-none` checked any file, or when the `workflows` job reported no ci-ok workflow |

Move `v1` only to a commit on `main`: it passed this CI as an up-to-date pull request.

## Add CI to a repository

Every repository has the same CI rules, checked on each pull request (below, "One standard"). From the
repository on GitHub, go to **Actions → New workflow** and add **SpeedB3 CI** and **SpeedB3 CI after
merge** under "By SpeedB3". In SpeedB3 CI keep the language jobs your code needs and give them their
inputs; leave the rest of both files as it is. Or copy the language jobs of a repository with the same stack:

| Repository | Jobs |
|---|---|
| internal-GenAIFinOps | backend (Python + PostgreSQL 18 + OpenAPI drift check), frontend, workflows, secrets, image (`genaifinops-backend`, built, not published yet) |
| internal-MigrationFinOps | python (PostgreSQL 18, `-n auto`, schema and ledger checks), workbench, workflows, secrets |
| internal-teamWorkflowAutomation | python, scripts (`scripts/*.ps1`), workflows, secrets (the poll workflows stay repo-specific) |
| team-vault-skills | scripts (Python, shell, PowerShell; evals and templates skipped), workflows, secrets |
| team-vault-templates | scripts (Python, shell, PowerShell; scaffolds and fixtures skipped), workflows, secrets |

The rows describe each `ci.yml` once its CI pull request (ci-ok gate, secret scan, Dependabot) has merged.

Every `ci.yml` ends with a `ci-ok` job that `needs` all the others and runs with `if: always()`. It is the only
check the ruleset requires, so a new job must be added to its `needs` list, or it isn't enforced. It fails
when a job failed, was cancelled or was skipped. No check notices a language job that is removed together
with its `needs` entry, so a reviewer reads every change to `ci.yml` for that. Then add the repository's
`CODEOWNERS`, ruleset (below) and `.github/dependabot.yml`.

### One standard

The `workflows` job ([`actionlint.yml`](.github/workflows/actionlint.yml)) fails a pull request whose
workflows leave the standard ([`.github/ci-standard.sh`](.github/ci-standard.sh), always read from `v1`,
whatever ref a repository calls the shared workflows with):

(In a repository whose default branch isn't `main`, its name stands wherever these rules and the
starters say `main` or `$default-branch`.)

- `ci.yml` has the starter's name, triggers, permissions and concurrency, the `workflows` and `secrets`
  jobs and the `ci-ok` gate, word for word (only the `needs` of `ci-ok` differ), and nothing else at the
  top level. Every other job calls a shared workflow of this repository at `@v1` and sets only `with`
  and `needs` (an `image` job also `packages: write`). What an input runs, `extra-commands` say, is
  left to the reviewer.
- `ci-merged.yml` is the starter's, word for word. Its `ci` job may add `packages: write`, for an `image` job.
- No workflow runs on `push` or `pull_request_target`, and no other workflow runs on pull requests or
  has a `ci-ok` job (the rulesets accept any job of that name). Scheduled and manual workflows are allowed.

So a check of a repository's own goes into a shared workflow here, as an input every repository can
use, not into one `ci.yml`. This repository's CI tests the script (its `standard` job), and leaves this
repository itself out, because its CI runs the shared workflows from the commit (`./` paths).

### Private dependencies

A uv project can depend on a package in a private repository of this organisation
(`name @ git+https://github.com/SpeedB3/...@tag` in `pyproject.toml`). The job's own token cannot read another
private repository, so `python-uv.yml` gets a token from the organisation's GitHub App instead. That token can
only read the repositories in `app-repositories` (required), only the install step gets it, and it is revoked
when the job ends. The uv cache is off for these jobs, because a later run, a fork's included, could restore
wheels built from the private source:

```yaml
    uses: SpeedB3/.github/.github/workflows/python-uv.yml@v1
    with:
      app-client-id: ${{ vars.PRIVATE_DEPS_APP_CLIENT_ID }}
      app-repositories: the-private-repo
    secrets:
      app-private-key: ${{ secrets.PRIVATE_DEPS_APP_PRIVATE_KEY }}
```

Setup, once, by an organisation owner: create a GitHub App owned by the organisation with only the
**Contents: read** repository permission and no webhook, and install it on the dependency repositories only.
Store its client ID as the organisation variable `PRIVATE_DEPS_APP_CLIENT_ID` and a private key as the
organisation secret `PRIVATE_DEPS_APP_PRIVATE_KEY`, available to the repositories that use it. Dependabot
pull requests read Dependabot secrets, not Actions secrets, so add the key there too. For Dependabot to
propose a new tag of the dependency, grant it access to that repository in the organisation's Dependabot
settings.

The audit step skips the git dependency itself (it has no version to look up). Its own dependencies are in
the lock and are still audited. The CI of this repository does not run the token steps, because they need
the App: the first caller's run is their test.

## Merging into main

No one pushes to `main` directly. Every change arrives through a pull request, and the pull request
merges only when:

- **one code owner approves it.** The repository's `.github/CODEOWNERS` names the `@SpeedB3/devs` team, so
  the code owners are its members (Organisation → Teams → devs). The team needs write access to the
  repository, or GitHub ignores the line. A code owner can't approve their own pull request, so the team
  keeps at least two members. A new push after the approval needs a new approval.
- every review thread is resolved;
- `ci-ok` passes, which means every job in its `needs` list succeeded. Only GitHub Actions can report it.
- the branch is up to date with `main`. If `main` moved since the last run, click **Update branch** (or
  rebase): the push runs CI again, and the approval must be given again. Let the **author** update the
  branch: whoever pushes last can't approve, so a reviewer who clicks it needs a second reviewer. For a
  Dependabot pull request, comment `@dependabot rebase` instead, so Dependabot stays the last pusher.
- it merges with **Squash and merge**, the only method allowed: every commit on `main` is then a tree CI
  tested. A merge commit or a rebase would also bring the pull request's own commits, which CI never
  tested on their own.

Force pushes to `main` and deleting it are blocked. There is no bypass, including for organisation
owners. To change who can approve, change the team's members, or edit `CODEOWNERS` in a pull request
(which itself needs an approval).

### When CI runs

CI runs in two cases, and never on a plain push (to `main`, another branch or a tag):

- **A pull request into `main`** (`ci.yml`): when it opens, gets a new push, or is reopened. A merge needs
  the branch up to date and `ci-ok` green, so this run already tested the tree that lands on `main`, and
  nothing runs again after the merge. (This repository also runs it when a pull request is edited, to
  check a new title or description for public content.)
- **A merge into any other branch** (`ci-merged.yml`, which calls `ci.yml`): when a pull request into
  another branch (a stacked pull request into its parent, say) is merged, CI runs once on that branch's
  new commit. It is skipped when that branch has an open pull request into `main`, because that pull
  request runs CI on the new commit anyway. Its checks show as `ci / ...` and are not required anywhere.

A pull request into another branch gets no CI while it is open. Once its base pull request has merged, it
is retargeted to `main` (GitHub does it when the base branch is deleted on merge, which the repository
setting "Automatically delete head branches" does; otherwise retarget it by hand). The retarget alone runs
no CI, so there is no `ci-ok` yet and it cannot merge: update the branch, which runs CI on the up-to-date
tree. The base was squash-merged, so its old commits are still on the branch; instead of merging `main` in,
drop them with `git rebase --onto main <old base tip>` and force-push (the approval is then needed again).

No `ci-ok` after a retarget? Update the branch, or close and reopen the pull request.

A repository adds both files, from the "SpeedB3 CI" and "SpeedB3 CI after merge" starter workflows or by
copying `ci-merged.yml` from this repository as it is (give its `ci` job `packages: write` if a job of
`ci.yml` asks for it); `ci.yml` needs `workflow_call:` in its `on:`.

Each repository gets the same ruleset, [`rulesets/repo-default.json`](rulesets/repo-default.json). It
requires the single check `ci-ok`, so it doesn't change when jobs are added or renamed. A repository admin
applies it once, and updates it with `PUT` to `repos/SpeedB3/<repo>/rulesets/<id>`. Find the id with
`gh api repos/SpeedB3/<repo>/rulesets`.

```
gh api -X POST repos/SpeedB3/<repo>/rulesets --input rulesets/repo-default.json
```

### Every repository, including new ones

[`rulesets/org-default.json`](rulesets/org-default.json) is an organisation ruleset. It targets every
repository, including ones created later. Its `repository_name.protected` is `false`, so repositories can
still be renamed (with `true`, no repository in the organisation could be renamed). On each default
branch it requires a pull request with one approval, a new approval after a new push, and every review
thread resolved. In a repository with `CODEOWNERS`, that approval must come from a code owner. It also
blocks force pushes and deletion.

[`rulesets/org-ci.json`](rulesets/org-ci.json) adds the rest of the repository ruleset for every
repository: `ci-ok` on an up-to-date branch, and squash-only merges. A new repository therefore can't
merge anything until it has CI; the pull request that adds `ci.yml` passes on its own run.
[`rulesets/org-release-tags.json`](rulesets/org-release-tags.json) lets only repository admins create, move
or delete a release tag (`v*`, `*-v*`), because a tag can point at any commit, reviewed or not.
A repository whose owners run their own CI can be left out in the live rulesets (`repository_name.exclude`); that list is not published here.

The repository ruleset repeats these rules, so a repository stays protected where the organisation
rulesets are not applied. GitHub applies all of them, so the stricter value wins: a rule is relaxed only
when every file that has it changes. Only an organisation owner can apply them, with a token that has the
`admin:org` scope (`gh auth refresh -s admin:org`):

```
gh api -X POST orgs/SpeedB3/rulesets --input rulesets/org-default.json
gh api -X POST orgs/SpeedB3/rulesets --input rulesets/org-ci.json
gh api -X POST orgs/SpeedB3/rulesets --input rulesets/org-release-tags.json
```

GitHub Actions can't approve pull requests in any repository ("Allow GitHub Actions to create and approve
pull requests" is off), so an approval always comes from a person.

## Versions

Callers use `@v1`. `v1` is a tag that moves forward for compatible changes. A change to the standard (the
starter workflows or `.github/ci-standard.sh`) moves `v1` only once every repository follows it, because
every repository's next run checks it:

```
git tag -f v1 && git push -f origin v1
```

Only repository admins can create, move or delete a `v*` tag here (tag ruleset
[`rulesets/dot-github-tags.json`](rulesets/dot-github-tags.json)), because every caller runs whatever `v1`
points at. Admins can change rulesets anyway, so the bypass gives them nothing new.

A breaking change, such as a renamed input or output, or a new required input, gets `v2`. Repositories then
move over one at a time. A renamed job is not breaking for a repository whose ruleset requires only `ci-ok`. A new
check that can fail on existing code (for example a stricter tool version) is not breaking either, but run
each caller against the branch before moving `v1`. Third-party actions are pinned by commit SHA, with the
version in a comment. Dependabot proposes their updates every week. Seven tool versions sit in `run:` lines,
step `env` or step `with`, outside Dependabot, and are bumped by hand:
- actionlint (`.github/workflows/actionlint.yml`, the download-script commit and the version argument in the
  actionlint step's `run:` block);
- ruff for loose scripts (`.github/workflows/scripts.yml`, the `uvx ruff@...` line);
- shellcheck (`scripts.yml`, `SHELLCHECK_VERSION` and `SHELLCHECK_SHA256`, from the release's asset digest);
- PSScriptAnalyzer (`scripts.yml`, `PSSA_VERSION`);
- pip-audit (`python-uv.yml`, the `uvx pip-audit@...` line);
- gitleaks (`secrets.yml`, `GITLEAKS_VERSION` and `GITLEAKS_SHA256`);
- uv (`python-uv.yml` and `scripts.yml`, the `version:` of each `setup-uv` step).

The actionlint job uses the runner image's shellcheck (on `run:` blocks) and yq; they are not pinned, so an
image update can change that check.

In the project repositories, once each repository's CI pull request has merged, Dependabot
(`.github/dependabot.yml`) proposes weekly grouped updates of uv, npm and GitHub Actions dependencies.
Dependabot security updates open a fix pull request when GitHub publishes an advisory for a dependency,
independent of the audit steps.
