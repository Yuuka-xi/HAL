extends RichTextEffect

const KeywordData = preload("res://Scene/WorkLog/keyword_data.gd")
var highlight_color := Color("ffd479")
var bbcode := "collect"
var label: RichTextLabel
var words: Array[Dictionary] = []

# [kw=真实ID] 替换为显示名称，未收录的关键词才高亮和提示。
func prepare(text: String) -> String:
	words.clear()
	var pattern := RegEx.create_from_string("\\[kw=([^\\]]+)\\]")
	var result := ""
	var cursor := 0
	for token in pattern.search_all(text):
		var id := token.get_string(1)
		result += text.substr(cursor, token.get_start() - cursor)
		result += "[collect index=%d]%s[/collect]" % [words.size(), KeywordData.NAMES[id]]
		words.append({"id": id, "collected": false})
		cursor = token.get_end()
	return result + text.substr(cursor)

func _process_custom_fx(fx: CharFXTransform) -> bool:
	var word: Dictionary = words[int(fx.env.index)]
	if not word.collected and not GameState.campaign["keywords"].get(word.id, false):
		fx.color = highlight_color
	return true

# 历史收录不重复提示，但仍可重新加入当前关卡的可用列表。
func collect() -> void:
	var names: PackedStringArray = []
	for word in words:
		if word.collected:
			continue
		word.collected = true
		var already_collected: bool = GameState.campaign["keywords"].get(word.id, false)
		if not GameState.get_available_keywords().get(word.id, false):
			GameState.unlock_keyword(word.id)
		if not already_collected:
			names.append(KeywordData.NAMES[word.id])
	if not names.is_empty():
		WorkLog.get_node("KeywordNotice").show_keywords(names)
		label.queue_redraw()

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
