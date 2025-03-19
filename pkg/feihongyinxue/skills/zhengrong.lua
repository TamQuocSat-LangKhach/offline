local zhengrong = fk.CreateSkill {
  name = "fhyx__zhengrong"
}

Fk:loadTranslationTable{
  ['fhyx__zhengrong'] = '征荣',
  ['$fhyx__glory'] = '荣',
  ['#fhyx__zhengrong-exchange'] = '征荣：选择任意张手牌替换等量的“荣”',
  ['#fhyx__zhengrong-choose'] = '征荣：将一名其他角色的一张牌置为“荣”',
  [':fhyx__zhengrong'] = '转换技，锁定技，游戏开始时，你将牌堆顶一张牌置于武将牌上，称为“荣”。当你于出牌阶段对其他角色使用牌结算后，阳：你选择任意张手牌替换等量的“荣”；阴：你将一名其他角色的一张牌置为“荣”。',
}

zhengrong:addEffect({fk.GameStart, fk.CardUseFinished}, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) then
      if event == fk.GameStart then
        return true
      elseif event ==  fk.CardUseFinished then
        if target == player and player.phase == Player.Play and data.tos and
          table.find(TargetGroup:getRealTargets(data.tos), function (id)
            return id ~= player.id
          end) then
          if player:getSwitchSkillState(skill.name, false) == fk.SwitchYang then
            return not player:isKongcheng()
          else
            return table.find(player.room:getOtherPlayers(player, false), function (p)
              return not p:isNude()
            end)
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:addToPile("$fhyx__glory", room.draw_pile[1], false, skill.name, player.id)
    elseif event ==  fk.CardUseFinished then
      if player:getSwitchSkillState(skill.name, true) == fk.SwitchYang then
        local cards = room:askToArrangeCards(player, {
          card_map = {player:getPile("$fhyx__glory"), player:getCardIds("h")},
          skill_name = "#fhyx__zhengrong-exchange",
          free_arrange = true,
        })
        U.swapCardsWithPile(player, cards[1], cards[2], skill.name, "$fhyx__glory")
      else
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return not p:isNude()
        end)
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          skill_name = "#fhyx__zhengrong-choose",
        })
        to = room:getPlayerById(to[1])
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = skill.name
        })
        player:addToPile("$fhyx__glory", card, false, skill.name, player.id)
      end
    end
  end,
})

return zhengrong
