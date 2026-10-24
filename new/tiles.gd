extends Node
class_name TileManger
var tile_maker=preload("res://code/staitic/tile.gd")
func load_all_tile():
	pass
var track_position:PackedVector2Array=PackedVector2Array()
var angle_data:PackedFloat32Array=PackedFloat32Array()
func _on_playandstop_pressed() -> void:
	track_position=$"../../AdofaiLoder".track_positon
	angle_data=$"../../AdofaiLoder".angle_data
	for i in range(track_position.size()):
		var f_an:float
		if i==0:
			f_an=0.0
		else:
			f_an=angle_data[i-1]
		var point=tile_maker.CaculatePoints(f_an+180,angle_data[i],25,45)
		var mesh=tile_maker.poly_to_mesh(point)
		var a=MeshInstance2D.new()
		a.mesh=mesh
		a.position=track_position[i]
		a.position.y*=-1
		add_child(a)
