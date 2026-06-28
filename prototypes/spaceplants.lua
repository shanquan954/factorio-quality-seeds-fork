-- Recipe for Cultivator:
local space_cultivator_recipe = {
    type = "recipe",
    name = "space-cultivator",
    localised_name = {"recipe-name.space-cultivator"},
    localised_description = {"recipe-description.space-cultivator"},
    category = "organic-or-assembling",
    surface_conditions =
    {
        {
        property = "gravity",
        min = 0,
        max = 0
        }
    },
    energy_required = 40,
    ingredients =
    {
        {type = "item", name = "nutrients", amount = 500},
        {type = "item", name = "steel-plate", amount = 20},
        {type = "item", name = "carbon-fiber", amount = 250},
        {type = "item", name = "quantum-processor", amount = 50},
        {type = "item", name = "landfill", amount = 50}
    },
    results = {{type="item", name="space-cultivator", amount=1}},
    enabled = false,
    icon = "__quality-seeds-fork__/graphics/icons/space-cultivator.png"
}

local space_cultivator_item = table.deepcopy(data.raw["item"]["biochamber"])
space_cultivator_item.name = "space-cultivator"
space_cultivator_item.place_result = "space-cultivator"
space_cultivator_item.icon = "__quality-seeds-fork__/graphics/icons/space-cultivator.png"
space_cultivator_item.localised_name = {"item-name.space-cultivator"}
space_cultivator_item.localised_description = {"item-description.space-cultivator"}
space_cultivator_item.order = "a[agricultural-tower]-b[greenhouse]-z[space-cultivator]"

local space_cultivator = table.deepcopy(data.raw["assembling-machine"]["biochamber"])
local space_cultivator_graphics = {
  animation =
  {
    layers =
    {
      util.sprite_load("__quality-seeds-fork__/graphics/entity/space-cultivator-anim",
      {
        priority = "high",
        animation_speed = 0.25,
        frame_count = 64,
        scale = 0.5
      }),
      util.sprite_load("__space-age__/graphics/entity/agricultural-tower/agricultural-tower-base-shadow",
      {
        priority = "high",
        frame_count = 1,
        repeat_count = 64,
        draw_as_shadow = true,
        scale = 0.5
      })
    }
  },
  recipe_not_set_tint = { primary = {r = 0.6, g = 0.6, b =  0.5, a = 1}, secondary = {r = 0.6, g =  0.6, b = 0.5, a = 1} },
  working_visualisations =
  {
    {
      always_draw = true,
      fog_mask = { rect = {{-30, -30}, {30, -2.75}}, falloff = 1 },
      animation = util.sprite_load("__quality-seeds-fork__/graphics/entity/space-cultivator-anim",
      {
        frame_count = 1,
        scale = 0.5
      }),
    },

    {
      --constant_speed = true,
      always_draw = true,
      apply_recipe_tint = "primary",
      animation = util.sprite_load("__quality-seeds-fork__/graphics/entity/space-cultivator-plants-mask",
      {
        priority = "high",
        frame_count = 64,
        animation_speed = 0.25,
        tint_as_overlay = true,
        scale = 0.5
      }),
    },
    {
      --constant_speed = true,
      apply_recipe_tint = "secondary",
      effect = "flicker",
      fadeout = true,
      animation = util.sprite_load("__quality-seeds-fork__/graphics/entity/space-cultivator-lights",
      {
        priority = "high",
        frame_count = 64,
        animation_speed = 0.25,
        blend_mode = "additive",
        scale = 0.5
      }),
    },
    {
      effect = "flicker",
      fadeout = true,
      light = {intensity = 1.0, size = 6, shift = {-0.45, -0.25}, color = {r = 1, g = 1, b = 1}}
    },
    {
      apply_recipe_tint = "secondary",
      effect = "flicker",
      fadeout = true,
      light = {intensity = 1.0, size = 16, shift = {-1.2, -0.5}, color = {r = 1, g = 1, b = 1}}
    }
  },
}
space_cultivator.name = "space-cultivator"
space_cultivator.crafting_categories = {"space-cultivation"}
space_cultivator.graphics_set = space_cultivator_graphics
space_cultivator.circuit_connector = circuit_connector_definitions["space-cultivator"]
space_cultivator.place_result = "space-cultivator"
space_cultivator.fast_replaceable_group = "space-cultivator"
space_cultivator.minable = {mining_time = 0.1, result = "space-cultivator"}
space_cultivator.collision_box = {{-2.4, -2.4}, {2.4, 2.4}}
space_cultivator.selection_box = {{-2.4, -2.4}, {2.4, 2.4}}
space_cultivator.surface_conditions =
{
    {
    property = "gravity",
    min = 0,
    max = 0
    }
}

local pipe_pictures_1 =
{
  north =
  {
    layers = {
      util.sprite_load("__quality-seeds-fork__/graphics/entity/pipes-north",
      {
        scale = 0.5,
        shift = {0,1},
      }),
    }
  },
  east = {
    layers = {
      util.sprite_load("__quality-seeds-fork__/graphics/entity/pipes-east",
      {
        scale = 0.5,
        shift = {-1,0},
      }),
    }
  },
  south = {
    layers = {
      util.sprite_load("__quality-seeds-fork__/graphics/entity/pipes-south",
      {
        scale = 0.5,
        shift = {0,-1},
      }),
    }
  },
  west = {
    layers = {
      util.sprite_load("__quality-seeds-fork__/graphics/entity/pipes-west",
      {
        scale = 0.5,
        shift = {1,0},
      })
    }
  }
}

space_cultivator.fluid_boxes =
{
    {
        pipe_covers = pipecoverspictures(),
        pipe_picture = pipe_pictures_1,
        production_type = "input",
        volume = 500,
        pipe_connections =
        {
            {
                flow_direction="input-output",
                direction = defines.direction.north,
                position = {-1, -2}
            }
        },
    },
    {
        pipe_covers = pipecoverspictures(),
        pipe_picture = pipe_pictures_1,
        production_type = "input",
        volume = 500,
        pipe_connections =
        {
            {
                flow_direction = "input-output",
                direction = defines.direction.south,
                position = {1, 2}
            }
        },
    }
}
space_cultivator.icon = "__quality-seeds-fork__/graphics/icons/space-cultivator.png"
space_cultivator.localised_name = {"entity-name.space-cultivator"}
space_cultivator.localised_description = {"entity-description.space-cultivator"}
space_cultivator.fluid_boxes_off_when_no_fluid_recipe = true
space_cultivator.energy_source.effectivity = 2.5


local space_cultivator_recipe_recycling = {
  type = "recipe",
  name = "space-cultivator-recycling",
  localised_name = {"recipe-name.space-cultivator-recycling"},
  localised_description = {"recipe-description.space-cultivator-recycling"},
  icon = nil,
  --subgroup = item.subgroup,
  icons = {
    {
      icon = "__quality__/graphics/icons/recycling.png"
    },
    {
      icon = "__quality-seeds-fork__/graphics/icons/space-cultivator.png",
      scale = 0.4
    },    
    {
      icon = "__quality__/graphics/icons/recycling-top.png"
    },
  },
  category = "recycling",
  hidden = true,
  enabled = true,
  unlock_results = false,
  ingredients = {{type = "item", name = "space-cultivator", amount = 1, ignored_by_stats = 1}},
  results = {
    {type = "item", name = "nutrients", amount = 500, probability = 0.25, ignored_by_stats = 500},
    {type = "item", name = "steel-plate", amount = 20, probability = 0.25, ignored_by_stats = 20},
    {type = "item", name = "carbon-fiber", amount = 250, probability = 0.25, ignored_by_stats = 250},
    {type = "item", name = "quantum-processor", amount = 50, probability = 0.25, ignored_by_stats = 50},
    {type = "item", name = "landfill", amount = 50, probability = 0.25, ignored_by_stats = 50}
  }, -- Will show as consumed when item is destroyed
  energy_required = 40/16,
  crafting_machine_tint = processing_tint
}

data.extend({
    space_cultivator, space_cultivator_recipe, space_cultivator_recipe_recycling, space_cultivator_item
})
