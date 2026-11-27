---
id: IP
title: Join by IP + show your own address
status: done
deps: NET1
area: net
parent: M4
human: false
owner: worker-IP
since: 2026-11-27T00:09:06
---
## Goal
Owner will test with a friend's MacBook. Some Wi-Fi networks block broadcast discovery, so "Nearby" may stay empty.
- The Visit picker gets a small **"Join by address"** field (rounded LineEdit plus a Join button) under Nearby: accepts
  `192.168.1.23` or `192.168.1.23:24611` (default port 24610). Same flow as clicking a nearby park (clouds, live view).
  A failure shows a toast ("Couldn't reach 192.168.1.23") and stays home.
- Show **your own address** so a friend can type it: in the Visit picker, a line "Your park: 192.168.1.40:24610" using
  the first private IPv4 from `IP.get_local_addresses()` (prefer 192.168.*, then 10.*, then 172.16–31.*) and `net.port`.
- Remember the last joined address for the session.
## Acceptance
`tests/test_net.gd` gets a join-by-address case on 127.0.0.1 (no discovery involved) and an address-parsing check.
`./gd check` ok. Shot of the picker with the field and your address.

> **review 2026-11-26T23:59:54:** Built: Visit picker gets a rounded 'Join by address' LineEdit + Join button under Nearby (Enter also joins), and a line 'Your park: <ip>:<port>' (or 'not on a network'). Files: scripts/net.gd (static parse_address: 'a.b.c.d' or 'a.b.c.d:port', default 24610; static local_address: 192.168 > 10 > 172.16-31; new joined signal; join() uses a 4 s ENet connect timeout, then restores ENet defaults once connected, so a dead address fails in ~7.5 s instead of ~31 s), scripts/visit_panel.gd (field, own-address line, last_address kept for the session, join_address signal), main.gd (open_picker(), join_address(): connects while staying home, plays clouds + live view on net.joined; on net.lost before that it toasts 'Couldn't reach 192.168.1.23' and stays home; bad text toasts 'Not an address: ...'), tests/test_net.gd (parse + local_address checks, join by 127.0.0.1:port with no discovery gets joined + the map, an unanswered port is lost within 10 s), tests/show_net.gd (NET_JOIN=1 / NET_JOIN=bad). ./gd check: all ok. Shots: picker with field (prefilled with remembered 192.168.1.23) and 'Your park: 192.168.0.177:24611'; NET_JOIN=1 shows the live visit of the friend park titled '127.0.0.1'; NET_JOIN=bad shows home with the 'Couldn't reach 127.0.0.1:24629' toast. Guesses: typed-address joins connect first and only then travel (so a failure really stays home, unlike Nearby clicks which travel first); the visit title is the address since the map message carries no park name; port shown in the toast only when non-default. Not verified: real two-machine Wi-Fi, typing/focus feel in the LineEdit (the Visit hotkeys may fire while typing, if any exist).
