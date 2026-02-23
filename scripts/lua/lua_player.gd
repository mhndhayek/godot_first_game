# player.gd
extends CharacterBody2D

@export var speed : float = 120.0

# Node references
@onready var anim_tree   : AnimationTree   = $AnimationTree
@onready var anim_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var walk_texture : Texture2D = preload("res://assets/The Female Adventurer - Free/The Female Adventurer - Free/Walk/walk.png")
@onready var idle_texture : Texture2D = preload("res://assets/The Female Adventurer - Free/The Female Adventurer - Free/Idle/Idle.png")
# The BlendSpace node is the root of the tree, so we expose it like this:

var last_dir := Vector2.DOWN
var is_idle := true

func _physics_process(delta: float) -> void:
	var dir = _get_input_dir()
	velocity = dir * speed
	move_and_slide()

	if dir == Vector2.ZERO:
		if not is_idle:
			# Just switched to idle
			anim_tree.active = false
			sprite.texture = idle_texture
			# Play idle animation based on last_dir
			if abs(last_dir.x) > abs(last_dir.y):
				if last_dir.x > 0:
					anim_player.play("idle_right")
				else:
					anim_player.play("idle_left")
			else:
				if last_dir.y > 0:
					anim_player.play("idle_down")
				else:
					anim_player.play("idle_up")
			is_idle = true
	else:
		if is_idle:
			# Just started moving
			anim_player.stop()
			anim_tree.active = true
			sprite.texture = walk_texture
			is_idle = false
		anim_tree.set("parameters/blend_position", dir)
		last_dir = dir

# ---------- Helpers ----------
func _get_input_dir() -> Vector2:
	var d = Vector2.ZERO
	if Input.is_action_pressed("move_right"): d.x += 1
	if Input.is_action_pressed("move_left"):  d.x -= 1
	if Input.is_action_pressed("move_down"):  d.y += 1
	if Input.is_action_pressed("move_up"):    d.y -= 1
	return d.normalized()
