extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var used=false
var fire_scene=preload("res://Environment/Fire/Fire.tscn")
var fire_parent;

# Called when the node enters the scene tree for the first time.
func _ready():
		fire_parent=get_node("../../Burning")
func create_fire():
		used=true
		var fire=fire_scene.instance()
		fire.global_position=global_position
		fire_parent.add_child(fire)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
