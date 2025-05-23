-------------------------------------
--------- ATLASES & SOUNDS ----------
-------------------------------------

SMODS.Atlas{
    key = "Jokers",
    path = "Jokers.png",
    px = 71,
    py = 95
}

SMODS.Atlas{
    key = "Extras",
    path = "Extras.png",
    px = 71,
    py = 95
}

SMODS.Sound{
    key = "pow_hit",
    path = "pow_hit.ogg"
}

-------------------------------------
-------- HELPERS & CONSTANTS --------
-------------------------------------

G.C.FISH = HEX("308fe3")
G.C.TETHERED = HEX('248571')

POW = {}
function POW.calc_chips(chips, mult, pow)
    local sign = function (number)
        return number > 0 and 1 or (number == 0 and 0 or -1)
    end
    return sign(chips)*(math.abs(chips)^pow)*mult
end

function POW.get_most_played_poker_hand()
    local _handname, _played, _order = 'High Card', -1, 100
    for k, v in pairs(G.GAME.hands) do
        if v.played > _played or (v.played == _played and _order > v.order) then 
            _played = v.played
            _handname = k
        end
    end
    return _handname
end

function POW.flip_helper(source, targets, func)
    if source then
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                source:juice_up(0.3, 0.5)
                return true
            end
        }))
    end
    for i = 1, #targets do
        local percent = 1.15 - (i - 0.999) / (#targets - 0.998) * 0.3
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.15,
            func = function()
                targets[i]:flip(); play_sound('card1', percent); targets[i]:juice_up(0.3, 0.3); return true
            end
        }))
    end
    delay(0.2)
    for i = 1, #targets do
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = func
        }))
    end
    for i = 1, #targets do
        local percent = 0.85 + (i - 0.999) / (#targets - 0.998) * 0.3
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.15,
            func = function()
                targets[i]:flip()
                play_sound('tarot2', percent, 0.6)
                targets[i]:juice_up(0.3, 0.3)
                return true
            end
        }))
    end
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.2,
        func = function()
            G.hand:unhighlight_all()
            return true
        end
    }))
    delay(0.5)
end


-- This method of loading would work for jokers too but I'm picky about collection order
local function requireFolder(path)
    local files = NFS.getDirectoryItemsInfo(SMODS.current_mod.path .. "/" .. path)
    for i = 1, #files do
        local file_name = files[i].name
        if file_name:sub(-4) == ".lua" then
            assert(SMODS.load_file(path .. file_name))()
        end
    end
end

-- Load Misc
requireFolder("misc/")

-- Load Jokers
assert(SMODS.load_file("jokers/pow_hand_jokers.lua"))()
assert(SMODS.load_file("jokers/reverse.lua"))()
assert(SMODS.load_file("jokers/fisherman.lua"))()
assert(SMODS.load_file("jokers/lich.lua"))()
assert(SMODS.load_file("jokers/frog.lua"))()
assert(SMODS.load_file("jokers/broker.lua"))()
assert(SMODS.load_file("jokers/big_bluff.lua"))()
assert(SMODS.load_file("jokers/joku.lua"))()
assert(SMODS.load_file("jokers/uranium_glass.lua"))()
assert(SMODS.load_file("jokers/blackjack.lua"))()
assert(SMODS.load_file("jokers/biker.lua"))()
assert(SMODS.load_file("jokers/chameleon.lua"))()
assert(SMODS.load_file("jokers/superhero.lua"))()


-------------------------------------
--------------- POW -----------------
-------------------------------------

-- hook for setting pow to 1 when a hand is being evaluated
local evaluate_play_ref = G.FUNCS.evaluate_play
G.FUNCS.evaluate_play = function(e)
    pow = 1
    return evaluate_play_ref(e)
end

-- hook for setting the pow text value to 1 when there is no pow key
local update_hand_text_ref = update_hand_text
function update_hand_text(config, vals)
    if not vals.pow then
        if pow then
            vals.pow = pow
        else
            vals.pow = 1
        end
    end
    return update_hand_text_ref(config, vals)
end

-- hook for allowing jokers to return pow in their calculate functions
local calculate_individual_effect_ref = SMODS.calculate_individual_effect
SMODS.calculate_individual_effect = function(effect, scored_card, key, amount, from_edition)
    if (key == 'pow' or key == 'h_pow' or key == 'pow_mod' or key == 'pow_decay') and amount then
        if effect.card and effect.card ~= scored_card then juice_card(effect.card) end
        pow = pow + amount
        update_hand_text({delay = 0}, {chips = hand_chips, mult = mult, pow = pow})
        if not effect.remove_default_message then
            if from_edition then
                card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = localize{type = 'variable', key = amount > 0 and 'a_pow' or 'a_pow_minus', vars = {amount}}, chip_mod = amount, colour = G.C.EDITION, edition = true})
            else
                if key ~= 'pow_mod' then
                    if effect.pow_message then
                        card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.pow_message)
                    else
                        card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'pow', amount, percent)
                    end
                end
            end
        end
        return true
    end
    return calculate_individual_effect_ref(effect, scored_card, key, amount, from_edition)
end

-- inserts the keys required to allow jokers to return pow in their calculate functions
table.insert(SMODS.calculation_keys, "pow")
table.insert(SMODS.calculation_keys, "h_pow")
table.insert(SMODS.calculation_keys, "pow_mod")
table.insert(SMODS.calculation_keys, "pow_decay")


-- custom number formatting for additional decimal places
local pow_number_format = function(num, e_switch_point)
    if type(num) ~= 'number' then return num end

    local sign = (num >= 0 and "") or "-"
    num = math.abs(num)
    G.E_SWITCH_POINT = G.E_SWITCH_POINT or 100000000000
    if not num or type(num) ~= 'number' then return num or '' end
    if num >= (e_switch_point or G.E_SWITCH_POINT) then
        local x = string.format("%.4g",num)
        local fac = math.floor(math.log(tonumber(x), 10))
        if num == math.huge then
            return sign.."naneinf"
        end
        
        local mantissa = round_number(x/(10^fac), 3)
        if mantissa >= 10 then
            mantissa = mantissa / 10
            fac = fac + 1
        end
        return sign..(string.format(fac >= 100 and "%.1fe%i" or fac >= 10 and "%.2fe%i" or "%.3fe%i", mantissa, fac))
    end
    local formatted
    if num ~= math.floor(num) and num < 10 then
        formatted = string.format("%.3f", num)
        if formatted:sub(-1) == "0" then
            formatted = formatted:gsub("%.?0+$", "")
        end
        -- Return already to avoid comas being added
        return tostring(num)
    else 
        formatted = string.format("%.0f", num)
    end
    return sign..(formatted:reverse():gsub("(%d%d%d)", "%1,"):gsub(",$", ""):reverse())
end


-- function for updating the pow text
G.FUNCS.hand_pow_UI_set = function(e)
    local new_pow_text = pow_number_format(G.GAME.current_round.current_hand.pow)
    if new_pow_text ~= G.GAME.current_round.current_hand.pow_text then 
        G.GAME.current_round.current_hand.pow_text = new_pow_text
        e.config.object.scale = scale_number(G.GAME.current_round.current_hand.pow, 0.55, 1000)
        e.config.object:update_text()
        if not G.TAROT_INTERRUPT_PULSE then G.FUNCS.text_super_juice(e, math.max(0,math.floor(math.log10(type(G.GAME.current_round.current_hand.pow) == 'number' and G.GAME.current_round.current_hand.pow or 1)))) end
    end
end


-- hook for the flames on the pow box
local flame_handler_ref = G.FUNCS.flame_handler
G.FUNCS.flame_handler = function(e)
  G.C.UI_POWLICK = G.C.UI_POWLICK or {1, 1, 1, 1}
  for i=1, 3 do
    G.C.UI_POWLICK[i] = math.min(math.max(((G.C.GREEN[i]*0.5+G.C.YELLOW[i]*0.5) + 0.1)^2, 0.1), 1)
  end
  return flame_handler_ref(e)
end

-- hook to fix scaling for negative numbers
local scale_number_ref = scale_number
scale_number = function(number, scale, max, e_switch_point)
  if type(number) == "number" and number < 0 then
    number = math.abs(number) * 10
  end
  return scale_number_ref(number, scale, max, e_switch_point)
end

-- hook for jokers to apply decay
local calculate_joker_ref = Card.calculate_joker
function Card:calculate_joker(context)
    local effect = calculate_joker_ref(self, context)
    if context.joker_main and self.ability.pow_decay then
        effect = effect or {}
        effect.pow_decay = -math.abs(self.ability.pow_decay)
    end
    return effect
end

-- hook for decay to show up on joker ui
local generate_card_ui_ref = generate_card_ui
generate_card_ui = function(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end, card)
    local ret = generate_card_ui_ref(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end, card)
    if _c and _c.set and _c.set == "Joker" and card and card.ability and card.ability.pow_decay and ret then
        localize{type = 'other', key = 'card_decay', nodes = ret.main, vars = {math.abs(card.ability.pow_decay)}}
    end
    return ret
end

-- function to get perma_pow from playing_cards
Card.get_pow_bonus = function (self)
    return self.ability.perma_pow and self.ability.perma_pow or 0
end