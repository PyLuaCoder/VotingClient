local rs = game.ReplicatedStorage
 
local maps = rs:WaitForChild("Maps")
local res = rs:WaitForChild("RemoteEvents")
 
local numMapsVoting = 3
local intermissionTime = 5
local voteTime = 10
 
local plrVotes = {}
 
 
function addVote(plr:Player, mapName:string)
    
    plrVotes[plr] = mapName
    res:WaitForChild("Voted"):FireAllClients(plrVotes)
end
 
function removePlayerVote(plr:Player)
    
    plrVotes[plr] = nil
    res:WaitForChild("Voted"):FireAllClients(plrVotes)
end
 
function loadMap(mapName:string)
    
    local newMap = maps[mapName]:Clone()
    newMap.Parent = workspace
    
    local spawns = newMap:WaitForChild("Spawns"):GetChildren()
    
    for i, plr in pairs(game.Players:GetPlayers()) do
        if plr.Character then
            plr.Character.HumanoidRootPart.CFrame = (spawns[i] and spawns[i].CFrame or spawns[i-#spawns]) + Vector3.new(0, 10, 0)
        end
    end
    
    return newMap
end
 
function removeMap(map:Instance)
    
    map:Destroy()
    
    for _, plr in pairs(game.Players:GetPlayers()) do
        plr:LoadCharacter()
    end
end
 
function handleRound()
    
    local plrsAlive = {}
    for _, plr in pairs(game.Players:GetPlayers()) do
        
        if plr.Character and plr.Character.Humanoid.Health > 0 then
            table.insert(plrsAlive, plr)
            
            plr.Character.Humanoid.Died:Connect(function()
                table.remove(plrsAlive, table.find(plrsAlive, plr))
            end)
        end
    end
    
    for i = 1, 20 do
        task.wait(1)
        if #plrsAlive == 0 then
            break
        end
    end
    
    task.wait(5)
end
 
 
res:WaitForChild("Voted").OnServerEvent:Connect(addVote)
 
game.Players.PlayerRemoving:Connect(removePlayerVote)
 
 
while true do
    
    task.wait(intermissionTime)
    
    local mapsToVote = maps:GetChildren()
    
    while #mapsToVote > numMapsVoting do
        table.remove(mapsToVote, math.random(1, #mapsToVote))
    end
    
    plrVotes = {}
    
    res:WaitForChild("VotingBegun"):FireAllClients(mapsToVote)
    
    task.wait(voteTime)
    
    local highestVotedFor = nil
    
    local votes = {}
    for i, map in pairs(mapsToVote) do
        votes[map.Name] = 0
        
        if i == 1 then
            highestVotedFor = map.Name
        end
    end
    
    for plr, vote in pairs(plrVotes) do
        
        if votes[vote] then
            votes[vote] += 1
            
            if votes[highestVotedFor] < votes[vote] then
                highestVotedFor = vote
            end
        end
    end
    
    res:WaitForChild("VotingEnded"):FireAllClients()
    
    local newMap = loadMap(highestVotedFor)
    
    handleRound()
    
    removeMap(newMap)
end
