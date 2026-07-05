class_name ObjectTargetCandidate
extends RefCounted

enum Kind {
	TILE,
	EDGE,
	CORNER
}

var kind: Kind = Kind.TILE
var coord: Vector2i = Vector2i.ZERO
var orientation: StringName = &""
var object_id: StringName = &""
var visual: Node3D


static func create_tile(coord_value: Vector2i, object_id_value: StringName, visual_value: Node3D) -> ObjectTargetCandidate:
	var candidate := ObjectTargetCandidate.new()
	candidate.kind = Kind.TILE
	candidate.coord = coord_value
	candidate.object_id = object_id_value
	candidate.visual = visual_value
	return candidate


static func create_edge(coord_value: Vector2i, orientation_value: StringName, object_id_value: StringName, visual_value: Node3D) -> ObjectTargetCandidate:
	var candidate := ObjectTargetCandidate.new()
	candidate.kind = Kind.EDGE
	candidate.coord = coord_value
	candidate.orientation = orientation_value
	candidate.object_id = object_id_value
	candidate.visual = visual_value
	return candidate


static func create_corner(coord_value: Vector2i, object_id_value: StringName, visual_value: Node3D) -> ObjectTargetCandidate:
	var candidate := ObjectTargetCandidate.new()
	candidate.kind = Kind.CORNER
	candidate.coord = coord_value
	candidate.object_id = object_id_value
	candidate.visual = visual_value
	return candidate


func get_signature() -> String:
	return "%s:%s:%s:%s" % [kind, coord, orientation, object_id]
