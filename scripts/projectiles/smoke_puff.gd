# smoke_puff.gd — one-shot impact puff; fades out then frees itself.
extends Node2D

const _TEXTURE := preload("res://assets/projectiles/smoke.png")
const _FADE_DURATION: float = 0.3
# smoke.png is 100×100px. Scale to ~15×15px to match the fireball's in-world size.
const _SPRITE_SCALE: Vector2 = Vector2(0.15, 0.15)


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _TEXTURE
	sprite.scale = _SPRITE_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, _FADE_DURATION)
	tween.tween_callback(queue_free)
