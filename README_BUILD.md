# Build Scaffold Notes

## Folder Layout

- `scenes/` — Godot scene files.
- `scripts/` — GDScript files.
- `data/` — level data, encounter tables, resources, and tuning data.
- `tests/` — headless tests and validation scripts.
- `art/` — source art, atlases, and imported assets.
- `build/` — exported web output (`build/web/index.html`).

## Contract For Later Code

The following names and paths are fixed. Code written by other tasks must honor them exactly.

### Input Actions

- `move_left`
- `move_right`
- `jump`
- `whip`
- `crouch`
- `pause`

### Main Scene Node Tree

Scene file: `res://scenes/main.tscn`

- `Main` (Node2D)
  - `Player` (CharacterBody2D) — script `res://scripts/player.gd`
  - `Level` (Node2D) — script `res://scripts/level.gd`
  - `Camera2D` — script `res://scripts/camera_rig.gd`
  - `HUD` (CanvasLayer) — script `res://scripts/hud.gd`
  - `Audio` (Node) — script `res://scripts/audio.gd`

### Expected Script Paths

- `res://scripts/player.gd`
- `res://scripts/level.gd`
- `res://scripts/camera_rig.gd`
- `res://scripts/hud.gd`
- `res://scripts/audio.gd`

### Viewport

- Logical viewport: `1280x720`
- Stretch mode: `canvas_items`
- Stretch aspect: `keep`
