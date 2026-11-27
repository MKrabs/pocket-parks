extends SceneTree
# Showcase: the toast stack: a lost connection (unplugged cable) above a wrecked building (hammer).
# ./gd shot shots/toasts.png 1 res://tests/show_toasts.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var t := CrimeToasts.new()
	root.add_child.call_deferred(t)
	t.ready.connect(func() -> void:
		t.add("wrecked", "Theo wrecked your Snack Stand")
		t.add("offline", "Couldn't reach 192.168.1.20")
		t.add("offline", "Lost the connection: back home"))
