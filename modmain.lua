
----------------------------------------------------
----------------- CONFIGURATION --------------------

TUNING.SHOW_DAMAGE_ONLY = GetModConfigData("dmg_only") == "on"		-- set to true, if you want to see damage only (no healing)

TUNING.SHOW_NUMBERS_THRESHOLD = 0.1
if GetModConfigData("amount_of_numbers") == "high" then
  TUNING.SHOW_NUMBERS_THRESHOLD = 0.001
end
if GetModConfigData("amount_of_numbers") == "low" then
  TUNING.SHOW_NUMBERS_THRESHOLD = 0.99
end

TUNING.SHOW_DECIMAL_POINTS = GetModConfigData("show_decimal_points")

TUNING.DISPLAY_MODE = GetModConfigData("display_mode")

TUNING.LABEL_FONT_SIZE = 70
if(GetModConfigData("number_size") == "tiny") then
  TUNING.LABEL_FONT_SIZE = 40
end
if(GetModConfigData("number_size") == "huge") then
  TUNING.LABEL_FONT_SIZE = 100
end
  
----------------------------------------------------


TUNING.HEALTH_LOSE_COLOR = {
  r = 0.7,
  g = 0,
  b = 0
}
TUNING.HEALTH_GAIN_COLOR = {
  r = 0,
  g = 0.7,
  b = 0
}


TUNING.LABEL_Y_START = 4

TUNING.LABEL_TIME = 1.0

TUNING.LABEL_TIME_DELTA = 0.01

TUNING.GRAVITY = 0.1
TUNING.FRICTION_PRESERVE = 0.9

TUNING.LIFT_ACC = 0.003
TUNING.SIDE_WAVE_RND = 0.15
TUNING.LABEL_Y_START_VELO = 0.05

TUNING.LABEL_MIN_AMPLITUDE_X = 0.8
TUNING.LABEL_MAX_AMPLITUDE_X = 1.6


local function CreateLabel(inst, parent)
  inst.persists = false
  if not inst.Transform then
    inst.entity:AddTransform()
  end
  inst.Transform:SetPosition( parent.Transform:GetWorldPosition() )

  return inst
end

local function CreateDamageIndicator(parent, amount)
  local inst = CreateLabel(GLOBAL.CreateEntity(), parent)

  local label = inst.entity:AddLabel()
  label:SetFont(GLOBAL.NUMBERFONT)
  label:SetFontSize( TUNING.LABEL_FONT_SIZE )
  label:SetPos(0, TUNING.LABEL_Y_START, 0)

  local color
  if amount < 0 then
    color = TUNING.HEALTH_LOSE_COLOR
  else
    color = TUNING.HEALTH_GAIN_COLOR
  end

  label:SetColour(color.r, color.g, color.b)

  local dp_no = "%d";
  local dp_yes = "%.1f";

  local format = dp_no

  if TUNING.SHOW_DECIMAL_POINTS == "all" then
    format = dp_yes
  end

  if math.abs(amount) < 1.0 and TUNING.SHOW_DECIMAL_POINTS == "low" then
    format = dp_yes
  end



  label:SetText(string.format(format, amount))
  --label:SetText( ("%d.1f"):format(amount) )  -- wanna have .x ?

  label:Enable(true)

  inst:StartThread(function()

      local label = inst.Label

      local t = 0
      local t_max = TUNING.LABEL_TIME
      local dt = TUNING.LABEL_TIME_DELTA

      -- waving upon mode ------------------
      local y = TUNING.LABEL_Y_START
      local dy = TUNING.LABEL_Y_START_VELO
      local ddy = 0.0

      local side = (math.random() * (TUNING.LABEL_MAX_AMPLITUDE_X - TUNING.LABEL_MIN_AMPLITUDE_X) + TUNING.LABEL_MIN_AMPLITUDE_X) * (math.random() >= 0.5 and -1 or 1)
      local dside = 0.0
      local ddside = 0.0
      -------------------------------------
      
      if TUNING.DISPLAY_MODE == 'straight' then
        side = side * 0.00
      end
      

      if TUNING.DISPLAY_MODE == 'bouncy' then
        -- bounce around mode ---------------
        y = TUNING.LABEL_Y_START
        dy = 0.05
        ddy = 0.0

        side = 0.0
        dside = 0.1
        if math.random() > 0.5 then
          dside = -dside
        end
        ddside = 0.0
        -----------------------------
      end

      while inst:IsValid() and t < t_max do

        if TUNING.DISPLAY_MODE == 'waving' or TUNING.DISPLAY_MODE == 'straight' then
          -- waving upon mode ------------------
          ddy = TUNING.LIFT_ACC * (math.random() * 0.5 + 0.5)
          dy = dy + ddy
          y = y + dy

          ddside = -side * math.random()*TUNING.SIDE_WAVE_RND
          dside = dside + ddside
          side = side + dside
          -------------------------------------
        end

        if TUNING.DISPLAY_MODE == 'bouncy' then
          -- bounce around mode ---------------
          ddy = -TUNING.GRAVITY
          dy = dy + ddy
          y = y + dy
          if y < 0 then
            y = -y
            dy = -dy * TUNING.FRICTION_PRESERVE
          end

          ddside = 0
          dside = dside + ddside
          side = side + dside
          -------------------------------------
        end

        local headingtarget = 45 --[[TheCamera.headingtarget]] % 180
        if headingtarget == 0 then
          label:SetPos(0, y, side)  		-- from 3d plane x = 0
        elseif headingtarget == 45 then
          label:SetPos(side, y, -side)	-- from 3d plane x + z = 0
        elseif headingtarget == 90 then
          label:SetPos(side, y, 0)		-- from 3d plane z = 0
        elseif headingtarget == 135 then
          label:SetPos(side, y, side)		-- from 3d plane z - x = 0
        end
        t = t + dt
        label:SetFontSize( TUNING.LABEL_FONT_SIZE * math.sqrt(1 - t / t_max))
        GLOBAL.Sleep(dt)
      end

      inst:Remove()
  end)

  return inst
end


AddComponentPostInit("health", function(Health, inst)
  inst:ListenForEvent("healthdelta", function(inst, data)
    if inst.components.health then
      local amount = (data.newpercent - data.oldpercent)*inst.components.health.maxhealth
      -- print(amount)
      if math.abs(amount) > TUNING.SHOW_NUMBERS_THRESHOLD then
        if not (TUNING.SHOW_DAMAGE_ONLY and amount > 0) then
          CreateDamageIndicator(inst, amount)
        end
      end
    end
  end)
end)
