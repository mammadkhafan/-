extends RigidBody3D
class_name PrototypeCarController

const IDLE_RPM:=850.0
const FINAL_DRIVE:=3.7
const WHEEL_RADIUS:=0.33
const MAX_STEER_ANGLE:=0.48
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
var wheel_rays:Array[RayCast3D]=[]
var wheel_meshes:Array[MeshInstance3D]=[]
var wheel_spin:=0.0
@onready var camera_pivot:Node3D=$CabinCameraPivot

func _ready()->void:
 vehicle_data=VehicleCatalog.get_vehicle(selected_car)
 mass=float(vehicle_data.get("mass",1200.0))
 _load_seat_setup()
 contact_monitor=true
 max_contacts_reported=8
 can_sleep=false
 _create_wheel_rig()

func _create_wheel_rig()->void:
 var positions=[Vector3(-0.82,-0.12,-1.35),Vector3(0.82,-0.12,-1.35),Vector3(-0.82,-0.12,1.35),Vector3(0.82,-0.12,1.35)]
 for i in range(4):
  var ray:=RayCast3D.new()
  ray.name="WheelRay"+str(i)
  ray.position=positions[i]
  ray.target_position=Vector3(0,-1.05,0)
  ray.collision_mask=1
  ray.enabled=true
  add_child(ray)
  wheel_rays.append(ray)
  var wheel:=MeshInstance3D.new()
  wheel.name="Wheel"+str(i)
  var mesh:=CylinderMesh.new()
  mesh.top_radius=WHEEL_RADIUS
  mesh.bottom_radius=WHEEL_RADIUS
  mesh.height=0.20
  wheel.mesh=mesh
  wheel.position=Vector3(positions[i].x,-0.38,positions[i].z)
  wheel.rotation.z=PI*0.5
  var material:=StandardMaterial3D.new()
  material.albedo_color=Color(0.035,0.035,0.04)
  wheel.material_override=material
  add_child(wheel)
  wheel_meshes.append(wheel)

func set_vehicle(index:int)->void:
 _save_seat_setup()
 selected_car=clampi(index,0,VehicleCatalog.count()-1)
 vehicle_data=VehicleCatalog.get_vehicle(selected_car)
 mass=float(vehicle_data.get("mass",1200.0))
 _load_seat_setup()

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
 _apply_wheel_physics(delta)
 _update_camera()

func _read_controls()->void:
 throttle_input=Input.get_action_strength("throttle") if engine_running else 0.0
 brake_input=Input.get_action_strength("brake")
 steering_input=Input.get_action_strength("steer_right")-Input.get_action_strength("steer_left")
 clutch_pressed=Input.is_action_pressed("clutch")
 if Input.is_action_just_pressed("gear_neutral"):
  gear=0
 elif Input.is_action_just_pressed("gear_reverse") and speed_kmh<1.5 and clutch_pressed:
  gear=-1
 elif clutch_pressed:
  for selected in range(1,7):
   if Input.is_action_just_pressed("gear_"+str(selected)):
    gear=selected

func _update_engine(delta:float)->void:
 speed_kmh=linear_velocity.length()*3.6
 var redline:=float(vehicle_data.get("max_rpm",6500.0))
 if not engine_running:
  engine_rpm=0.0
  if Input.is_action_just_pressed("engine_start"):
   engine_running=true
   engine_rpm=IDLE_RPM
  return
 var ratio:=absf(float(GEAR_RATIOS.get(gear,0.0)))
 var coupled:=gear!=0 and not clutch_pressed
 if coupled:
  var wheel_rpm:=linear_velocity.length()/(TAU*WHEEL_RADIUS)*60.0
  var target:=clampf(wheel_rpm*ratio*FINAL_DRIVE,IDLE_RPM,redline)
  engine_rpm=move_toward(engine_rpm,target,delta*4200.0)
  if speed_kmh<2.5 and engine_rpm<1050.0 and throttle_input<0.28:
   engine_running=false
   engine_rpm=0.0
 else:
  engine_rpm=move_toward(engine_rpm,IDLE_RPM+throttle_input*(redline-IDLE_RPM),delta*4500.0)

func _apply_wheel_physics(_delta:float)->void:
 var up:=global_transform.basis.y.normalized()
 var forward:Vector3=-global_transform.basis.z
 var right:=global_transform.basis.x
 var redline:=float(vehicle_data.get("max_rpm",6500.0))
 var torque:=float(vehicle_data.get("torque",180.0))
 var rpm_fraction:=clampf(engine_rpm/maxf(redline,1.0),0.0,1.0)
 var torque_curve:=clampf(0.55+1.1*rpm_fraction-0.65*pow(rpm_fraction,2.0),0.35,1.0)
 var ratio:=float(GEAR_RATIOS.get(gear,0.0))
 var drive_force:=0.0
 if engine_running and gear!=0 and not clutch_pressed:
  drive_force=torque*torque_curve*ratio*FINAL_DRIVE/WHEEL_RADIUS*throttle_input
  drive_force=clampf(drive_force,-mass*9.81*1.15,mass*9.81*1.15)
 var top_speed:=float(vehicle_data.get("top",180.0))
 if speed_kmh>top_speed and drive_force>0.0:
  drive_force=0.0
 for i in range(wheel_rays.size()):
  var ray:=wheel_rays[i]
  ray.force_raycast_update()
  if not ray.is_colliding():
   continue
  var hit:Vector3=ray.get_collision_point()
  var normal:Vector3=ray.get_collision_normal().normalized()
  var origin:Vector3=ray.global_position
  var distance:=origin.distance_to(hit)
  var compression:=clampf(0.92-distance,0.0,0.32)
  var contact_offset:=hit-global_position
  var point_velocity:=linear_velocity+angular_velocity.cross(hit-global_position)
  var normal_velocity:=point_velocity.dot(normal)
  var spring_force:=maxf(0.0,compression*24000.0-normal_velocity*2300.0)
  spring_force=minf(spring_force,mass*9.81*1.8)
  apply_force(normal*spring_force,contact_offset)
  var wheel_forward:=forward
  if i<2:
   wheel_forward=forward.rotated(up,-steering_input*MAX_STEER_ANGLE)
  wheel_forward=(wheel_forward-normal*wheel_forward.dot(normal)).normalized()
  var wheel_right:=wheel_forward.cross(normal).normalized()
  var lateral_speed:=point_velocity.dot(wheel_right)
  var longitudinal_speed:=point_velocity.dot(wheel_forward)
  var friction_limit:=spring_force*float(vehicle_data.get("grip",1.0))
  var lateral_force:=clampf(-lateral_speed*mass*1.8,-friction_limit,friction_limit)
  var driven_force:=drive_force*0.25 if i>=2 else drive_force*0.25
  var brake_force:=brake_input*SERVICE_BRAKE*0.25
  var longitudinal_force:=clampf(driven_force-longitudinal_speed*mass*0.08-signf(longitudinal_speed)*brake_force,-friction_limit,friction_limit)
  apply_force(wheel_right*lateral_force+wheel_forward*longitudinal_force,contact_offset)
  if i<2:
   wheel_rays[i].rotation.y=-steering_input*MAX_STEER_ANGLE
   wheel_meshes[i].rotation.y=-steering_input*MAX_STEER_ANGLE
 wheel_spin+=linear_velocity.length()*_delta/WHEEL_RADIUS
 for wheel in wheel_meshes:
  wheel.rotation.x=wheel_spin

func _update_camera()->void:
 camera_pivot.position=Vector3(0.0,1.0+seat_offset.y,-0.35+seat_offset.z)
 camera_pivot.rotation=Vector3(look_pitch+seat_pitch,look_yaw,0.0)

func select_gear_from_h_pattern(row:int,column:int)->void:
 if not clutch_pressed:
  return
 var map=[[1,3,5],[2,4,6]]
 if row>=0 and row<2 and column>=0 and column<3:
  gear=map[row][column]

func set_gear_from_ui(value:int)->void:
 if value==0:
  gear=0
 elif value==-1 and speed_kmh<1.5 and clutch_pressed:
  gear=-1
 elif clutch_pressed:
  gear=clampi(value,1,6)

func adjust_seat(axis:String,amount:float)->void:
 if axis=="forward":
  seat_offset.z=clampf(seat_offset.z+amount,-0.25,0.25)
 elif axis=="height":
  seat_offset.y=clampf(seat_offset.y+amount,-0.2,0.2)
 elif axis=="backrest":
  seat_pitch=clampf(seat_pitch+amount,deg_to_rad(-12),deg_to_rad(12))
 _save_seat_setup()

func _load_seat_setup()->void:
 var config:=ConfigFile.new()
 if config.load("user://settings.cfg")!=OK:
  return
 var section:="seat_"+str(selected_car)
 seat_offset.z=float(config.get_value(section,"forward",0.0))
 seat_offset.y=float(config.get_value(section,"height",0.0))
 seat_pitch=float(config.get_value(section,"backrest",0.0))

func _save_seat_setup()->void:
 var config:=ConfigFile.new()
 config.load("user://settings.cfg")
 var section:="seat_"+str(selected_car)
 config.set_value(section,"forward",seat_offset.z)
 config.set_value(section,"height",seat_offset.y)
 config.set_value(section,"backrest",seat_pitch)
 config.save("user://settings.cfg")

func get_dashboard_data()->Dictionary:
 return {"speed_kmh":snappedf(speed_kmh,0.1),"rpm":int(engine_rpm),"gear":"R" if gear==-1 else ("N" if gear==0 else str(gear)),"engine_running":engine_running,"clutch_pressed":clutch_pressed}
