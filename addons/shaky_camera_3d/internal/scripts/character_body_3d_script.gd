extends CharacterBody3D


const SPEED := 5.0

var total_number_of_animations: int
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: ShakyCamera3D = $ShakyCamera3D
@onready var current_animation_label = %CurrentTypeOfShake


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var current_anim_name: String
	for type_of_shake in camera.TypesOfShake:
		if camera.TypesOfShake[type_of_shake] == camera.type_of_shake:
			current_anim_name = type_of_shake
			break
	
	total_number_of_animations = camera.TypesOfShake.size()
	current_animation_label.text = "CURRENT TYPE OF SHAKE: " + current_anim_name


func _input(event: InputEvent):
	## Rotate camera if the mouse is captured.
	if (event is InputEventMouseMotion) and (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		rotate_camera(event.relative)


func _physics_process(delta):
	## Handle pressing "esc" key.
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	## Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	## Change animations on pressing "spacebar".
	if Input.is_action_just_pressed("ui_accept"):
		change_animation()

	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func change_animation() -> void:
	## Set animation to the next one.
	camera.type_of_shake = (camera.type_of_shake + 1) % total_number_of_animations
	
	## Find animation name as a string.
	var current_type_of_shake: String
	for type_of_shake in camera.TypesOfShake:
		if camera.TypesOfShake[type_of_shake] == camera.type_of_shake:
			current_type_of_shake = type_of_shake
			break
	
	## Update text label.
	current_animation_label.text = "CURRENT TYPE OF SHAKE: " + current_type_of_shake


func rotate_camera(mouse_axis : Vector2) -> void:
	const MOUSE_SENSITIVITY := 1.0
	const CAMERA_VERTICAL_ANGLE_LIMIT := PI / 2
	
	rotation.y -= mouse_axis.x * (MOUSE_SENSITIVITY/1000)
	camera.rotation.x = clamp(
		camera.rotation.x - mouse_axis.y * (MOUSE_SENSITIVITY/1000), 
		-CAMERA_VERTICAL_ANGLE_LIMIT, CAMERA_VERTICAL_ANGLE_LIMIT)
