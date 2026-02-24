# Newbie Game — Claude Code Project Instructions

## What This Project Is
A top-down 2D game built in **Godot 4.6+** using **GDScript only**.
Currently has two layers:
- **Simple player scene** (`Scenes/Player.tscn`) — 8-directional movement, AnimationTree blending. Starting point for custom game development.
- **LimboAI combat demo** (`demo/`) — Wave-based combat (10 rounds, 9 enemy archetypes) using behavior trees and hierarchical state machines. Reference implementation for AI patterns.

The goal is to grow the simple player scene into a full top-down 2D game, drawing patterns from the demo where useful.

## Tech Stack
| Tool | Version | Notes |
|------|---------|-------|
| Godot | 4.6.1 stable | Forward+ renderer, Vulkan |
| Language | GDScript only | No C# — ignore the [dotnet] section in project.godot |
| AI Framework | LimboAI | Behavior trees (BTPlayer) + state machines (LimboHSM) |
| Renderer | Forward+ | Set in project.godot |
| Input | Arrow keys | move_up/down/left/right defined in project.godot |

## Project Structure (Key Files)
```
godot_first_game/
├── CLAUDE.md                        # This file
├── project.godot                    # Engine config — edit via editor UI, not manually
├── Simulator.tscn                   # MAIN SCENE (entry point)
├── Scenes/
│   ├── Player.tscn                  # Simple player (lua_player.gd)
│   └── World.tscn                   # Wraps Simulator.tscn
├── scripts/lua/lua_player.gd        # Player movement + animation (CharacterBody2D)
├── demo/
│   ├── agents/scripts/agent_base.gd # Base class for all combat agents
│   ├── agents/player/player.gd      # Combat player (extends agent_base)
│   ├── agents/player/states/        # LimboHSM states: idle, move, attack, dodge
│   ├── agents/scripts/health.gd     # Health component (class_name Health)
│   ├── agents/scripts/hitbox.gd     # Damage dealer (class_name Hitbox)
│   ├── agents/scripts/hurtbox.gd    # Damage receiver (class_name Hurtbox)
│   ├── ai/tasks/                    # 11 custom BT tasks (arrive, pursue, flank, etc.)
│   ├── ai/trees/                    # 9 .tres behavior tree resources
│   └── scenes/game.gd               # Wave spawner, UI, 10-round system
└── assets/
    ├── The Female Adventurer - Free/ # Player sprite (8-dir walk + idle)
    ├── Nature & village pack - ACT 1/# World tileset
    ├── Sunfield Road/               # Additional environment art
    └── Tiny_Pixel_World/            # Additional pixel art
```

## Coding Standards (GDScript)

### Naming Conventions
| Item | Convention | Example |
|------|-----------|---------|
| Variables, functions, params | `snake_case` | `move_speed`, `get_health()` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_SPEED = 120.0` |
| Classes (`class_name`) | `PascalCase` | `class_name Health` |
| Signals | `snake_case`, past tense | `health_depleted`, `player_died` |
| Nodes in scenes | `PascalCase` | `AnimationPlayer`, `CollisionShape2D` |
| Scene files | `PascalCase.tscn` | `Player.tscn` |
| Script files | `snake_case.gd` | `lua_player.gd`, `agent_base.gd` |
| Enum values | `UPPER_SNAKE_CASE` | `Direction.NORTH` |

### Type Annotations
Always annotate exports and function signatures:
```gdscript
@export var move_speed: float = 120.0
@export var health: int = 100

func take_damage(amount: int) -> void:
    pass

func get_direction() -> Vector2:
    return Vector2.ZERO
```

### Signal Declarations
```gdscript
signal health_depleted
signal damage_taken(amount: int)
```

### Structure Order in a Script
1. `class_name` (if needed)
2. `extends`
3. Signals
4. Constants
5. `@export` variables
6. Private variables (prefix with `_` for truly private)
7. `@onready` variables
8. `_ready()`, `_process()`, `_physics_process()`
9. Public functions
10. Private helper functions

### Rules
- Prefer `@onready` over accessing nodes in `_ready()`
- Use `CharacterBody2D` for anything that moves with collision
- Use `Area2D` for hitboxes/hurtboxes (see demo pattern)
- Use `move_and_slide()` for physics movement — not `position +=`
- Do NOT store scene-relative paths as strings; use `@onready var _node = $Path`
- Comments only where logic is non-obvious — no docstrings on obvious getters
- One class per file; `class_name` only when the class needs to be referenced globally

### Demo Patterns to Reuse
- Health/damage: copy `health.gd` + `hitbox.gd` + `hurtbox.gd` pattern
- Player state machine: see `demo/agents/player/states/` for LimboHSM usage
- Enemy AI: see `demo/ai/tasks/` for behavior tree task structure
- Wave spawning: see `demo/scenes/game.gd`

## Roles
Switch Claude's active role with a slash command:

| Command | Role |
|---------|------|
| `/developer` | GDScript programming, scenes, game systems |
| `/designer` | Game design, balance, level layout, player feel |
| `/ai-engineer` | LimboAI behavior trees, enemy logic, state machines |
| `/artist` | Asset integration, sprite setup, animations, tilemaps |
| `/tester` | QA, bug hunting, headless validation, edge cases |

## CLI Validation
```bash
# Validate project (no window):
"E:\Godot_v4.6.1-stable_win64_console.exe" --path "E:\Dev\godot_first_game" --headless --quit

# Run game:
"E:\Godot_v4.6.1-stable_win64_console.exe" --path "E:\Dev\godot_first_game"
```

## What NOT to Do
- Do not edit `project.godot` manually — use the Godot editor UI
- Do not add C# files — this is a GDScript-only project
- Do not add `.tmp` files to git — they are editor artifacts
- Do not modify the `demo/` directory for game features — treat it as read-only reference
- Do not create utility helpers for one-time use — keep it simple
- Do not use `_process()` for physics — always use `_physics_process()` for movement
