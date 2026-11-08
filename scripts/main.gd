extends Node3D
const TRAFFIC_PRESETS={"خاموش":0,"خیلی کم":5,"کم":15,"متوسط":30,"زیاد":50,"خیلی زیاد":80}
var car:PrototypeCarController
var speed_label:Label
var rpm_label:Label
var gear_label:Label
var engine_label:Label
var speed_gauge:Control
var rpm_gauge:Control
var touch_targets:Array[Dictionary]=[]
var active_touches:Dictionary={}
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
  engine_label.text="موتور: روشن" if d.engine_running else "موتور: خاموش"
  speed_gauge.set("value",float(d.speed_kmh))
  rpm_gauge.set("value",float(d.rpm))
  for i in range(mirror_cameras.size()):
   mirror_cameras[i].global_position=car.global_transform*mirror_offsets[i]
   mirror_cameras[i].global_rotation=car.global_rotation+Vector3(0.0,mirror_yaws[i],0.0)
func _build_world()->void:
	_build_winding_road()
	var builder=load("res://scripts/world_builder.gd").new()
	builder.build_world(self,road_curve)
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
 body.visible=true
 var paint:=StandardMaterial3D.new()
 paint.albedo_color=Color(0.12,0.32,0.72)
 body.material_override=paint
 car.add_child(body)
 # Cockpit-only interior: no exterior hood/body is rendered from the driver's camera.
 var dash:=MeshInstance3D.new()
 var dash_mesh:=BoxMesh.new()
 dash_mesh.size=Vector3(1.72,0.24,0.58)
 dash.mesh=dash_mesh
 dash.position=Vector3(0,0.34,-0.88)
 var dash_mat:=StandardMaterial3D.new()
 dash_mat.albedo_color=Color(0.055,0.065,0.075)
 dash_mat.roughness=0.78
 dash.material_override=dash_mat
 car.add_child(dash)
 for side in [-1.0,1.0]:
  var pillar:=MeshInstance3D.new()
  var pillar_mesh:=BoxMesh.new()
  pillar_mesh.size=Vector3(0.09,1.05,0.12)
  pillar.mesh=pillar_mesh
  pillar.position=Vector3(side*0.83,0.82,-1.05)
  pillar.rotation.z=side*deg_to_rad(-9.0)
  pillar.material_override=dash_mat
  car.add_child(pillar)
 var roof:=MeshInstance3D.new()
 var roof_mesh:=BoxMesh.new()
 roof_mesh.size=Vector3(1.8,0.09,1.25)
 roof.mesh=roof_mesh
 roof.position=Vector3(0,1.52,0.25)
 roof.material_override=dash_mat
 car.add_child(roof)
 var steering:=MeshInstance3D.new()
 var steering_mesh:=TorusMesh.new()
 steering_mesh.inner_radius=0.205
 steering_mesh.outer_radius=0.235
 steering.mesh=steering_mesh
 steering.position=Vector3(-0.02,0.54,-0.52)
 steering.rotation.x=deg_to_rad(72)
 steering.material_override=dash_mat
 car.add_child(steering)
 var steering_hub:=MeshInstance3D.new()
 var hub_mesh:=CylinderMesh.new()
 hub_mesh.top_radius=0.09
 hub_mesh.bottom_radius=0.09
 hub_mesh.height=0.07
 steering_hub.mesh=hub_mesh
 steering_hub.position=Vector3(-0.02,0.54,-0.52)
 steering_hub.rotation.x=deg_to_rad(72)
 steering_hub.material_override=dash_mat
 car.add_child(steering_hub)
 var pivot:=Node3D.new()
 pivot.name="CabinCameraPivot"
 pivot.position=Vector3(0,0.88,-0.18)
 car.add_child(pivot)
 var camera:=Camera3D.new()
 camera.current=true
 camera.fov=78
 camera.position=Vector3(0,0.0,0.12)
 pivot.add_child(camera)
 add_child(car)
func _build_hud()->void:
 var layer:=CanvasLayer.new()
 layer.layer=5
 add_child(layer)
 var root:=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 layer.add_child(root)
 # Clear, high-contrast status strip
 var status:=PanelContainer.new()
 status.anchor_left=0.02
 status.anchor_top=0.02
 status.anchor_right=0.30
 status.anchor_bottom=0.18
 status.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.04,0.06,0.88),Color(0.18,0.72,0.92)))
 root.add_child(status)
 var status_col:=VBoxContainer.new()
 status.add_child(status_col)
 speed_label=_label(status_col,"000 km/h",Vector2.ZERO,22)
 gear_label=_label(status_col,"دنده N",Vector2.ZERO,18)
 engine_label=_label(status_col,"موتور: روشن",Vector2.ZERO,16)
 _make_touch_button(root,"◀",Vector2(0.025,0.73),Vector2(76,68),"steer_left")
 _make_touch_button(root,"▶",Vector2(0.115,0.73),Vector2(76,68),"steer_right")
 _make_touch_button(root,"گاز",Vector2(0.86,0.70),Vector2(105,76),"throttle")
 _make_touch_button(root,"ترمز",Vector2(0.86,0.84),Vector2(105,68),"brake")
 _make_touch_button(root,"کلاچ",Vector2(0.72,0.84),Vector2(100,62),"clutch")
 _make_touch_button(root,"استارت",Vector2(0.025,0.88),Vector2(92,48),"engine_start")
 _shifter(root)
 _settings_panel(root)
 _seat_panel(root)
 _build_live_mirrors(root)
 _build_gauges(root)

func _panel_style(bg:Color,edge:Color)->StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=bg
 style.border_color=edge
 style.set_border_width_all(2)
 style.set_corner_radius_all(12)
 style.content_margin_left=10
 style.content_margin_right=10
 style.content_margin_top=6
 style.content_margin_bottom=6
 return style

func _make_touch_button(parent:Control,title:String,anchor:Vector2,size:Vector2,action:String,gear_value:int=999)->void:
 var panel:=PanelContainer.new()
 panel.anchor_left=anchor.x
 panel.anchor_top=anchor.y
 panel.anchor_right=anchor.x
 panel.anchor_bottom=anchor.y
 panel.offset_right=size.x
 panel.offset_bottom=size.y
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.06,0.09,0.86),Color(0.12,0.72,0.92)))
 var label:=Label.new()
 label.text=title
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",19)
 label.add_theme_color_override("font_color",Color(0.9,0.97,1.0))
 panel.add_child(label)
 parent.add_child(panel)
 touch_targets.append({"control":panel,"action":action,"gear":gear_value})

func _input(event:InputEvent)->void:
 if event is InputEventScreenTouch:
  if event.pressed:
   for target in touch_targets:
    var control:Control=target.control
    if is_instance_valid(control) and control.get_global_rect().has_point(event.position):
     var gear_value:int=int(target.gear)
     if gear_value!=999:
      car.set_gear_from_ui(gear_value)
     else:
      active_touches[event.index]=str(target.action)
      Input.action_press(str(target.action))
     get_viewport().set_input_as_handled()
     break
  elif active_touches.has(event.index):
   var action:String=active_touches[event.index]
   active_touches.erase(event.index)
   var still_held:=false
   for value in active_touches.values():
    if value==action: still_held=true
   if not still_held: Input.action_release(action)
   get_viewport().set_input_as_handled()

func _build_gauges(parent:Control)->void:
 speed_gauge=load("res://scripts/gauge.gd").new()
 speed_gauge.name="Speedometer"
 speed_gauge.set("caption","سرعت")
 speed_gauge.set("unit","km/h")
 speed_gauge.set("max_value",240.0)
 speed_gauge.set("value",0.0)
 speed_gauge.anchor_left=0.39
 speed_gauge.anchor_top=0.69
 speed_gauge.anchor_right=0.53
 speed_gauge.anchor_bottom=0.98
 parent.add_child(speed_gauge)
 rpm_gauge=load("res://scripts/gauge.gd").new()
 rpm_gauge.name="Tachometer"
 rpm_gauge.set("caption","دور موتور")
 rpm_gauge.set("unit","RPM")
 rpm_gauge.set("max_value",8000.0)
 rpm_gauge.set("value",850.0)
 rpm_gauge.anchor_left=0.54
 rpm_gauge.anchor_top=0.69
 rpm_gauge.anchor_right=0.68
 rpm_gauge.anchor_bottom=0.98
 parent.add_child(rpm_gauge)

func _label(parent:Control,value:String,pos:Vector2,size:int)->Label:
 var l:=Label.new()
 l.text=value
 l.position=pos
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color(0.92,0.98,1.0))
 l.add_theme_color_override("font_shadow_color",Color.BLACK)
 l.add_theme_constant_override("shadow_offset_x",2)
 l.add_theme_constant_override("shadow_offset_y",2)
 parent.add_child(l)
 return l

func _shifter(parent:Control)->void:
 var panel:=PanelContainer.new()
 panel.anchor_left=0.39
 panel.anchor_top=0.40
 panel.anchor_right=0.68
 panel.anchor_bottom=0.67
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.04,0.06,0.82),Color(0.15,0.55,0.72)))
 parent.add_child(panel)
 var col:=VBoxContainer.new()
 panel.add_child(col)
 var title:=Label.new()
 title.text="H  |  برای تعویض، کلاچ را بگیر"
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 col.add_child(title)
 for row in range(2):
  var line:=HBoxContainer.new()
  col.add_child(line)
  for column in range(3):
   var value:int=[[1,3,5],[2,4,6]][row][column]
   _make_touch_button(parent,str(value),Vector2(0.405+float(column)*0.088,0.455+float(row)*0.105),Vector2(48,43),"",value)
 _make_touch_button(parent,"N",Vector2(0.42,0.625),Vector2(48,35),"",0)
 _make_touch_button(parent,"R",Vector2(0.55,0.625),Vector2(48,35),"",-1)

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
