# chest.gd — Loot chest that opens when hit by a fireball.
# bouncing/Idle.png and bouncing/Open.png are 256×32 horizontal strips (8 frames × 32×32 px).
# Frames are extracted via AtlasTexture so AnimatedSprite2D shows one frame at a time.
extends StaticBody2D

const _IDLE_TEX := preload("res://assets/Nature & village pack - ACT 1/Chest/bouncing/Idle.png")
const _OPEN_TEX := preload("res://assets/Nature & village pack - ACT 1/Chest/bouncing/Open.png")

# Each frame in the strip is 32×32 px; 8 frames total.
const _FRAME_W: int = 32
const _FRAME_H: int = 32
const _FRAME_COUNT: int = 8

# 0.5 → 16×16 px on screen, keeping the chest smaller than the player (10×18 px hitbox).
const _SCALE := Vector2(0.5, 0.5)

# Collision layer 1 matches the tilemap physics layer so both the player
# (collision_mask 25 → includes layer 1) and fireball (mask 25) collide.
const _COL_LAYER: int = 1

signal opened

var _opened: bool = false
var _anim_sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = _COL_LAYER
	collision_mask = 0
	_build_nodes()


func _build_nodes() -> void:
	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.scale = _SCALE
	_anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := SpriteFrames.new()
	_add_strip_animation(frames, "idle", _IDLE_TEX, true, 8.0)
	_add_strip_animation(frames, "open", _OPEN_TEX, false, 8.0)

	_anim_sprite.sprite_frames = frames
	add_child(_anim_sprite)
	_anim_sprite.play("idle")

	var shape := RectangleShape2D.new()
	shape.size = Vector2(12.0, 10.0)
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


# Slices a horizontal sprite strip into individual AtlasTexture frames.
func _add_strip_animation(
		frames: SpriteFrames,
		anim: StringName,
		sheet: Texture2D,
		loop: bool,
		fps: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	frames.set_animation_speed(anim, fps)
	for i in _FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * _FRAME_W, 0, _FRAME_W, _FRAME_H)
		frames.add_frame(anim, atlas)


# Called by fireball on impact.
func open() -> void:
	if _opened:
		return
	_opened = true
	_anim_sprite.play("open")
	opened.emit()
