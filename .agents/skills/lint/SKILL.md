---
name: lint
description: 'Use when linting, fixing lint errors, running rubocop, erb-lint, stylelint, or standard, checking code style, auto-correcting offenses, or cleaning up remaining manual lint violations in this Rails app.'
argument-hint: '[optional paths or files to lint]'
---

# Linting

Run and fix the configured linters for this Rails workspace using the project-standard workflow.

## When to Use

- Run project lint checks before finishing a change
- Auto-fix lint issues where safe fixes exist
- Review remaining lint violations that require manual edits
- Re-run lint after code changes to confirm the workspace is clean

## Available Linters

- Ruby: `bundle exec rubocop`
- ERB: `bundle exec erb_lint --lint-all`
- SCSS: `yarn run stylelint`
- JavaScript: `yarn run lint`

## Procedure

1. Decide scope.
   - If the user names specific files or directories, lint those when the tool supports it.
   - Otherwise, run the full project lint workflow.
2. Run auto-fix first.
   - Ruby: `bundle exec rubocop -A`
   - ERB: `bundle exec erb_lint --lint-all -a`
   - SCSS: `yarn run stylelint --fix`
   - JavaScript: `yarn run lint --fix`
3. Re-run the linters without fix flags.
   - Use the normal lint commands to surface any remaining violations.
4. Evaluate the result.
   - If everything passes, report that all lint checks pass.
   - If violations remain, summarize them by file, line, and rule name.
5. Decide whether to continue with manual fixes.
   - Ask the user before applying manual fixes.
   - If the user declines, stop and report the remaining issues.
6. One at a time, for each file with requiring manual fixes:
   1. Apply the necessary edits to fix them.
      - Follow the guidance in the "Suggested Fixes" section below for common violations.
      - Fix only real linter violations.
      - Avoid any unrelated code changes or refactors.
      - Fix only real linter violations.
      - If a violation requires a design decision or behavior change, ask the user if they would like to proceed before applying the fix or disable the lint rule.
   2. Allow the user to review the manual fixes before moving to the next file.
7. Re-run the affected linters after manual edits.
   - Confirm the modified files are clean.

## Decision Points

- If auto-fix resolves everything, stop and report success.
- If a lint rule requires a design tradeoff or behavior change, ask before applying a manual fix.
- If a linter appears to hang or produce no output, retry with a fresh terminal invocation before assuming success.

## Output Expectations

- For a clean run: `All lint checks pass.`
- For remaining issues, report them in a compact file-by-file format.
- When manual fixes are needed, explain what was changed and which linter issue it resolves.

## Suggested Fixes

- When disabling a lint rule, prefer an inline disable comment for just the specific line. If the rule cannot be disabled inline, disable the rule for the smallest possible scope (e.g., method, class).

### Ruby

- For `Layout/LineLength`: split into multiple lines only at word boundaries. If a clean split is not practical, add an inline disable comment for that line: `# rubocop:disable Layout/LineLength`.
- For `Metrics/AbcSize`, `Metrics/CyclomaticComplexity`, and `Metrics/PerceivedComplexity`: reduce complexity by extracting smaller methods or simplifying logic.
- For `Style/Documentation`: add a brief class comment describing the purpose of the class.
- For `Metrics/ParameterLists`: add an inline disable comment for that method: `# rubocop:disable Metrics/ParameterLists`.

## Quality Checks

- Auto-fix commands ran before manual edits
- Follow-up lint commands ran after fixes
- Remaining issues, if any, are clearly listed
- No lint rules were disabled unless explicitly requested
- No unrelated code changes were introduced