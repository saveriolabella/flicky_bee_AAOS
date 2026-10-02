@tool
extends EditorPlugin

const MANUAL_AAR := "res://android/plugins/ReadyLinkAudioFocusPlugin.release.aar"
const BUILD_AAR := "res://android-audio-focus-plugin/plugin/build/outputs/aar/ReadyLinkAudioFocusPlugin.release.aar"

class AndroidAudioFocusExportPlugin extends EditorExportPlugin:
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if FileAccess.file_exists(MANUAL_AAR):
			return PackedStringArray([MANUAL_AAR])
		if FileAccess.file_exists(BUILD_AAR):
			return PackedStringArray([BUILD_AAR])
		push_warning("ReadyLinkAudioFocusPlugin AAR not found. Expected one of: %s or %s" % [MANUAL_AAR, BUILD_AAR])
		return PackedStringArray()

	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray()

	func _get_android_dependencies_maven_repos(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray()


var export_plugin: AndroidAudioFocusExportPlugin


func _enter_tree() -> void:
	export_plugin = AndroidAudioFocusExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	if export_plugin:
		remove_export_plugin(export_plugin)
		export_plugin = null
