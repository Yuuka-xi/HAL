extends Node

signal campaign_changed

var play_time_seconds := 0.0 # 累计游戏时长
var campaign: Dictionary = {
	"variable1": false,
	"variable2": false
	}

# .dialogue 通过这个方法写入状态，并通知任务 UI 刷新。
func set_campaign_value(key: String, value: Variant) -> void:
	campaign[key] = value
	campaign_changed.emit()

# 新游戏时清空进度和时长
func reset() -> void:
	play_time_seconds = 0.0
	campaign.clear()
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
