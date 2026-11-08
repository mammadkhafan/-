extends RefCounted
class_name VehicleCatalog
const VEHICLES := [
{"name":"Compact 1","mass":980.0,"power":55.0,"torque":105.0,"max_rpm":6200.0,"grip":1.0,"top":155.0},
{"name":"Compact 2","mass":1050.0,"power":68.0,"torque":125.0,"max_rpm":6400.0,"grip":1.02,"top":170.0},
{"name":"Hatchback Sport","mass":1120.0,"power":110.0,"torque":180.0,"max_rpm":6800.0,"grip":1.12,"top":210.0},
{"name":"City Sedan","mass":1240.0,"power":90.0,"torque":160.0,"max_rpm":6500.0,"grip":1.0,"top":190.0},
{"name":"Family Sedan","mass":1380.0,"power":125.0,"torque":210.0,"max_rpm":6500.0,"grip":1.03,"top":215.0},
{"name":"Classic Coupe","mass":1180.0,"power":145.0,"torque":220.0,"max_rpm":7000.0,"grip":1.1,"top":230.0},
{"name":"Roadster","mass":1080.0,"power":155.0,"torque":205.0,"max_rpm":7200.0,"grip":1.18,"top":235.0},
{"name":"Muscle Coupe","mass":1650.0,"power":280.0,"torque":420.0,"max_rpm":6000.0,"grip":1.05,"top":250.0},
{"name":"Sport Sedan","mass":1580.0,"power":250.0,"torque":350.0,"max_rpm":7000.0,"grip":1.18,"top":260.0},
{"name":"Super Sport","mass":1420.0,"power":390.0,"torque":480.0,"max_rpm":8200.0,"grip":1.3,"top":310.0},
{"name":"Track Special","mass":1260.0,"power":430.0,"torque":500.0,"max_rpm":8500.0,"grip":1.38,"top":320.0},
{"name":"Vintage Sedan","mass":1320.0,"power":48.0,"torque":95.0,"max_rpm":4800.0,"grip":0.88,"top":125.0},
{"name":"Offroad 4x4","mass":1980.0,"power":180.0,"torque":340.0,"max_rpm":5800.0,"grip":1.05,"top":185.0},
{"name":"Pickup","mass":2100.0,"power":160.0,"torque":360.0,"max_rpm":5200.0,"grip":0.96,"top":175.0},
{"name":"Delivery Van","mass":2250.0,"power":125.0,"torque":280.0,"max_rpm":5000.0,"grip":0.9,"top":150.0},
{"name":"City Bus","mass":7800.0,"power":240.0,"torque":900.0,"max_rpm":2600.0,"grip":0.82,"top":105.0},
{"name":"Rally Car","mass":1280.0,"power":300.0,"torque":400.0,"max_rpm":7500.0,"grip":1.25,"top":245.0},
{"name":"Electric Compact","mass":1450.0,"power":120.0,"torque":260.0,"max_rpm":12000.0,"grip":1.05,"top":180.0},
{"name":"Electric Sport","mass":1880.0,"power":330.0,"torque":600.0,"max_rpm":14000.0,"grip":1.22,"top":260.0},
{"name":"Heavy Truck","mass":8500.0,"power":320.0,"torque":1400.0,"max_rpm":2400.0,"grip":0.78,"top":120.0}
]
static func get_vehicle(index:int)->Dictionary:
 return VEHICLES[clampi(index,0,VEHICLES.size()-1)].duplicate(true)
static func count()->int:
 return VEHICLES.size()
