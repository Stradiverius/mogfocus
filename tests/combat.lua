-- Run in a fresh Lua VM so no integration has been installed before combat.
mockCombat = true
M:Initialize()
assert(M.ready and not M.Integration.tab and not M.UI.frame)
CreateMockCollections(1)
M.Integration:Collections()
assert(not M.Integration.tab and M.Integration.pendingCollections)
mockCombat = false
local eventFrame
for _, frame in ipairs(mockFrames) do
    if frame.events.PLAYER_REGEN_ENABLED then eventFrame = frame end
end
assert(eventFrame)
eventFrame.scripts.OnEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert(M.Integration.tab and M.UI.frame)
local tab = M.Integration.tab
eventFrame.scripts.OnEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert(M.Integration.tab == tab)
print("PASS isolated combat-first initialization, deferred Collections and repeated regeneration")
