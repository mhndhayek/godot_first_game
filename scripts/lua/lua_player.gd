# lua_player.gd
extends CharacterBody2D

const _START_MENU_SCRIPT := preload("res://scripts/ui/start_menu.gd")
const _FIREBALL_SCRIPT := preload("res://scripts/projectiles/fireball.gd")

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
	_setup_controller_bindings()
	_menu = _START_MENU_SCRIPT.new()
	add_child(_menu)
	_menu.start_pressed.connect(_on_menu_start)
	_menu.world_pressed.connect(_on_menu_world)
	_menu.quit_pressed.connect(_on_menu_quit)
	_menu.show_menu()


func _unhandled_input(event: InputEvent) -> void:
	if _game_started and not _menu.visible and event.is_action_pressed("ui_cancel"):
		menu_mode = true
		_menu.show_menu()
		get_viewport().set_input_as_handled()
		return

	# "shoot" action: spacebar, controller A, or controller B.
	if not menu_mode and event.is_action_pressed("shoot") and not event.is_echo():
		_shoot()
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


func set_resume_mode(enabled: bool) -> void:
	_menu.set_resume_mode(enabled)


# ---------- Combat ----------

func _shoot() -> void:
	var fireball := _FIREBALL_SCRIPT.new()
	get_tree().current_scene.add_child(fireball)
	fireball.global_position = global_position + last_dir * 20.0
	fireball.launch(last_dir, speed * 1.15)


# ---------- Menu callbacks ----------

func _on_menu_start() -> void:
	_game_started = true
	menu_mode = false
	_menu.hide_menu()


func _on_menu_world() -> void:
	get_tree().change_scene_to_file("res://Scenes/WorldGen.tscn")


func _on_menu_quit() -> void:
	get_tree().quit()


# ---------- Helpers ----------

func _get_input_dir() -> Vector2:
	# get_axis handles both digital keys and analog joystick correctly.
	var d := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up",   "move_down")
	)
	return d.normalized()


# ---------- Controller setup ----------

# Registers joypad events onto existing and new input actions at runtime.
# Called once in _ready() — avoids editing project.godot manually.
func _setup_controller_bindings() -> void:
	# Movement — left joystick mapped onto existing move_* actions.
	_add_joy_axis("move_up",    JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down",  JOY_AXIS_LEFT_Y,  1.0)
	_add_joy_axis("move_left",  JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X,  1.0)

	# Shoot — create action once, then add keyboard + A + B.
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		_add_key_event("shoot", KEY_SPACE)
	_add_joy_button("shoot", JOY_BUTTON_A)
	_add_joy_button("shoot", JOY_BUTTON_B)

	# Menu open / close — Xbox Start → ui_cancel (same as Escape).
	_add_joy_button("ui_cancel", JOY_BUTTON_START)

	# Menu confirm — A → ui_accept (confirm highlighted item).
	_add_joy_button("ui_accept", JOY_BUTTON_A)

	# Menu navigation — left stick → ui_up / ui_down.
	_add_joy_axis("ui_up",   JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("ui_down", JOY_AXIS_LEFT_Y,  1.0)


func _add_joy_button(action: String, button: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _add_joy_axis(action: String, axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


func _add_key_event(action: String, keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)
