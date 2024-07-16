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
	for csg_shape : CSGShape3D in csg:
		
		
		var mesh_instance = MeshInstance3D.new()
		var csg_mesh : Mesh = csg_shape.get_meshes()[1]
		var csg_transform : Transform3D = csg_shape.global_transform
		var csg_name = csg_shape.name
		var csg_material = csg_shape.material_override
		
		var staticBody = Node3D.new()
		staticBody.transform.origin = csg_transform.origin
		staticBody.transform.basis = csg_transform.basis
		csg_shape.get_parent().add_child(staticBody)
		staticBody.name = csg_name
		staticBody.owner = root
		
		
		mesh_instance.mesh = csg_mesh
		staticBody.add_child(mesh_instance)
		mesh_instance.owner = root
		mesh_instance.name = "Mesh Instance"
		mesh_instance.create_trimesh_collision()
		mesh_instance.material_override = csg_material
		
		#var collisionShape = CollisionShape3D.new()
		#var shape = BoxShape3D.new()
		#
		#collisionShape.shape = shape
		#
		#staticBody.add_child(collisionShape)
		#collisionShape.owner = root
		#collisionShape.name = "Collision Shape"
		#collisionShape.scale = mesh_instance.scale
		#
		csg_shape.get_parent().remove_child(csg_shape)
