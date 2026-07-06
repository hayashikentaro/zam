# Repository Agent Instructions

- Keep this prototype lightweight. Avoid backend services, persistence, auth, or heavy UI frameworks unless the user explicitly asks for them or they become clearly necessary.
- Treat `tmp/` as disposable reference material. Runtime code must not depend on files under `tmp/`; copy any required assets or samples into tracked project files first.
- Keep battle logic independent from rendering. TypeScript should own battle rules, protocol definitions, sample turn outputs, and logic tests.
- Godot should own production rendering, input feel, timing, audio/visual synchronization, and battle UI preview scenes.
- Verify Godot UI and animation behavior in Godot preview scenes or the actual Godot scene, not only through external mocks or web prototypes.
- After changing UI, always launch the app or relevant Godot scene before finishing, and report what was launched.
- For battle UI work, add or update a focused preview scene when practical so individual components can be adjusted without running the full game flow.
- After implementation, run the smallest relevant verification command or manual preview check and report what was checked.
- After making repository changes, always commit and push those changes before finishing the task, unless the user explicitly says not to.
