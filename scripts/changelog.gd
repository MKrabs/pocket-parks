class_name Changelog
# CHANGELOG.md → the "What's new" card (docs/design/game.md → Versions and changelog). Pure text, no nodes.

const PATH := "res://CHANGELOG.md"  # packed raw into exports via export_presets.cfg include_filter

## The newest released section: {version, title, body} of the first `## [x.y.z]` (Unreleased skipped), or {}.
static func latest(text: String) -> Dictionary:
	var re := RegEx.create_from_string("^## \\[(\\d+\\.\\d+\\.\\d+)\\][^:\\n]*:?\\s*(.*)$")
	var out := {}
	var body: PackedStringArray = []
	for line in text.split("\n"):
		if line.begins_with("## "):
			if not out.is_empty():
				break
			var m := re.search(line)
			if m:
				out = {"version": m.get_string(1), "title": m.get_string(2).strip_edges()}
		elif not out.is_empty():
			body.append(line)
	if not out.is_empty():
		out["body"] = "\n".join(body).strip_edges()
	return out

## Markdown subset → BBCode: `###` headings, `- ` bullets (wrapped lines joined), **bold**. Other brackets are escaped.
static func to_bbcode(md: String) -> String:
	var items: Array[String] = []
	for line in md.split("\n"):
		var s := line.strip_edges().replace("[", "[lb]")
		if s == "":
			continue
		if s.begins_with("#"):
			items.append("[font_size=18][b]%s[/b][/font_size]" % s.lstrip("# "))
		elif s.begins_with("- "):
			items.append("•  " + s.substr(2))
		elif not items.is_empty():
			items[-1] += " " + s  # continuation of a wrapped bullet
	return RegEx.create_from_string("\\*\\*(.+?)\\*\\*").sub("\n".join(items), "[b]$1[/b]", true)

## Open the card on its own only once per new version, and not on a fresh start (nothing "new" yet).
static func should_show(seen: String, current: String, fresh: bool) -> bool:
	return not fresh and seen != current

static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))
