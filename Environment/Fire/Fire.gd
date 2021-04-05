extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var players_in_range=[]
var spread_points_in_range=[]
export(float) var damage=10;
#var fire_scene=preload("res://Environment/Fire/Fire.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Fire_area_entered(area):
	spread_points_in_range.push_back(area)


func _on_Fire_area_exited(area):
	spread_points_in_range.erase(area)


func _on_Fire_body_entered(body):
	players_in_range.push_back(body)


func _on_Fire_body_exited(body):
	players_in_range.erase(body)


func damage():
		if players_in_range.size()>0:
				for player in players_in_range:
						player.damage(damage)

func spread():
		if spread_points_in_range.size()>0:
				for point in spread_points_in_range:
						if !point.used:
								point.create_fire()
