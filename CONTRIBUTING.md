# Contributing Guidelines

Thanks for contributing to Foundry.

This project is a compile-time MVVM stack for Flutter. Contributions should improve developer experience, runtime reliability, or generated output quality while preserving architectural clarity.

## Core Principles

- Deliver direct user or developer value. Avoid speculative features.
- Reinforce MVVM boundaries. New behavior should make the MVVM workflow clearer, safer, or easier.
- Keep APIs intentional and minimal. Prefer small, composable additions over broad abstractions.
- Preserve backward compatibility unless the change is intentionally breaking and clearly documented.

## Definition Of A Good Feature

A feature is in scope when it does at least one of the following:

- Improves MVVM correctness (validation, guardrails, architecture checks).
- Improves generated code quality, safety, or maintainability.
- Reduces boilerplate for common Foundry workflows.
- Improves runtime ergonomics in foundry_core or foundry_flutter.
- Improves navigation safety or typed routing behavior.

A feature is out of scope when it:

- Adds complexity without clear measurable value.
- Introduces cross-layer coupling that weakens MVVM boundaries.
- Duplicates existing package responsibilities.

## Workspace Structure

- apps/liftlog: reference app and integration surface.
- packages/foundry_annotations: annotation contracts.
- packages/foundry_generator: source_gen/build_runner generation and validation.
- packages/foundry_core: runtime primitives and DI scopes.
- packages/foundry_flutter: Flutter integration widgets and scope bindings.
- packages/foundry_navigation_flutter: typed route and navigation runtime.

## Before You Start

- Open an issue for non-trivial changes (new feature, API changes, behavior changes).
- For breaking changes, propose migration plan and affected packages first.
- Keep PRs focused. Prefer one concern per PR.

## Required For Every Change

### 1) Tests

All code changes must include tests unless the change is truly docs-only.

- Add or update unit tests for changed logic.
- Add generator tests for codegen and validation changes.
- Add integration coverage in apps/liftlog when behavior spans package boundaries.
- Include regression tests for fixed bugs.

Minimum expectation:

- New behavior has at least one positive-path test.
- Error and edge cases are covered where relevant.

### 2) Code Documentation

Update code-level docs whenever public behavior changes.

- Public classes, methods, and annotations need accurate doc comments.
- Error messages and diagnostics should explain what failed and how to fix it.
- Generated output comments should stay consistent with source terminology.

### 3) README And Docs Updates

If behavior, API names, workflows, or commands change, update docs in the same PR.

At minimum, update:

- The package README where the change lives.
- Root README when cross-package workflows or architecture guidance change.
- Any relevant plans/spec docs if they are now stale.

## Coding Standards

- Follow existing Dart and Flutter style in the repository.
- Prefer clear, explicit naming over clever abstractions.
- Keep functions focused and side effects obvious.
- Avoid dead code and commented-out implementations.
- Do not rename user-facing APIs casually; if needed, document migration steps.

## MVVM Architecture Rules

- Views should not contain business logic.
- ViewModels should not depend on other ViewModels directly.
- Shared domain logic belongs in services.
- State should remain immutable for generated mixin workflows.
- Dependency wiring should remain constructor-first and deterministic.

## Generation And Build Changes

When changing annotations or generators:

- Update both annotations and generator validation paths.
- Regenerate affected .g.dart files and verify no stale output.
- Ensure diagnostics match current API naming and expected architecture.
- Keep builder names/extensions coherent across build.yaml and factory exports.

## Validation Checklist (Run Before PR)

From repo root:

- dart analyze packages/foundry_annotations packages/foundry_core packages/foundry_generator apps/liftlog
- In affected package/app, run build_runner as needed:
  - dart run build_runner build --delete-conflicting-outputs
- Run tests for affected packages/apps.

Optional workspace helpers:

- melos run analyze
- melos run test
- melos run format

## Pull Request Checklist

Include the following in your PR description:

- Problem statement and why this change is needed.
- Scope of changes by package.
- Test coverage added/updated.
- Docs/README updates made.
- Breaking changes and migration notes (if any).
- Follow-up work intentionally deferred (if any).

## Commit Guidance

- Use concise, descriptive commit messages.
- Keep related changes grouped together.
- Avoid mixing large refactors with behavior changes unless necessary.

## Breaking Changes

If your PR includes breaking behavior:

- Call it out clearly in title and description.
- Provide migration instructions and before/after examples.
- Update affected changelogs in the same PR.

## Review Expectations

Maintainers will prioritize:

- Architectural fit with Foundry MVVM.
- Test quality and regression risk.
- API clarity and naming consistency.
- Documentation completeness.
- Simplicity and long-term maintainability.

## Security And Safety

- Do not commit secrets, tokens, or credentials.
- Avoid adding dependencies without clear justification.
- Prefer safe defaults for generated/runtime behavior.

Thanks for helping improve Foundry.