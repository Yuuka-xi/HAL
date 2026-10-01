extends Node

const SAVE_SCHEMA_VERSION := 1

var play_time_seconds := 0.0 # 累计游戏时长
var campaign: Dictionary = {} # 存放具体玩法的数据，当前是空字典

# 新游戏时清空进度和时长
func reset() -> void:
	play_time_seconds = 0.0
	campaign.clear()

# 把当前状态打包成字典，包含版本号、时长和 campaign
func snapshot() -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"play_time_seconds": play_time_seconds,
		"campaign": campaign.duplicate(true),
	}

# 从字典恢复状态
# 这两个函数通常由 SaveManager 调用
func restore(data: Dictionary) -> void:
	play_time_seconds = float(data.get("play_time_seconds", 0.0))
	campaign = data.get("campaign", {}).duplicate(true)
