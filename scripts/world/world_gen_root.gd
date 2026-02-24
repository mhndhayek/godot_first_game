# world_gen_root.gd — Root script for WorldGen.tscn.
# Orchestrates generation and positions the player at the campfire beacon.
extends Node2D

# Preload explicitly: class_name resolution is unreliable during scene-change in Godot 4.
const _GENERATOR_SCRIPT := preload("res://scripts/world/world_generator.gd")

@onready var _ground: TileMapLayer = $Ground
@onready var _water: TileMapLayer = $Water
@onready var _props: Node2D = $Props
@onready var _player: CharacterBody2D = $Player/Lua


func _ready() -> void:
	var gen: RefCounted = _GENERATOR_SCRIPT.new()
	var spawn_tile: Vector2i = gen.generate(_ground, _water, _props, randi())
	_player.global_position = gen.get_world_position(spawn_tile)
	_player.set_resume_mode(true)  # relabels "Start" → "Resume" in the in-world menu
