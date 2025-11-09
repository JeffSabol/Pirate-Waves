extends Resource
class_name TradeRoute

@export var name: String
@export var from_port: NodePath
@export var to_port: NodePath
@export var path2d: NodePath        # optional spline route
@export var waypoints: PackedVector2Array
@export var base_traffic_per_minute := 1.0
@export var pirate_pressure := 0.2
