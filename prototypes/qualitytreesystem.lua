require("util")

data:extend({ {
  type = "collision-layer",
  name = "fertile-soil"
} })

local function create_custom_collision_layer_for_plant(plant_prototype)
  local growable_tiles = table.deepcopy(plant_prototype.autoplace.tile_restriction)

  for _, tile_name in ipairs(growable_tiles) do
    local tile = data.raw["tile"][tile_name]
    if tile then
      if not tile.collision_mask then tile.collision_mask = { layers = {} } end
      if not tile.collision_mask.layers then tile.collision_mask.layers = {} end
      tile.collision_mask.layers["fertile-soil"] = true
    end
  end
end

local function create_quality_plant(plant_prototype, seed_prototype)
  --- Useful local references:
  local plant_name = plant_prototype.name
  if not plant_prototype.minable then
    log("" .. plant_name .. " does not have any minable results... skipping.")
    return
  end

  local plant_harvest_results = table.deepcopy(plant_prototype.minable.results)

  -- Its more balanced to have to work for your seeds. And theoretically, you could have a small mini-pentapod factory to upscale all seeds to the max anyway.
  local spore_multiplier = 100
  if settings.startup["balanced-seeds-mode"].value then
    spore_multiplier = 30
    for _, result in pairs(plant_harvest_results) do
      if result.amount then
        -- Scale fixed amount
        result.amount = math.max(math.floor(result.amount * 0.3), 1)
      elseif result.amount_min and result.amount_max then
        -- Scale range amounts
        result.amount_min = math.max(math.floor(result.amount_min * 0.3), 1)
        result.amount_max = math.max(math.floor(result.amount_max * 0.3), 1)
      end
    end
  end

  local plant_icon = plant_prototype.icon
      or (plant_prototype.icons and plant_prototype.icons[1] and plant_prototype.icons[1].icon)

  if not plant_icon then
    log("" .. plant_name .. " does not have an icon ... skipping.")
    return
  end

  local predicted_seed_name = plant_prototype.name .. "-seed"

  -- Look for the seed if it wasn't provided.
  if not seed_prototype then
    seed_prototype = data.raw["item"][predicted_seed_name]
  end

  -- Exhaustively search for the seed if it wasn't found.
  if not seed_prototype then
    for item_name, item in pairs(data.raw.item) do
      if item.plant_result then
        if item.plant_result == plant_name then
          seed_prototype = data.raw["item"][item_name]
          log("Found item " .. item_name .. " for tree " .. plant_name)
          goto found_seed
        end
      end
    end
    for item_name, capsule in pairs(data.raw.capsule) do
      if capsule.plant_result then
        if capsule.plant_result == plant_name then
          seed_prototype = data.raw["capsule"][item_name]
          log("Found capsule " .. item_name .. " for tree " .. plant_name)
          goto found_seed
        end
      end
    end
  end

  ::found_seed::

  -- Still no prototype, this tree will not be qualitied.
  if not seed_prototype then
    log("Expected Seed prototype (" .. predicted_seed_name .. ") not found for tree " .. plant_name)
    return
  end

  local tile_buildability_rules = {
    {
      area = { { -1.0, -1.0 }, { 1.0, 1.0 } },
      remove_on_collision = false
    },
  }

  if plant_prototype.autoplace and plant_prototype.autoplace.tile_restriction then
    log("Grabbing autoplace collision from " .. plant_name .. ".")
    create_custom_collision_layer_for_plant(plant_prototype)
    growable_tiles = { layers = { ["fertile-soil"] = true } }
    tile_buildability_rules[1].required_tiles = growable_tiles
    log(serpent.block(tile_buildability_rules))
  else
    if plant_prototype.tile_buildability_rules then
      if plant_prototype.tile_buildability_rules[1].required_tiles then
        tile_buildability_rules[1].required_tiles = plant_prototype.tile_buildability_rules[1].required_tiles
      end
      if plant_prototype.tile_buildability_rules[1].colliding_tiles then
        tile_buildability_rules[1].colliding_tiles = plant_prototype.tile_buildability_rules[1].colliding_tiles
      end
    end
  end

  local variations = plant_prototype.variations
  if not variations then
    log("No variations graphic found for trunk of " .. plant_name .. ", Will skip.")
    return
  end

  local variation_trunk = plant_prototype.variations[1].trunk
  if not variation_trunk then
    log("No graphic found for trunk of " .. plant_name .. ", Will skip.")
    return
  end

  local variation_leaves = plant_prototype.variations[1].leaves
  if not variation_leaves then
    log("No graphic found for leaves of " .. plant_name .. ", Will skip.")
    return
  end

  local seed_name = seed_prototype.name
  local plant_label = plant_prototype.localised_name or { "entity-name." .. plant_name }
  if type(plant_label) == "string" then
    plant_label = { "", plant_label }
  end
  local seed_label = seed_prototype.localised_name or { "item-name." .. seed_name }
  if type(seed_label) == "string" then
    seed_label = { "", seed_label }
  end

  -- Create a new Collision Layer, for the Greenhouse to use.
  local recipe_category = {
    type = "recipe-category",
    name = "cultivation-" .. plant_name
  }

  -- Create the Cultivator used for this tree:
  local cultivator = table.deepcopy(data.raw["assembling-machine"]["biochamber"])
  local agricultural_graphics = table.deepcopy(data.raw["agricultural-tower"]["agricultural-tower"]["graphics_set"])

  agricultural_graphics.animation.layers = {}

  table.insert(agricultural_graphics.animation.layers,
    util.sprite_load("__quality-seeds-fork__/graphics/entity/green-house-back",
      {
        priority = "high",
        animation_speed = 0.25,
        frame_count = 1,
        repeat_count = 64,
        scale = 0.5
      }))

  local shift = nil
  if variation_trunk.shift then
    shift = { variation_trunk.shift[1] + 0.1, variation_trunk.shift[2] + 0.0 }
  end

  table.insert(agricultural_graphics.animation.layers, {
    filename = variation_trunk.filename,
    width = variation_trunk.width,
    height = variation_trunk.height,
    x = 0,
    y = 0,
    frame_count = 1,
    repeat_count = 64,
    shift = shift,
    scale = variation_trunk.scale
  })

  if variation_leaves.layers then
    for _, layer in ipairs(variation_leaves.layers) do
      local new_layer = table.deepcopy(layer)
      new_layer.x = 0
      new_layer.y = 0
      new_layer.repeat_count = 64
      new_layer.frame_count = 1
      new_layer.shift = shift
      table.insert(agricultural_graphics.animation.layers, new_layer)
    end
  else
    local new_layer = table.deepcopy(variation_leaves)
    if plant_name == "tree-plant" then
      new_layer.tint = { r = 111 + 40, g = 123 + 40, b = 45 + 40 }
    end
    new_layer.x = 0
    new_layer.y = 0
    new_layer.repeat_count = 64
    new_layer.frame_count = 1
    new_layer.shift = shift
    table.insert(agricultural_graphics.animation.layers, new_layer)
  end

  table.insert(agricultural_graphics.animation.layers,
    util.sprite_load("__quality-seeds-fork__/graphics/entity/green-house-front",
      {
        priority = "high",
        animation_speed = 0.25,
        frame_count = 64,
        scale = 0.5
      }))

  table.insert(agricultural_graphics.animation.layers,
    util.sprite_load("__space-age__/graphics/entity/agricultural-tower/agricultural-tower-base-shadow",
      {
        priority = "high",
        frame_count = 1,
        repeat_count = 64,
        draw_as_shadow = true,
        scale = 0.5
      }))

  local cultivator_icons = {
    {
      icon = "__quality-seeds-fork__/graphics/icons/cultivator_back.png",
      shift = { 0.0, 5 }
    },
    {
      icon = plant_icon,
      scale = 0.5
    },
    {
      icon = "__quality-seeds-fork__/graphics/icons/cultivator_front.png",
      shift = { 0.0, 5 }
    }
  }

  local cultivator_name = plant_name .. "-greenhouse"
  local processing_tint = plant_prototype.agricultural_tower_tint
  cultivator.name = cultivator_name
  --cultivator.fixed_recipe = "cultivate-" .. plant_name

  cultivator.tile_buildability_rules = tile_buildability_rules
  cultivator.effect_receiver = {} -- Remove the added productivity of the biochamber.
  cultivator.crafting_categories = { recipe_category.name }
  cultivator.minable = { mining_time = 0.1, result = cultivator_name }
  cultivator.fast_replaceable_group = "greenhouse"
  cultivator.place_result = cultivator_name
  cultivator.circuit_connector = circuit_connector_definitions[cultivator_name]
  cultivator.graphics_set = agricultural_graphics
  cultivator.fluid_boxes =
  {
    {
      production_type = "input",
      volume = 1000,
      pipe_connections =
      {
        {
          flow_direction = "input",
          direction = defines.direction.north,
          position = { 0, -1 }
        }
      },
      filter = "water"
    },
    {
      production_type = "output",
      volume = 1000,
      pipe_connections =
      {
        {
          flow_direction = "output",
          direction = defines.direction.south,
          position = { 0, 1 }
        }
      }
    }
  }
  cultivator.icons = cultivator_icons
  cultivator.localised_name = { "entity-name.cultivator", plant_label }
  cultivator.localised_description = { "entity-description.cultivator", plant_label }

  cultivator.fluid_boxes_off_when_no_fluid_recipe = false
  cultivator.collision_mask = { layers = { object = true, train = true, is_object = true, is_lower_object = true } } -- collide just with object-layer and train-layer which don't collide with water, this allows us to build on water for water plants like slipstacks.

  -- Emissions logic:
  local spore_emmisions = { spores = 0 }
  if plant_prototype.harvest_emissions and plant_prototype.harvest_emissions.spores then
    spore_emmisions.spores = plant_prototype.harvest_emissions.spores * 2
  end
  cultivator.energy_source.emissions_per_minute = { spores = 0, pollution = -1 } --spore_emmisions --emissions_per_m
  -- We do this because trees take many minutes to grow. But still, use some Efficiency modules!

  -- Recipe for Cultivator:
  local cultivator_recipe = {
    type = "recipe",
    name = cultivator_name,
    localised_name = { "recipe-name.cultivator", plant_label },
    localised_description = { "recipe-description.cultivator", plant_label },
    category = "organic-or-assembling",
    surface_conditions =
    {
      {
        property = "pressure",
        min = 2000,
        max = 2000
      }
    },
    energy_required = 20,
    ingredients =
    {
      { type = "item", name = "nutrients",        amount = 5 },
      { type = "item", name = seed_name,          amount = 1 },
      { type = "item", name = "steel-plate",      amount = 20 },
      { type = "item", name = "advanced-circuit", amount = 5 },
      { type = "item", name = "landfill",         amount = 9 }
    },
    results = { { type = "item", name = cultivator_name, amount = 1 } },
    enabled = false,
    icons = cultivator_icons
  }

  local cultivator_recipe_recycling = {
    type = "recipe",
    name = cultivator_name .. "-recycling",
    localised_name = { "recipe-name.cultivator-recycling", plant_label },
    localised_description = { "recipe-description.cultivator-recycling", plant_label },
    icon = nil,
    --subgroup = item.subgroup,
    icons = {
      {
        icon = "__quality__/graphics/icons/recycling.png"
      },
      {
        icon = "__quality-seeds-fork__/graphics/icons/cultivator_back.png",
        shift = { 0.0, 5 }
      },
      {
        icon = plant_icon,
        scale = 0.5
      },
      {
        icon = "__quality-seeds-fork__/graphics/icons/cultivator_front.png",
        shift = { 0.0, 5 }
      },
      {
        icon = "__quality__/graphics/icons/recycling-top.png"
      },
    },
    category = "recycling",
    hidden = true,
    enabled = true,
    unlock_results = false,
    ingredients = { { type = "item", name = cultivator_name, amount = 1, ignored_by_stats = 1 } },
    results = {
      { type = "item", name = "nutrients",        amount = 5,  probability = 0.25, ignored_by_stats = 5 },
      { type = "item", name = seed_name,          amount = 1,  probability = 0.25, ignored_by_stats = 1 },
      { type = "item", name = "steel-plate",      amount = 20, probability = 0.25, ignored_by_stats = 20 },
      { type = "item", name = "advanced-circuit", amount = 5,  probability = 0.25, ignored_by_stats = 5 },
      { type = "item", name = "landfill",         amount = 9,  probability = 0.25, ignored_by_stats = 9 }
    }, -- Will show as consumed when item is destroyed
    energy_required = 20 / 16,
    crafting_machine_tint = processing_tint
  }

  local cultivator_item = table.deepcopy(data.raw["item"]["biochamber"])
  cultivator_item.name = cultivator_name
  cultivator_item.place_result = cultivator_name
  cultivator_item.icons = cultivator_icons
  cultivator_item.order = "a[agricultural-tower]-b[greenhouse]-c[" .. plant_name .. "]"

  local spore_result = { type = "fluid", name = "spores", amount = spore_emmisions.spores * spore_multiplier, ignored_by_productivity = 100 }
  local steam_result = { type = "fluid", name = "steam", amount = 100, ignored_by_productivity = 100, temperature = 180 }

  local input_fluid = { type = "fluid", name = "water", amount = 100 }

  plant_harvest_results_space = table.deepcopy(plant_harvest_results)

  if spore_emmisions.spores > 0 then
    table.insert(plant_harvest_results, spore_result)
  else
    table.insert(plant_harvest_results, steam_result)
  end

  -- Adjustments for Demolisher Agriculture mod.
  if plant_name == "demolisher-pupae" then
    steam_result["temperature"] = 1000
    input_fluid["name"] = "sulfuric-acid"
  end

  -- Recipe to cultivate Fruits from Seeds.
  local recipe_cultivate = {
    type = "recipe",
    name = "cultivate-" .. plant_name,
    icon = plant_icon,
    category = "cultivation-" .. plant_name,
    localised_name = { "recipe-name.cultivate", plant_label },
    localised_description = { "recipe-description.cultivate", plant_label },
    enabled = false,
    hidden = false,
    result_is_always_fresh = true,
    preserve_products_in_machine_output = true,
    ingredients = {
      { type = "item", name = seed_name, amount = 1 },
      input_fluid
    },
    energy_required = (plant_prototype.growth_ticks / 60) * 1.5, -- / 60 to normalise for 60 UPS.
    results = plant_harvest_results,
    allow_productivity = true,
    crafting_machine_tint = processing_tint,
  }

  -- Recipe to cultivate Fruits from Seeds.
  local recipe_cultivate_space = {
    type = "recipe",
    name = "cultivate-space-" .. plant_name,
    icon = plant_icon,
    category = "space-cultivation",
    localised_name = { "recipe-name.cultivate-space", plant_label },
    localised_description = { "recipe-description.cultivate-space", plant_label },
    enabled = false,
    hidden = false,
    result_is_always_fresh = true,
    preserve_products_in_machine_output = true,
    ingredients = {
      { type = "item",  name = seed_name, amount = 1 },
      { type = "fluid", name = "water",   amount = 100 }
    },
    energy_required = (plant_prototype.growth_ticks / 60) * 0.25, -- / 60 to normalise for 60 UPS. Things grow faster in space!
    results = plant_harvest_results_space,
    allow_productivity = true,                                    -- True, because fuck it we ball, this is the end of the game.
    crafting_machine_tint = processing_tint,
    surface_conditions =
    {
      {
        property = "gravity",
        min = 0,
        max = 0
      }
    },
  }

  -- Recipe for upcycling seeds
  local recipe_gmo = {
    type = "recipe",
    name = "gmo-" .. plant_name,
    localised_name = { "recipe-name.gmo", seed_label },
    localised_description = { "recipe-description.gmo", seed_label },
    order = "d[organic-processing]-a[" .. seed_name .. "]",
    category = "organic",
    enabled = false,
    ingredients = {
      { type = "item",  name = seed_name,      amount = 1 },
      { type = "item",  name = "pentapod-egg", amount = 1 },
      { type = "fluid", name = "spores",       amount = 100, ignored_by_stats = 100 }
    },
    energy_required = 5,
    results = {
      { type = "item",  name = seed_name,      amount = 1 },
      { type = "item",  name = "pentapod-egg", amount = 1,   probability = 0.5 },
      { type = "fluid", name = "spores",       amount = 100, ignored_by_stats = 100 }
    },
    main_product = seed_name,
    allow_productivity = false,
    maximum_productivity = 0.0,
    crafting_machine_tint = processing_tint,
    hide_from_signal_gui = false,
    icons = {
      {
        icon = data.raw.fluid["spores"].icon,
        scale = 0.8,
        shift = { 0, 0 }
      },
      {
        icon = "__quality__/graphics/icons/recycling.png"
      },
      {
        icon = data.raw.item["pentapod-egg"].icon,
        scale = 0.4,
        shift = { 0, 0 }
      },
      {
        icon = "__quality__/graphics/icons/recycling-top.png"
      },
      {
        icon = seed_prototype.icon or (seed_prototype.icons and seed_prototype.icons[1] and seed_prototype.icons[1].icon),
        scale = 0.5,
        shift = { 5.0, 5.0 }
      },
    }
  }

  data:extend {
    recipe_category,
    recipe_gmo,
    recipe_cultivate,
    recipe_cultivate_space,
    cultivator_recipe_recycling,
    cultivator,
    cultivator_item,
    cultivator_recipe
  }

  table.insert(data.raw.technology["space-cultivation"]["effects"],
    { type = "unlock-recipe", recipe = recipe_cultivate_space.name })

  -- Override for Boompuff-plant agriculture mod, so that you can't just grow boompuffs.
  if plant_name == "boompuff-plant" and data.raw.technology["boompuff-ascension"] then
    table.insert(data.raw.technology["boompuff-ascension"]["effects"],
      { type = "unlock-recipe", recipe = recipe_cultivate.name })
    table.insert(data.raw.technology["boompuff-ascension"]["effects"],
      { type = "unlock-recipe", recipe = cultivator_recipe.name })
    table.insert(data.raw.technology["boompuff-ascension"]["effects"], {
      type = "unlock-recipe",
      recipe = recipe_gmo
          .name
    })
    return
  end

  table.insert(data.raw.technology["fruit-cultivation"]["effects"],
    { type = "unlock-recipe", recipe = recipe_cultivate.name })
  table.insert(data.raw.technology["fruit-cultivation"]["effects"],
    { type = "unlock-recipe", recipe = cultivator_recipe.name })
  table.insert(data.raw.technology["fruit-cultivation"]["effects"], { type = "unlock-recipe", recipe = recipe_gmo.name })
end

log("Looking for plants to quality...")

local ignore_set = {}
for _, name in pairs(quality_seeds.ignore_plants or {}) do
  ignore_set[name] = true
end

if settings.startup["default-all-plants-cultivation"].value then
  for _, plant in pairs(data.raw["plant"]) do
    if not ignore_set[plant.name] then
      log("Processing plant " .. plant.name)
      create_quality_plant(plant, nil)
    else
      log("Skipping ignored plant " .. plant.name)
    end
  end
else
  for _, name in pairs(quality_seeds.allow_plants) do
    log("Processing plant " .. name)
    create_quality_plant(data.raw["plant"][name], nil)
  end
end
