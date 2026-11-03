# Shared CI/CD

Every SpeedB3 repository runs the same pipeline. The pipeline lives here as
[reusable workflows](https://docs.github.com/actions/using-workflows/reusing-workflows). Each repository
has only a short `.github/workflows/ci.yml` that calls them. A fix made here reaches every repository on
its next run.

| Workflow | Language | What it does |
|---|---|---|
| [`python-uv.yml`](.github/workflows/python-uv.yml) | Python (uv projects) | `uv sync --locked`, ruff lint and format check, pyright, pytest. It can start PostgreSQL and create the test databases. ruff and pytest must be dev dependencies, and pyright too unless `pyright: false`. |
| [`node.yml`](.github/workflows/node.yml) | TypeScript / JavaScript (npm) | `npm ci`, `npm audit` of runtime dependencies (high and above), then the package.json scripts you list. |
| [`container.yml`](.github/workflows/container.yml) | Dockerfile | hadolint, then the image build. Pushes to the default branch (`main`) and `v*` tags publish it to `ghcr.io/speedb3/<image>` with an SBOM and provenance. Pull requests only build it. |
| [`scripts.yml`](.github/workflows/scripts.yml) | Loose Python, shell, PowerShell | One job per language: py_compile + ruff bug rules + listed self-tests, shellcheck, PSScriptAnalyzer. It checks every such file in the repository, so list a uv project's Python files in `exclude` (e.g. `backend/*.py`), because Ruff runs with `--isolated` and ignores the project's config. |
| [`actionlint.yml`](.github/workflows/actionlint.yml) | GitHub Actions YAML | actionlint, with shellcheck on `run:` blocks. |

Each file's header shows how to call it, its `inputs` list every option, and it names the status checks it
reports.

## Tests of the pipeline

Each shared workflow has its own test. The [CI](.github/workflows/ci.yml) of this repository runs every
workflow from the current commit against a fixture project in [`tests/`](tests) (actionlint runs over this repository itself):

| Job | Fixture | Proves |
|---|---|---|
| `python` | `tests/python` | lock check, ruff, strict pyright, pytest, the `env` input |
| `python-postgres` | `tests/python` | the PostgreSQL service, two created databases, `extra-commands`, and that the job passes with `format-check: false` and `pyright: false` (their skip expressions are evaluated; a skipped step shows as skipped in the run log) |
| `node` | `tests/node` (no dependencies) | `npm ci`, audit, the four scripts |
| `container` | `tests/container` | hadolint and a build; `publish: false`, so nothing is pushed |
| `scripts` | `tests/scripts` | shellcheck, PSScriptAnalyzer, py_compile and ruff on the fixture files, the self-test, and that `exclude` skips a deliberately broken file (each job's log lists the files it checked) |
| `scripts-none` | nothing (everything excluded) | a repository without loose scripts passes |
| `workflows` | this repository | actionlint over all of the above |

Move `v1` only when this CI is green on `main`.

## Add CI to a repository

From the repository on GitHub, go to **Actions → New workflow** and pick **SpeedB3 CI** under
"By SpeedB3". Keep the jobs you need. Or copy the `ci.yml` of a repository with the same stack:

| Repository | Jobs |
|---|---|
| internal-GenAIFinOps | backend (Python + PostgreSQL 18 + OpenAPI drift check), frontend, workflows, image (`genaifinops-backend`) |
| internal-MigrationFinOps | python (PostgreSQL 18, `-n auto`, schema and ledger checks), workbench, workflows |
| internal-teamWorkflowAutomation | python, scripts (`scripts/*.ps1`), workflows (the poll workflows stay repo-specific) |
| team-vaults | scripts (Python, shell, PowerShell; evals and templates skipped), workflows |

Then add the repository's `CODEOWNERS` and ruleset (below).

## Merging into main

No one pushes to `main` directly. Every change arrives through a pull request, and the pull request
merges only when:

- **one code owner approves it.** The code owners are the project members named in the repository's
  `.github/CODEOWNERS`. A code owner can't approve their own pull request, so each file names at least
  two people. A new push after the approval needs a new approval.
- every review thread is resolved;
- every CI job passes. Only GitHub Actions can report these checks.

Force pushes to `main` and deleting it are blocked. There is no bypass, including for organisation
owners. To change who can approve, edit `CODEOWNERS` in a pull request (which itself needs an approval).

The rules are one ruleset per repository, in [`rulesets/`](rulesets) (`dot-github.json` is this
repository). An owner applies them once; rulesets need admin access:

```
for r in internal-GenAIFinOps internal-MigrationFinOps internal-teamWorkflowAutomation team-vaults; do
  gh api -X POST repos/SpeedB3/$r/rulesets --input rulesets/$r.json
done
gh api -X POST repos/SpeedB3/.github/rulesets --input rulesets/dot-github.json
```

To update one later, find its id with `gh api repos/SpeedB3/<repo>/rulesets` and `PUT` the file to
`repos/SpeedB3/<repo>/rulesets/<id>`. When a job is added or renamed in a `ci.yml`, update the
`required_status_checks` in that repository's ruleset. A required check that never reports blocks every
merge. On the Team plan, rulesets are set per repository. An organisation-wide ruleset needs GitHub
Enterprise.

## Versions

Callers use `@v1`. `v1` is a tag that moves forward for compatible changes:

```
git tag -f v1 && git push -f origin v1
```

A breaking change, such as a renamed input, a new required input or a renamed job (it changes the
status-check names), gets `v2`. Repositories then move over one at a time. Third-party actions are pinned by
commit SHA, with the version in a comment. Dependabot proposes their updates every week. Two tool versions
sit in `run:` lines, outside Dependabot, and are bumped by hand: actionlint
(`.github/workflows/actionlint.yml`, the download-script commit and `1.7.12`) and ruff for loose scripts
(`.github/workflows/scripts.yml`, `ruff@0.17.3`).
