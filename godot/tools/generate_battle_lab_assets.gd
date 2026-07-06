extends SceneTree

const OUT_DIR := "res://assets/battle_lab"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_make_dragon_texture().save_png(OUT_DIR + "/gold_dragon.png")
	_make_dragon_texture(0).save_png(OUT_DIR + "/gold_dragon_idle_0.png")
	_make_dragon_texture(1).save_png(OUT_DIR + "/gold_dragon_idle_1.png")
	for i in 5:
		_make_party_texture(_party_palette(i)).save_png(OUT_DIR + "/party_%d.png" % i)
		_make_party_texture(_party_palette(i), 0).save_png(OUT_DIR + "/party_%d_idle_0.png" % i)
		_make_party_texture(_party_palette(i), 1).save_png(OUT_DIR + "/party_%d_idle_1.png" % i)
	quit()

func _party_palette(index: int) -> Array:
	var palettes := [
		[Color(0.93, 0.86, 0.55), Color(0.25, 0.75, 0.42), Color(0.48, 0.30, 0.18)],
		[Color(0.72, 0.82, 1.0), Color(0.22, 0.42, 0.85), Color(0.42, 0.26, 0.16)],
		[Color(1.0, 0.78, 0.88), Color(0.86, 0.28, 0.48), Color(0.34, 0.18, 0.42)],
		[Color(0.82, 1.0, 0.82), Color(0.1, 0.62, 0.48), Color(0.94, 0.74, 0.45)],
		[Color(1.0, 0.72, 0.58), Color(0.82, 0.34, 0.22), Color(0.50, 0.24, 0.14)],
	]
	return palettes[index % palettes.size()]

func _make_party_texture(palette: Array, frame := 0) -> Image:
	var img := Image.create(22, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var skin := Color(0.98, 0.78, 0.56, 1.0)
	var hair: Color = palette[2]
	var cloth: Color = palette[1]
	var trim: Color = palette[0]
	var shadow := Color(0.08, 0.08, 0.09, 1.0)
	var bob := frame % 2
	_rect(img, 7, 3 + bob, 8, 4, hair)
	_rect(img, 6, 7 + bob, 10, 6, skin)
	_rect(img, 5, 9, 3, 6, hair)
	_rect(img, 14, 9, 3, 6, hair)
	_rect(img, 7, 14 + bob, 8, 8, cloth)
	_rect(img, 5, 15 + bob, 3, 6, trim)
	_rect(img, 14, 15 + bob, 3, 6, trim)
	_rect(img, 8, 22, 3, 5, cloth)
	_rect(img, 13, 22, 3, 5, cloth)
	_rect(img, 6, 27, 5, 2, shadow)
	_rect(img, 12, 27, 5, 2, shadow)
	_outline_alpha(img, shadow)
	return img

func _make_dragon_texture(frame := 0) -> Image:
	var img := Image.create(110, 88, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gold := Color(0.94, 0.58, 0.12, 1.0)
	var gold_light := Color(1.0, 0.82, 0.24, 1.0)
	var gold_dark := Color(0.48, 0.27, 0.11, 1.0)
	var wing := Color(0.60, 0.43, 0.30, 0.95)
	var horn := Color(0.95, 0.95, 0.90, 1.0)
	var mouth := Color(0.55, 0.08, 0.05, 1.0)
	var black := Color(0.05, 0.04, 0.04, 1.0)

	var wing_bob := frame % 2
	_rect(img, 18, 12 - wing_bob, 30, 24, wing)
	_rect(img, 44, 10 - wing_bob, 36, 28, wing)
	_rect(img, 24, 35, 54, 24, gold)
	_rect(img, 10, 48, 32, 22, gold)
	_rect(img, 5, 56, 18, 12, gold_light)
	_rect(img, 36, 28, 38, 16, gold_light)
	_rect(img, 64, 44, 34, 24, gold)
	_rect(img, 76, 58, 24, 12 + wing_bob, mouth)
	_rect(img, 78, 68, 22, 4, horn)
	_rect(img, 4, 34, 10, 24, gold)
	_rect(img, 0, 28, 8, 20, horn)
	_rect(img, 83, 38, 12, 12, horn)
	_rect(img, 94, 36, 10, 8, horn)
	_rect(img, 72, 28, 14, 16, gold_light)
	_rect(img, 36, 58, 9, 18, gold_dark)
	_rect(img, 54, 58, 9, 18, gold_dark)
	_rect(img, 26, 72, 14, 6, horn)
	_rect(img, 52, 74, 14, 6, horn)
	_rect(img, 85, 59, 4, 4, black)
	_rect(img, 78, 63, 22, 2, horn)
	_outline_alpha(img, black)
	return img

func _rect(img: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(max(0, y), min(img.get_height(), y + height)):
		for px in range(max(0, x), min(img.get_width(), x + width)):
			img.set_pixel(px, py, color)

func _outline_alpha(img: Image, color: Color) -> void:
	var points: Array[Vector2i] = []
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var p: Vector2i = Vector2i(x, y) + offset
					if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
						if img.get_pixel(p.x, p.y).a == 0.0:
							points.append(p)
	for point in points:
		img.set_pixel(point.x, point.y, color)
