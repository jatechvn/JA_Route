---
name: auto-changelog
description: Skill that automatically creates or updates the RELEASE_NOTES.md file based on the git commit history since the most recent version (tag). Activates when the user wants to write release notes automatically or prepare before a release.
---

# Auto Changelog Skill

This skill helps the Agent automate writing `RELEASE_NOTES.md` in preparation for publishing a new release (works well together with the `new-release` skill).

## Execution Process (For Agent)
1. **Find the latest tag:** Run `git describe --tags --abbrev=0` to find the most recent tag.
2. **Get the commit list:** Run `git log <tag_gần_nhất>..HEAD --pretty=format:"%s"` to get the new commits.
3. **Categorize and translate:** Read the commit messages, automatically categorize them into groups (Features, Bug Fixes, Chores), and translate the content into Vietnamese or the language requested by the user in a clear, friendly way.
4. **Update the file:** Update this content into the `RELEASE_NOTES.md` file. Make sure the file is nicely formatted in Markdown.
5. **Notify:** Report back to the user that the file is ready for the next step (calling `new-release`).
