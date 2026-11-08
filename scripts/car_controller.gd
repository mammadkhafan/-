extends RigidBody3D
class_name PrototypeCarController
const IDLE_RPM:=850.0
const REDLINE_RPM:=6500.0
const MAX_ENGINE_FORCE:=12500.0
const SERVICE_BRAKE:=17000.0
const GEAR_RATIOS={-1:-3.25,1:3.45,2:2.05,3:1.42,4:1.05,5:0.82,6:0.68}
var vehicle_data:Dictionary={}
var gear:=0
var engine_rpm:=IDLE_RPM
var engine_running:=true
var clutch_pressed:=false
var throttle_input:=0.0
var brake_input:=0.0
var steering_input:=0.0
var speed_kmh:=0.0
var look_yaw:=0.0
var look_pitch:=0.0
var seat_offset:=Vector3.ZERO
var seat_pitch:=0.0
var mouse_look_active:=false
var selected_car:=0
@onready var camera_pivot:Node3D=$CabinCameraPivot
func _ready()->void:
 vehicle_data=VehicleCatalog.get_vehicle(selected_car)
 mass=float(vehicle_data.get("mass",1200.0))
 contact_monitor=true
 max_contacts_reported=8
 can_sleep=false
func set_vehicle(index:int)->void:
 selected_car=clampi(index,0,19)
 vehicle_data=VehicleCatalog.get_vehicle(selected_car)
 mass=float(vehicle_data.get("mass",1200.0))
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
  mouse_look_active=event.pressed
 elif event is InputEventMouseMotion and mouse_look_active:
  look_yaw=clampf(look_yaw-event.relative.x*0.002,deg_to_rad(-110),deg_to_rad(110))
  look_pitch=clampf(look_pitch-event.relative.y*0.002,deg_to_rad(-40),deg_to_rad(30))
 elif event is InputEventScreenDrag:
  look_yaw=clampf(look_yaw-event.relative.x*0.002,deg_to_rad(-110),deg_to_rad(110))
  look_pitch=clampf(look_pitch-event.relative.y*0.002,deg_to_rad(-40),deg_to_rad(30))
func _physics_process(delta:float)->void:
 _read_controls()
 _update_engine(delta)
 _apply_drive_forces()
 _update_camera()
func _read_controls()->void:
 throttle_input=Input.get_action_strength("throttle") if engine_running else 0.0
 brake_input=Input.get_action_strength("brake")
 steering_input=Input.get_action_strength("steer_right")-Input.get_action_strength("steer_left")
 clutch_pressed=Input.is_action_pressed("clutch")
 if Input.is_action_just_pressed("gear_neutral"): gear=0
 elif Input.is_action_just_pressed("gear_reverse") and speed_kmh<1.5 and clutch_pressed: gear=-1
 elif clutch_pressed:
  for selected in range(1,7):
   if Input.is_action_just_pressed("gear_"+str(selected)): gear=selected
func _update_engine(delta:float)->void:
 speed_kmh=linear_velocity.length()*3.6
 if not engine_running:
  engine_rpm=0.0
  if Input.is_action_just_pressed("engine_start"):
   engine_running=true
   engine_rpm=IDLE_RPM
  return
 var ratio:=absf(float(GEAR_RATIOS.get(gear,0.0)))
 var coupled:=gear!=0 and not clutch_pressed
 if coupled:
  var target:=clampf(speed_kmh*ratio*17.0,IDLE_RPM,REDLINE_RPM)
  engine_rpm=move_toward(engine_rpm,target,delta*3200.0)
  if speed_kmh<2.5 and engine_rpm<1050.0 and throttle_input<0.28:
   engine_running=false
   engine_rpm=0.0
 else:
  engine_rpm=move_toward(engine_rpm,IDLE_RPM+throttle_input*(REDLINE_RPM-IDLE_RPM),delta*4500.0)
func _apply_drive_forces()->void:
 var forward:Vector3=-global_transform.basis.z
 if engine_running and gear!=0 and not clutch_pressed:
  var ratio:=float(GEAR_RATIOS.get(gear,0.0))
  var power_scale:=float(vehicle_data.get("power",100.0))/150.0
  var rpm_scale:=clampf(engine_rpm/3200.0,0.18,1.25)
  apply_central_force(forward*MAX_ENGINE_FORCE*power_scale*throttle_input*ratio*0.24*rpm_scale)
 if brake_input>0.0 and linear_velocity.length()>0.05:
  apply_central_force(-linear_velocity.normalized()*SERVICE_BRAKE*brake_input)
 if linear_velocity.length()>0.5:
  apply_torque(Vector3.UP*steering_input*linear_velocity.length()*145.0*float(vehicle_data.get("grip",1.0)))
 apply_central_force(-linear_velocity*95.0)
func _update_camera()->void:
 camera_pivot.position=Vector3(0.0,1.0+seat_offset.y,-0.35+seat_offset.z)
 camera_pivot.rotation=Vector3(look_pitch+seat_pitch,look_yaw,0.0)
func select_gear_from_h_pattern(row:int,column:int)->void:
 if not clutch_pressed: return
 var map=[[1,3,5],[2,4,6]]
 if row>=0 and row<2 and column>=0 and column<3: gear=map[row][column]
func set_gear_from_ui(value:int)->void:
 if value==0: gear=0
 elif value==-1 and speed_kmh<1.5 and clutch_pressed: gear=-1
 elif clutch_pressed: gear=clampi(value,1,6)
func adjust_seat(axis:String,amount:float)->void:
 if axis=="forward": seat_offset.z=clampf(seat_offset.z+amount,-0.25,0.25)
 elif axis=="height": seat_offset.y=clampf(seat_offset.y+amount,-0.2,0.2)
 elif axis=="backrest": seat_pitch=clampf(seat_pitch+amount,deg_to_rad(-12),deg_to_rad(12))
func get_dashboard_data()->Dictionary:
 return {"speed_kmh":snappedf(speed_kmh,0.1),"rpm":int(engine_rpm),"gear":"R" if gear==-1 else ("N" if gear==0 else str(gear)),"engine_running":engine_running,"clutch_pressed":clutch_pressed}
