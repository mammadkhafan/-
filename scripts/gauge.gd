extends Control
var caption: String = "Gauge"
var unit: String = ""
var max_value: float = 100.0
var value: float = 0.0

func _draw()->void:
 var center:=Vector2(size.x*0.5,size.y*0.56)
 var radius:=minf(size.x*0.43,size.y*0.43)
 draw_circle(center,radius+5.0,Color(0.01,0.025,0.04,0.88))
 draw_arc(center,radius,deg_to_rad(135),deg_to_rad(405),72,Color(0.16,0.25,0.31),5.0,true)
 draw_arc(center,radius,deg_to_rad(135),deg_to_rad(405),72,Color(0.05,0.72,0.92),3.0,true)
 for i in range(11):
  var angle:=deg_to_rad(135.0+27.0*float(i))
  var outer:=center+Vector2(cos(angle),sin(angle))*radius
  var inner:=center+Vector2(cos(angle),sin(angle))*(radius-9.0)
  draw_line(inner,outer,Color(0.82,0.91,0.96),2.0)
 var ratio:=clampf(value/maxf(max_value,1.0),0.0,1.0)
 var needle_angle:=deg_to_rad(135.0+270.0*ratio)
 var tip:=center+Vector2(cos(needle_angle),sin(needle_angle))*(radius-14.0)
 draw_line(center,tip,Color(1.0,0.28,0.19),3.5,true)
 draw_circle(center,5.0,Color(0.92,0.96,1.0))
 var font:=ThemeDB.fallback_font
 if font:
  draw_string(font,Vector2(0,size.y-22.0),caption,HORIZONTAL_ALIGNMENT_CENTER,size.x,13,Color(0.8,0.91,0.97))
  draw_string(font,Vector2(0,center.y+radius*0.55),str(int(value))+" "+unit,HORIZONTAL_ALIGNMENT_CENTER,size.x,12,Color.WHITE)

func _process(_delta:float)->void:
 queue_redraw()
