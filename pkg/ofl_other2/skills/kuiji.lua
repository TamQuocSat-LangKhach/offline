local kuiji = fk.CreateSkill {
  name = "ofl__kuiji"
}

Fk:loadTranslationTable{
  ['ofl__kuiji'] = '窥机',
  ['#ofl__kuiji'] = '窥机：你可以观看一名角色的手牌，弃置双方四种花色手牌',
  [':ofl__kuiji'] = '出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以弃置你与其共计四张花色各不相同的手牌。若如此做，弃置牌数较多的角色失去1点体力，弃置牌数较少的角色获得〖仇海〗直到本轮结束。',
  ['$ofl__kuiji1'] = '同道者为忠，殊途者为奸！',
  ['$ofl__kuiji2'] = '区区不才，可为帝之耳目，试问汝有何能？',
}

kuiji:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#ofl__kuiji",
  can_use = function(self, player)
    return player:usedSkillTimes(kuiji.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select.id ~= player.id and not Fk:currentRoom():getPlayerById(to_select.id):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askToPoxi(player, {
      poxi_type = kuiji.name,
      data = {
        { player.general, player:getCardIds("h") },
        { target.general, target:getCardIds("h") },
      },
      cancelable = true
    })
    if #cards == 0 then return end
    local cards1 = table.filter(cards, function(id) return table.contains(player:getCardIds("h"), id) end)
    local cards2 = table.filter(cards, function(id) return table.contains(target:getCardIds("h"), id) end)
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = kuiji.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = kuiji.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if #cards1 == #cards2 then return end
    local p1, p2 = player, target
    if #cards1 < #cards2 then
      p1, p2 = target, player
    end
    if not p1.dead then
      room:loseHp(p1, 1, kuiji.name)
    end
    if not p2.dead and not p2:hasSkill("chouhai", true) then
      room:handleAddLoseSkills(p2, "chouhai", nil, true, false)
      room.logic:getCurrentEvent():findParent(GameEvent.Round):addCleaner(function()
        room:handleAddLoseSkills(p2, "-chouhai", nil, true, false)
      end)
    end
  end,
})

return kuiji
