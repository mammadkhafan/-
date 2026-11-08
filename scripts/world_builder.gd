extends RefCounted
class_name OpenRoadWorldBuilder

const ASPHALT := Color(0.075, 0.082, 0.09)
const GRASS := Color(0.19, 0.29, 0.16)

func build_world(root: Node3D, curve: Curve3D) -> void:
	_build_lighting(root)
	_build_ground(root)
	_build_road(root, curve)
	_build_forest(root, curve)
	_build_hills(root, curve)
	_build_town(root)

func _material(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _build_lighting(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, -32.0, 0.0)
	sun.light_color = Color(1.0, 0.91, 0.78)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	root.add_child(sun)

	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.12, 0.31, 0.52)
	sky_mat.sky_horizon_color = Color(0.69, 0.78, 0.83)
	sky_mat.ground_bottom_color = Color(0.12, 0.16, 0.13)
	sky_mat.ground_horizon_color = Color(0.48, 0.57, 0.48)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.72, 0.77)
	env.fog_density = 0.0018
	env.fog_sky_affect = 0.7
	world.environment = env
	root.add_child(world)

func _build_ground(root: Node3D) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40000.0, 40000.0)
	ground.mesh = plane
	ground.position.y = -0.2
	ground.material_override = _material(GRASS, 1.0)
	root.add_child(ground)

	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40000.0, 1.0, 40000.0)
	collision.shape = shape
	body.position.y = -0.7
	body.add_child(collision)
	root.add_child(body)

func _build_road(root: Node3D, curve: Curve3D) -> void:
	var length := curve.get_baked_length()
	var road_mat := _material(ASPHALT, 0.96)
	var line_mat := _material(Color(0.92, 0.88, 0.68), 0.8)
	var shoulder_mat := _material(Color(0.35, 0.34, 0.29), 1.0)
	var d := 0.0
	while d < length:
		var next_d := minf(d + 42.0, length)
		var a := curve.sample_baked(d)
		var b := curve.sample_baked(next_d)
		var delta := b - a
		var seg_len := delta.length()
		if seg_len > 0.1:
			var mid := (a + b) * 0.5
			var yaw := atan2(-delta.x, -delta.z)
			_add_box(root, Vector3(13.0, 0.24, seg_len + 0.8), mid + Vector3(0.0, -0.05, 0.0), yaw, road_mat, true)
			_add_box(root, Vector3(0.13, 0.018, seg_len), mid + Vector3(0.0, 0.085, 0.0), yaw, line_mat, false)
			_add_box(root, Vector3(0.16, 0.02, seg_len), mid + Vector3(-6.15, 0.09, 0.0), yaw, shoulder_mat, false)
			_add_box(root, Vector3(0.16, 0.02, seg_len), mid + Vector3(6.15, 0.09, 0.0), yaw, shoulder_mat, false)
			for mark_d in range(0, int(seg_len), 12):
				var p := a.lerp(b, clampf(float(mark_d) / seg_len, 0.0, 1.0))
				_add_box(root, Vector3(0.12, 0.025, 4.0), p + Vector3(0.0, 0.105, 0.0), yaw, line_mat, false)
		d = next_d

func _add_box(root: Node3D, size: Vector3, pos: Vector3, yaw: float, mat: Material, collision: bool) -> void:
	var node: Node3D
	if collision:
		node = StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		node.add_child(cs)
	else:
		node = Node3D.new()
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = mat
	node.add_child(visual)
	node.position = pos
	node.rotation.y = yaw
	root.add_child(node)

func _build_forest(root: Node3D, curve: Curve3D) -> void:
	var length := curve.get_baked_length()
	var count := clampi(int(length / 24.0), 100, 700)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.34
	trunk_mesh.height = 4.2
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 1.75
	leaf_mesh.height = 3.5
	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk_mesh
	trunk_mm.instance_count = count * 2
	var leaf_mm := MultiMesh.new()
	leaf_mm.transform_format = MultiMesh.TRANSFORM_3D
	leaf_mm.mesh = leaf_mesh
	leaf_mm.instance_count = count * 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 73521
	for i in range(count):
		var distance := (float(i) + rng.randf_range(0.0, 1.0)) / float(count) * length
		var p := curve.sample_baked(distance)
		var p2 := curve.sample_baked(minf(distance + 2.0, length))
		var tangent := (p2 - p).normalized()
		var side := tangent.cross(Vector3.UP).normalized()
		for lane in range(2):
			var sign := -1.0 if lane == 0 else 1.0
			var offset := rng.randf_range(18.0, 52.0)
			var pos := p + side * sign * offset
			var scale := rng.randf_range(0.72, 1.45)
			var trunk_t := Transform3D(Basis().scaled(Vector3(scale, scale, scale)), pos + Vector3(0.0, 2.1 * scale, 0.0))
			var leaf_t := Transform3D(Basis().scaled(Vector3(scale, scale, scale)), pos + Vector3(0.0, 4.25 * scale, 0.0))
			var idx := i * 2 + lane
			trunk_mm.set_instance_transform(idx, trunk_t)
			leaf_mm.set_instance_transform(idx, leaf_t)
	var trunks := MultiMeshInstance3D.new()
	trunks.multimesh = trunk_mm
	trunks.material_override = _material(Color(0.22, 0.13, 0.075), 1.0)
	root.add_child(trunks)
	var leaves := MultiMeshInstance3D.new()
	leaves.multimesh = leaf_mm
	leaves.material_override = _material(Color(0.12, 0.29, 0.13), 1.0)
	root.add_child(leaves)

func _build_hills(root: Node3D, curve: Curve3D) -> void:
	var length := curve.get_baked_length()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4811
	var hill_mesh := SphereMesh.new()
	hill_mesh.radius = 1.0
	hill_mesh.height = 2.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = hill_mesh
	mm.instance_count = 70
	for i in range(70):
		var d := float(i) / 70.0 * length
		var p := curve.sample_baked(d)
		var p2 := curve.sample_baked(minf(d + 3.0, length))
		var side := (p2 - p).cross(Vector3.UP).normalized()
		var sign := -1.0 if i % 2 == 0 else 1.0
		var distance := rng.randf_range(95.0, 210.0)
		var size := Vector3(rng.randf_range(35.0, 85.0), rng.randf_range(24.0, 65.0), rng.randf_range(35.0, 80.0))
		var pos := p + side * sign * distance + Vector3(0.0, size.y * 0.5 - 3.0, 0.0)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(size), pos))
	var hills := MultiMeshInstance3D.new()
	hills.multimesh = mm
	hills.material_override = _material(Color(0.24, 0.32, 0.22), 1.0)
	root.add_child(hills)

func _build_town(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9872
	for i in range(22):
		var width := rng.randf_range(8.0, 13.0)
		var depth := rng.randf_range(8.0, 15.0)
		var height := rng.randf_range(7.0, 18.0)
		var x := -48.0 - float(i % 4) * 17.0
		var z := -90.0 - float(i / 4) * 62.0
		var tint := Color.from_hsv(rng.randf_range(0.04, 0.13), rng.randf_range(0.12, 0.28), rng.randf_range(0.58, 0.82))
		_add_box(root, Vector3(width, height, depth), Vector3(x, height * 0.5, z), rng.randf_range(-0.04, 0.04), _material(tint, 0.9), false)
		var roof := _material(Color(0.19, 0.16, 0.14), 1.0)
		_add_box(root, Vector3(width + 0.4, 0.35, depth + 0.4), Vector3(x, height + 0.15, z), 0.0, roof, false)
		for floor in range(maxi(1, int(height / 3.0))):
			for col in range(2):
				var window_mat := _material(Color(0.13, 0.24, 0.31), 0.25, 0.15)
				_add_box(root, Vector3(1.15, 1.35, 0.08), Vector3(x - width * 0.25 + float(col) * width * 0.5, 1.9 + float(floor) * 3.0, z - depth * 0.5 - 0.06), 0.0, window_mat, false)
	for i in range(34):
		var z := -260.0 - float(i) * 155.0
		var x := 30.0 + float(i % 3) * 16.0
		var height := rng.randf_range(4.0, 7.0)
		var house_mat := _material(Color.from_hsv(rng.randf_range(0.04, 0.14), 0.18, 0.72), 0.95)
		_add_box(root, Vector3(8.5, height, 9.0), Vector3(x, height * 0.5, z), 0.0, house_mat, false)
		_add_box(root, Vector3(9.0, 0.3, 9.5), Vector3(x, height + 0.12, z), 0.0, _material(Color(0.25, 0.18, 0.14)), false)
