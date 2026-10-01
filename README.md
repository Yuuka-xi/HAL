# Bones

- `core/autoload/`：游戏状态、存档与音频管理。
- `core/scene_transition/`：场景淡入淡出。
- `ui/screens/`：启动页面和设置面板。
- `addons/dialogue_manager/`：对话插件。
- `Asset/Fonts/`：已有字体资源。

存档接口为 `SaveManager.save_game(slot)` 和 `SaveManager.load_game(slot)`。
音频接口为 `AudioManager.play_music(stream)` 和 `AudioManager.play_sfx(stream)`。
正式玩法确定后再添加游戏内容。
