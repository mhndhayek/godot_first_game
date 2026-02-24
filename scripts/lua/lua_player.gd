# lua_player.gd
extends CharacterBody2D

const _START_MENU_SCRIPT = preload("res://scripts/ui/start_menu.gd")

@export var speed: float = 120.0

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_texture: Texture2D = preload("res://assets/The Female Adventurer - Free/The Female Adventurer - Free/Walk/walk.png")
@onready var idle_texture: Texture2D = preload("res://assets/The Female Adventurer - Free/The Female Adventurer - Free/Idle/Idle.png")

var last_dir := Vector2.DOWN
var is_idle := true
var menu_mode: bool = true

var _menu: CanvasLayer
var _game_started: bool = false


func _ready() -> void:
	_menu = _START_MENU_SCRIPT.new()
	add_child(_menu)
	_menu.start_pressed.connect(_on_menu_start)
	_menu.quit_pressed.connect(_on_menu_quit)
	_menu.show_menu()


func _unhandled_input(event: InputEvent) -> void:
	if _game_started and not _menu.visible and event.is_action_pressed("ui_cancel"):
		menu_mode = true
		_menu.show_menu()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if menu_mode:
		velocity = Vector2.ZERO
		return

	var dir := _get_input_dir()
	velocity = dir * speed
	move_and_slide()

	if dir == Vector2.ZERO:
		if not is_idle:
			anim_tree.active = false
			sprite.texture = idle_texture
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
			anim_player.stop()
			anim_tree.active = true
			sprite.texture = walk_texture
			is_idle = false
		anim_tree.set("parameters/blend_position", dir)
		last_dir = dir


func set_menu_mode(enabled: bool) -> void:
	menu_mode = enabled


# ---------- Menu callbacks ----------

func _on_menu_start() -> void:
	_game_started = true
	menu_mode = false
	_menu.hide_menu()


func _on_menu_quit() -> void:
	get_tree().quit()


# ---------- Helpers ----------

func _get_input_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_action_pressed("move_right"): d.x += 1
	if Input.is_action_pressed("move_left"):  d.x -= 1
	if Input.is_action_pressed("move_down"):  d.y += 1
	if Input.is_action_pressed("move_up"):    d.y -= 1
	return d.normalized()
