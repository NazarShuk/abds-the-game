# Button to activate the painting and show the paint panel

@tool
extends Button

class_name PluginButton

var root :Node
var csgs : Array

# Show button in UI, untoggled
func show_button(root: Node, csg : Array):
	self.root = root
	self.csgs = csg
	show()

# Hide button in UI, untoggled
func hide_button():
	hide()

func _on_PluginButton_pressed() -> void:
	convert_csg_to_meshinstance()

func convert_csg_to_meshinstance():
	for mesh_instance in csgs:
		var original_mesh = mesh_instance.mesh
		var original_transform = mesh_instance.global_transform
		var original_name = mesh_instance.name
		
		# Create new BoxMesh
		var box_mesh = BoxMesh.new()
		
		# Get the AABB (bounding box) of the original mesh
		var aabb = original_mesh.get_aabb()
		
		# Set the box size based on the AABB dimensions
		box_mesh.size = aabb.size
		
		# Update the mesh instance
		mesh_instance.mesh = box_mesh
		
		# Adjust transform to account for AABB center offset
		var center_offset = aabb.position + (aabb.size * 0.5)
		mesh_instance.global_transform = original_transform.translated(center_offset)
		
		# Keep the original name
		mesh_instance.name = original_name
