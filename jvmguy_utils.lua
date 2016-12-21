
-- Enforce a square of land, with a tree border
-- this is equivalent to the CreateCropCircle code
function CreateCropHexagon(surface, centerPos, chunkArea, tileRadius)

    local dirtTiles = {}
    for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
        for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do

            local distVar1 = math.floor(math.max(math.abs(centerPos.x - i), math.abs(centerPos.y - j)))
            local distVar2 = math.floor(math.abs(centerPos.x - i) + math.abs(centerPos.y - j))
            local distVar = math.max(distVar1, distVar2 * 0.707);

            -- Fill in all unexpected water in a circle
            if (distVar < tileRadius) then
                if (surface.get_tile(i,j).collides_with("water-tile") or ENABLE_SPAWN_FORCE_GRASS) then
                    table.insert(dirtTiles, {name = "grass", position ={i,j}})
                end
            end

            -- Create a ring
            if ((distVar < tileRadius) and 
                (distVar > tileRadius-1.9)) then
                surface.create_entity({name="tree-01", amount=1, position={i, j}})
            end
        end
    end


    surface.set_tiles(dirtTiles)
end

function CreateWaterStrip(surface, spawnPos, tileRadius)
    local waterTiles = {{name = "water", position ={spawnPos.x+0,spawnPos.y-tileRadius}},
                        {name = "water", position ={spawnPos.x+1,spawnPos.y-tileRadius}},
                        {name = "water", position ={spawnPos.x+2,spawnPos.y-tileRadius}},
                        {name = "water", position ={spawnPos.x+3,spawnPos.y-tileRadius}},
                        {name = "water", position ={spawnPos.x+4,spawnPos.y-tileRadius}},
                        {name = "water", position ={spawnPos.x+5,spawnPos.y-tileRadius}},
                        {name = "water", position ={spawnPos.x+6,spawnPos.y-tileRadius}},
                        {name = "water", position ={spawnPos.x+7,spawnPos.y-tileRadius}},
                        {name = "water", position ={spawnPos.x+8,spawnPos.y-tileRadius}}}
    -- DebugPrint("Setting water tiles in this chunk! " .. chunkArea.left_top.x .. "," .. chunkArea.left_top.y)
    surface.set_tiles(waterTiles)
end

function GiveSpecialItems(player)
    player.insert{name = "power-armor-mk2", count = 1}
    player.insert{name = "fusion-reactor-equipment", count=1}
    player.insert({name = "exoskeleton-equipment", count=3})
    player.insert({name = "personal-roboport-equipment", count=4})
    player.insert{name="construction-robot", count = 40}
    player.insert{name="blueprint", count = 3}
    player.insert{name="deconstruction-planner", count = 1}
    player.insert{name="night-vision-equipment", count = 1}
    player.insert{name="steel-axe", count = 5}
end
function GiveFastStartItems(player)
  -- raw materials
    player.insert{name = "coal", count = 100}
    player.insert{name = "iron-plate", count = 100}
    player.insert{name = "copper-plate", count = 100}
    player.insert{name = "steel-plate", count = 100}
    player.insert{name = "electronic-circuit", count = 200}
    player.insert{name = "iron-gear-wheel", count = 200}
    -- fast power setup
    player.insert{name = "offshore-pump", count = 1}
    player.insert{name = "boiler", count = 14}
    player.insert{name = "steam-engine", count = 10}
    player.insert({name = "pipe", count=50})
    player.insert({name = "pipe-to-ground", count=10})
    -- resource extraction    
    player.insert{name = "stone-furnace", count = 49} -- there's one already there
    player.insert{name = "electric-mining-drill", count = 50}
    -- production
    player.insert({name = "assembling-machine-2", count=20})
    -- connectivity
    player.insert{name = "medium-electric-pole", count = 50}
    player.insert{name = "transport-belt", count=200}
    player.insert({name = "underground-belt", count=50})
    player.insert({name = "splitter", count=50})
    player.insert({name = "inserter", count=100})
    player.insert({name = "fast-inserter", count=50})
end