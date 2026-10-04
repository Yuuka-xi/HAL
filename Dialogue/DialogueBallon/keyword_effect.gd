extends RichTextEffect

const KeywordData = preload("res://Scene/WorkLog/keyword_data.gd")
const HIGHLIGHT = Color("ffd479")
var bbcode := "collect"
var label: RichTextLabel
var words: Array[Dictionary] = []

# 复制实际绘制的字形，而不是重新排版一个 Label，因此换行位置也保持一致。
class FlyingWord extends Node2D:
	var glyphs: Array = []
	var font_size: int
	var origin: Vector2

	func _draw() -> void:
		var server := TextServerManager.get_primary_interface()
		for glyph in glyphs:
			server.font_draw_glyph(glyph.font, get_canvas_item(), font_size,
				glyph.position - origin, glyph.index, Color("ffd479"))

# [kw=真实ID] 自动替换为显示名称和收录效果；每个标记独立播放，不检查解锁状态。
func prepare(text: String) -> String:
	words.clear()
	var pattern := RegEx.create_from_string("\\[kw=([^\\]]+)\\]")
	var result := ""
	var cursor := 0
	for token in pattern.search_all(text):
		var id := token.get_string(1)
		result += text.substr(cursor, token.get_start() - cursor)
		result += "[collect index=%d]%s[/collect]" % [words.size(), KeywordData.NAMES[id]]
		words.append({"id": id, "glyphs": {}, "collected": false})
		cursor = token.get_end()
	return result + text.substr(cursor)

func _process_custom_fx(fx: CharFXTransform) -> bool:
	var word: Dictionary = words[int(fx.env.index)]
	if not word.collected:
		fx.color = HIGHLIGHT
	if not fx.outline:
		word.glyphs[Vector2i(fx.range.x, fx.glyph_index)] = {
			"font": fx.font, "index": fx.glyph_index,
			"position": fx.transform.origin + fx.offset,
		}
	return true

# 飞入期间由调用方锁住推进；动画结束才写入 GameState 并取消高亮。
func collect(host: Node, target: Control) -> void:
	if words.is_empty():
		return
	await RenderingServer.frame_post_draw
	for word in words:
		var copy := FlyingWord.new()
		copy.glyphs = word.glyphs.values()
		copy.font_size = label.get_theme_font_size("normal_font_size")
		copy.origin = copy.glyphs[0].position if not copy.glyphs.is_empty() else Vector2.ZERO
		host.add_child(copy)
		copy.transform = label.get_global_transform() * Transform2D(0.0, copy.origin)
		var destination := target.get_global_rect().get_center()
		var tween := host.create_tween().set_parallel(true)
		tween.tween_property(copy, "position", destination, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(copy, "scale", copy.scale * 0.25, 0.6)
		tween.tween_property(copy, "modulate:a", 0.0, 0.2).set_delay(0.4)
		await tween.finished
		copy.queue_free()
		word.collected = true
		GameState.unlock_keyword(word.id)
		label.queue_redraw()
	var flash := host.create_tween()
	flash.tween_property(target, "modulate", HIGHLIGHT, 0.1)
	flash.tween_property(target, "modulate", Color.WHITE, 0.15)
	await flash.finished

# 插件的停顿、速度与行内指令使用字符编号；补上前缀和关键词后同步移动这些编号。
func shift_index(index: int, text: String, prefix: String) -> int:
	var tags := RegEx.create_from_string("\\[[^\\]]*\\]")
	var keywords := RegEx.create_from_string("\\[kw=([^\\]]+)\\]")
	for token in keywords.search_all(prefix):
		prefix = prefix.replace(token.get_string(), KeywordData.NAMES[token.get_string(1)])
	var offset := tags.sub(prefix, "", true).length()
	for token in keywords.search_all(text):
		if tags.sub(text.left(token.get_start()), "", true).length() <= index:
			offset += String(KeywordData.NAMES[token.get_string(1)]).length()
	return index + offset
