-- Nov 2016
--
-- Code that handles everything regarding giving each player a separate spawn
-- Includes the GUI stuff

--------------------------------------------------------------------------------
-- EVENT RELATED FUNCTIONS
--------------------------------------------------------------------------------

-- When a new player is created, present the spawn options
-- Assign them to the main force so they can communicate with the team
-- without shouting.
function SeparateSpawnsPlayerCreated(event)
    local player = game.players[event.player_index]
    player.force = MAIN_FORCE
    global.playerCooldowns[player.name] = {setRespawn=event.tick}
    DisplayWelcomeTextGui(player)
end


-- Check if the player has a different spawn point than the default one
-- Make sure to give the default starting items
function SeparateSpawnsPlayerRespawned(event)
    local player = game.players[event.player_index]
    SendPlayerToSpawn(player)
end


function GenerateSpawnChunk( event, spawnPos)
    local surface = event.surface
    local chunkArea = event.area

    local chunkAreaCenter = {x=chunkArea.left_top.x+(CHUNK_SIZE/2),
                             y=chunkArea.left_top.y+(CHUNK_SIZE/2)}
    local warningArea = {left_top=
                            {x=spawnPos.x-WARNING_AREA_TILE_DIST,
                             y=spawnPos.y-WARNING_AREA_TILE_DIST},
                        right_bottom=
                            {x=spawnPos.x+WARNING_AREA_TILE_DIST,
                             y=spawnPos.y+WARNING_AREA_TILE_DIST}}
    if CheckIfChunkIntersects(chunkArea,warningArea) then

		
        local landArea = {left_top=
                            {x=spawnPos.x-ENFORCE_LAND_AREA_TILE_DIST,
                             y=spawnPos.y-ENFORCE_LAND_AREA_TILE_DIST},
                          right_bottom=
                            {x=spawnPos.x+ENFORCE_LAND_AREA_TILE_DIST,
                             y=spawnPos.y+ENFORCE_LAND_AREA_TILE_DIST}}

        local safeArea = {left_top=
                            {x=spawnPos.x-SAFE_AREA_TILE_DIST,
                             y=spawnPos.y-SAFE_AREA_TILE_DIST},
                          right_bottom=
                            {x=spawnPos.x+SAFE_AREA_TILE_DIST,
                             y=spawnPos.y+SAFE_AREA_TILE_DIST}}


                                 

        -- Make chunks near a spawn safe by removing enemies
        if CheckIfChunkIntersects(chunkArea,safeArea) then
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
                entity.destroy()
            end
        
        -- Create a warning area with reduced enemies
        elseif CheckIfChunkIntersects(chunkArea,warningArea) then
            local counter = 0
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
                if ((counter % WARN_AREA_REDUCTION_RATIO) ~= 0) then
                    entity.destroy()
                end
                counter = counter + 1
            end

            -- Remove all big and huge worms
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, name = "medium-worm-turret"}) do
                    entity.destroy()
            end
            for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, name = "big-worm-turret"}) do
                    entity.destroy()
            end

        end

        -- Fill in any water to make sure we have guaranteed land mass at the spawn point.
        if CheckIfChunkIntersects(chunkArea,landArea) then

            -- remove trees in the immediate areas?
            for key, entity in pairs(surface.find_entities_filtered({area=chunkArea, type= "tree"})) do
                if ((spawnPos.x - entity.position.x)^2 + (spawnPos.y - entity.position.y)^2 < ENFORCE_LAND_AREA_TILE_DIST^2) then
                    entity.destroy()
                end
            end
			if (ENABLE_CROP_OCTAGON) then
	            CreateCropOctagon(surface, spawnPos, chunkArea, scenario.config.separateSpawns.land, scenario.config.separateSpawns.trees, scenario.config.separateSpawns.moat)
			else
	            CreateCropCircle(surface, spawnPos, chunkArea, scenario.config.separateSpawns.land)
			end

            GenerateStartingResources( surface, chunkArea, spawnPos);
            if scenario.config.teleporter.enabled then
                local pos = { x=spawnPos.x+scenario.config.teleporter.spawnPosition.x, y=spawnPos.y+scenario.config.teleporter.spawnPosition.y }
                if CheckIfInChunk(pos.x, pos.y, chunkArea) then
                    local dest = scenario.config.teleporter.siloTeleportPosition
                    CreateTeleporter(surface, pos, { x=dest.x, y=dest.y })
                end
            end 
        end
    end
end

function DistanceFromPoint( spawnPos, p)
    local dx = spawnPos.x - p.x
    local dy = spawnPos.y - p.y
    local dist = math.sqrt( dx*dx + dy*dy)
    return dist
end

-- return the spawn from table t,  nearest position p
function NearestSpawns( t, p )
  local candidates = {}
  for key, spawnPos in pairs(t) do
    if spawnPos ~= nil then
        spawnPos.key = key;
        spawnPos.dist = DistanceFromPoint(spawnPos, p)
        table.insert( candidates, spawnPos );
    end
  end
  table.sort (candidates, function (k1, k2) return k1.dist < k2.dist end )
  return candidates
end
  
function NearestSpawn( t, p )
    local candidates = NearestSpawns(t,p);
    return candidates[1]
end


-- This is the main function that creates the spawn area
-- Provides resources, land and a safe zone
function SeparateSpawnsGenerateChunk(event)
    local surface = event.surface
    
    if surface.name == GAME_SURFACE_NAME then
        -- Only take into account the nearest spawn when generating resources
        local chunkArea = event.area
        local midPoint = {x = (chunkArea.left_top.x + chunkArea.right_bottom.x)/2,
                            y = (chunkArea.left_top.y + chunkArea.right_bottom.y)/2 } 
        local spawnPos = NearestSpawn( global.allSpawns, midPoint)
        GenerateSpawnChunk(event, spawnPos)
    end
end

function GetUniqueSpawn(name)
    for _,spawn in pairs(global.allSpawns) do
        if spawn ~= nil and spawn.createdFor == name then
            return spawn
        end
    end
    return nil;
end 


function RemovePlayer(player)

    -- TODO dump items into a chest.

    -- Clear out global variables for that player???
    if (global.playerSpawns[player.name] ~= nil) then
        global.playerSpawns[player.name] = nil;
    end

    local uniqueSpawn = GetUniqueSpawn(player.name);
    
    -- If a uniqueSpawn was created for the player, mark it as unused.
    if (uniqueSpawn ~= nil) then
        if scenario.config.wipespawn.enabled then
            SendBroadcastMsg(player.name .. " base was reclaimed.");
            wipespawn.markForRemoval(uniqueSpawn)
            uniqueSpawn.used = false;
            uniqueSpawn.createdFor = nil;
        elseif scenario.config.regrow.enabled then
            SendBroadcastMsg(player.name .. " base was abandoned.");
            uniqueSpawn.used = false;
            uniqueSpawn.createdFor = nil;
        else
            uniqueSpawn.used = false;
            uniqueSpawn.createdFor = nil;
            SendBroadcastMsg(player.name .. " base was freed up.");
        end
    end
    
    -- Remove from shared spawns
    if (global.sharedSpawns[player.name] ~= nil) then
        global.sharedSpawns[player.name] = nil;
    end

    -- remove that player's cooldown setting
    if (global.playerCooldowns[player.name] ~= nil) then
        global.playerCooldowns[player.name] = nil;
    end

    -- Remove from shared spawn player slots (need to search all)
    for _,sharedSpawn in pairs(global.sharedSpawns) do
        for key,playerName in pairs(sharedSpawn.players) do
            if (player.name == playerName) then
                sharedSpawn.players[key] = nil;
            end
        end
    end

    -- Remove the character completely
    game.remove_offline_players({player});
end

-- Call this if a player leaves the game
-- Seems to be susceptiable to causing desyncs...
function FindUnusedSpawns(event)
    local player = game.players[event.player_index]
    if (event.player_index>1 and player.online_time < MIN_ONLINE_TIME) then
        RemovePlayer(player);
    end
end


function CreateNewSharedSpawn(player)
    local playerSpawn = global.playerSpawns[player.name];
    global.sharedSpawns[player.name] = {openAccess=true,
                                    position={x=playerSpawn.x,y=playerSpawn.y},
                                    surface=playerSpawn.surface,
                                    seq=playerSpawn.seq,
                                    players={}}
end

function GetOnlinePlayersAtSharedSpawn(ownerName)
    if (global.sharedSpawns[ownerName] ~= nil) then

        -- Does not count base owner
        local count = 0

        -- For each player in the shared spawn, check if online and add to count.
        for _,player in pairs(game.connected_players) do
            if (ownerName == player.name) then
                count = count + 1
            end

            for _,playerName in pairs(global.sharedSpawns[ownerName].players) do
            
                if (playerName == player.name) then
                    count = count + 1
                end
            end
        end

        return count
    else
        return 0
    end
end


-- Get the number of currently available shared spawns
-- This means the base owner has enabled access AND the number of online players
-- is below the threshold.
function GetNumberOfAvailableSharedSpawns()
    local count = 0

    for ownerName,sharedSpawn in pairs(global.sharedSpawns) do
        if (sharedSpawn.openAccess) then
            if (GetOnlinePlayersAtSharedSpawn(ownerName) < MAX_ONLINE_PLAYERS_AT_SHARED_SPAWN) then
                count = count+1
            end
        end
    end

    return count
end

function GetNumberOfAvailableSoloSpawns()
    local count = 0

    for _,spawn in pairs(global.allSpawns) do
        if spawn ~= nil and not spawn.used then
            count = count+1
        end
    end

    return count
end

--------------------------------------------------------------------------------
-- NON-EVENT RELATED FUNCTIONS
-- These should be local functions where possible!
--------------------------------------------------------------------------------
function InitSpawnGlobalsAndForces()
    -- Contains an array of all player spawns
    -- A secondary array tracks whether the character will respawn there.
    
    
    if (global.allSpawns == nil) then
        global.allSpawns = {}
    end
    if (global.playerSpawns == nil) then
        global.playerSpawns = {}
    end
    if (global.sharedSpawns == nil) then
        global.sharedSpawns = {}
    end

    -- InitSpawnPoint( 0, 0, 0);
    for n = 1,scenario.config.separateSpawns.numSpawnPoints do
          spawnGenerator.InitSpawnPoint( n )
          global.lastSpawn = n
    end
    -- another spawn for admin. admin gets the last spawn
	if scenario.config.separateSpawns.extraSpawn ~= nil then
        spawnGenerator.InitSpawnPoint( scenario.config.separateSpawns.extraSpawn);
	end
	
    if (global.playerCooldowns == nil) then
        global.playerCooldowns = {}
    end

    local gameForce = game.create_force(MAIN_FORCE)

    gameForce.set_spawn_position(game.forces["player"].get_spawn_position(GAME_SURFACE_NAME), GAME_SURFACE_NAME)
    gameForce.worker_robots_storage_bonus=scenario.config.bots.worker_robots_storage_bonus;
    gameForce.worker_robots_speed_modifier=scenario.config.bots.worker_robots_speed_modifier;
    
    SetCeaseFireBetweenAllForces()
    AntiGriefing(gameForce)
    SetForceGhostTimeToLive(gameForce)
end

function AddSpawn()
    -- used as a command to expand in-game number of spawns
    -- if extraSpawn is configured, this does not work correctly
    local n = global.lastSpawn + 1;
    if scenario.config.separateSpawns.extraSpawn ~= nil and n == scenario.config.separateSpawns.extraSpawn then
        n = n + 1
    end
    spawnGenerator.InitSpawnPoint( n )
    global.lastSpawn = n;
end

function CheckIfInChunk(x, y, chunkArea)
    if x>=chunkArea.left_top.x and x<chunkArea.right_bottom.x
    and y>=chunkArea.left_top.y and y<chunkArea.right_bottom.y then
        return true;
    end
    return false;
end

local function CreateItems( surface, tiles, itemName, contents )
    for _, tile in pairs(tiles) do
        local chest = surface.create_entity({name=itemName, position=tile, force=MAIN_FORCE})
        if contents~=nil then
            for _,item in pairs(contents) do
                chest.insert(item)
            end
        end
    end
end

local mixedResources = { "iron-ore", "copper-ore", "coal", "iron-ore", "copper-ore", "coal", "stone" }

local function CreateResources( surface, tiles, startAmount, resourceName, mixedOres )
    for _, tile in pairs(tiles) do
        local realResourceName = resourceName
        if mixedOres and math.random() < 0.2 then
            local r = math.random(#mixedResources);
            realResourceName = mixedResources[r]; 
        end
        surface.create_entity({name=realResourceName, amount=startAmount, position=tile})
    end
end

function GenerateStartingResources(surface, chunkArea, spawnPos)
    --local surface = player.surface
    local pos = { x=spawnPos.x, y=spawnPos.y } 
    for _, res in pairs( scenario.config.separateSpawns.resources ) do
        -- resource may specify dx,dy or x,y relative to spawn
        if res.x ~= nil then
            pos.x = spawnPos.x + res.x
        end
        if res.y ~= nil then
            pos.y = spawnPos.y + res.y
        end
        if res.dx ~= nil then
            pos.x = pos.x + res.dx
        end
        if res.dy ~= nil then
            pos.y = pos.y + res.dy
        end
        local tiles = TilesInShape( chunkArea, pos, res.shape, res.height, res.width);
        if (res.type ~= nil) then
            CreateResources( surface, tiles, res.amount, res.type, res.mixedOres );
        elseif (res.name ~= nil) then
            CreateItems( surface, tiles, res.name, res.contents );
        end
    end   
end

function DoesPlayerHaveCustomSpawn(player)
    for name,spawnPos in pairs(global.playerSpawns) do
        if (player.name == name and spawnPos ~= nil) then
            return true
        end
    end
    return false
end

function ChangePlayerSpawn(player, pos, surfaceName, seq)
    global.playerSpawns[player.name] = { x=pos.x, y=pos.y, surface=surfaceName, seq=seq }
end

function SendPlayerToNewSpawnAndCreateIt(player, spawn)
    -- Send the player to that position
    if spawn == nil then
      DebugPrint("SendPlayerToNewSpawnAndCreateIt: error. spawn is nil")
      spawn = { x = 0, y = 0 }
    end
    player.teleport(spawn, game.surfaces[GAME_SURFACE_NAME])
    ChartArea(player.force, player.position, 4)

    -- If we get a valid spawn point, setup the area
    if ((spawn.x ~= 0) and (spawn.y ~= 0)) then
        ClearNearbyEnemies(player, SAFE_AREA_TILE_DIST)
    else      
        DebugPrint("THIS SHOULD NOT EVER HAPPEN! Spawn failed!")
        SendBroadcastMsg("Failed to create spawn point for: " .. player.name)
    end
end

function SendPlayerToSpawn(player)
    if (DoesPlayerHaveCustomSpawn(player)) then
        player.teleport(global.playerSpawns[player.name], game.surfaces[GAME_SURFACE_NAME])
    else
        player.teleport(game.forces[MAIN_FORCE].get_spawn_position(GAME_SURFACE_NAME), game.surfaces[GAME_SURFACE_NAME])
    end
end
