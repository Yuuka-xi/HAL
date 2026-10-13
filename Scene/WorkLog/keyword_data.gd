extends RefCounted

const NAMES = {
	# 新手教程
	"unknown_audio_source": "未知声音来源",
	"elliot": "Elliot",
	"hal": "hal",
	"keyword": "关键词",
	"household_robot": "家务机器人",
	"owner": "拥有者",
	# 关卡1
	"memory_storage_drive": "记忆存储盘",
	"storage_box": "收纳盒",
	"dsk": "dsk",
	"toy": "玩具",
	"tulip": "郁金香",
	"sofa": "单人沙发",
	"door_lock": "门锁",
	"pc": "台式机",
	"disc_reader": "读盘器",
	"door": "门",
	# 关卡2
	"bedroom": "卧室",
	"sensor": "感应器",
	"bed": "床",
	"cleaner": "清洁剂",
	"coffee": "咖啡"
	
}

# 双词组合按编号排序，用 + 连接；值是 .dialogue 中的入口标题。
const ENTRIES = {
	# 新手教程
	"unknown_audio_source": "unknown_audio_source_info",
	"elliot": "elliot_info",
	"hal": "hal_info",
	"keyword": "keyword_info",
	"elliot+hal": "elliot_hal_info",
	"household_robot": "household_robot_info",
	"owner": "owner_info",
	"hal+household_robot": "household_robot_hal_info",
	# 关卡1
	"memory_storage_drive": "memory_storage_drive_info",
	"storage_box": "storage_box_info",
	"dsk": "dsk_info",
	"toy": "toy_info",
	"tulip": "tulip_info",
	"sofa": "sofa_info",
	"door_lock": "door_lock_info",
	"door+door_lock": "door_info",
	"elliot+toy": "elliot_toy_info",
	"elliot+tulip": "elliot_tulip_info",
	"elliot+sofa": "elliot_sofa_info",
	"pc": "pc_info",
	"disc_reader": "disc_reader_info",
	"door": "door_info",
	"memory_storage_drive+storage_box": "memory_storage_drive_storage_box_info",
	"dsk+pc": "dsk_pc_info",
	"hal+memory_storage_drive": "hal_memory_storage_drive_info",
	# 关卡2
	"bedroom": "bedroom_info",
	"sensor":"sensor_info",
	"bed": "bed_info",
	"bed+sensor": "bed_sensor_info",
	"cleaner": "cleaner_info",
	"coffee": "coffee_info"
	
}
