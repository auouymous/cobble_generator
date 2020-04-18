cobble_generator = {}
local MP = minetest.get_modpath("cobble_generator").."/"

local string_format = string.format

local output_item = "default:cobble"
local output_quantity = {1, 2, 4, 8, 16, 32} -- quantity per interval per tier
local interval = 3 -- seconds



local use_node_io = (minetest.get_modpath("node_io") ~= nil)
local use_pipeworks = (minetest.get_modpath("pipeworks") ~= nil)

local flush = function(inv, stack, pos, put_pos, put_side, put_dir)
	local put_node = minetest.get_node(put_pos)
	local put_ndef = minetest.registered_nodes[put_node.name]

	if use_node_io and node_io.can_put_item(put_pos, put_node, put_side) == 1 then
		local room = node_io.can_put_item(put_pos, put_node, put_side, stack, stack:get_count())
		if room > 0 then
			local leftovers = node_io.put_item(put_pos, put_node, put_side, pos, stack)
			if not leftovers:is_empty() then
				inv:set_stack("main", 1, leftovers)
				return false
			end
			inv:set_stack("main", 1, leftovers)
		end
	elseif use_pipeworks and put_ndef.tube ~= nil then
		local eject = stack:take_item(stack:get_count())
		inv:set_stack("main", 1, stack)
		pipeworks.tube_inject_item(pos, pos, {x=0, y=put_dir, z=0}, eject)
	else
		local put_meta = minetest.get_meta(put_pos)
		if put_meta == nil then return false end
		local put_inv = put_meta:get_inventory()
		if put_inv == nil or put_inv:get_size("main") == 0 then return false end
		local leftovers = put_inv:add_item("main", stack)
		if not leftovers:is_empty() then
			inv:set_stack("main", 1, leftovers)
			return false
		end
		inv:set_stack("main", 1, leftovers)
	end
	return true
end

local set_state = function(pos, meta, timer, active)
	local output_item_description = ItemStack(output_item.." 1"):get_definition().description
	if active then
		timer:start(interval)
		meta:set_string("infotext", string_format("Active\n\nPunch to eject %s now", output_item_description))
	else
		meta:set_string("infotext", string_format("Inactive\n\nPunch to eject %s and restart", output_item_description))
	end
end

local restart_timer = function(pos, meta)
	local timer = minetest.get_node_timer(pos)
	if not timer:is_started() then
		set_state(pos, meta, timer, true)
	end
end

local mesecon_rules = {
	{x=-1, y= 0, z= 0},
	{x= 1, y= 0, z= 0},
	{x= 0, y=-1, z= 0},
	{x= 0, y= 1, z= 0},
	{x= 0, y= 0, z=-1},
	{x= 0, y= 0, z= 1},
}

for i = 1,6 do
	local node_name = "cobble_generator:mk"..i
	local texture = "cobble_generator_S"..i..".png"

	minetest.register_node(node_name, {
		description = "Cobble Generator Mk"..i,
		tiles = {"cobble_generator_UD.png", "cobble_generator_UD.png", texture, texture, texture, texture},
		sounds = default.node_sound_metal_defaults(),
		groups = {cracky = 1, level = 2},
		is_ground_content = false,

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:set_size('main', 1)

			local spos = pos.x .. "," .. pos.y .. "," .. pos.z
			local formspec =
				"size[8,6.5]" ..
				"list[nodemeta:" .. spos .. ";main;3.5,0.5;1,1;]" ..
				"list[current_player;main;0,2.35;8,1;]" ..
				"list[current_player;main;0,3.58;8,3;8]" ..
				"listring[nodemeta:" .. spos .. ";main]" ..
				"listring[current_player;main]" ..
				default.get_hotbar_bg(0,2.35)
			meta:set_string("formspec", formspec)

			set_state(pos, meta, minetest.get_node_timer(pos), true)
		end,

		on_timer = function(pos)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local stack = inv:get_stack("main", 1)
			if stack:get_count() + output_quantity[i] > stack:get_stack_max() then
				if not flush(inv, stack, pos, {x=pos.x, y=pos.y+1, z=pos.z}, "U", 1) then
					flush(inv, stack, pos, {x=pos.x, y=pos.y-1, z=pos.z}, "D", -1)
				end
			end
			local leftovers = inv:add_item("main", ItemStack(output_item.." "..output_quantity[i]))
			if not leftovers:is_empty() then
				set_state(pos, meta, nil, false)
				return false -- full, stop production
			end
			return true
		end,

		on_punch = function(pos, node, puncher)
			if minetest.is_protected(pos, puncher:get_player_name()) then return end

			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local stack = inv:get_stack("main", 1)
			if stack:get_count() > 0 then
				if not flush(inv, stack, pos, {x=pos.x, y=pos.y+1, z=pos.z}, "U", 1) then
					flush(inv, stack, pos, {x=pos.x, y=pos.y-1, z=pos.z}, "D", -1)
				end
			end
			restart_timer(pos, meta)
		end,

		can_dig = function(pos, player)
			if minetest.is_protected(pos, player:get_player_name()) then return end

			return true
		end,
		on_destruct = function(pos)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			local stack = inv:get_stack("main", 1)
			if not inv:is_empty("main") then
				minetest.add_item(pos, stack)
			end
		end,
		on_blast = function(pos, intensity)
			local drops = {}
			default.get_inventory_drops(pos, "main", drops)
			drops[#drops+1] = node_name
			minetest.remove_node(pos)
			return drops
		end,

		allow_metadata_inventory_put = function() return 0 end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) then return 0 end

			restart_timer(pos, minetest.get_meta(pos))

			return stack:get_count()
		end,

		-- node_io
		node_io_can_take_item = function(pos, node, side)
			return true
		end,
		node_io_take_item = function(pos, node, side, taker_pos, want_item, want_count)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local stack = inv:get_stack("main", 1)
			local want = stack:take_item(want_count)
			inv:set_stack("main", 1, stack)
			restart_timer(pos, meta)
			return want
		end,
		node_io_get_item_size = function(pos, node, side)
			return 1
		end,
		node_io_get_item_name = function(pos, node, side, index)
			return output_item
		end,
		node_io_get_item_stack = function(pos, node, side, index)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:get_stack("main", 1)
		end,
		-- node_io and pipeworks
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			if use_node_io then
				node_io.update_neighbors(pos)
			elseif use_pipeworks then
				pipeworks.after_place(pos, placer, itemstack, pointed_thing)
			end
		end,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			if use_node_io then
				node_io.update_neighbors(pos)
			elseif use_pipeworks then
				pipeworks.after_dig(pos, oldnode, oldmetadata, digger)
			end
		end,
		-- pipeworks
		tube = {
			insert_object = function(pos, node, stack, direction)
				return stack
			end,
			can_insert = function(pos, node, stack, direction)
				return false
			end,
			input_inventory = "main",
			connect_sides = {bottom = 1, top = 1}
		},
		-- mesecons
		mesecons = {
			effector = {
				rules = mesecon_rules,
				action_on = function (pos, node)
					-- stop production
					local timer = minetest.get_node_timer(pos)
					timer:stop()
					set_state(pos, minetest.get_meta(pos), nil, false)
				end,
				action_off = function (pos, node)
					-- restart
					restart_timer(pos, minetest.get_meta(pos))
				end,
			}
		},
	})

	if i == 1 then
		local pick_or_breaker = "default:pick_steel"
		local block_or_detector = "default:steelblock"
		if use_pipeworks and pipeworks.enable_node_breaker then pick_or_breaker = "pipeworks:nodebreaker_off" end
		if minetest.get_modpath("mesecons_detector") ~= nil then block_or_detector = "mesecons_detector:node_detector_off" end
		minetest.register_craft({
			output = node_name.." 1",
			recipe = {
				{"default:steel_ingot", pick_or_breaker, "default:steel_ingot"},
				{"bucket:bucket_water", "default:stone", "bucket:bucket_lava"},
				{"default:steel_ingot", block_or_detector, "default:steel_ingot"},
			}
		})
	else
		local lesser_node_name = "cobble_generator:mk"..(i-1)
		-- upgrade
		minetest.register_craft({
			output = node_name.." 1",
			recipe = {
				{lesser_node_name, lesser_node_name},
			}
		})
		-- downgrade
		minetest.register_craft({
			output = lesser_node_name.." 2",
			recipe = {
				{node_name},
			}
		})
	end
end

print("[MOD] Cobble Generator loaded")
