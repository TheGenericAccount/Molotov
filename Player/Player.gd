extends KinematicBody2D

export (int) var player_index=0
export (int) var speed = 1200
export (int) var dash_speed = 2300
export (int) var jump_speed = -3200
export(Vector2) var right_walljump=Vector2(-3200, 3200)
export (int) var gravity = 6000
export (int) var wall_gravity = 2000
export (float) var dash_time = 1.5
export (float, 0, 1.0) var friction = 0.1
export (float, 0, 1.0) var acceleration = 0.25
export (float, 0, 1.0) var walljump_friction = 0.1
export(float) var health=100

var early_jump_time=0.2
enum State{
	standing, walking, jumping, landing, dashing, walljumping
}
var current_state=State.standing
var input_direction=Vector2.ZERO
var can_dash=true
var can_jump=true
var jump_pressed_early=false
var last_walljump_direction=Direcion.none
var wall_direction=Direcion.none
onready var start_pos=position
onready var jump_timer=get_node("JumpDelayTimer")
onready var dash_timer=get_node("DashTimer")
onready var left_raycasts=get_node("Raycasts/Left").get_children()
onready var right_raycasts=get_node("Raycasts/Right").get_children()
onready var anim=$Sprite
var velocity = Vector2.ZERO
var time=0
var pull_force=Vector2.ZERO
var bottle_scene=preload("res://Environment/Bottle.tscn")
var can_throw=true
export (int) var facing_direction=-1
enum Direcion{
	left
	right
	none
}

func get_input(delta):
	var walking_direction = 0
	input_direction=Vector2.ZERO
	if Input.is_action_pressed(str("walk_right", player_index)):
		anim.play("walkR")
		facing_direction=1
		input_direction.x+=1
		walking_direction += 1
	if Input.is_action_pressed(str("walk_left", player_index)):
		anim.play("walkL")
		facing_direction=-1
		input_direction.x-=1
		walking_direction -= 1
	if walking_direction==0:
			if facing_direction==1:
					anim.play("standR")
			else:
					anim.play("standL")
#if Input.is_action_pressed(str("walk_up", player_index)):
#	input_direction.y-=1
#if Input.is_action_pressed(str("walk_down", player_index)):
#	input_direction.y+=1
	if not current_state==State.dashing:
		handle_walking(walking_direction, delta)



func handle_walking(walking_direction, delta):
	var fric=0
	if(current_state==State.walljumping):
		fric=walljump_friction
	else:
		fric=friction
	
	if walking_direction != 0 and (wall_direction==Direcion.none or is_on_floor()):
		if current_state==State.walljumping:
			current_state=State.landing
		if is_slower_than_max_speed():
			velocity.x = lerp(velocity.x, walking_direction * speed, acceleration)
		else:
			print("keep velocity")
	else:
		velocity.x = lerp(velocity.x, 0, fric*delta*60)

func test_fire():
	if Input.is_action_just_pressed(str("fire", player_index)):
			if !can_throw:
					return
			can_throw=false
			$ThrowTimer.start()
			fire()
		
func ThrowTimeout():
		can_throw=true

func fire():
		var bottle=bottle_scene.instance()
		bottle.global_position=global_position
		bottle.linear_velocity.x*=facing_direction
		get_node("../../PhysicsObjects").add_child(bottle)


func is_slower_than_max_speed():
	var is_slower=false
	if velocity.x>0:
		if velocity.x<wall_direction*speed:
			is_slower=true
	elif velocity.x<0:
		if velocity.x>-wall_direction*speed:
			is_slower=true
	else:
		is_slower=true
	return is_slower

func _physics_process(delta):
	time+=delta
	get_input(delta)
	test_fire()
	handle_gravity(delta)
	var snap = Vector2.DOWN * 16 if is_on_floor() else Vector2.ZERO
	if current_state==State.dashing:
		velocity+=pull_force*1
	else:
		velocity+=pull_force
	handle_grounding()
	handle_dashing()
	handle_jumping()
	handle_state()
	check_for_dying()
	#velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP)
	velocity = move_and_slide(velocity, Vector2.UP)

func handle_gravity(delta):
	var grav=gravity
	if(wall_direction<2):
		if velocity.y>0:
			grav=wall_gravity
	if not pull_force==Vector2.ZERO:
		grav=0
	if not current_state==State.dashing:
		velocity.y += grav * delta

func handle_state():
	if(is_on_floor())and ((not current_state==State.dashing)):
		if abs(velocity.x)>0.1:
			current_state=State.walking
		else:
			current_state=State.standing
	elif current_state<4:
		if(velocity.y<0):
			current_state=State.jumping
		else:
			current_state=State.landing
#	else:
#		print(current_state)


func handle_grounding():
	if is_on_floor():
		can_dash=true
		can_jump=true
		last_walljump_direction=Direcion.none
	wall_direction=get_wall_direction()

func handle_dashing():
	if Input.is_action_just_pressed("dash") and can_dash:
		if input_direction==Vector2.ZERO:
				input_direction.x=1
		can_dash=false
		current_state=State.dashing
		var dash_dir=input_direction.normalized()*dash_speed
		velocity=dash_dir
		dash_timer.wait_time=dash_time
		dash_timer.start()

func handle_jumping():
	if Input.is_action_just_pressed(str("walk_up", player_index)):
		if current_state==State.dashing:
			current_state=State.landing
			velocity=Vector2.ZERO
			jump_pressed_early=false
		elif wall_direction<2:
			walljump()
		elif can_jump:
			jump()
		else:
			jump_pressed_early=true
			jump_timer.wait_time=early_jump_time
			jump_timer.start()
	elif jump_pressed_early and can_jump:
		jump_pressed_early=false
		jump()
	elif jump_pressed_early and wall_direction<2:
		jump_pressed_early=false
		walljump()

func walljump():
	if(wall_direction==Direcion.left):
		velocity=right_walljump
	else:
		velocity=Vector2(-right_walljump.x, right_walljump.y)
	last_walljump_direction=wall_direction
	current_state=State.walljumping

func get_wall_direction():
	var direction=Direcion.none
	var last_dir=wall_direction
	if last_walljump_direction==Direcion.left or last_walljump_direction==Direcion.none:
		for i in range(right_raycasts.size()):
			if right_raycasts[i].is_colliding():
				if not right_raycasts[i].is_in_group("killing"):
					direction=Direcion.right
					if last_dir==Direcion.none:
						velocity.y=0
	if last_walljump_direction==Direcion.right or last_walljump_direction==Direcion.none:
		for i in range(left_raycasts.size()):
			if left_raycasts[i].is_colliding():
				if not left_raycasts[i].is_in_group("killing"):
					direction=Direcion.left
					if last_dir==Direcion.none:
						velocity.y=0
	return direction

func jump():
	print("jump")
	can_jump=false
	velocity.y = jump_speed
	current_state=State.jumping



func check_for_dying():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider!=null:
			if collision.collider.is_in_group("killing"):
				if time>0.1:
					die()


func die():
	pull_force=Vector2.ZERO
	position=start_pos
	velocity=Vector2(0,0)
	get_parent().get_parent().get_node("Camera2D").reset_camera()
	print("player died")
	var dashes=get_node("/root/Main/Scene/MainGame/Environment/DashResets").get_children()
	for i in range(dashes.size()):
		dashes[i].visible=true
	var spawned_objects=get_node("/root/Main/Scene/MainGame/Environment/SpawnedObjects").get_children()
	for i in range(spawned_objects.size()):
		spawned_objects[i].queue_free()
	time=0

func _on_DashTimer_timeout():
	if current_state==State.dashing:
		current_state=State.landing


func _on_JumpDelayTimer_timeout():
	jump_pressed_early=false


func _on_LosingTile_body_entered(body):
	pass # Replace with function body.


func _on_CollisionArea_body_entered(body):
	if body.is_in_group("Normal")and current_state==State.dashing:
		print("fall")
		current_state=State.landing
		velocity=Vector2.ZERO
		jump_pressed_early=false




func _on_CollisionArea_area_entered(area):
	if area.is_in_group("Portal"):
		position=area.get_pos_to_teleport()
		area.queue_free()


func _on_Timer_timeout():
	print("test")


func damage(dmg):
		health-=dmg
		if health<=0:
				lose()

func flip_player_index():
	if player_index==0:
		return 1
	else:
		return 0

func lose():
	get_tree().get_root().get_node("Game").win(flip_player_index())
	queue_free()
