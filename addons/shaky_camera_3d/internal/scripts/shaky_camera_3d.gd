## A variation of Camera3D node with shake animations to imitate
## filming while in motion.

@icon("icon.svg")

class_name ShakyCamera3D
extends Camera3D


enum TypesOfShake {
	INVESTIGATION,
	CLOSEUP,
	WEDDING,
	WALK_TO_THE_SOTORE,
	HANDYCAM_RUN,
	OUT_OF_CAR_WINDOW
}

## Type of shake that will be played.
@export var type_of_shake: TypesOfShake = TypesOfShake.HANDYCAM_RUN

## Disable the animation.
@export var disabled: bool = false

@export_group("Animation Effect Multipliers", "multiplier_")
@export var multiplier_position: float = 1.0
@export var multiplier_rotation: float = 1.0
@export var multiplier_speed: float = 1.0


#region Internal (do not touch)

## The position and rotation of camera around which the camera "shakes" around.
@onready var true_position := position
@onready var true_rotation := rotation

@onready var animation_player: AnimationPlayer = $AnimationPlayer


## Animation framerate
const FPS = 24.0

## Names of the animations inside the AnimationPlayer
const animation_names = {
	TypesOfShake.INVESTIGATION: "shaky_camera_3d/investigation",
	TypesOfShake.CLOSEUP: "shaky_camera_3d/closeup",
	TypesOfShake.WEDDING: "shaky_camera_3d/wedding",
	TypesOfShake.WALK_TO_THE_SOTORE: "shaky_camera_3d/walk_to_the_store",
	TypesOfShake.HANDYCAM_RUN: "shaky_camera_3d/handycam_run",
	TypesOfShake.OUT_OF_CAR_WINDOW: "shaky_camera_3d/out_of_car_window"
}


var position_offsets: Vector3
var rotation_offsets: Vector3
var last_known_position_offsets: Vector3
var last_known_rotation_offsets: Vector3


var use_set_method_allowed: bool = true

## Change `true_position` and `true_rotation` instead of real `position` and
## `rotation` since they are being set based on an animation.
##
## To avoid invoking this methind when `position` and `rotation` are set by
## animation we check a `use_set_method_allowed` flag.
##
## Because the `value` Vector3, either a value of `position` or `rotation`, contains not only
## the new coordinate we want to set, but also a values that are added by animation, we perfom some
## calculations to get only the value that isn't affected by animation.
##
## EXAMPLE:
##
## `true_rotation` == (1,1,1)
## `last_known_rotation_offsets` == (1.4,1.4,1.4)
##
## Somewhere in the code the user of this addon sets camera's `rotation:x` to 5:
## `$ShakyCamera3D.rotation.x = 5`
## Godot actually interpretes this like this:
## `$ShakyCamera3D.rotation.x = $ShakyCamera3D.rotation + Vector3(5,0,0)` 
##
## Because the `rotation` is set by an animation we have to change `true_rotation`
## to actually rotate the camera.
##
## `value` will equal to
## (5,0,0) + `true_rotation` + `last_known_rotation_offsets` == (7.4,2.4,2.4).
## (7.4,2.4,2.4) - (1.4,1.4,1.4) == (5,1,1)
## We finally set `true_rotation` to this (5,1,1) (it's user's (5,0,0) + `true_rotation`).
func _set(property, value):
	if property == "rotation" and use_set_method_allowed:
		true_rotation = value - last_known_rotation_offsets
		return true
	elif property == "position" and use_set_method_allowed:
		true_position = value - last_known_position_offsets
		return true
	return false
#endregion


func _process(_delta):
	animation_player.current_animation = animation_names[type_of_shake]
	animation_player.speed_scale = FPS * multiplier_speed
	animation_player.active = not disabled
	
	## To animate camera position (add shake to it) we take it's
	## starting position (and rotation) and add little offsets
	## to it every frame.
	##
	## This makes it so that position of the camera doesn't equal the offset
	## itself which would have caused it to shake around a (0, 0, 0)
	## coordinate instead of where we want the camera to be.
	
	if not disabled:
		## Add shake from the animation.
		last_known_position_offsets = position_offsets * multiplier_position
		last_known_rotation_offsets = rotation_offsets * multiplier_rotation
	
	use_set_method_allowed = false
	position = true_position + last_known_position_offsets
	rotation = true_rotation + last_known_rotation_offsets
	use_set_method_allowed = true
