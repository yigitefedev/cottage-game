class_name GameGridData
extends Resource

var tiles: Dictionary = {}
var edges: Dictionary = {}
var corners: Dictionary = {}


func has_tile(coord: Vector2i) -> bool:
	return tiles.has(coord)


func create_tile(coord: Vector2i, usable: bool = true) -> GameTileData:
	var tile := GameTileData.new(coord)
	tile.usable = usable
	tiles[coord] = tile
	return tile


func get_tile(coord: Vector2i) -> GameTileData:
	return tiles.get(coord, null)


func get_or_create_tile(coord: Vector2i, usable: bool = true) -> GameTileData:
	if has_tile(coord):
		return get_tile(coord)

	return create_tile(coord, usable)


func remove_tile(coord: Vector2i) -> void:
	tiles.erase(coord)


func get_edge_key(coord: Vector2i, orientation: StringName) -> String:
	return "%s,%s:%s" % [coord.x, coord.y, orientation]


func has_edge(coord: Vector2i, orientation: StringName) -> bool:
	return edges.has(get_edge_key(coord, orientation))


func get_edge(coord: Vector2i, orientation: StringName) -> GameEdgeData:
	return edges.get(get_edge_key(coord, orientation), null)


func get_or_create_edge(coord: Vector2i, orientation: StringName) -> GameEdgeData:
	var key := get_edge_key(coord, orientation)

	if edges.has(key):
		return edges[key]

	var edge := GameEdgeData.new(coord, orientation)
	edges[key] = edge
	return edge


func get_corner(coord: Vector2i) -> GameCornerData:
	return corners.get(coord, null)


func get_or_create_corner(coord: Vector2i) -> GameCornerData:
	if corners.has(coord):
		return corners[coord]

	var corner := GameCornerData.new(coord)
	corners[coord] = corner
	return corner
