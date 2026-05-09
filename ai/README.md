# AI Specialisms

This directory contains prompt-engineering specifications ("specialisms") that guide Claude on recurring task types in this repository. Each specialism is a self-contained XML file bundling a task definition, step-by-step workflow, quality rubric, and formatting rules.

A `UserPromptSubmit` hook in `.claude/settings.json` injects this file into every session. Claude must identify the matching specialism before acting, or ask the user for direction if none clearly fits.

## Specialism index

| Name | File | Summary | Trigger keywords |
|------|------|---------|-----------------|
| docstrings | [docstrings.xml](docstrings.xml) | Add or normalize Julia docstrings on public symbols using the package's established convention | docstring, docs, document, missing doc, undocumented |
| documentation | [documentation.xml](documentation.xml) | Improve markdown pages under `docs/src/` for clarity and Documenter.jl consistency | markdown, docs page, readme, guide, tutorial, documenter |
| base-show | [base-show.xml](base-show.xml) | Add concise `Base.show` methods for types with unhelpful default REPL output | show, display, print, repr, REPL output |

## Adding a new specialism

1. Copy `_template.xml` → `ai/<name>.xml`.
2. Fill in all four sections (`<task>`, `<workflow>`, `<rubric>`, `<formatting>`).
3. Add a row to the index table above.
4. Keep steps general: describe how to *discover* targets (grep, module introspection) rather than naming specific files or symbols.

## How activation works

On every user prompt, the hook runs:

```sh
cat ai/README.md && printf '\n---\nSPECIALISM ROUTING ...\n'
```

Claude receives this index plus the routing instruction. It must:

- If a specialism clearly matches → read the full XML file, then follow its task/workflow/rubric/formatting.
- If no specialism clearly matches → pause and ask the user to pick an existing specialism or approve a new one before doing any work.

## Authoring principle

Specialisms describe a *class* of task, not a specific instance. Workflow steps say "find candidates by grepping for struct declarations" — not "edit `src/Foo.jl`". This makes every specialism valid as the codebase grows and refactors.
