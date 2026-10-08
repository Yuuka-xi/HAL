extends RefCounted

const NAMES = {
	# 新手教程
	"elliot": "Elliot",
	"hal": "hal",
	"keyword": "关键词",
	"household_robot": "家务机器人",
	"owner": "拥有者",
	# 关卡1
	"memory_storage_drive": "记忆储存盘",
	"storage_box": "储存盘收纳盒",
	"model": "42",
	"pc": "台式机",
	"disc_reader": "读盘器"
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
	"memory_storage_drive": "memory_storage_drive_info",
	"storage_box": "storage_box_info",
	"model": "model_info",
	"pc": "pc_info",
	"disc_reader": "disc_reader_info",
	"memory_storage_drive+storage_box": "memory_storage_drive_storage_box_info",
	"model+pc": "model_pc_info",
	"hal+memory_storage_drive": "hal_memory_storage_drive_info"
}
