# Newbie Game Project

## Overview
This repository contains a Godot game project called **Newbie Game**. The project is ready for development and can be built and run directly from the Godot editor.

## Prerequisites
- **Godot Engine 4.x** (recommended) or any recent stable release that supports `.project.godot` files.
- A text editor or IDE of your choice (e.g., VS Code, Visual Studio).

> If you do not have Godot installed, download it from the [official website](https://godotengine.org/download).

## Project Structure
```
newbie-game/
├── .editorconfig
├── .gitattributes
├── .gitignore
├── icon.svg
├── icon.svg.import
├── project.godot          # Godot project file
├── Simulator.tscn
├── tile_map_layer.tscn
├── addons/                # Third‑party add‑ons (e.g., limboai)
└── ...                    # Asset, scene, script directories
```

- `project.godot` is the main project configuration file.
- Scenes such as `Simulator.tscn`, `tile_map_layer.tscn`, and all scenes under `Scenes/` are entry points for gameplay.

## How to Open the Project

1. **Launch Godot** – Start the Godot editor from your installed location or via command line:  
   ```bash
   godot --path newbie-game/
   ```
2. **Open the Project** – In Godot, click **Import**, navigate to `newbie-game/`, and select `project.godot`. The project will load with all assets and scenes.

## Building & Running

### From the Editor
- Once opened, press **Play** (the ▶ button) in the top toolbar.  
  - *Default scene*: `Simulator.tscn` (configured in Project Settings → Run → Main Scene).  
- You can also run any scene directly by right‑clicking it in the FileSystem dock and selecting **Run**.

### From Command Line
If you prefer to launch the game without opening the editor UI:

```bash
godot --path newbie-game/ --main-pack Simulator.tscn
```

> Replace `Simulator.tscn` with any other scene file to run that scene instead.

## Common Commands

- **Export Project** – Use Godot’s export templates to build binaries for Windows, macOS, Linux, etc.  
  - Open the editor → *Project* → *Export*, select a platform, and click **Export Project**.
- **Run Tests** – The project currently has no automated tests; add them under `tests/` if needed.

## Contributing

1. Fork or clone this repository.  
2. Create a new branch: `git checkout -b feature/<name>`.  
3. Commit your changes and push to your fork.  
4. Open a pull request against the main branch.

Please follow the existing coding style and add tests where appropriate.

## Troubleshooting

- **Missing Assets** – If you see “File not found” errors, ensure the `assets/` directory is present and has correct file paths.
- **Godot Version Mismatch** – Some assets may rely on Godot 4.x features. Use the matching version to avoid deprecation warnings.

## License

This project is released under the MIT license. See the [LICENSE](LICENSE) file for details.

---

Happy coding! 🚀