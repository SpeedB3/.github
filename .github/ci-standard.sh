#!/usr/bin/env bash
# The SpeedB3 standard (CI.md, "One standard"), checked in the repository root against the starter
# workflows in the folder given as $1 (workflow-templates/ of SpeedB3/.github), with $default-branch
# read as the repository's default branch, $2 (main when left out):
#   - ci.yml has the starter's name, triggers, permissions, concurrency, standard jobs (workflows,
#     secrets) and ci-ok gate (its `needs` aside), nothing else at the top level, and every other
#     job calls a shared workflow at @v1 with only uses, with, needs and named secrets (an image
#     job also packages: write);
#   - ci-merged.yml is the starter's (its ci job may add packages: write, for an image job);
#   - no workflow runs on push or pull_request_target, and no other workflow runs on pull requests
#     or has a ci-ok job.
# actionlint.yml runs it in every repository but SpeedB3/.github; this repository's CI tests it
# (the standard job of ci.yml). Needs yq (mikefarah, v4), which the runner image has.
set -euo pipefail
starters=${1:?usage: ci-standard.sh <workflow-templates folder>}
command -v yq > /dev/null || { echo "::error::yq not found"; exit 1; }
std=$(mktemp -d)
branch=${2:-main}
for f in ci ci-merged; do
  t=$(< "$starters/speedb3-$f.yml")
  printf '%s\n' "${t//\$default-branch/$branch}" > "$std/$f.yml"
done

status=0
fail() { echo "::error file=$1::$2"; status=1; }
# One part of a workflow as one line of JSON, without comments.
part() { yq -o=json -I=0 "$2 | ... comments = \"\"" "$1"; }

ci=.github/workflows/ci.yml
merged=.github/workflows/ci-merged.yml
[ -f "$ci" ] || { echo "::error::$ci is missing (CI.md, \"One standard\")"; exit 1; }
[ -f "$merged" ] || { echo "::error::$merged is missing (CI.md, \"One standard\")"; exit 1; }

for q in .name .on .permissions .concurrency .jobs.workflows .jobs.secrets '.jobs."ci-ok" | del(.needs)'; do
  [ "$(part "$ci" "$q")" = "$(part "$std/ci.yml" "$q")" ] || fail "$ci" "$q differs from the SpeedB3 CI starter workflow"
done
[ "$(yq 'keys | sort | join(" ")' "$ci")" = "concurrency jobs name on permissions" ] \
  || fail "$ci" "only name, on, permissions, concurrency and jobs at the top level"
own=$(yq '.jobs | to_entries | .[] | select(.key != "ci-ok")
  | select((.value.uses // "") | test("^SpeedB3/\.github/\.github/workflows/(python-uv|node|bun|scripts|actionlint|secrets|container)\.yml@v1$") | not) | .key' "$ci")
[ -z "$own" ] || fail "$ci" "every job but ci-ok calls a shared workflow at @v1, not: $(echo "$own" | tr '\n' ' ')"
# A job calling a shared workflow sets only its inputs, named secrets (not inherit) and order; an image
# job (container.yml) also needs packages: write.
extra=$(yq '.jobs | to_entries | .[] | select(.key != "ci-ok")
  | select(
      ([.value | keys | .[] | select(. != "uses" and . != "with" and . != "needs" and . != "secrets" and . != "permissions")] | length) > 0
      or ((.value | has("secrets")) and (.value.secrets | tag) != "!!map")
      or ((.value | has("permissions")) and (
        (.value.permissions | keys | sort | join(",")) != "contents,packages"
        or .value.permissions.contents != "read" or .value.permissions.packages != "write")))
  | .key' "$ci")
[ -z "$extra" ] || fail "$ci" "a job calling a shared workflow takes only uses, with, needs and named secrets (and an image job packages: write), not: $(echo "$extra" | tr '\n' ' ')"

q='del(.jobs.ci.permissions)'
[ "$(part "$merged" "$q")" = "$(part "$std/ci-merged.yml" "$q")" ] \
  || fail "$merged" "differs from the SpeedB3 CI after merge starter workflow"
case "$(part "$merged" '.jobs.ci.permissions')" in
  null | '{"contents":"read","packages":"write"}') ;;
  *) fail "$merged" "its ci job may only add packages: write" ;;
esac

# The required check is any job called ci-ok, so only ci.yml may have one, and only ci.yml and
# ci-merged.yml run on pull requests.
shopt -s nullglob
for f in .github/workflows/*.yml .github/workflows/*.yaml; do
  events=$(yq '[.on] | flatten | .[] | ((select(tag == "!!map") | keys | .[]), select(tag == "!!str"))' "$f")
  if grep -qxE 'push|pull_request_target' <<< "$events"; then
    fail "$f" "no workflow runs on push or pull_request_target (CI.md, \"When CI runs\")"
  fi
  [ "$f" = "$ci" ] || [ "$f" = "$merged" ] || {
    if grep -qxE 'pull_request|merge_group' <<< "$events"; then
      fail "$f" "only ci.yml and ci-merged.yml run on pull requests"
    fi
    if [ "$(yq '[.jobs // {} | to_entries | .[] | select(.key == "ci-ok" or .value.name == "ci-ok")] | length' "$f")" != 0 ]; then
      fail "$f" "only ci.yml has a ci-ok job, the check the rulesets require"
    fi
  }
done
[ "$status" = 0 ] && echo "SpeedB3 standard: ok"
exit "$status"
