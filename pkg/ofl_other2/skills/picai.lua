local picai = fk.CreateSkill {
  name = "ofl__picai"
}

Fk:loadTranslationTable{
  ['ofl__picai'] = '庀材',
  ['#ofl__picai'] = '庀材：令至多%arg名角色依次将一张手牌置于牌堆顶',
  ['#ofl__picai-put'] = '庀材：请将一张手牌置于牌堆顶，%src 将根据类别摸牌',
  ['#ofl__picai-prey'] = '庀材：获得其中一张牌',
  [':ofl__picai'] = '出牌阶段限一次，你可以令至多X名角色依次将一张手牌置于牌堆顶，然后你亮出牌堆顶等量张牌：其中每有一种类型，你摸一张牌，若你摸了三张牌，因此失去牌的角色依次从亮出的牌中选择一张获得（X为你的体力值）。',
  ['$ofl__picai1'] = '修得广厦千万，可庇汉室不倾。',
  ['$ofl__picai2'] = '吾虽鄙夫，亦远胜尔等狂叟！'
}

picai:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function (player)
    return player.hp
  end,
  prompt = function(self, player, selected_cards, selected_targets)
    return "#ofl__picai:::"..player.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(picai.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < player.hp and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect, event)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead and not p:isKongcheng() then
        local card = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          pattern = ".|hand",
          prompt = "#ofl__picai-put:"..player.id,
          skill_name = picai.name,
        })
        room:moveCards({
          ids = card,
          from = p.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = picai.name,
          moveVisible = false,
          drawPilePosition = 1,
        })
      end
    end
    if player.dead then return end
    local cards = room:getNCards(#effect.tos)
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, picai.name, nil, true, player.id)
    local types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    if not player.dead then
      player:drawCards(#types, picai.name)
      if #types == 3 then
        for _, id in ipairs(effect.tos) do
          local p = room:getPlayerById(id)
          if not p.dead then
            cards = table.filter(cards, function (i)
              return room:getCardArea(i) == Card.Processing
            end)
            if #cards > 0 then
              local card = room:askToChooseCardsAndPlayers(p, {
                min_card_num = 1,
                max_card_num = 1,
                targets = { p.id },
                pattern = ".",
                prompt = "#ofl__picai-prey",
                skill_name = picai.name,
              })
              table.removeOne(cards, card[2][1])
              room:moveCardTo(card[2], Card.PlayerHand, p, fk.ReasonJustMove, picai.name, nil, true, p.id)
            else
              return
            end
          end
        end
      end
    end
    if #cards > 0 then
      room:cleanProcessingArea(cards)
    end
  end,
})

return picai
