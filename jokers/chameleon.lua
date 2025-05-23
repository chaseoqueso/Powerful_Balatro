SMODS.Joker{
    key = "Chameleon",
    rarity = 3,
    atlas = "Jokers",
    pos = {x = 7, y = 1},
    cost = 8,
    config = { extra = { pow = 0.1 } },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_wild
        return {
            vars = { card.ability.extra.pow }
        }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand and not context.end_of_round and not context.other_card.debuff and SMODS.has_enhancement(context.other_card, "m_wild") then
            return {
                pow = card.ability.extra.pow,
                card = context.other_card,
                message = localize{"a_pow"}
            }
        end
    end,
}