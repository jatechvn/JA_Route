---
name: feature-scaffold
description: Skill that automatically generates the directory structure and boilerplate code for a new feature in Flutter (following Clean Architecture / MVVM conventions).
---

# Feature Scaffold Skill

This skill quickly generates boilerplate code when starting a new feature in the project.

## Execution Workflow (For Agent)
1. **Gather information:** Confirm the feature name (e.g., `login`, `payment`) and the architecture/state management in use (Riverpod, Bloc, Provider) if not already clear.
2. **Create directories:** Automatically create the feature directory under `lib/features/<feature_name>/` including:
   - `presentation/` (contains views, widgets, controllers/blocs)
   - `domain/` (contains entities, repository interfaces)
   - `data/` (contains models, datasources, repository implementations)
3. **Generate Boilerplate Code:** Create basic .dart files for the directories above with empty classes, including necessary imports and inheritance structure.
4. **Report:** List the files created and guide the user on where to start coding.
