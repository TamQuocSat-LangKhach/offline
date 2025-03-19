local juqian = fk.CreateSkill {
  name = "juqian"
}

Fk:loadTranslationTable{
  ['juqian'] = '聚黔',
  ['#juqian-choose'] = '聚黔：你可以令至多两名角色选择成为起义军或你对其造成1点伤害',
  ['#juqian-ask'] = '聚黔：点“确定”加入起义军（起义军技能点击左上角查看），或点“取消” %src 对你造成1点伤害！',
  [':juqian'] = '锁定技，游戏开始时，你获得起义军标记，然后令至多两名不为一号位且非起义军角色依次选择一项：1.获得起义军标记；2.你对其造成1点伤害。',
}

juqian:addEffect(fk.GameStart, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(juqian.name)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if not IsInsurrectionary(player) then
      JoinInsurrectionary(player)
      room:handleAddLoseSkills(player, "insurrectionary&|-insurrectionary&", nil, false, true)  --迅速加载一下技能
    end
    local targets = table.filter(room.alive_players, function (p)
      return p.seat ~= 1 and not IsInsurrectionary(p)
    end)
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 2,
      prompt = "#juqian-choose",
      skill_name = juqian.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      for _, p in ipairs(tos) do
        if not p.dead then
          if not room:askToSkillInvoke(p, {
            skill_name = juqian.name,
            prompt = "#juqian-ask:" .. player.id,
          }) then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = juqian.name,
            }
          else
            JoinInsurrectionary(p)
          end
        end
      end
    end
  end,
})

return juqian
