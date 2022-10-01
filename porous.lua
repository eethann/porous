-- Porous Gate
-- A matrix gate using amplitude 
-- and pitch levels to pass or 
-- gate input.
--
--
-- e2: set min pitch
-- e3: set max pitch
-- k2+e2: set min amp
-- k2+e3: set max amp
--
-- k3: invert gate states
-- k2+k3: set all on
--
-- Signal is compared to 8 pitch  
-- and 8 amp windows.
--
-- Windows are split evenly
-- between min and max thresholds
-- (amp linear, pitch exp)
--
-- Grid is used to turn on/off
-- state of amp/pitch windows
-- amp vertical, pitch horiz.
--
-- TODO:
-- Sidechain
-- Support 16 col grids
--
-- This app came out of the 
-- field recording workshop
-- at Luck Dragon, 2022-09
-- thanks @danderks and
-- @jaceknighter

Lattice = require ("lattice")
local grid = util.file_exists(_path.code.."midigrid") and include "midigrid/lib/mg_128" or grid
g = grid.connect() -- 'g' represents a connected grid

engine.name = 'Porous'

local message
local pitch_poll_l, pitch_poll_r, amp_poll_l, amp_poll_r
local pitch_val_l, pitch_val_r, amp_val_l, amp_val_r

keys_down = { 0,0,0 }

window_ons = {
  {1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1}
}

pitch_windows = {}

amp_windows = {}

-- State of the tests for the gate being open or closed
amp_pass = 0
pitch_pass = 0

function init()
  print("Init Porous Gate")
  message = "porous gate"
  pitch_val_l = 0
  pitch_val_r = 0
  amp_val_l = 0
  amp_val_r = 0
  -- TODO integrate with params
  -- TODO add quantization support
  -- TODO make exponential, maybe also make it possible to quantize to scale with histerisis
  add_params()
  generate_amp_windows(params:get("porous_amp_min"), params:get("porous_amp_max"))
  generate_pitch_windows(params:get("porous_pitch_min"), params:get("porous_pitch_max"))
  audio.pitch_on()
  pitch_poll_l = poll.set("pitch_in_l")
  pitch_poll_l.callback = function(val)
    pitch_val_l = val 
    update_gate(amp_val_l, pitch_val_l, 1) 
  end
  pitch_poll_l:start()
  amp_poll_l = poll.set("amp_in_l")
  amp_poll_l.callback = function(val) 
    amp_val_l = val 
    update_gate(amp_val_l, pitch_val_l, 1)
  end
  amp_poll_l:start()
  pitch_poll_r = poll.set("pitch_in_r")
  pitch_poll_r.callback = function(val)
    pitch_val_r = val 
    update_gate(amp_val_r, pitch_val_r, 2) 
  end
  pitch_poll_r:start()
  amp_poll_r = poll.set("amp_in_r")
  amp_poll_r.callback = function(val) 
    amp_val_r = val 
    update_gate(amp_val_r, pitch_val_r, 2)
  end
  amp_poll_r:start()
  init_lattice()
  redraw()
  grid_redraw()
  -- lat:start()
  -- function grid.add(new_grid)
  --   g = new_grid
  --   -- g.key = make_grid_key_fn(update_fn)
  --   -- TODO look into setting a flag here instead of calling directly
  --   grid_redraw()
  -- end
end

function add_params()
  params:add_separator('header', 'porous')
  params:add_control(
    'porous_amp_min', -- ID
    'min amp',
    controlspec.new(
      0, -- min
      1, -- max
      'lin', -- warp
      0.001, -- output quantization
      0, -- default value
      '', -- string for units
      0.005 -- adjustment quantization
    ) --,
    -- params UI formatter:
    -- function(param)
    --   return strip_trailing_zeroes(param:get()*100)..'%'
    -- end
  )
  params:add_control(
    'porous_amp_max', -- ID
    'max amp',
    controlspec.new(
      0, -- min
      1, -- max
      'lin', -- warp
      0.001, -- output quantization
      0.1, -- default value
      '', -- string for units
      0.005 -- adjustment quantization
    ) --,
    -- params UI formatter:
    -- function(param)
    --   return strip_trailing_zeroes(param:get()*100)..'%'
    -- end
  )
  params:set_action("porous_amp_min", function(val) generate_amp_windows(val, params:get("porous_amp_max")) end)
  params:set_action("porous_amp_max", function(val) generate_amp_windows(params:get("porous_amp_min"), val) end)
  -- params:add{type = "number", id = "porous_amp_min", name = "min amp",
  -- min = 0, max = 1, default = 0, action=function(val) generate_amp_windows(val, params:get("porous_amp_max")) end}
  -- params:add{type = "number", id = "porous_amp_max", name = "max amp",
  -- min = 0, max = 1, default = 0.1, action=function(val) generate_amp_windows(params:get("porous_amp_min"), val) end}
  params:add{type = "taper", id = "porous_pitch_min", name = "min pitch",
  min = 0, max = 1720, default = 44, action=function(val) generate_pitch_windows(val, params:get("porous_pitch_max")) end}
  params:add{type = "taper", id = "porous_pitch_max", name = "max pitch",
  min = 0, max = 1720, default = 880, action=function(val) generate_pitch_windows(params:get("porous_pitch_min"), val) end}
  -- low/hi for amp
  -- low/hi for pitch
  -- scale for quantization
end

function generate_pitch_windows(min, max)
  pitch_windows = make_exp_ranges(min, max, 8)
end

function generate_amp_windows(min, max)
  amp_windows = make_lin_ranges(min, max, 8) 
end

function make_lin_ranges(min, max, steps)
  return make_ranges(min, max, steps, util.linlin)
end

function make_exp_ranges(min, max, steps)
  return make_ranges(min, max, steps, util.linexp)
end

function make_ranges(min, max, steps, f) 
  local ranges = {}
  for i=1,steps do
    ranges[i] = {f(0, 1, min, max, (i - 1)/steps), f(0, 1, min, max, i/steps)}
  end
  return ranges
end

function init_lattice()
  lat = Lattice:new{
    auto = true,
    meter = 4,
    ppqn = 96
  }

  lat_pat1 = lat:new_pattern{
    action = function(t) 
      pitch_poll_l:update()
      amp_poll_l:update()
    end,
    -- division = 1/4,
    division = 1/(96*4),
    enabled = true
  }
end

function update_gate(amp_val, pitch_val, chan)
  local level = 0
  amp_pass = 0
  pitch_pass = 0
  for a_i=1, #amp_windows do
    if amp_val >= amp_windows[a_i][1] and amp_val < amp_windows[a_i][2] then
      amp_pass = a_i
      break
    end
  end
  for p_i=1, #pitch_windows do
    if pitch_val >= pitch_windows[p_i][1] and pitch_val < pitch_windows[p_i][2] then
        pitch_pass = p_i
        break
    end
  end
  if (amp_pass > 0) and (pitch_pass > 0) then
    -- print(amp_pass)
    -- print(pitch_pass)
    level = window_ons[amp_pass][pitch_pass]
    amp_pass = amp_pass * level
    pitch_pass = pitch_pass * level
  end
  -- audio.level_monitor(level)
  if chan == 1 then
    engine.amp1(level)
  else
    engine.amp2(level)
  end
  redraw()
end

function key(k, z) 
  keys_down[k] = z
  if z == 1 and k == 3 then
    if keys_down[2] == 1 then
      for i=1,8 do
        for j=1,8 do
          window_ons[i][j] = 1
        end
      end
    else
      for i=1,8 do
        for j=1,8 do
          window_ons[i][j] = 1- window_ons[i][j]
        end
      end
    end
    grid_redraw()
    redraw()
  end
end

function enc(e, d)
  if keys_down[2] == 1 then
    if e == 2 then
      params:set("porous_amp_min", params:get("porous_amp_min") + (d*0.01))
    elseif e == 3 then
      params:set("porous_amp_max", params:get("porous_amp_max") + (d*0.01))
    end
  else
    if e == 2 then
      params:set("porous_pitch_min", params:get("porous_pitch_min") + d)
    elseif e == 3 then
      params:set("porous_pitch_max", params:get("porous_pitch_max") + d)
    end
  end
end

function redraw()
  screen.clear()
  -- Draw states of gate
  screen.level(4)
  for i=1,8 do
    for j=1,8 do
      if window_ons[j][i] == 1 then
        screen.rect(64 + (6 * (i-1)), 8 + (6 * (8-j)), 6, 6)
        screen.fill() 
      end
    end
  end
  screen.level(15)
  -- Draw frame
  screen.rect(64,8,49,49)
  screen.stroke()
  -- Draw current pitch and amp lines
  local pitch_min = params:get("porous_pitch_min")
  local pitch_max = params:get("porous_pitch_max")
  local pitch_level_l = util.clamp(util.explin(pitch_min, pitch_max, 0, 47, pitch_val_l), 0, 47)
  local pitch_level_r = util.clamp(util.explin(pitch_min, pitch_max, 0, 47, pitch_val_r), 0, 47)
  local amp_min = params:get("porous_amp_min")
  local amp_max = params:get("porous_amp_max")
  local amp_level_l = util.clamp(util.linlin(amp_min, amp_max, 0, 47, amp_val_l), 0, 47)
  local amp_level_r = util.clamp(util.linlin(amp_min, amp_max, 0, 47, amp_val_r), 0, 47)
  screen.level(8)
  if (pitch_level_l >= 0) and (pitch_level_l <= 47) then
    screen.move(64 + (math.floor(pitch_level_l)), 8)
    screen.line(64 + (math.floor(pitch_level_l)), 56)
    screen.stroke()
  end
  if (pitch_level_r >= 0) and (pitch_level_r <= 47) then
    screen.move(64 + (math.floor(pitch_level_r)), 8)
    screen.line(64 + (math.floor(pitch_level_r)), 56)
    screen.stroke()
  end
  if (amp_level_l >= 0) and (amp_level_l <= 47) then
    screen.move(64, 8 + (math.floor(48 - amp_level_l)))
    screen.line(112,8 + (math.floor(48 - amp_level_l)))
    screen.stroke()
  end
  if (amp_level_r >= 0) and (amp_level_r <= 47) then
    screen.move(64, 8 + (math.floor(48 - amp_level_r)))
    screen.line(112,8 + (math.floor(48 - amp_level_r)))
    screen.stroke()
  end
  screen.level(15)
  screen.pixel(64 + (math.floor(pitch_level_l)) - 1, 8 + (math.floor(48 - amp_level_l)) - 1)
  screen.pixel(64 + (math.floor(pitch_level_r)) - 1, 8 + (math.floor(48 - amp_level_r)) - 1)
  screen.fill()
  screen.move(64+24, 64)
  screen.text_center("Pitch")
  screen.move(64, 64)
  screen.text_center(pitch_min)
  screen.move(112, 64)
  screen.text_center(pitch_max)
  screen.move(56,32)
  screen.text_rotate(60,40,"Amp",-90)
  screen.move(60,16)
  screen.text_right(amp_max)
  screen.move(60,56)
  screen.text_right(amp_min)
  screen.move(12, 20)
  screen.level(pitch_pass > 0 and 15 or 6)
  screen.text("Pitch:")
  screen.move(12, 28)
  screen.text(math.floor(pitch_val_l * 10) / 10)
  screen.move(12, 44)
  screen.level(amp_pass > 0 and 15 or 6)
  screen.text("Amp")
  screen.move(12, 52)
  screen.text(math.floor(amp_val_l * 100) / 100)
  screen.update()
end

function g.key(x,y,z)
  if z == 1 then
    window_ons[9-y][x] = 1 - window_ons[9-y][x]
  end
  grid_redraw()
end

function grid_redraw()
  g:all(0)
  for a_i=1,#window_ons do
    for p_i=1,#window_ons[a_i] do
      g:led(p_i, 9 - a_i, 15 * (window_ons[a_i][p_i]))
    end
  end 
  g:refresh()
end