extends RigidBody3D
class_name PrototypeCarController

# Early driving prototype. Forward is local -Z (Godot convention).
const MAX_RPM := 6500.0
const IDLE_RPM := 850.0
const ENGINE_FORCE := 9500.0
const BRAKE_FORCE := 14000.0
const GEAR_RATIOS := { -1: -3.2, 1: 3.4, 2: 2.1, 3: 1.45, 4: 1.0, 5: 0.82, 6: 0.68 }

var gear: int = 0 # 0 = neutral, -1 = reverse, 1..6 = forward
var engine_rpm: float = IDLE_RPM
var engine_running := true
var clutch_pressed := false
var steering_input := 0.0
var throttle_input := 0.0
var speed_kmh := 0.0
var look_yaw := 0.0
var look_pitch := 0.0

@onready var camera_pivot: Node3D = $CabinCameraPivot

func _physics_process(delta: float) -> void:
	_read_controls()
	_update_engine(delta)
	_apply_vehicle_forces(delta)
	_update_camera(delta)

func _read_controls() -> void:
	throttle_input = Input.get_action_strength("throttle") if engine_running else 0.0
	steering_input = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	clutch_pressed = Input.is_action_pressed("clutch")

	if Input.is_action_just_pressed("gear_neutral"):
		gear = 0
	elif Input.is_action_just_pressed("gear_reverse") and linear_velocity.length() < 0.5 and clutch_pressed:
		gear = -1
	elif clutch_pressed:
		for selected_gear in range(1, 7):
			if Input.is_action_just_pressed("gear_" + str(selected_gear)):
				gear = selected_gear

func _update_engine(delta: float) -> void:
	speed_kmh = linear_velocity.length() * 3.6
	if not engine_running:
		engine_rpm = 0.0
		if Input.is_action_just_pressed("throttle"):
			engine_running = true
			engine_rpm = IDLE_RPM
		return

	var ratio: float = abs(float(GEAR_RATIOS.get(gear, 0.0)))
	var coupled := gear != 0 and not clutch_pressed
	if coupled:
		var estimated_rpm := IDLE_RPM + speed_kmh * ratio * 18.0
		engine_rpm = move_toward(engine_rpm, min(estimated_rpm, MAX_RPM), delta * 2600.0)
	else:
		var target_rpm := IDLE_RPM + throttle_input * (MAX_RPM - IDLE_RPM)
		engine_rpm = move_toward(engine_rpm, target_rpm, delta * 4200.0)

	# Simplified stall behavior: releasing clutch at very low RPM while in gear stalls.
	if coupled and speed_kmh < 3.0 and engine_rpm < 1250.0 and throttle_input < 0.35:
		engine_running = false
		engine_rpm = 0.0

func _apply_vehicle_forces(_delta: float) -> void:
	var forward := -global_transform.basis.z
	if engine_running and gear != 0 and not clutch_pressed:
		var ratio: float = float(GEAR_RATIOS.get(gear, 0.0))
		var rpm_factor := clamp(engine_rpm / 3000.0, 0.25, 1.4)
		apply_central_force(forward * ENGINE_FORCE * throttle_input * ratio * 0.28 * rpm_factor)
	if Input.is_action_pressed("brake") and linear_velocity.length() > 0.1:
		apply_central_force(-linear_velocity.normalized() * BRAKE_FORCE)
	if linear_velocity.length() > 0.5:
		apply_torque(Vector3.UP * steering_input * linear_velocity.length() * 170.0)
	apply_central_force(-linear_velocity * 90.0)

func _update_camera(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_delta := get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size * 0.5
		look_yaw = clamp(look_yaw - mouse_delta.x * 0.0008, deg_to_rad(-100), deg_to_rad(100))
		look_pitch = clamp(look_pitch - mouse_delta.y * 0.0008, deg_to_rad(-35), deg_to_rad(25))
		Input.warp_mouse(get_viewport().get_visible_rect().size * 0.5)
	camera_pivot.rotation = camera_pivot.rotation.lerp(Vector3(look_pitch, look_yaw, 0.0), delta * 8.0)

func select_gear_from_h_pattern(row: int, column: int) -> void:
	# H-pattern mapping for a future touch/physical shifter UI.
	if clutch_pressed:
		if row == 0 and column == 0: gear = 1
		elif row == 0 and column == 1: gear = 2
		elif row == 1 and column == 0: gear = 3
		elif row == 1 and column == 1: gear = 4
		elif row == 2 and column == 0: gear = 5
		elif row == 2 and column == 1: gear = 6

func get_dashboard_data() -> Dictionary:
	return {
		"speed_kmh": snapped(speed_kmh, 0.1),
		"rpm": int(engine_rpm),
		"gear": "R" if gear == -1 else ("N" if gear == 0 else str(gear)),
		"engine_running": engine_running,
		"clutch_pressed": clutch_pressed
	}
