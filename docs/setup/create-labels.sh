#!/usr/bin/env bash
set -euo pipefail

# Requires: gh CLI authenticated (gh auth login)

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"
  gh label create "$name" --color "$color" --description "$description" --force
}

create_label "type:feature" "0075ca" "Feature (parent) issue"
create_label "type:task" "7057ff" "Plan-derived task (child) issue"
create_label "needs:triage" "fbca04" "Stub needs refinement before Ready"
create_label "risk:high" "d93f0b" "Escalate model tier during execution"

echo "Labels created."
