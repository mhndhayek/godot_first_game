# world_generator.gd — Procedural world generation.
# Pure logic class: no Node base, fully testable by instantiating alone.
# Call generate() with the three layers and a seed; returns spawn tile position.
class_name WorldGenerator

const WORLD_W: int = 200  # world width in tiles
const WORLD_H: int = 200  # world height in tiles
const TILE_SIZE: int = 8  # px per tile (matches existing tileset convention)

# TileSet atlas source IDs assigned by _build_tileset()
const SRC_GROUND: int = 0
const SRC_WATER: int = 1

# Confirmed tile atlas coordinates from tile_map_layer.tscn (Grounds.png, 8×8 grid)
const GROUND_TILES: Array[Vector2i] = [
	Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3),
	Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4),
]
const WATER_TILE: Vector2i = Vector2i(0, 0)  # first cell in water.png atlas

# Asset paths
const _PATH_GROUNDS := "res://assets/Nature & village pack - ACT 1/Nature/Grounds/Grounds.png"
const _PATH_WATER := "res://assets/Nature & village pack - ACT 1/Nature/Grounds/water.png"
const _PATH_TREE_MINI := "res://assets/Nature & village pack - ACT 1/Nature/mini trees.png"
const _PATH_TREE_NORMAL := "res://assets/Nature & village pack - ACT 1/Nature/normal trees.png"
const _PATH_TREE_TALL := "res://assets/Nature & village pack - ACT 1/Nature/tall trees.png"
const _PATH_ROCKS := "res://assets/Nature & village pack - ACT 1/Nature/Rocks.png"
const _PATH_TENT := "res://assets/Nature & village pack - ACT 1/Containers & Tents/Tents.png"
const _PATH_CAMPFIRE := "res://assets/Nature & village pack - ACT 1/Containers & Tents/Campfire.png"
const _PATH_WALK := "res://assets/The Female Adventurer - Free/The Female Adventurer - Free/Walk/walk.png"
const _PATH_CHEST_SCENE := "res://Scenes/Chest.tscn"

# Tree spritesheet layout: 384×192px, assumed 8 columns × 4 rows = 32 variants
const _TREE_HFRAMES: int = 8
const _TREE_VFRAMES: int = 4

# Campfire spritesheet: 192×32px = 6 frames × 32px each
const _CAMPFIRE_HFRAMES: int = 6
const _CAMPFIRE_FRAME_SIZE: int = 32

# Rocks spritesheet: 208×96px = 13 columns × 6 rows of 16×16px each
const _ROCK_HFRAMES: int = 13
const _ROCK_VFRAMES: int = 6
const _ROCK_FRAME_SIZE: int = 16

var _rng := RandomNumberGenerator.new()

# Tracks occupied tile positions to avoid overlapping props.
var _occupied: Dictionary = {}

# Counters populated during generate() — readable by tests via get().
var _chest_count: int = 0
var _tree_count: int = 0


# ── Public API ───────────────────────────────────────────────────────────────

# Fills ground/water layers and populates props. Returns spawn tile (Vector2i).
# Caller should convert to world position via get_world_position().
func generate(
		ground: TileMapLayer,
		water: TileMapLayer,
		props: Node2D,
		seed: int) -> Vector2i:
	_rng.seed = seed
	_occupied.clear()
	_chest_count = 0
	_tree_count = 0

	var tileset := _build_tileset()
	ground.tile_set = tileset
	water.tile_set = tileset

	_fill_ground(ground)
	var lake_centers := _place_lakes(ground, water)
	var spawn_tile := _find_spawn(lake_centers)
	_place_campfire(props, spawn_tile)
	_scatter_trees(water, props)
	_scatter_rocks(water, props)
	_scatter_chests(water, props)
	_scatter_tents(water, props)
	_scatter_monsters(water, props)

	return spawn_tile


# Converts a tile coordinate to its world-space centre position.
func get_world_position(tile: Vector2i) -> Vector2:
	return Vector2(
		tile.x * TILE_SIZE + TILE_SIZE * 0.5,
		tile.y * TILE_SIZE + TILE_SIZE * 0.5
	)


# ── TileSet construction ──────────────────────────────────────────────────────

func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Source 0: ground (Grounds.png)
	var gs := TileSetAtlasSource.new()
	gs.texture = load(_PATH_GROUNDS)
	gs.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for coord in GROUND_TILES:
		gs.create_tile(coord)
	ts.add_source(gs, SRC_GROUND)

	# Source 1: water (water.png)
	var ws := TileSetAtlasSource.new()
	ws.texture = load(_PATH_WATER)
	ws.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ws.create_tile(WATER_TILE)
	ts.add_source(ws, SRC_WATER)

	return ts


# ── Ground fill ───────────────────────────────────────────────────────────────

func _fill_ground(ground: TileMapLayer) -> void:
	for y in WORLD_H:
		for x in WORLD_W:
			var atlas_coord := GROUND_TILES[_rng.randi() % GROUND_TILES.size()]
			ground.set_cell(Vector2i(x, y), SRC_GROUND, atlas_coord)


# ── Lakes ─────────────────────────────────────────────────────────────────────

# Returns Array[Vector2i] of lake centre tiles (used to avoid placing spawn in water).
func _place_lakes(ground: TileMapLayer, water: TileMapLayer) -> Array[Vector2i]:
	var centers: Array[Vector2i] = []
	var lake_count := _rng.randi_range(5, 8)
	var margin := 20  # keep lakes away from world edges

	for _i in lake_count:
		var cx := _rng.randi_range(margin, WORLD_W - margin)
		var cy := _rng.randi_range(margin, WORLD_H - margin)
		var radius := _rng.randi_range(8, 14)
		centers.append(Vector2i(cx, cy))

		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				# Slightly irregular lakes via noise offset on the radius check
				var dist := sqrt(float(dx * dx + dy * dy))
				var jitter := _rng.randf_range(-1.5, 1.5)
				if dist <= radius + jitter:
					var tx := cx + dx
					var ty := cy + dy
					if tx >= 0 and tx < WORLD_W and ty >= 0 and ty < WORLD_H:
						var tile := Vector2i(tx, ty)
						water.set_cell(tile, SRC_WATER, WATER_TILE)
						ground.set_cell(tile, -1, Vector2i(-1, -1))  # erase ground under water
						_occupied[tile] = true

	return centers


# ── Spawn position ────────────────────────────────────────────────────────────

func _find_spawn(lake_centers: Array[Vector2i]) -> Vector2i:
	var cx := WORLD_W / 2
	var cy := WORLD_H / 2
	# Search outward from centre until a dry, unoccupied tile is found.
	for radius in range(0, 40):
		for attempt in 8:
			var angle := _rng.randf() * TAU
			var tx := cx + int(cos(angle) * radius)
			var ty := cy + int(sin(angle) * radius)
			var tile := Vector2i(tx, ty)
			if _is_safe_spawn(tile, lake_centers):
				return tile
	return Vector2i(cx, cy)  # fallback: world centre


func _is_safe_spawn(tile: Vector2i, lake_centers: Array[Vector2i]) -> bool:
	if _occupied.has(tile):
		return false
	for center in lake_centers:
		if tile.distance_to(center) < 22:
			return false
	return true


# ── Prop placement helpers ────────────────────────────────────────────────────

# Campfire: 192×32px = 6 frames of 32×32px. Animated via AnimatedSprite2D.
func _place_campfire(props: Node2D, spawn_tile: Vector2i) -> void:
	var tex: Texture2D = load(_PATH_CAMPFIRE)
	var anim := AnimatedSprite2D.new()
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.scale = Vector2(0.5, 0.5)

	var frames := SpriteFrames.new()
	frames.add_animation("burn")
	frames.set_animation_loop("burn", true)
	frames.set_animation_speed("burn", 8.0)
	for i in _CAMPFIRE_HFRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * _CAMPFIRE_FRAME_SIZE, 0, _CAMPFIRE_FRAME_SIZE, _CAMPFIRE_FRAME_SIZE)
		frames.add_frame("burn", atlas)

	anim.sprite_frames = frames
	anim.name = "Beacon"
	anim.position = get_world_position(spawn_tile)
	props.add_child(anim)
	anim.play("burn")
	_occupied[spawn_tile] = true


# Trees: 384×192px strip, 8×4 frames = 32 variants.
# Each tree is a StaticBody2D (collision_layer 1) so the player is blocked.
func _scatter_trees(water: TileMapLayer, props: Node2D) -> void:
	var tree_paths := [_PATH_TREE_MINI, _PATH_TREE_NORMAL, _PATH_TREE_TALL]
	# Start at 0.5 per sizing rule — adjust after in-game visual test.
	var tree_scales := [Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(0.5, 0.5)]
	var count := 350

	for _i in count:
		var tile := _random_dry_tile(water)
		if tile == Vector2i(-1, -1):
			continue
		var kind := _rng.randi() % 3

		var body := _make_solid_body("Tree", get_world_position(tile))
		var sprite := _make_sprite(tree_paths[kind], tree_scales[kind], _TREE_HFRAMES, _TREE_VFRAMES)
		sprite.frame = _rng.randi() % (_TREE_HFRAMES * _TREE_VFRAMES)
		body.add_child(sprite)

		var col := _make_circle_col(3.0, Vector2(0.0, 2.0))
		body.add_child(col)

		props.add_child(body)
		_mark_radius(tile, 2)
		_tree_count += 1


# Rocks: 208×96px = 13 cols × 6 rows of 16×16px. StaticBody2D with collision.
func _scatter_rocks(water: TileMapLayer, props: Node2D) -> void:
	var tex: Texture2D = load(_PATH_ROCKS)
	var count := 120

	for _i in count:
		var tile := _random_dry_tile(water)
		if tile == Vector2i(-1, -1):
			continue

		var body := _make_solid_body("Rock", get_world_position(tile))

		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.hframes = _ROCK_HFRAMES
		sprite.vframes = _ROCK_VFRAMES
		sprite.frame = _rng.randi() % (_ROCK_HFRAMES * _ROCK_VFRAMES)
		# 16px frame × 0.5 = 8px on screen — pebble-sized, within player hitbox.
		sprite.scale = Vector2(0.5, 0.5)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body.add_child(sprite)

		var col := _make_circle_col(3.5, Vector2.ZERO)
		body.add_child(col)

		props.add_child(body)
		_occupied[tile] = true


# Chests: instantiate Chest.tscn (StaticBody2D + AnimatedSprite2D + collision).
func _scatter_chests(water: TileMapLayer, props: Node2D) -> void:
	var chest_scene: PackedScene = load(_PATH_CHEST_SCENE)
	for _i in 25:
		var tile := _random_dry_tile(water)
		if tile == Vector2i(-1, -1):
			continue
		var chest: Node = chest_scene.instantiate()
		chest.name = "Chest"
		chest.position = get_world_position(tile)
		props.add_child(chest)
		_occupied[tile] = true
		_chest_count += 1


func _scatter_tents(water: TileMapLayer, props: Node2D) -> void:
	# Tents.png: 432×464px, multiple tent styles. Use first tent region (top-left quadrant).
	# Region 144×232px assumed for first tent. Scale to 48px logical wide: 48/144 ≈ 0.33.
	# Require visual test before sign-off.
	var cluster_count := _rng.randi_range(4, 6)
	for _c in cluster_count:
		var base_tile := _random_dry_tile(water)
		if base_tile == Vector2i(-1, -1):
			continue
		for offset_x in range(0, 3):
			var tile := Vector2i(base_tile.x + offset_x * 6, base_tile.y)
			if _occupied.has(tile):
				continue
			var sprite := _make_sprite(_PATH_TENT, Vector2(0.33, 0.33), 1, 1)
			sprite.name = "Store"
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0.0, 0.0, 144.0, 232.0)
			sprite.position = get_world_position(tile)
			props.add_child(sprite)
			_occupied[tile] = true


func _scatter_monsters(water: TileMapLayer, props: Node2D) -> void:
	# Placeholder: Female Adventurer walk.png with red tint.
	# TODO: restore demo/assets with `git restore demo/assets/` and copy enemy sprites
	# to assets/enemies/ before implementing proper combat in WorldGen.
	for _i in 50:
		var tile := _random_dry_tile(water)
		if tile == Vector2i(-1, -1):
			continue
		var sprite := _make_sprite(_PATH_WALK, Vector2(1.0, 1.0), 8, 6)
		sprite.name = "Monster"
		sprite.frame = _rng.randi() % 48
		sprite.modulate = Color(1.0, 0.25, 0.25, 1.0)  # red tint = placeholder
		sprite.position = get_world_position(tile)
		props.add_child(sprite)
		_occupied[tile] = true


# ── Node factories ────────────────────────────────────────────────────────────

# StaticBody2D on layer 1 — blocks player (mask 25 includes layer 1) and fireball.
func _make_solid_body(body_name: String, world_pos: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = world_pos
	return body


func _make_circle_col(radius: float, offset: Vector2) -> CollisionShape2D:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = offset
	return col


# ── Sprite factory ────────────────────────────────────────────────────────────

func _make_sprite(path: String, scale: Vector2, hframes: int, vframes: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.scale = scale
	sprite.hframes = hframes
	sprite.vframes = vframes
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite


# ── Tile helpers ──────────────────────────────────────────────────────────────

# Returns a random unoccupied, dry tile. Returns Vector2i(-1, -1) on failure.
func _random_dry_tile(water: TileMapLayer) -> Vector2i:
	for _attempt in 100:
		var tx := _rng.randi_range(1, WORLD_W - 2)
		var ty := _rng.randi_range(1, WORLD_H - 2)
		var tile := Vector2i(tx, ty)
		if _occupied.has(tile):
			continue
		if water.get_cell_source_id(tile) != -1:
			continue
		return tile
	return Vector2i(-1, -1)


func _mark_radius(center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			_occupied[Vector2i(center.x + dx, center.y + dy)] = true
