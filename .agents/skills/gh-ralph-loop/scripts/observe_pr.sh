#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: observe_pr.sh [options]

Observe the PR associated with the current branch and emit a JSON summary.

Options:
  --pr <number|url|branch>  Explicit PR reference for `gh pr view`
  --repo <owner/repo>       Override repository
  --wait-for-checks         Wait until checks finish via `gh pr checks --watch`
  --required-only           Restrict checks to required checks
  --interval <seconds>      Poll interval for watch mode (default: 10)
  -h, --help                Show this help

Exit codes:
  0   Clean: checks passed and no unresolved review threads / changes requested
  20  Failing checks exist
  30  Checks passed but review action is still required
EOF
}

die() {
  echo "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

repo=""
pr_ref=""
wait_for_checks=0
required_only=0
interval=10

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      [[ $# -ge 2 ]] || die "--pr requires a value"
      pr_ref="$2"
      shift 2
      ;;
    --repo)
      [[ $# -ge 2 ]] || die "--repo requires a value"
      repo="$2"
      shift 2
      ;;
    --wait-for-checks)
      wait_for_checks=1
      shift
      ;;
    --required-only)
      required_only=1
      shift
      ;;
    --interval)
      [[ $# -ge 2 ]] || die "--interval requires a value"
      interval="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

require_cmd gh
require_cmd jq

gh auth status >/dev/null

pr_fields='number,url,title,baseRefName,headRefName,reviewDecision'
pr_args=(pr view --json "$pr_fields")
if [[ -n "$pr_ref" ]]; then
  pr_args+=("$pr_ref")
fi
if [[ -n "$repo" ]]; then
  pr_args+=(--repo "$repo")
fi
pr_json="$(gh "${pr_args[@]}")"

pr_url="$(jq -r '.url' <<<"$pr_json")"
number="$(jq -r '.number' <<<"$pr_json")"
title="$(jq -r '.title' <<<"$pr_json")"
base_ref="$(jq -r '.baseRefName' <<<"$pr_json")"
head_ref="$(jq -r '.headRefName' <<<"$pr_json")"
review_decision="$(jq -r '.reviewDecision // "REVIEW_REQUIRED"' <<<"$pr_json")"

repo_slug="$(jq -rn --arg url "$pr_url" '$url | capture("github.com/(?<repo>[^/]+/[^/]+)/pull/(?<number>[0-9]+)$").repo')"
owner="${repo_slug%/*}"
repo_name="${repo_slug#*/}"

if [[ "$wait_for_checks" -eq 1 ]]; then
  watch_args=(pr checks --watch --interval "$interval")
  if [[ -n "$pr_ref" ]]; then
    watch_args+=("$pr_ref")
  fi
  if [[ "$required_only" -eq 1 ]]; then
    watch_args+=(--required)
  fi
  if [[ -n "$repo" ]]; then
    watch_args+=(--repo "$repo")
  fi

  set +e
  gh "${watch_args[@]}" >/dev/null
  watch_status=$?
  set -e
  if [[ "$watch_status" -ne 0 && "$watch_status" -ne 1 && "$watch_status" -ne 8 ]]; then
    exit "$watch_status"
  fi
fi

checks_args=(pr checks --json bucket,name,state,workflow,link)
if [[ -n "$pr_ref" ]]; then
  checks_args+=("$pr_ref")
fi
if [[ "$required_only" -eq 1 ]]; then
  checks_args+=(--required)
fi
if [[ -n "$repo" ]]; then
  checks_args+=(--repo "$repo")
fi
checks_json="$(gh "${checks_args[@]}")"

graphql_query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first: 20) {
            nodes {
              author { login }
              body
              createdAt
            }
          }
        }
      }
      reviews(first: 50) {
        nodes {
          state
          body
          submittedAt
          author { login }
        }
      }
    }
  }
}'

threads_payload="$(
  gh api graphql \
    -F query="$graphql_query" \
    -F owner="$owner" \
    -F repo="$repo_name" \
    -F number="$number"
)"

summary_json="$(
  jq -n \
    --arg pr_url "$pr_url" \
    --arg repo_slug "$repo_slug" \
    --argjson number "$number" \
    --arg title "$title" \
    --arg base_ref "$base_ref" \
    --arg head_ref "$head_ref" \
    --arg review_decision "$review_decision" \
    --argjson checks "$checks_json" \
    --argjson payload "$threads_payload" \
    '
    def unresolved_threads:
      $payload.data.repository.pullRequest.reviewThreads.nodes
      | map(select(.isResolved | not));
    def requested_changes:
      $payload.data.repository.pullRequest.reviews.nodes
      | map(select(.state == "CHANGES_REQUESTED"));
    {
      pull_request: {
        repo: $repo_slug,
        number: $number,
        url: $pr_url,
        title: $title,
        base_ref: $base_ref,
        head_ref: $head_ref
      },
      checks: {
        total: ($checks | length),
        buckets: ($checks | group_by(.bucket) | map({bucket: .[0].bucket, count: length})),
        failing: ($checks | map(select(.bucket == "fail"))),
        pending: ($checks | map(select(.bucket == "pending"))),
        passing: ($checks | map(select(.bucket == "pass")))
      },
      reviews: {
        review_decision: $review_decision,
        change_requests: requested_changes,
        unresolved_threads: unresolved_threads,
        unresolved_thread_count: (unresolved_threads | length)
      }
    }'
)"

printf '%s\n' "$summary_json"

has_failing_checks="$(jq -r '.checks.failing | length > 0' <<<"$summary_json")"
needs_review_action="$(jq -r '.reviews.unresolved_thread_count > 0 or .reviews.review_decision == "CHANGES_REQUESTED" or (.reviews.change_requests | length > 0)' <<<"$summary_json")"

if [[ "$has_failing_checks" == "true" ]]; then
  exit 20
fi

if [[ "$needs_review_action" == "true" ]]; then
  exit 30
fi

exit 0
