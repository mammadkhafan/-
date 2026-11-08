extends Node3D
var route:Curve3D
var distance:=0.0
var speed:=12.0
var route_length:=1.0
func configure(curve:Curve3D,start_distance:float,speed_mps:float)->void:
 route=curve
 distance=start_distance
 speed=speed_mps
 route_length=maxf(route.get_baked_length(),1.0)
func _process(delta:float)->void:
 if route==null: return
 distance=fposmod(distance+speed*delta,route_length)
 var point:=route.sample_baked(distance)
 var ahead:=route.sample_baked(fposmod(distance+2.0,route_length))
 global_position=point+Vector3(0,0.45,0)
 look_at(ahead+Vector3(0,0.45,0),Vector3.UP)
