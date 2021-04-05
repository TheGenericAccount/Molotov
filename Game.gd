extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func win(index):
	get_node("Control/Panel/Label").text=str("player ", index+1, " won")
	$Control.visible=true
	$Timer.start()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		get_tree().paused=!get_tree().paused


func _on_Timer_timeout():
	get_tree().change_scene("res://Game.tscn")
