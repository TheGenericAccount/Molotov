extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var spread_points_in_range=[]
var hit_snapshot=[]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func ground_hit():
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func spread():
		if spread_points_in_range.size()<=0:
				spread_points_in_range=hit_snapshot
		if spread_points_in_range.size()>0:
				for point in spread_points_in_range:
					if !point.has_method("create_fire"):
						return
					if !point.used:
							point.create_fire()

func _on_HitArea_body_entered(body):
	print("hit", body.name)
	if body.is_in_group("Player"):
			return
	if body==self: 
			return
	hit_snapshot=spread_points_in_range
	$DestructTimer.start()


func _on_DestructTimer_timeout():
	spread()
	queue_free()


func _on_HitArea_area_entered(area):
	spread_points_in_range.push_back(area)


func _on_HitArea_area_exited(area):
	spread_points_in_range.erase(area)
