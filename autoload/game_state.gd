extends Node

# gamestate状态发生变化的信号，需要用campaign_changed.emit()主动发出
signal campaign_changed

# 新游戏的初始模板
const INITIAL_CAMPAIGN = {
	"keywords": {},
	"keyword_reads": {},
	"attributes": {
		"social": 0, 
		"exploration": 0, 
		"logic": 0, 
		"emotion": 0},
	"flags": {
		"vision_enabled": false, # 视觉模块初始未开启
		"emotion_visible": false}, # 表示隐藏情感 UI
	"choices": {},
}

var play_time_seconds := 0.0 # 累计游戏时长
var campaign: Dictionary = INITIAL_CAMPAIGN.duplicate(true) # 创建真正用于游玩的状态字典

# .dialogue 通过这个方法写入状态，并通知任务 UI 刷新。
func set_campaign_value(key: String, value: Variant) -> void:
	campaign[key] = value
	campaign_changed.emit()

## 工作日志模块（关键词）
# 每关重新设置可用列表，历史收录仍保留在 keywords 中。
func start_keyword_list(level: String, initial_keywords: Array) -> void:
	campaign["current_level"] = level
	campaign["level_keywords"] = {}
	for id in initial_keywords:
		campaign["level_keywords"][id] = true
		campaign["keywords"][id] = true
	campaign_changed.emit()

func get_available_keywords() -> Dictionary:
	return campaign.get("level_keywords", campaign.get("keywords", {}))

# 收录关键词；说明文字不存入存档，只保存编号对应的解锁状态。
func unlock_keyword(id: String) -> void:
	var keywords: Dictionary = campaign.get("keywords", {})
	keywords[id] = true
	campaign["keywords"] = keywords
	if campaign.has("level_keywords"):
		campaign["level_keywords"][id] = true
	campaign_changed.emit()

# 双词变化需要查询对应组合才算已读；剧情可传 false 主动提示变化。
func set_keyword_read(ids: Array, value := true) -> void:
	var sorted_ids := ids.duplicate()
	sorted_ids.sort()
	var reads: Dictionary = campaign.get("keyword_reads", {})
	reads["+".join(sorted_ids)] = value
	if value:
		for id in sorted_ids:
			reads[id] = true
	set_campaign_value("keyword_reads", reads)

## 价值评估模块（属性）
# 数值与显示无关：情感未显示时也可以读取和修改。
func get_attribute(id: String) -> int:
	return campaign.get("attributes", {}).get(id, 0)

# 把属性设为指定值
func set_attribute(id: String, value: int) -> void:
	var attributes: Dictionary = campaign.get("attributes", {})
	attributes[id] = value
	set_campaign_value("attributes", attributes)

# 在原数值上增减
func add_attribute(id: String, amount: int) -> void:
	set_attribute(id, get_attribute(id) + amount)

## flags保存真假事实
# 读取指定事实，不存在则按 false 处理
func get_flag(id: String) -> bool:
	return campaign.get("flags", {}).get(id, false)

# 修改指定事实，不需要全部预先声明。调用 set_flag("door_open", true) 就会在 flags 中加入这个事实。
func set_flag(id: String, value: bool) -> void:
	var flags: Dictionary = campaign.get("flags", {})
	flags[id] = value
	set_campaign_value("flags", flags)

## choices 保存具体选择
# 读取某次选择，没有记录则返回空字符串 ""
func get_choice(id: String) -> String:
	return campaign.get("choices", {}).get(id, "")

# 记录某次选择
func set_choice(id: String, value: String) -> void:
	var choices: Dictionary = campaign.get("choices", {})
	choices[id] = value
	set_campaign_value("choices", choices)

# 新游戏时清空进度和时长
func reset() -> void:
	play_time_seconds = 0.0
	campaign = INITIAL_CAMPAIGN.duplicate(true)
	campaign_changed.emit()

# 把当前状态打包成字典，包含时长和 campaign
func snapshot() -> Dictionary:
	return {
		"play_time_seconds": play_time_seconds,
		"campaign": campaign.duplicate(true),
	}

# 从字典恢复状态
# 这两个函数通常由 SaveManager 调用
func restore(data: Dictionary) -> void:
	play_time_seconds = float(data.get("play_time_seconds", 0.0))
	campaign = data.get("campaign", {}).duplicate(true)
	campaign_changed.emit()
