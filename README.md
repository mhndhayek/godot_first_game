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

The following keyboard inputs are configured in `project.godot`:

| Action      | Key         |
|-------------|-------------|
| `move_up`   | Arrow Up    |
| `move_down` | Arrow Down  |
| `move_left` | Arrow Left  |
| `move_right`| Arrow Right |

## Physics Layers

| Layer | Name          |
|-------|---------------|
| 1     | World         |
| 2     | Player        |
| 3     | onGround      |
| 4     | PlayerHeight  |
| 5     | 2PlayerH      |
| 6     | Roof          |

## Common Commands

- **Export Project** — Open the editor → *Project* → *Export*, select a platform, and click **Export Project**. Export templates must be downloaded for the matching Godot version.
- **Run Tests** — The project currently has no automated tests; add them under `tests/` if needed.

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
