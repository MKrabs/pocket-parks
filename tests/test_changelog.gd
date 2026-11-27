extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

const MD := """# Changelog

## [Unreleased]

### Added
- Not out yet.

## [0.3.0] - 2026-12-01: A nicer park

### Added
- **Park charm:** guests rate
  the walk [between] stops.

## [0.2.0] - 2026-11-27: Visit in person
- Old.
"""

func _init() -> void:
	var s := Changelog.latest(MD)
	ok(s.get("version") == "0.3.0", "newest released section, not Unreleased: %s" % s)
	ok(s.get("title") == "A nicer park", "title after the colon")
	ok(not s.get("body", "").contains("Not out yet") and not s.get("body", "").contains("Old."), "only that section")
	var bb := Changelog.to_bbcode(s["body"])
	ok(bb.contains("[b]Added[/b]"), "heading bold")
	ok(bb.contains("•  [b]Park charm:[/b] guests rate the walk [lb]between] stops."), "bullet joined, bold kept, [ escaped: %s" % bb)
	ok(Changelog.latest("## [Unreleased]\n- x").is_empty(), "no release yet")
	var real := Changelog.latest(FileAccess.get_file_as_string(Changelog.PATH))
	ok(not real.is_empty(), "res://CHANGELOG.md has a released section")

	ok(Changelog.should_show("0.2.0", "0.3.0", false), "shows after an update")
	ok(Changelog.should_show("", "0.3.0", false), "shows for a save from before the card")
	ok(not Changelog.should_show("0.3.0", "0.3.0", false), "only once per version")
	ok(not Changelog.should_show("", "0.3.0", true), "not on a fresh start")
	done()
