#!/bin/bash
set -euo pipefail

PROJECT_DIR="/home/glemsom/Documents/git/dkvm-qemu"
SKILL_FILE="/home/glemsom/.pi/agent/skills/documentation-writer/SKILL.md"
PROVIDER="opencode-go"
MODEL="deepseek-v4-flash"

# Common instructions for every agent
COMMON_INSTRUCTIONS="
You are a Pi coding agent working on the DKVM QEMU project.
Any code changes must be committed and pushed to git (main branch).
After implementing the changes: (1) commit with a descriptive message, (2) push to origin main.
Then update the GitHub issue to reflect what was done.

BE CONCISE. Use caveman mode. Get it done.
"

mkdir -p /tmp/pi-delegation

delegate() {
    local ISSUE_NUM="$1"
    local SESSION_NAME="pi-issue-$ISSUE_NUM"
    local PROMPT_FILE="/tmp/pi-delegation/issue-$ISSUE_NUM-prompt.md"

    # Build the prompt file
    cat > "$PROMPT_FILE" << PROMPTEOF
# Task: Fix GitHub issue #$ISSUE_NUM

Project: DKVM QEMU (custom QEMU build with per-die asymmetric L3 cache patches)
Directory: $PROJECT_DIR

## Your skill
You MUST use the Diátaxis documentation framework loaded from the appended system prompt.

## Instructions
$COMMON_INSTRUCTIONS

## Steps
1. Read the issue: \`gh issue view $ISSUE_NUM\`
2. Read any relevant files mentioned in the issue
3. Implement the changes exactly as described in the issue
4. Commit and push to origin main
5. Update the GitHub issue: \`gh issue comment $ISSUE_NUM --body "Implemented in [commit hash]"\`
6. Close the issue if it's fully resolved: \`gh issue close $ISSUE_NUM\`

Get started now.
PROMPTEOF

    echo "Creating tmux session: $SESSION_NAME"
    tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" \
        "cd $PROJECT_DIR && cat '$PROMPT_FILE' | pi -p --provider $PROVIDER --model $MODEL --no-session --append-system-prompt '$SKILL_FILE' 2>&1 | tee /tmp/pi-delegation/$SESSION_NAME.log; echo '---DONE---' >> /tmp/pi-delegation/$SESSION_NAME.log; sleep 5"
}

# Delegate all 8 issues
delegate 21 "README.md too thin"
delegate 20 "How-to guide for local APK building"
delegate 19 "How-to guide for libvirt integration"
delegate 18 "CONTEXT.md dead stub"
delegate 17 "Architecture.md and cpuid-cache-encoding.md overlap"
delegate 16 "Typo in simulate-9950x3d.md"
delegate 15 "APK install tutorial"
delegate 14 "ADR-0001 contradicts patch structure"

echo ""
echo "All 8 delegations launched. Monitoring sessions..."
echo ""
echo "Quick commands:"
echo "  tmux ls                        # list sessions"
echo "  tmux attach -t pi-issue-16     # watch specific agent"
echo "  tail -f /tmp/pi-delegation/*.log  # watch all logs"
