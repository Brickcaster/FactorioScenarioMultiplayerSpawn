-- frontier_silo.lua
-- Nov 2016

require("config")
--require("oarc_utils")

frontier_silo = {}

function frontier_silo.init()
    if ENABLE_RANDOM_SILO_POSITION then
        SetRandomSiloPosition()
    else
        global.siloPosition = SILO_POSITION
    end
    if FRONTIER_ROCKET_SILO_MODE then
        ChartRocketSiloArea(game.forces[MAIN_FORCE])
    end
end

-- This creates a random silo position, stored to global.siloPosition
-- It uses the config setting SILO_CHUNK_DISTANCE and spawns the silo somewhere
-- on a circle edge with radius using that distance.
function SetRandomSiloPosition()
    if (global.siloPosition == nil) then
        -- Get an X,Y on a circle far away.
        distX = math.random(0,SILO_CHUNK_DISTANCE_X)
        distY = RandomNegPos() * math.floor(math.sqrt(SILO_CHUNK_DISTANCE_X^2 - distX^2))
        distX = RandomNegPos() * distX

        -- Set those values.
        local siloX = distX*CHUNK_SIZE + CHUNK_SIZE/2
        local siloY = distY*CHUNK_SIZE + CHUNK_SIZE/2
        global.siloPosition = {x = siloX, y = siloY}
    end
end


-- Sets the global.siloPosition var to the set in the config file
-- function SetFixedSiloPosition()
--     if (global.siloPosition == nil) then
--         global.siloPosition = SILO_POSITION
--     end
-- end

function frontier_silo.CreateCropCircle(surface, centerPos, chunkArea, tileRadius)
    
        local tileRadSqr = tileRadius^2
    
        local dirtTiles = {}
        for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
            for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do
    
                -- This ( X^2 + Y^2 ) is used to calculate if something
                -- is inside a circle area.
                local distVar = math.floor((centerPos.x - i)^2 + (centerPos.y - j)^2)
    
                -- Fill in all unexpected water in a circle
                if (distVar < tileRadSqr) then
                    if (surface.get_tile(i,j).collides_with("water-tile") or ENABLE_SPAWN_FORCE_GRASS) then
                        table.insert(dirtTiles, {name = "grass", position ={i,j}})
                    end
                end
    
                -- Create a circle of trees around the spawn point.
                if ((distVar < tileRadSqr-200) and 
                    (distVar > tileRadSqr-260)) then
                    surface.create_entity({name="tree-01", amount=1, position={i, j}})
                end
            end
        end
    
    
        surface.set_tiles(dirtTiles)
    end

-- Create a rocket silo
local function CreateRocketSilo(surface, chunkArea)
    if CheckIfInArea(global.siloPosition, chunkArea) then

        -- Delete any entities beneat the silo?
        for _, entity in pairs(surface.find_entities_filtered{area = {{global.siloPosition.x-50, global.siloPosition.y-50},{global.siloPosition.x+50, global.siloPosition.y+50}}}) do
            entity.destroy()
        end

        -- Set tiles below the silo
        local tiles = {}
        local i = 1
        for dx = -6,6 do
            for dy = -7,6 do
                tiles[i] = {name = "grass", position = {global.siloPosition.x+dx, global.siloPosition.y+dy}}
                i=i+1
            end
        end
        surface.set_tiles(tiles, false)
        tiles = {}
        i = 1
        for dx = -5,5 do
            for dy = -6,5 do
                tiles[i] = {name = "concrete", position = {global.siloPosition.x+dx, global.siloPosition.y+dy}}
                i=i+1
            end
        end
        surface.set_tiles(tiles, true)

        -- Create silo and assign to main force
        local silo = surface.create_entity{name = "rocket-silo", position = {global.siloPosition.x+0.5, global.siloPosition.y}, force = MAIN_FORCE}
        silo.destructible = false
        silo.minable = false

		if scenario.config.silo.addBeacons then
            -- Add Beacons
            -- x = right, left; y = up, down
            -- top 1 left 1
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-8, global.siloPosition.y-9}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- top 2
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-5, global.siloPosition.y-9}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- top 3
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-2, global.siloPosition.y-9}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- top 4
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+2, global.siloPosition.y-9}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- top 5
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+5, global.siloPosition.y-9}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- top 6 right 1
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+8, global.siloPosition.y-9}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- left 2
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-6, global.siloPosition.y-6}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- left 3
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-6, global.siloPosition.y-3}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- left 4
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-6, global.siloPosition.y}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- left 5
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-6, global.siloPosition.y+3}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- left 6 bottom 1
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-8, global.siloPosition.y+6}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- left 7 bottom 2
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x-5, global.siloPosition.y+6}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- right 2
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+6, global.siloPosition.y-6}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- right 3
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+6, global.siloPosition.y-3}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- right 4
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+6, global.siloPosition.y}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- right 5
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+6, global.siloPosition.y+3}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- right 6 bottom 3
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+5, global.siloPosition.y+6}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- right 7 bottom 4
            local beacon = surface.create_entity{name = "beacon", position = {global.siloPosition.x+8, global.siloPosition.y+6}, force = MAIN_FORCE}
            beacon.destructible = false
            beacon.minable = false
            -- substations
            -- top left
            local substation = surface.create_entity{name = "substation", position = {global.siloPosition.x-8, global.siloPosition.y-6}, force = MAIN_FORCE}
            substation.destructible = false
            substation.minable = false
            -- top right
            local substation = surface.create_entity{name = "substation", position = {global.siloPosition.x+9, global.siloPosition.y-6}, force = MAIN_FORCE}
            substation.destructible = false
            substation.minable = false
            -- bottom left
            local substation = surface.create_entity{name = "substation", position = {global.siloPosition.x-8, global.siloPosition.y+4}, force = MAIN_FORCE}
            substation.destructible = false
            substation.minable = false
            -- bottom right
            local substation = surface.create_entity{name = "substation", position = {global.siloPosition.x+9, global.siloPosition.y+4}, force = MAIN_FORCE}
            substation.destructible = false
            substation.minable = false

            -- end adding beacons
		end
		if scenario.config.silo.addPower then
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-46, global.siloPosition.y+3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-46, global.siloPosition.y-3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-43, global.siloPosition.y-6}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-40, global.siloPosition.y-6}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-37, global.siloPosition.y-6}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-37, global.siloPosition.y-3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-37, global.siloPosition.y}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-37, global.siloPosition.y+3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-46, global.siloPosition.y-6}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-43, global.siloPosition.y+3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "solar-panel", position = {global.siloPosition.x-40, global.siloPosition.y+3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "radar", position = {global.siloPosition.x-46, global.siloPosition.y}, force = MAIN_FORCE}
            radar.destructible = false
            local substation = surface.create_entity{name = "substation", position = {global.siloPosition.x-41, global.siloPosition.y-1}, force = MAIN_FORCE}
            substation.destructible = false
            local radar = surface.create_entity{name = "accumulator", position = {global.siloPosition.x-43, global.siloPosition.y-1}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "accumulator", position = {global.siloPosition.x-43, global.siloPosition.y-3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "accumulator", position = {global.siloPosition.x-43, global.siloPosition.y+1}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "accumulator", position = {global.siloPosition.x-41, global.siloPosition.y-3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "accumulator", position = {global.siloPosition.x-41, global.siloPosition.y+1}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "accumulator", position = {global.siloPosition.x-39, global.siloPosition.y-1}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "accumulator", position = {global.siloPosition.x-39, global.siloPosition.y-3}, force = MAIN_FORCE}
            radar.destructible = false
            local radar = surface.create_entity{name = "accumulator", position = {global.siloPosition.x-39, global.siloPosition.y+1}, force = MAIN_FORCE}
            radar.destructible = false
		end
        
        if scenario.config.teleporter.enabled then
            CreateTeleporter(surface, scenario.config.teleporter.siloPosition, nil)
        end 
        
    end
end

-- Remove rocket silo from recipes
function RemoveRocketSiloRecipe(event)
    local recipes = event.research.force.recipes
    recipes["rocket-silo"].enabled = false
end

-- Generates the rocket silo during chunk generation event
-- Includes a crop circle
function GenerateRocketSiloChunk(event)
    local surface = event.surface
    if surface.name ~= GAME_SURFACE_NAME then return end
    local chunkArea = event.area

    local safeArea = {left_top=
                        {x=global.siloPosition.x-150,
                         y=global.siloPosition.y-150},
                      right_bottom=
                        {x=global.siloPosition.x+150,
                         y=global.siloPosition.y+150}}
                             

    -- Clear enemies directly next to the rocket
    if CheckIfChunkIntersects(chunkArea,safeArea) then
        for _, entity in pairs(surface.find_entities_filtered{area = chunkArea, force = "enemy"}) do
            entity.destroy()
        end
    end

    -- Create rocket silo
    CreateRocketSilo(surface, chunkArea)
    frontier_silo.CreateCropCircle(surface, global.siloPosition, chunkArea, 70)
end

function ChartRocketSiloArea(force)
    force.chart(game.surfaces[GAME_SURFACE_NAME], {{global.siloPosition.x-(CHUNK_SIZE*2), global.siloPosition.y-(CHUNK_SIZE*2)}, {global.siloPosition.x+(CHUNK_SIZE*2), global.siloPosition.y+(CHUNK_SIZE*2)}})
end

Event.register(-1, frontier_silo.init)
Event.register(defines.events.on_research_finished, frontier_silo.RemoveRocketSiloRecipe)
Event.register(defines.events.on_chunk_generated, frontier_silo.GenerateRocketSiloChunk)