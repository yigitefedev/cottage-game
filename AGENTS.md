# Repository Guidelines

## Project Structure & Module Organization

This is a Godot 4.7 cozy farming game.. The main scene is `scenes/main/main.tscn`, set in `project.godot`.
-WORKLOG.md is your log file that contains changes made by other AI Agents. read the entries from the last commit to now everytime.
- `scripts/` contains GDScript grouped by domain: `player/`, `grid/`, `items/`, `crops/`, `managers/`, `workstations/`, `UI/`, and `dev tools/`.
- `scenes/` contains Godot scene files by feature or entity type.
- `resources/` contains reusable `.tres` data for items, crops, trees, actions, grids, and workstations.
- `art/`, `models/`, and `external/` hold assets, shaders, models, and third-party/sample content.
- `tools/` contains editor/import utilities such as `CropTableImporter.gd`.
- `data/import/` stores import sources like `crop_table.xlsx` and generated JSON.

## Build, Test, and Development Commands

Use the Godot editor as the primary development environment.

- `godot --path .` opens the project from the repository root.
- `godot --headless --path . --quit` performs a quick project load/import check in environments with the Godot CLI.
- Run the game from the editor to test `scenes/main/main.tscn`.

## Coding Style & Naming Conventions
Before editing, inspect related scripts first.
Keep naming and architecture consistent.
Use GDScript conventions already present in the project:
Always use explicit static types. Never rely on type inference.
Foundation first – build scaffolding (data models, interfaces, utils) before high-level features.
Design principles – data-driven, modular, extensible, compartmentalized. Follow language’s canonical formatter (PEP 8, rustfmt, go fmt, gdformat…).
class-definitions-order (tool → class_name → extends → signals → enums → consts → exports → vars).

## Commit & Logging Guidelines

- Do not create commits unless the user explicitly asks.
-At the end of each task summarize every meaningful every meaningful change, append a short entry to WORKLOG.md. 
- Each worklog entry should start with a date (dd.mm.yy - hour) and then with change type ("-added" , "-updates on", "-fixed") 
example: "[07.07.26 - 12.45] -added time simulation layer to simulate game while skipping time"
example: "[08.07.26 - 16.24] -updates on TileVisualManager to support layer based refresh"
example: "[05.07.26 - 06.32] -fixed a bug where items can entering the tool row when inventory is full"

-