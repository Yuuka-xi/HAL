extends RefCounted

const NAMES = {
	# 新手教程
	"elliot": "Elliot",
	"hal": "hal",
	"keyword": "关键词",
	"household_robot": "家务机器人",
	"owner": "拥有者",
	# 关卡1
	"mobile_module": "移动模块",
	"large_cart": "大推车",
	"strength_limit": "力量限制",
	"eve": "Eve",
	"impact": "撞击",
	"auto_bookcase": "自动书柜",
	"switch": "开关"
}

# 双词组合按编号排序，用 + 连接；值是 .dialogue 中的入口标题。
const ENTRIES = {
	# 新手教程
	"elliot": "elliot_info",
	"hal": "hal_info",
	"keyword": "keyword_info",
	"elliot+hal": "ownership_info",
	"household_robot": "robot_info",
	"owner": "owner_info",
	# 关卡1
	"mobile_module": "mobile_module_info",
	"large_cart": "large_cart_info",
	"strength_limit": "strength_limit_info",
	"eve": "eve_info",
	"impact": "impact_info",
	"auto_bookcase": "auto_bookcase_info",
	"switch": "switch_info"
}
