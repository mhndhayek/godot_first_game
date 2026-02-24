# fireball.gd — shared projectile used by the player and enemies.
# Extends CharacterBody2D so move_and_slide() handles wall collision natively.
extends CharacterBody2D

const _TEXTURE := preload("res://assets/projectiles/fireball.png")
const _SMOKE_SCRIPT := preload("res://scripts/projectiles/smoke_puff.gd")

const _FRAME_COUNT: int = 3
const _FRAME_DURATION: float = 0.1   # seconds per frame → 10 fps animation
const _LIFETIME: float = 1.8         # auto-despawn if nothing is hit
# fireball.png is 300×100px with 3 frames laid out horizontally (hframes=3, each 100×100px).
# Uniform scale 0.15 → 15×15px in-world, matching the smoke puff and ≈ player sprite width.
const _SPRITE_SCALE: Vector2 = Vector2(0.15, 0.15)

# collision_mask = 25 matches the player's mask:
# layers 1 + 4 + 5 (values 1 + 8 + 16) — stops on the same tiles the player stops on.
# collision_layer = 0 so no other body registers the fireball until enemies need it.
const _COL_MASK: int = 25

var _direction: Vector2 = Vector2.ZERO
var _speed: float = 0.0
var _anim_timer: float = 0.0
var _lifetime_timer: float = 0.0
var _hit: bool = false

var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = _COL_MASK
	_build_nodes()


func _build_nodes() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _TEXTURE
	_sprite.hframes = _FRAME_COUNT
	_sprite.scale = _SPRITE_SCALE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

	var shape := CircleShape2D.new()
	shape.radius = 5.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


# Called by the spawner (player or enemy) immediately after adding to the scene.
func launch(direction: Vector2, spd: float) -> void:
	_direction = direction.normalized()
	_speed = spd
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	if _hit:
		return

	velocity = _direction * _speed
	move_and_slide()

	# Animate through the 3 frames while in flight.
	_anim_timer += delta
	if _anim_timer >= _FRAME_DURATION:
		_anim_timer -= _FRAME_DURATION
		_sprite.frame = (_sprite.frame + 1) % _FRAME_COUNT

	# Collision: move_and_slide stopped us against something solid.
	if get_slide_collision_count() > 0:
		_on_impact()
		return

	# Lifetime: despawn if nothing was hit within range.
	_lifetime_timer += delta
	if _lifetime_timer >= _LIFETIME:
		_on_impact()


func _on_impact() -> void:
	if _hit:
		return
	_hit = true

	# Check if a chest was hit and open it.
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider and collider.has_method("open"):
			collider.open()

	var puff := _SMOKE_SCRIPT.new()
	# Add puff to the fireball's parent so it outlives the fireball node.
	get_parent().add_child(puff)
	puff.global_position = global_position

	queue_free()
