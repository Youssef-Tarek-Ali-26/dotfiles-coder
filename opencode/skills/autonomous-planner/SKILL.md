---
name: autonomous-planner
description: Plan and execute autonomous multi-hour coding sessions with GitHub Projects, milestones, and OpenSpec-driven batches
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: autonomous-sessions
---

# Autonomous Work Planner

Plan batched, autonomous coding sessions that can run for hours without supervision. Combines OpenSpec for spec-driven development with GitHub Projects for tracking.

## When to Use This Skill

- User wants to "leave you to work overnight"
- User wants to plan features for autonomous execution
- User needs batched work with QA gates between phases
- User wants GitHub Project boards with milestones

## Prerequisites

Before using this skill, ensure:

1. **OpenSpec is installed** (if not, run: `npm install -g @fission-ai/openspec@latest && openspec init`)
2. **GitHub CLI authenticated** (`gh auth status`)
3. **Dev branch exists** (create with `git checkout -b dev` if needed)

## Workflow Overview

```
Phase 1: PLANNING (with user)
├── User provides high-level features/goals
├── Break into Batches (Milestones)
├── Create OpenSpec proposals for each feature
├── Create GitHub Issues with task lists
├── Create GitHub Project board
└── User approves plan

Phase 2: EXECUTION (autonomous)
├── Work through Batch 1
│   ├── For each Issue: /openspec-apply → implement → PR
│   └── Mark issues done as PRs created
├── Create "Batch 1 QA Gate" issue
└── STOP - await user review

Phase 3: REVIEW (with user)
├── User reviews all Batch 1 PRs
├── User merges approved PRs
├── User closes QA Gate issue
└── Proceed to Batch 2 (repeat Phase 2)
```

## Step-by-Step Process

### Step 1: Gather Requirements

Ask the user:
```
What features/improvements do you want built?
- Provide rough bullet points or descriptions
- Which are foundational vs. depend on others?
- Any areas off-limits or needing approval?
```

### Step 2: Create Batch Structure

Organize work into sequential batches:

```markdown
## Batch 1: Foundation (Milestone)
- Feature A: [description]
- Feature B: [description]
- Integration tests for A+B

## Batch 2: Advanced (depends on Batch 1)
- Feature C: [depends on A]
- Feature D: [standalone]

## Batch 3: Polish
- Performance optimizations
- Documentation updates
```

### Step 3: Create OpenSpec Proposals

For each feature, create an OpenSpec proposal:

```bash
# Use the /openspec-proposal command or ask AI:
"Create an OpenSpec proposal for [Feature A]"
```

This creates:
```
openspec/changes/<feature-name>/
├── proposal.md      # What and why
├── tasks.md         # Implementation checklist
└── specs/           # Spec deltas
```

### Step 4: Create GitHub Issues

For each feature, create a GitHub Issue:

```bash
gh issue create \
  --title "[Feature] Feature A - Brief description" \
  --body "$(cat <<'EOF'
## OpenSpec Reference
See `openspec/changes/<feature-name>/proposal.md`

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Dependencies
Blocked by: None (or #issue-number)

## Notes for AI
- Follow existing patterns in `path/to/reference`
- Run tests with `npm test`
- Lint with `npm run lint`
EOF
)" \
  --milestone "Batch 1: Foundation" \
  --label "feature,batch-1"
```

### Step 5: Create GitHub Project Board

```bash
# Create project
gh project create --title "Norn Platform Roadmap" --owner @me

# Get project number
PROJECT_NUM=$(gh project list --owner @me --format json | jq '.projects[0].number')

# Add issues to project
gh project item-add $PROJECT_NUM --owner @me --url <issue-url>
```

### Step 6: Create QA Gate Issues

For each batch, create a QA gate:

```bash
gh issue create \
  --title "[QA Gate] Batch 1 Review" \
  --body "$(cat <<'EOF'
## Batch 1 Completion Checklist

### PRs to Review
- [ ] PR #X - Feature A
- [ ] PR #Y - Feature B
- [ ] PR #Z - Integration Tests

### Verification
- [ ] All PRs pass CI
- [ ] Code review complete
- [ ] Manual testing done (if needed)
- [ ] No regressions

### Sign-off
Close this issue when Batch 1 is approved to unlock Batch 2.
EOF
)" \
  --milestone "Batch 1: Foundation" \
  --label "qa-gate,batch-1"
```

## Autonomous Execution Protocol

When executing autonomously:

### For Each Feature Issue:

1. **Read the OpenSpec proposal**
   ```
   Read openspec/changes/<feature>/proposal.md and tasks.md
   ```

2. **Apply the OpenSpec change**
   ```
   /openspec-apply <feature-name>
   ```

3. **Implement tasks** following the checklist

4. **Verify**
   - Run `lsp_diagnostics` on changed files
   - Run project tests if available
   - Ensure no type errors

5. **Create PR**
   ```bash
   git checkout -b feature/<feature-name>
   git add -A && git commit -m "feat: <description>"
   git push -u origin feature/<feature-name>
   gh pr create --title "feat: <description>" --body "Closes #<issue-number>..."
   ```

6. **Update Issue**
   - Link PR to issue
   - Check off completed tasks

7. **Archive OpenSpec change** (after PR merged)
   ```
   /openspec-archive <feature-name>
   ```

### Batch Completion:

1. Update QA Gate issue with all PRs created
2. **STOP and notify user**:
   ```
   Batch 1 complete. Created PRs:
   - PR #X - Feature A
   - PR #Y - Feature B
   
   Please review and close the QA Gate issue (#Z) when approved.
   I will continue with Batch 2 after approval.
   ```

## Issue Template

Use this template for all feature issues:

```markdown
## Summary
Brief description of what this feature does.

## OpenSpec Reference
`openspec/changes/<name>/proposal.md`

## Acceptance Criteria
- [ ] User can X
- [ ] System does Y when Z
- [ ] Error handling for edge case

## Implementation Tasks
- [ ] Add database migration
- [ ] Create API endpoint
- [ ] Update frontend component
- [ ] Write unit tests
- [ ] Update documentation

## Technical Notes
- Reference existing pattern: `path/to/example`
- Use library X for Y
- Consider edge case Z

## Dependencies
- Blocked by: #issue (or "None")
- Blocks: #issue (or "None")

## Definition of Done
- [ ] All tasks checked
- [ ] Tests pass
- [ ] Lint clean
- [ ] PR created and linked
```

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/openspec-proposal` | Create new feature proposal |
| `/openspec-apply` | Implement a proposal |
| `/openspec-archive` | Archive completed change |
| `openspec list` | View active changes |
| `openspec validate <name>` | Validate spec formatting |
| `gh issue create` | Create GitHub issue |
| `gh pr create` | Create pull request |
| `gh project item-add` | Add issue to project board |

## Anti-Patterns

NEVER:
- Continue to next batch without user approval at QA gate
- Create PRs that merge to main directly (use dev branch)
- Skip writing tests for new features
- Ignore failing CI checks
- Work on issues not in the current batch

ALWAYS:
- Create one PR per feature/issue
- Link PRs to issues with "Closes #X"
- Update task checklists as you complete work
- Stop at QA gates and wait for user
- Follow existing codebase patterns
