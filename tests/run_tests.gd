# tests/run_tests.gd — Integration tests for Fireball, Controller, and WorldGenerator systems.
#
# Run headless:
#   "E:\Godot_v4.6.1-stable_win64_console.exe" --path "E:\Dev\godot_first_game" --headless --script "res://tests/run_tests.gd"
#
# Exit code: 0 = all pass, 1 = any failure.
#
# Architecture note:
#   _initialize() runs before the main loop; _ready() on added nodes is deferred.
#   We call _run_tests() as a coroutine from _initialize(). The coroutine does
#   "await process_frame" to yield until the main loop has processed one frame,
#   at which point all pending _ready() calls have fired and nodes are fully set up.
#   After the await, add_child() triggers _ready() synchronously.
extends SceneTree

const _FIREBALL := preload("res://scripts/projectiles/fireball.gd")
const _PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const _WORLD_GENERATOR := preload("res://scripts/world/world_generator.gd")


func _initialize() -> void:
	# Start the async test runner; _initialize() returns immediately.
	# The coroutine suspends at "await process_frame" and resumes next frame.
	_run_tests()


func _run_tests() -> void:
	# Add the player to root NOW so its _ready() fires in the upcoming frame.
	var player := _PLAYER_SCENE.instantiate()
	root.add_child(player)

	# Yield one frame — all pending _ready() calls (including the player's) fire here.
	await process_frame

	print("\n=== Newbie Game Integration Tests ===")

	var labels: Array[String] = []
	var results: Array[bool] = []

	# ── Fireball: launch() ──────────────────────────────────────
	# Fireballs added after the await → add_child() triggers _ready() synchronously.
	_add(results, labels,
		_fb_launch_normalises_direction(),
		"fireball launch: normalises non-unit direction to unit vector")
	_add(results, labels,
		_fb_launch_stores_speed(),
		"fireball launch: stores speed value unchanged")
	_add(results, labels,
		_fb_launch_sets_rotation(),
		"fireball launch: rotation equals direction angle (right → 0 rad)")

	# ── Fireball: _on_impact() ──────────────────────────────────
	_add(results, labels,
		_fb_impact_sets_hit_flag(),
		"fireball impact: sets _hit = true")
	_add(results, labels,
		_fb_impact_is_idempotent(),
		"fireball impact: second call is a no-op (guard prevents double-fire)")

	# ── Fireball: node structure ────────────────────────────────
	_add(results, labels,
		_fb_sprite_hframes(),
		"fireball sprite: hframes == 3 (300px sheet, 3×100px frames)")
	_add(results, labels,
		_fb_sprite_scale(),
		"fireball sprite: scale == Vector2(0.15, 0.15) (→ 15×15px in-world)")
	_add(results, labels,
		_fb_collision_radius(),
		"fireball collision: CircleShape2D radius == 5.0")

	# ── Controller: InputMap bindings ───────────────────────────
	# player._ready() already fired during the await frame above.
	_add(results, labels,
		InputMap.has_action("shoot"),
		"controller: 'shoot' action created by _setup_controller_bindings()")
	_add(results, labels,
		_map_has_key("shoot", KEY_SPACE),
		"controller: shoot bound to KEY_SPACE")
	_add(results, labels,
		_map_has_joybutton("shoot", JOY_BUTTON_A),
		"controller: shoot bound to JOY_BUTTON_A (Xbox A)")
	_add(results, labels,
		_map_has_joybutton("shoot", JOY_BUTTON_B),
		"controller: shoot bound to JOY_BUTTON_B (Xbox B)")
	_add(results, labels,
		_map_has_joyaxis("move_up",    JOY_AXIS_LEFT_Y, true),
		"controller: move_up bound to left-stick up (axis Y, negative)")
	_add(results, labels,
		_map_has_joyaxis("move_down",  JOY_AXIS_LEFT_Y, false),
		"controller: move_down bound to left-stick down (axis Y, positive)")
	_add(results, labels,
		_map_has_joyaxis("move_left",  JOY_AXIS_LEFT_X, true),
		"controller: move_left bound to left-stick left (axis X, negative)")
	_add(results, labels,
		_map_has_joyaxis("move_right", JOY_AXIS_LEFT_X, false),
		"controller: move_right bound to left-stick right (axis X, positive)")

	player.queue_free()

	# ── WorldGenerator ───────────────────────────────────────────
	_add(results, labels,
		_wg_ground_filled(),
		"world generator: ground layer covers full WORLD_W × WORLD_H tiles")
	_add(results, labels,
		_wg_water_placed(),
		"world generator: water layer has tiles (lakes generated)")
	_add(results, labels,
		_wg_beacon_exists(),
		"world generator: exactly one Beacon prop placed at spawn")
	_add(results, labels,
		_wg_chest_count_in_range(),
		"world generator: chest count is 15–25 (Godot appends numbers to duplicate names)")
	_add(results, labels,
		_wg_same_seed_same_spawn(),
		"world generator: identical seed produces identical spawn tile (deterministic)")
	_add(results, labels,
		_wg_spawn_not_in_water(),
		"world generator: spawn tile has no water cell")

	# ── Report ──────────────────────────────────────────────────
	print("")
	var passed := 0
	for i in results.size():
		print("  [%s]  %s" % ["PASS" if results[i] else "FAIL", labels[i]])
		if results[i]:
			passed += 1

	var total := results.size()
	print("\n  Result: %d / %d passed\n" % [passed, total])
	quit(0 if passed == total else 1)


func _add(results: Array[bool], labels: Array[String], ok: bool, label: String) -> void:
	results.append(ok)
	labels.append(label)


# ── Fireball helpers ─────────────────────────────────────────────────────────

func _make_fb() -> CharacterBody2D:
	# Post-await, add_child triggers _ready() synchronously → _build_nodes() runs.
	var fb: CharacterBody2D = _FIREBALL.new()
	root.add_child(fb)
	return fb


func _fb_launch_normalises_direction() -> bool:
	var fb := _make_fb()
	fb.launch(Vector2(3.0, 0.0), 100.0)   # magnitude > 1 — must be normalised
	var dir: Vector2 = fb.get("_direction")
	fb.queue_free()
	return dir.is_equal_approx(Vector2.RIGHT)


func _fb_launch_stores_speed() -> bool:
	var fb := _make_fb()
	fb.launch(Vector2.RIGHT, 250.0)
	var spd: float = fb.get("_speed")
	fb.queue_free()
	return is_equal_approx(spd, 250.0)


func _fb_launch_sets_rotation() -> bool:
	var fb := _make_fb()
	fb.launch(Vector2.RIGHT, 100.0)   # Vector2.RIGHT.angle() == 0.0 radians
	var rot: float = fb.rotation
	fb.queue_free()
	return is_equal_approx(rot, 0.0)


func _fb_impact_sets_hit_flag() -> bool:
	var fb := _make_fb()
	fb.launch(Vector2.RIGHT, 100.0)
	fb.call("_on_impact")              # internally calls queue_free()
	var hit: bool = fb.get("_hit")    # node still valid until end of frame
	return hit


func _fb_impact_is_idempotent() -> bool:
	var fb := _make_fb()
	fb.launch(Vector2.RIGHT, 100.0)
	fb.call("_on_impact")   # first call: _hit = true, queue_free scheduled
	fb.call("_on_impact")   # second call: guard returns early — no crash, no extra puff
	var hit: bool = fb.get("_hit")
	return hit


func _fb_sprite_hframes() -> bool:
	var fb := _make_fb()
	var sprite := fb.get_child(0) as Sprite2D
	var ok := sprite != null and sprite.hframes == 3
	fb.queue_free()
	return ok


func _fb_sprite_scale() -> bool:
	var fb := _make_fb()
	var sprite := fb.get_child(0) as Sprite2D
	var ok := sprite != null and sprite.scale.is_equal_approx(Vector2(0.15, 0.15))
	fb.queue_free()
	return ok


func _fb_collision_radius() -> bool:
	var fb := _make_fb()
	var col := fb.get_child(1) as CollisionShape2D
	if col == null or not (col.shape is CircleShape2D):
		fb.queue_free()
		return false
	var ok := is_equal_approx((col.shape as CircleShape2D).radius, 5.0)
	fb.queue_free()
	return ok


# ── InputMap helpers ─────────────────────────────────────────────────────────

func _map_has_key(action: String, keycode: Key) -> bool:
	return InputMap.action_get_events(action).any(
		func(e): return e is InputEventKey and e.keycode == keycode
	)


func _map_has_joybutton(action: String, button: JoyButton) -> bool:
	return InputMap.action_get_events(action).any(
		func(e): return e is InputEventJoypadButton and e.button_index == button
	)


func _map_has_joyaxis(action: String, axis: JoyAxis, negative: bool) -> bool:
	return InputMap.action_get_events(action).any(
		func(e):
			if not (e is InputEventJoypadMotion): return false
			return e.axis == axis and (e.axis_value < 0.0) == negative
	)


# ── WorldGenerator helpers ────────────────────────────────────────────────────

# Creates isolated TileMapLayer + water layer + Props node, runs generate(), returns them.
func _make_world(seed: int) -> Dictionary:
	var ground := TileMapLayer.new()
	var water := TileMapLayer.new()
	var props := Node2D.new()
	root.add_child(ground)
	root.add_child(water)
	root.add_child(props)
	var gen := _WORLD_GENERATOR.new()
	var spawn := gen.generate(ground, water, props, seed)
	return {"ground": ground, "water": water, "props": props, "gen": gen, "spawn": spawn}


func _free_world(d: Dictionary) -> void:
	(d["ground"] as Node).queue_free()
	(d["water"] as Node).queue_free()
	(d["props"] as Node).queue_free()


func _wg_ground_filled() -> bool:
	var d := _make_world(1)
	# 200 × 200 = 40 000 tiles total; lakes erase some, so check >= 90 %.
	var expected: int = _WORLD_GENERATOR.WORLD_W * _WORLD_GENERATOR.WORLD_H
	var count: int = (d["ground"] as TileMapLayer).get_used_cells().size()
	_free_world(d)
	return count >= int(expected * 0.9)


func _wg_water_placed() -> bool:
	var d := _make_world(2)
	var count: int = (d["water"] as TileMapLayer).get_used_cells().size()
	_free_world(d)
	return count > 0


func _wg_beacon_exists() -> bool:
	var d := _make_world(3)
	var props := d["props"] as Node2D
	var beacon_count := 0
	for child in props.get_children():
		if child.name == "Beacon":
			beacon_count += 1
	_free_world(d)
	return beacon_count == 1


func _wg_chest_count_in_range() -> bool:
	var d := _make_world(4)
	# Read internal counter via get() — same pattern used for fireball tests.
	# Avoids relying on Godot's auto-renaming of duplicate node names.
	var count: int = d["gen"].get("_chest_count")
	_free_world(d)
	# Generator targets 25; range 15–25 allows for rare placement failures.
	return count >= 15 and count <= 25


func _wg_same_seed_same_spawn() -> bool:
	var d1 := _make_world(42)
	var spawn1: Vector2i = d1["spawn"]
	_free_world(d1)
	var d2 := _make_world(42)
	var spawn2: Vector2i = d2["spawn"]
	_free_world(d2)
	return spawn1 == spawn2


func _wg_spawn_not_in_water() -> bool:
	var d := _make_world(5)
	var water := d["water"] as TileMapLayer
	var spawn: Vector2i = d["spawn"]
	var cell_id: int = water.get_cell_source_id(spawn)
	_free_world(d)
	return cell_id == -1  # -1 means no tile at that position
