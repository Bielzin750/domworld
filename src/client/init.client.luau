-- Airfront client entry. Owned by the Session/Main agent (see PORT.md §Ownership).
-- Dev harness hook: if workspace attribute AF_DEV is set (in a developer's own Studio place),
-- run src/client/Dev/<AF_DEV>.luau instead of the game. Never set AF_DEV in the shipped place.
-- Modified for DomWorld, 2026 — see git history for details.
local dev = workspace:GetAttribute("AF_DEV")
if type(dev) == "string" and dev ~= "" then
	local mod = script:FindFirstChild("Dev") and script.Dev:FindFirstChild(dev)
	if mod then
		print("[DomWorld] client dev harness:", dev)
		require(mod)
		return
	end
	warn("[DomWorld] AF_DEV harness not found on client:", dev)
end
local Main = script:FindFirstChild("Main")
if Main then
	require(Main).start()
else
	print("[DomWorld] client boot (Main not yet written)")
end
