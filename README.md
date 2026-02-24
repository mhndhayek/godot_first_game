# Newbie Game Project

## Overview
This repository contains a Godot game project called **Newbie Game**. The project is written entirely in GDScript and can be opened and run directly from the Godot editor.

## Prerequisites
- **Godot Engine 4.6+** — the project requires Godot 4.6 or newer (the project file was upgraded to 4.6 on first import and will not open in earlier versions).
  - Download from the [official website](https://godotengine.org/download).
  - The standard (non-.NET) build is sufficient — no C# or .NET SDK required.
- **No additional dependencies** — all scripts are GDScript (`.gd`).
- **Vulkan-capable GPU** recommended — the project uses the **Forward+** renderer.

> Validated with `Godot_v4.6.1-stable_win64_console.exe` on Windows 11, NVIDIA GeForce RTX 5070 Ti (Vulkan 1.4.303).

## Project Structure
```
godot_first_game/
├── icon.svg
├── icon.svg.import
├── project.godot          # Godot project configuration
├── Simulator.tscn         # Main scene (entry point)
├── tile_map_layer.tscn
├── Scenes/
│   ├── Player.tscn
│   └── World.tscn
├── scripts/
│   └── lua/
│       └── lua_player.gd  # Player script
├── assets/                # Sprite packs and art assets
├── demo/                  # LimboAI demo scenes and scripts
└── addons/                # Editor plugins (copilot-advanced, ai_autonomous_agent)
```

- `project.godot` is the main project configuration file.
- `Simulator.tscn` is configured as the main scene in Project Settings.

## How to Open the Project

1. **Launch Godot** — start the Godot editor (e.g. `E:\Godot_v4.6.1-stable_win64_console.exe`).
2. **Import the Project** — in the Project Manager, click **Import**, navigate to the `godot_first_game/` folder, and select `project.godot`.
3. Godot will import all assets and resolve scene UIDs on first open. This step is required before any CLI usage.

## Building & Running

### From the Editor
- Once opened, press **Play** (the ▶ button) in the top toolbar.
  - Default scene: `Simulator.tscn` (set in Project Settings → Application → Run → Main Scene).
- To run any scene directly, right-click it in the FileSystem dock and select **Run**.

### From the Command Line

**Validate (headless — no window, exits cleanly if project is healthy):**
```bash
"E:\Godot_v4.6.1-stable_win64_console.exe" --path "E:\Dev\godot_first_game" --headless --quit
```

**Run the game:**
```bash
"E:\Godot_v4.6.1-stable_win64_console.exe" --path "E:\Dev\godot_first_game"
```

Both commands have been validated and run successfully on this machine.

## Input Mapping

Keyboard defaults are defined in `project.godot`. Controller bindings are registered at runtime by `lua_player.gd`.

| Action       | Keyboard       | Xbox Controller          |
|--------------|----------------|--------------------------|
| `move_up`    | Arrow Up       | Left stick up            |
| `move_down`  | Arrow Down     | Left stick down          |
| `move_left`  | Arrow Left     | Left stick left          |
| `move_right` | Arrow Right    | Left stick right         |
| `shoot`      | Space          | A button or B button     |
| `ui_cancel`  | Escape         | Start button (open menu) |

## Physics Layers

| Layer | Name          |
|-------|---------------|
| 1     | World         |
| 2     | Player        |
| 3     | onGround      |
| 4     | PlayerHeight  |
| 5     | 2PlayerH      |
| 6     | Roof          |

## Running Tests

Automated integration tests live in `tests/run_tests.gd` and cover the fireball system and controller bindings.

**Run the test suite (headless, no window):**
```bash
"E:\Godot_v4.6.1-stable_win64_console.exe" --path "E:\Dev\godot_first_game" --headless --script "res://tests/run_tests.gd"
```

Each test prints `[PASS]` or `[FAIL]` followed by a description. Exit code `0` means all tests passed; exit code `1` means one or more failed.

**What is tested:**

| Suite | Tests |
|-------|-------|
| Fireball — `launch()` | Direction normalisation, speed storage, rotation angle |
| Fireball — `_on_impact()` | `_hit` flag set, idempotency guard |
| Fireball — node structure | Sprite hframes, sprite scale, collision radius |
| Controller — InputMap | `shoot` action exists, KEY_SPACE + JOY_BUTTON_A/B bindings |
| Controller — movement | Left-stick axis bindings for all four move_* actions |

**Architecture note:** The runner extends `SceneTree` and uses `await process_frame` after adding scene nodes so that Godot's deferred `_ready()` calls fire before assertions run.

## Common Commands

- **Export Project** — Open the editor → *Project* → *Export*, select a platform, and click **Export Project**. Export templates must be downloaded for the matching Godot version.

## Addons

| Addon                  | Purpose                                      |
|------------------------|----------------------------------------------|
| `copilot-advanced`     | AI-assisted code completion in the editor    |
| `ai_autonomous_agent`  | LLM integration (Jan, Ollama, Gemini, etc.)  |

These addons are editor-only and do not affect gameplay.

## Contributing

1. Fork or clone this repository.
2. Create a new branch: `git checkout -b feature/<name>`.
3. Commit your changes and push to your fork.
4. Open a pull request against the `main` branch.

Please follow the existing coding style and add tests where appropriate.

## Troubleshooting

- **"Main scene's path could not be resolved from UID"** — The project has not been imported yet. Open it in the Godot editor first, then retry any CLI commands.
- **Missing Assets** — If you see "File not found" errors, ensure the `assets/` directory is present and file paths are correct.
- **Godot Version Mismatch** — Use Godot 4.6 or newer. The project file was upgraded to 4.6 on first import and will not open correctly in earlier versions.
- **`.tmp` files in `Scenes/`** — These are leftover temp files from editor sessions and can be safely deleted.

## License

This project is released under the MIT license. See the [LICENSE](LICENSE) file for details.
