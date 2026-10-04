extends RefCounted

const NAMES = {
	"elliot": "Elliot",
	"hal": "hal",
	"keyword": "关键词",
	"household_robot": "家务机器人",
	"owner": "拥有者",
}

# 双词组合按编号排序，用 + 连接；值是 .dialogue 中的入口标题。
const ENTRIES = {
	"elliot": "elliot_info",
	"hal": "hal_info",
	"keyword": "keyword_info",
	"elliot+hal": "ownership_info",
	"household_robot": "robot_info",
	"owner": "owner_info",
}
