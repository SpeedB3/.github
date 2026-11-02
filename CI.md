# Shared CI/CD

Every SpeedB3 repository runs the same pipeline. The pipeline lives here as
[reusable workflows](https://docs.github.com/actions/using-workflows/reusing-workflows). Each repository
has only a short `.github/workflows/ci.yml` that calls them. A fix made here reaches every repository on
its next run.

| Workflow | What it does |
|---|---|
| [`python-uv.yml`](.github/workflows/python-uv.yml) | `uv sync --locked`, ruff lint and format check, pyright, pytest. It can start PostgreSQL and create the test databases. |
| [`node.yml`](.github/workflows/node.yml) | `npm ci`, then the package.json scripts you list (default `lint typecheck test build`). |
| [`container.yml`](.github/workflows/container.yml) | CD: builds a Docker image. Pushes to `main` and `v*` tags publish it to `ghcr.io/speedb3/<image>`; pull requests only build it. |
| [`actionlint.yml`](.github/workflows/actionlint.yml) | Lints the calling repository's workflow files. |

Each file's header shows how to call it, and its `inputs` list every option.

## Add CI to a repository

From the repository on GitHub, go to **Actions → New workflow** and pick **SpeedB3 CI** under
"By SpeedB3". Keep the jobs you need. Or copy the `ci.yml` of a repository with the same stack:

| Repository | Jobs |
|---|---|
| internal-GenAIFinOps | backend (Python + PostgreSQL 18), frontend, workflows, image (`genaifinops-backend`) |
| internal-MigrationFinOps | python (PostgreSQL 18, `-n auto`, schema and ledger checks), workbench, workflows |
| internal-teamWorkflowAutomation | python, workflows (the poll workflows stay repo-specific) |

## Versions

Callers use `@v1`. `v1` is a tag that moves forward for compatible changes:

```
git tag -f v1 && git push -f origin v1
```

A breaking change, such as a renamed input or a new required input, gets `v2`. Repositories then move
over one at a time. Third-party actions are pinned by commit SHA, with the version in a comment.

## Make CI required

To block merges on red CI, add a branch ruleset to each repository (**Settings → Rules → Rulesets**):
target the default branch, enable **Require status checks to pass**, and add the job checks (for example
`backend / python`, `frontend / node`). An organisation-wide ruleset that applies to every repository
needs GitHub Enterprise; on the Team plan, rulesets are set per repository.
