local juedian = fk.CreateSkill {
  name = "ofl__juedian"
}

Fk:loadTranslationTable{
  ['ofl__juedian'] = '决巅',
  ['ofl__juedian_beishui'] = '背水：此【决斗】伤害+1',
  ['#ofl__juedian-choice'] = '决巅：请选择一项，视为对 %dest 视为使用【决斗】',
  [':ofl__juedian'] = '锁定技，当你每回合首次使用指定唯一目标的牌造成伤害后，你选择一项，然后视为对受伤角色使用一张【决斗】：1.失去1点体力；2.减1点体力上限；背水：此【决斗】造成的伤害+1。',
}

juedian:addEffect(fk.Damage, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and data.card and
      not data.to.dead and player:canUseTo(Fk:cloneCard("duel"), data.to) then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event == nil then return end
      if #TargetGroup:getRealTargets(use_event.data[1].tos) ~= 1 then return end
      return #room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        return use.from == player.id and use.tos and #TargetGroup:getRealTargets(use.tos) == 1 and use.damageDealt
      end, Player.HistoryTurn) == 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"loseHp", "loseMaxHp", "ofl__juedian_beishui"},
      skill_name = skill.name,
      prompt = "#ofl__juedian-choice::" .. data.to.id
    })
    local card = Fk:cloneCard("duel")
    card.skillName = skill.name
    local use = {
      from = player.id,
      tos = {{data.to.id}},
      card = card,
    }
    if choice ~= "loseMaxHp" then
      room:loseHp(player, 1, skill.name)
    end
    if choice ~= "loseHp" and not player.dead then
      room:changeMaxHp(player, -1)
    end
    if choice == "ofl__juedian_beishui" and not player.dead then
      use.additionalDamage = 1
    end
    if not data.to.dead and player:canUseTo(card, data.to) then
      room:useCard(use)
    end
  end,
})

return juedian
