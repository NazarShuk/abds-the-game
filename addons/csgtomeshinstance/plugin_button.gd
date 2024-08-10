# Button to activate the painting and show the paint panel

@tool
extends Button

class_name PluginButton

var root :Node
var csg :Array

# Show button in UI, untoggled
func show_button(root: Node, csg):
	self.root = root
	self.csg = csg
	show()

# Hide button in UI, untoggled
func hide_button():
	hide()

func _on_PluginButton_pressed() -> void:
	convert_csg_to_meshinstance()

func convert_csg_to_meshinstance():
	for csg_shape : CSGBox3D in csg:
		
		
		var mesh_instance = MeshInstance3D.new()
		var csg_mesh : ArrayMesh = csg_shape.get_meshes()[1]
		csg_mesh.regen_normal_maps()
		var csg_transform : Transform3D = csg_shape.global_transform
		var csg_name = csg_shape.name
		var csg_material = csg_shape.material_override
		
		var m = BoxMesh.new()
		m.size = csg_shape.size
		mesh_instance.mesh = m
		csg_shape.get_parent().add_child(mesh_instance)
		mesh_instance.owner = root
		mesh_instance.name = csg_name
		mesh_instance.create_trimesh_collision()
		mesh_instance.material_override = csg_material
		mesh_instance.transform = csg_transform
	
		csg_shape.get_parent().remove_child(csg_shape)


func _on_button_pressed():
	pass # Replace with function body.
