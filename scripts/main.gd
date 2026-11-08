extends Node3D
const TRAFFIC_PRESETS={"خاموش":0,"خیلی کم":5,"کم":15,"متوسط":30,"زیاد":50,"خیلی زیاد":80}
var car:RigidBody3D
var speed_label:Label
var rpm_label:Label
var gear_label:Label
var traffic_nodes:Array[Node3D]=[]
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
 plane.size=Vector2(20000,20000)
 ground.mesh=plane
 ground.position.y=-0.12
 var grass:=StandardMaterial3D.new()
 grass.albedo_color=Color(0.22,0.34,0.19)
 ground.material_override=grass
 add_child(ground)
 _build_winding_road()
func _build_winding_road()->void:
 var points=[Vector3(0,0,0),Vector3(0,0,-900),Vector3(420,0,-1900),Vector3(900,0,-3000),Vector3(700,0,-4300),Vector3(-250,0,-5400),Vector3(-900,0,-6500),Vector3(-700,0,-7900),Vector3(250,0,-9000),Vector3(1000,0,-10300),Vector3(800,0,-11700),Vector3(-150,0,-13000),Vector3(-850,0,-14300),Vector3(-400,0,-15700),Vector3(0,0,-17000)]
 for p in points: road_curve.add_point(p)
 road_curve.bake_interval=2.0
 for i in range(points.size()-1):
  var a:Vector3=points[i]
  var b:Vector3=points[i+1]
  var length:=a.distance_to(b)
  var road:=StaticBody3D.new()
  road.position=(a+b)*0.5+Vector3(0,-0.04,0)
  road.look_at(Vector3(b.x,road.position.y,b.z),Vector3.UP)
  var shape:=CollisionShape3D.new()
  var box:=BoxShape3D.new()
  box.size=Vector3(13.0,0.3,length+3.0)
  shape.shape=box
  road.add_child(shape)
  var visual:=MeshInstance3D.new()
  var mesh:=BoxMesh.new()
  mesh.size=box.size
  visual.mesh=mesh
  var mat:=StandardMaterial3D.new()
  mat.albedo_color=Color(0.12,0.13,0.14)
  visual.material_override=mat
  road.add_child(visual)
  add_child(road)
 # 17 km at 200 km/h is approximately 5.1 minutes.
func _build_player_car()->void:
 car=RigidBody3D.new()
 car.name="PlayerCar"
 car.position=Vector3(0,1.1,5)
 car.set_script(load("res://scripts/car_controller.gd"))
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
   var value:= [[1,3,5],[2,4,6]][row][column]
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
 traffic.select(2)
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
func _spawn_traffic()->void:
 for n in traffic_nodes:
  if is_instance_valid(n): n.queue_free()
 traffic_nodes.clear()
 var count:int=int(TRAFFIC_PRESETS.get(traffic_level,15))
 var length:=maxf(road_curve.get_baked_length(),1.0)
 for i in range(count):
  var npc:=Node3D.new()
  npc.set_script(load("res://scripts/traffic_car.gd"))
  var visual:=MeshInstance3D.new()
  var mesh:=BoxMesh.new()
  mesh.size=Vector3(1.7,0.85,3.5)
  visual.mesh=mesh
  var mat:=StandardMaterial3D.new()
  mat.albedo_color=Color.from_hsv(fposmod(float(i)*0.137,1.0),0.55,0.8)
  visual.material_override=mat
  npc.add_child(visual)
  add_child(npc)
  npc.configure(road_curve,length*float(i)/maxf(float(count),1.0),8.0+float(i%5)*1.4)
  traffic_nodes.append(npc)
func _apply_fps()->void:
 Engine.max_fps=clampi(int(settings.fps),1,60)
func _load_settings()->void:
 var file:=ConfigFile.new()
 if file.load("user://settings.cfg")==OK:
  settings.fps=int(file.get_value("game","fps",60))
  traffic_level=str(file.get_value("game","traffic","کم"))
func _save_settings()->void:
 var file:=ConfigFile.new()
 file.set_value("game","fps",settings.fps)
 file.set_value("game","traffic",traffic_level)
 file.save("user://settings.cfg")
