extends Node3D
const TRAFFIC_PRESETS={"خاموش":0,"خیلی کم":5,"کم":15,"متوسط":30,"زیاد":50,"خیلی زیاد":80}
var car:PrototypeCarController
var speed_label:Label
var rpm_label:Label
var gear_label:Label
var traffic_nodes:Array[Node3D]=[]
var mirror_cameras:Array[Camera3D]=[]
var mirror_offsets:=[Vector3(-0.72,1.05,0.65),Vector3(0.0,1.05,0.65),Vector3(0.72,1.05,0.65)]
var mirror_yaws:=[2.65,3.14159,3.63]
var selected_vehicle:=0
var road_curve:=Curve3D.new()
var traffic_level:="کم"
var settings={"fps":60,"traffic":"کم"}
func _ready()->void:
 _load_settings()
 _build_world()
 _build_player_car()
 _build_hud()
 _apply_fps()
 _spawn_traffic()
func _process(_delta:float)->void:
 if is_instance_valid(car):
  var d:Dictionary=car.get_dashboard_data()
  speed_label.text="%03d km/h"%int(d.speed_kmh)
  rpm_label.text="RPM %04d"%int(d.rpm)
  gear_label.text="دنده "+str(d.gear)
  for i in range(mirror_cameras.size()):
   mirror_cameras[i].global_position=car.global_transform*mirror_offsets[i]
   mirror_cameras[i].global_rotation=car.global_rotation+Vector3(0.0,mirror_yaws[i],0.0)
func _build_world()->void:
 var sun:=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-48,-28,0)
 sun.shadow_enabled=true
 add_child(sun)
 var env:=WorldEnvironment.new()
 var e:=Environment.new()
 e.background_mode=Environment.BG_SKY
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color=Color(0.62,0.68,0.76)
 env.environment=e
 add_child(env)
 var ground:=MeshInstance3D.new()
 var plane:=PlaneMesh.new()
 plane.size=Vector2(40000,40000)
 ground.mesh=plane
 ground.position.y=-0.12
 var grass:=StandardMaterial3D.new()
 grass.albedo_color=Color(0.22,0.34,0.19)
 ground.material_override=grass
 add_child(ground)
 var ground_body:=StaticBody3D.new()
 var ground_collision:=CollisionShape3D.new()
 var ground_box:=BoxShape3D.new()
 ground_box.size=Vector3(40000,1,40000)
 ground_collision.shape=ground_box
 ground_body.position.y=-0.62
 ground_body.add_child(ground_collision)
 add_child(ground_body)
 _build_winding_road()
 _build_landmarks()
func _build_landmarks()->void:
 for i in range(18):
  var building:=MeshInstance3D.new()
  var mesh:=BoxMesh.new()
  var h:=8.0+float(i%5)*3.0
  mesh.size=Vector3(11.0,h,13.0)
  building.mesh=mesh
  building.position=Vector3(-38.0-float(i%3)*17.0,h*0.5,-120.0-float(i/3)*75.0)
  var mat:=StandardMaterial3D.new()
  mat.albedo_color=Color.from_hsv(0.08+float(i%6)*0.07,0.22,0.68)
  building.material_override=mat
  add_child(building)
 for i in range(10):
  var house:=MeshInstance3D.new()
  var hm:=BoxMesh.new()
  hm.size=Vector3(9,5,8)
  house.mesh=hm
  house.position=Vector3(28.0+float(i%2)*15.0,2.5,-2400.0-float(i)*520.0)
  add_child(house)
 _make_service_stop(Vector3(220,0,-4300),"پمپ بنزین",Color(0.82,0.68,0.16))
 _make_service_stop(Vector3(780,0,-9600),"تعمیرگاه",Color(0.18,0.48,0.72))
 _make_service_stop(Vector3(-300,0,-13900),"پارکینگ",Color(0.28,0.58,0.34))
func _make_service_stop(pos:Vector3,title_text:String,tint:Color)->void:
 var building:=MeshInstance3D.new()
 var mesh:=BoxMesh.new()
 mesh.size=Vector3(16,5,10)
 building.mesh=mesh
 building.position=pos+Vector3(0,2.5,0)
 var mat:=StandardMaterial3D.new()
 mat.albedo_color=tint
 building.material_override=mat
 add_child(building)
 var sign:=Label3D.new()
 sign.text=title_text
 sign.position=pos+Vector3(0,6,0)
 add_child(sign)
 var lot:=MeshInstance3D.new()
 var lm:=BoxMesh.new()
 lm.size=Vector3(28,0.15,24)
 lot.mesh=lm
 lot.position=pos+Vector3(0,0.05,14)
 var pavement:=StandardMaterial3D.new()
 pavement.albedo_color=Color(0.2,0.2,0.2)
 lot.material_override=pavement
 add_child(lot)
func _build_winding_road()->void:
 var points=[Vector3(0,0,0),Vector3(0,0,-794),Vector3(370,0,-1676),Vector3(794,0,-2646),Vector3(618,0,-3796),Vector3(-221,0,-4763),Vector3(-794,0,-5734),Vector3(-618,0,-6968),Vector3(221,0,-7938),Vector3(882,0,-9085),Vector3(706,0,-10298),Vector3(-132,0,-11466),Vector3(-750,0,-12613),Vector3(-353,0,-13834),Vector3(0,0,-14996)]
 for point in points:
  road_curve.add_point(point)
 road_curve.bake_interval=2.0
 var route_length:=road_curve.get_baked_length()
 var segment_count:=ceili(route_length/100.0)
 for i in range(segment_count):
  var d0:=float(i)*100.0
  var d1:=minf(float(i+1)*100.0,route_length)
  var a:=road_curve.sample_baked(d0)
  var b:=road_curve.sample_baked(d1)
  var segment_length:=a.distance_to(b)
  var road:=StaticBody3D.new()
  road.position=(a+b)*0.5+Vector3(0,-0.04,0)
  road.look_at(Vector3(b.x,road.position.y,b.z),Vector3.UP)
  var shape:=CollisionShape3D.new()
  var box:=BoxShape3D.new()
  box.size=Vector3(13.0,0.3,segment_length+2.0)
  shape.shape=box
  road.add_child(shape)
  var visual:=MeshInstance3D.new()
  var mesh:=BoxMesh.new()
  mesh.size=box.size
  visual.mesh=mesh
  var material:=StandardMaterial3D.new()
  material.albedo_color=Color(0.12,0.13,0.14)
  visual.material_override=material
  road.add_child(visual)
  add_child(road)
 # Route length is about 16.7 km: roughly five minutes at 200 km/h.
func _build_player_car()->void:
 car=load("res://scripts/car_controller.gd").new()
 car.name="PlayerCar"
 car.position=Vector3(0,1.1,5)
 car.linear_damp=0.15
 car.angular_damp=2.0
 var shape:=CollisionShape3D.new()
 var box:=BoxShape3D.new()
 box.size=Vector3(1.85,0.65,4.2)
 shape.shape=box
 car.add_child(shape)
 var body:=MeshInstance3D.new()
 var mesh:=BoxMesh.new()
 mesh.size=box.size
 body.mesh=mesh
 var paint:=StandardMaterial3D.new()
 paint.albedo_color=Color(0.12,0.32,0.72)
 body.material_override=paint
 car.add_child(body)
 var dash:=MeshInstance3D.new()
 var dash_mesh:=BoxMesh.new()
 dash_mesh.size=Vector3(1.55,0.28,0.48)
 dash.mesh=dash_mesh
 dash.position=Vector3(0,0.48,-1.0)
 car.add_child(dash)
 var wheel:=MeshInstance3D.new()
 var wheel_mesh:=TorusMesh.new()
 wheel_mesh.inner_radius=0.25
 wheel_mesh.outer_radius=0.31
 wheel.mesh=wheel_mesh
 wheel.position=Vector3(0,0.63,-0.62)
 car.add_child(wheel)
 for side in [-1.0,1.0]:
  var pedal:=MeshInstance3D.new()
  var pm:=BoxMesh.new()
  pm.size=Vector3(0.12,0.22,0.06)
  pedal.mesh=pm
  pedal.position=Vector3(side*0.22,0.12,-0.62)
  car.add_child(pedal)
 var lever:=MeshInstance3D.new()
 var lm:=CylinderMesh.new()
 lm.height=0.38
 lever.mesh=lm
 lever.position=Vector3(0.32,0.35,-0.25)
 car.add_child(lever)
 var pivot:=Node3D.new()
 pivot.name="CabinCameraPivot"
 pivot.position=Vector3(0,1.0,-0.35)
 car.add_child(pivot)
 var camera:=Camera3D.new()
 camera.current=true
 camera.fov=78
 camera.position=Vector3(0,0.1,0.15)
 pivot.add_child(camera)
 add_child(car)
func _build_hud()->void:
 var layer:=CanvasLayer.new()
 add_child(layer)
 var root:=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(root)
 speed_label=_label(root,"000 km/h",Vector2(18,14),28)
 rpm_label=_label(root,"RPM 0850",Vector2(18,52),18)
 gear_label=_label(root,"دنده N",Vector2(18,78),18)
 _hold(root,"گاز",Vector2(0.84,0.70),Vector2(100,65),"throttle")
 _hold(root,"ترمز",Vector2(0.84,0.83),Vector2(100,65),"brake")
 _hold(root,"چپ",Vector2(0.02,0.78),Vector2(82,62),"steer_left")
 _hold(root,"راست",Vector2(0.12,0.78),Vector2(82,62),"steer_right")
 _hold(root,"کلاچ",Vector2(0.70,0.84),Vector2(92,58),"clutch")
 _hold(root,"استارت (E)",Vector2(0.02,0.90),Vector2(100,48),"engine_start")
 _shifter(root)
 _settings_panel(root)
 _seat_panel(root)
 _build_live_mirrors(root)
func _label(parent:Control,value:String,pos:Vector2,size:int)->Label:
 var l:=Label.new()
 l.text=value
 l.position=pos
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color.WHITE)
 l.add_theme_color_override("font_shadow_color",Color.BLACK)
 l.add_theme_constant_override("shadow_offset_x",2)
 l.add_theme_constant_override("shadow_offset_y",2)
 parent.add_child(l)
 return l
func _hold(parent:Control,title:String,anchor:Vector2,size:Vector2,action:String)->void:
 var b:=Button.new()
 b.text=title
 b.anchor_left=anchor.x
 b.anchor_top=anchor.y
 b.anchor_right=anchor.x
 b.anchor_bottom=anchor.y
 b.offset_right=size.x
 b.offset_bottom=size.y
 b.button_down.connect(func():Input.action_press(action))
 b.button_up.connect(func():Input.action_release(action))
 parent.add_child(b)
func _shifter(parent:Control)->void:
 var panel:=PanelContainer.new()
 panel.anchor_left=0.39
 panel.anchor_top=0.75
 panel.anchor_right=0.61
 panel.anchor_bottom=0.99
 parent.add_child(panel)
 var col:=VBoxContainer.new()
 panel.add_child(col)
 var title:=Label.new()
 title.text="الگوی H — کلاچ را نگه دار"
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 col.add_child(title)
 for row in range(2):
  var line:=HBoxContainer.new()
  col.add_child(line)
  for column in range(3):
   var value:int = [[1,3,5],[2,4,6]][row][column]
   var b:=Button.new()
   b.text=str(value)
   b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   b.pressed.connect(func():car.set_gear_from_ui(value))
   line.add_child(b)
 var bottom:=HBoxContainer.new()
 col.add_child(bottom)
 for pair in [["N",0],["R",-1]]:
  var b:=Button.new()
  b.text=pair[0]
  var v:int=pair[1]
  b.pressed.connect(func():car.set_gear_from_ui(v))
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  bottom.add_child(b)
func _settings_panel(parent:Control)->void:
 var panel:=PanelContainer.new()
 panel.anchor_left=0.76
 panel.anchor_top=0.02
 panel.anchor_right=0.99
 panel.anchor_bottom=0.27
 parent.add_child(panel)
 var col:=VBoxContainer.new()
 panel.add_child(col)
 var title:=Label.new()
 title.text="تنظیمات / خودرو / ترافیک"
 col.add_child(title)
 var fps:=OptionButton.new()
 for n in range(1,61): fps.add_item(str(n),n)
 fps.select(clampi(int(settings.fps)-1,0,59))
 fps.item_selected.connect(func(i:int):
  settings.fps=fps.get_item_id(i)
  _apply_fps()
  _save_settings()
 )
 col.add_child(fps)
 var traffic:=OptionButton.new()
 for name in TRAFFIC_PRESETS.keys(): traffic.add_item(name)
 var saved_traffic_index:=2
 for i in range(traffic.item_count):
  if traffic.get_item_text(i)==traffic_level: saved_traffic_index=i
 traffic.select(saved_traffic_index)
 traffic.item_selected.connect(func(i:int):
  traffic_level=traffic.get_item_text(i)
  settings.traffic=traffic_level
  _spawn_traffic()
  _save_settings()
 )
 col.add_child(traffic)
 var cars:=OptionButton.new()
 for i in range(VehicleCatalog.count()): cars.add_item(VehicleCatalog.get_vehicle(i).name)
 cars.item_selected.connect(func(i:int):car.set_vehicle(i))
 col.add_child(cars)
func _seat_panel(parent:Control)->void:
 var panel:=PanelContainer.new()
 panel.anchor_left=0.02
 panel.anchor_top=0.02
 panel.anchor_right=0.31
 panel.anchor_bottom=0.19
 parent.add_child(panel)
 var row:=HBoxContainer.new()
 panel.add_child(row)
 for spec in [["جلو","forward",-0.03],["عقب","forward",0.03],["بالا","height",0.03],["پایین","height",-0.03],["پشتی+","backrest",0.03],["پشتی-","backrest",-0.03]]:
  var b:=Button.new()
  b.text=spec[0]
  var axis:String=spec[1]
  var amount:float=spec[2]
  b.pressed.connect(func():car.adjust_seat(axis,amount))
  row.add_child(b)
func _build_live_mirrors(parent:Control)->void:
 var captions=["چپ","وسط","راست"]
 for i in range(3):
  var viewport:=SubViewport.new()
  viewport.size=Vector2i(240,120)
  viewport.world_3d=get_viewport().world_3d
  viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
  var camera:=Camera3D.new()
  camera.rotation.y=mirror_yaws[i]
  camera.fov=72
  camera.current=true
  viewport.add_child(camera)
  car.add_child(viewport)
  mirror_cameras.append(camera)
  var frame:=TextureRect.new()
  frame.texture=viewport.get_texture()
  frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  frame.stretch_mode=TextureRect.STRETCH_SCALE
  frame.anchor_left=0.31+float(i)*0.115
  frame.anchor_top=0.025
  frame.anchor_right=0.42+float(i)*0.115
  frame.anchor_bottom=0.13
  parent.add_child(frame)
  var adjust:=Button.new()
  adjust.text=captions[i]+" زاویه"
  adjust.anchor_left=0.31+float(i)*0.115
  adjust.anchor_top=0.13
  adjust.anchor_right=0.42+float(i)*0.115
  adjust.anchor_bottom=0.13
  adjust.offset_bottom=28
  adjust.pressed.connect(func():
   mirror_yaws[i]=fposmod(mirror_yaws[i]+deg_to_rad(5.0),TAU)
   mirror_cameras[i].rotation.y=mirror_yaws[i]
   _save_mirror_settings()
  )
  parent.add_child(adjust)
func _spawn_traffic()->void:
 for n in traffic_nodes:
  if is_instance_valid(n): n.queue_free()
 traffic_nodes.clear()
 var count:int=int(TRAFFIC_PRESETS.get(traffic_level,15))
 var length:=maxf(road_curve.get_baked_length(),1.0)
 for i in range(count):
  var npc:Node3D=load("res://scripts/traffic_car.gd").new()
  var visual:=MeshInstance3D.new()
  var mesh:=BoxMesh.new()
  mesh.size=Vector3(1.7,0.85,3.5)
  visual.mesh=mesh
  var mat:=StandardMaterial3D.new()
  mat.albedo_color=Color.from_hsv(fposmod(float(i)*0.137,1.0),0.55,0.8)
  visual.material_override=mat
  npc.add_child(visual)
  add_child(npc)
  npc.call("configure",road_curve,length*float(i)/maxf(float(count),1.0),8.0+float(i%5)*1.4)
  traffic_nodes.append(npc)
func _select_vehicle(index:int)->void:
 _save_mirror_settings()
 selected_vehicle=clampi(index,0,VehicleCatalog.count()-1)
 car.set_vehicle(selected_vehicle)
 _load_mirror_settings()
 for i in range(mirror_cameras.size()):
  mirror_cameras[i].global_rotation=car.global_rotation+Vector3(0.0,mirror_yaws[i],0.0)

func _load_mirror_settings()->void:
 var file:=ConfigFile.new()
 if file.load("user://settings.cfg")!=OK:
  return
 for i in range(3):
  mirror_yaws[i]=float(file.get_value("mirrors","car_"+str(selected_vehicle)+"_"+str(i),[2.65,3.14159,3.63][i]))

func _save_mirror_settings()->void:
 var file:=ConfigFile.new()
 file.load("user://settings.cfg")
 for i in range(3):
  file.set_value("mirrors","car_"+str(selected_vehicle)+"_"+str(i),mirror_yaws[i])
 file.save("user://settings.cfg")

func _apply_fps()->void:
 Engine.max_fps=clampi(int(settings.fps),1,60)
func _load_settings()->void:
 var file:=ConfigFile.new()
 if file.load("user://settings.cfg")==OK:
  settings.fps=int(file.get_value("game","fps",60))
  traffic_level=str(file.get_value("game","traffic","کم"))
  if not TRAFFIC_PRESETS.has(traffic_level): traffic_level="کم"
  _load_mirror_settings()
func _save_settings()->void:
 var file:=ConfigFile.new()
 file.set_value("game","fps",settings.fps)
 file.set_value("game","traffic",traffic_level)
 file.save("user://settings.cfg")
