---
id: IP
title: Join by IP + show your own address
status: todo
deps: NET1
area: net
parent: M4
human: false
owner: 
since: 
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
