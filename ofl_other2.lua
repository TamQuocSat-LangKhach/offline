local extension = Package("ofl_other2")
extension.extensionName = "offline"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ofl_other2"] = "线下-综合2",
}

local godzhangjiao = General(extension, "ofl__godzhangjiao", "god", 4)
godzhangjiao.total_hidden = true
local sanshou = fk.CreateTriggerSkill{
  name = "ofl__sanshou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.contains({Player.Start, Player.Finish}, data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.to = Player.Play
    local isDeputy = true
    if player.general == "ofl__godzhangjiao" then
      isDeputy = false
    end
    room:setPlayerMark(player, "ofl__sanshou-phase", isDeputy and 2 or 1)
    local result = room:askForCustomDialog(
      player, self.name,
      "packages/utility/qml/ChooseSkillFromGeneralBox.qml",
      {
        {"ofl__godzhangbao", "ofl__godzhangliang"},
        {Fk.generals["ofl__godzhangbao"]:getSkillNameList(), Fk.generals["ofl__godzhangliang"]:getSkillNameList()},
        "#ofl__sanshou-choose",
      }
    )
    if result == "" then
      result = "ofl__godzhangbao"
    else
      result = table.unpack(json.decode(result))
    end
    room:changeHero(player, result, false, isDeputy, true, false, false)
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("ofl__sanshou-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:changeHero(player, "ofl__godzhangjiao", false, player:getMark("ofl__sanshou-phase") == 2, true, false, false)
  end,
}
godzhangjiao:addSkill(sanshou)
Fk:loadTranslationTable{
  ["ofl__godzhangjiao"] = "神张角",
  ["#ofl__godzhangjiao"] = "万千",
  ["illustrator:ofl__godzhangjiao"] = "鬼画府",

  ["ofl__mingdao"] = "瞑道",
  [":ofl__mingdao"] = "游戏开始时，你可以将一张“众”置入你的装备区。",
  ["ofl__zhongfu"] = "众附",
  [":ofl__zhongfu"] = "每轮开始时，你可以声明一种花色，然后令手牌最少的角色依次选择一项：1.将一张牌置于牌堆顶；2.从牌堆底摸一张牌，"..
  "当以此法失去牌的角色造成伤害，你发动一次〖瞑道〗。",
  ["ofl__dangjing"] = "荡京",
  [":ofl__dangjing"] = "当你发动〖众附〗后，若你装备区内的牌为全场最多，你可以令一名角色进行一次判定，若为你〖众附〗声明的花色，你对其造成1点"..
  "雷电伤害并重复此流程。",
  ["ofl__sanshou"] = "三首",
  [":ofl__sanshou"] = "锁定技，你的准备阶段和结束阶段改为出牌阶段，并在此阶段将武将牌改为张宝或张梁。此阶段结束后把武将牌替换回张角。",

  ["#ofl__sanshou-choose"] = "三首：选择此阶段要变为的武将",
}

local godzhangbao = General(extension, "ofl__godzhangbao", "god", 4)
godzhangbao.hidden = true
local zhouyuan = fk.CreateActiveSkill{
  name = "ofl__zhouyuan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#ofl__zhouyuan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {}
    for _, id in ipairs(target:getCardIds("h")) do
      local color = Fk:getCardById(id):getColorString()
      if color ~= "nocolor" then
        table.insertIfNeed(choices, color)
      end
    end
    local color1 = room:askForChoice(target, choices, self.name, "#ofl__zhouyuan-choice:"..player.id, false, {"red", "black"})
    local color2 = color1 == "black" and "red" or "black"
    local cards = table.filter(target:getCardIds("h"), function (id)
      return Fk:getCardById(id):getColorString() == color1
    end)
    target:addToPile("ofl__zhoubing", cards, false, self.name, target.id)
    if not player.dead and not player:isKongcheng() then
      cards = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getColorString() == color2
      end)
      if #cards > 0 then
        player:addToPile(player:hasSkill("ofl__zhaobing") and "ofl__zhoubing&" or "ofl__zhoubing", cards, false, self.name, player.id)
      end
    end
  end,
}
local zhouyuan_delay = fk.CreateTriggerSkill{
  name = "#ofl__zhouyuan_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("ofl__zhoubing&") + #player:getPile("ofl__zhoubing") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local cards = table.simpleClone(player:getPile("ofl__zhoubing&"))
    table.insertTableIfNeed(cards, player:getPile("ofl__zhoubing"))
    player.room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, "ofl__zhouyuan")
  end,
}
local zhaobing = fk.CreateProhibitSkill{
  name = "ofl__zhaobing",
  prohibit_use = function(self, player, card)
    if not player:hasSkill(self) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and (table.find(subcards, function(id)
        return table.contains(player:getPile("ofl__zhoubing&"), id)
      end) or player.phase ~= Player.Play)
    end
  end,
  prohibit_response = function(self, player, card)
    if not player:hasSkill(self) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and (table.find(subcards, function(id)
        return table.contains(player:getPile("ofl__zhoubing&"), id)
      end) or player.phase ~= Player.Play)
    end
  end,
}
zhouyuan:addRelatedSkill(zhouyuan_delay)
godzhangbao:addSkill(zhouyuan)
godzhangbao:addSkill(zhaobing)
godzhangbao:addSkill("ofl__sanshou")
Fk:loadTranslationTable{
  ["ofl__godzhangbao"] = "神张宝",
  ["#ofl__godzhangbao"] = "万千",
  ["illustrator:ofl__godzhangbao"] = "NOVART",

  ["ofl__zhouyuan"] = "咒怨",
  [":ofl__zhouyuan"] = "出牌阶段限一次，你可以选择一名其他角色，其将所有黑色/红色手牌扣置于其武将牌上，你将所有红色/黑色手牌置于武将牌上，"..
  "这些牌称为“咒兵”。出牌阶段结束时，你与其收回“咒兵”。",
  ["ofl__zhaobing"] = "诏兵",
  [":ofl__zhaobing"] = "出牌阶段，你可以将“咒兵”如手牌般使用或打出。",
  ["#ofl__zhouyuan"] = "咒怨：令一名角色选择颜色，其将此颜色、你将另一种颜色的手牌置于武将牌上",
  ["#ofl__zhouyuan-choice"] = "咒怨：请选择一种颜色，你将此颜色、%src 将另一种颜色手牌分别置于武将牌上",
  ["#ofl__zhouyuan_delay"] = "咒怨",
  ["ofl__zhoubing"] = "咒兵",
  ["ofl__zhoubing&"] = "咒兵",

  ["$ofl__zhouyuan1"] = "习得一道新符，试试看吧！",
  ["$ofl__zhouyuan2"] = "这事，你管不了！",
  ["$ofl__zhaobing1"] = "此计成矣！",
  ["$ofl__zhaobing2"] = "哈哈，中招了吧！",
  ["~ofl__godzhangbao"] = "这咒不管用了吗……？",
}

local godzhangliang = General(extension, "ofl__godzhangliang", "god", 4)
godzhangliang.hidden = true
local jijun = fk.CreateTriggerSkill{
  name = "ofl__jijun",
  anim_type = "drawcard",
  derived_piles = "ofl__godzhangliang_fang",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to == player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
      skipDrop = true,
    }
    room:judge(judge)
    if room:getCardArea(judge.card) == Card.Processing then
      if player.dead then
        room:moveCardTo(judge.card, Card.DiscardPile, nil, fk.ReasonJudge)
      else
        local choice = room:askForChoice(player, {"ofl__jijun1", "ofl__jijun2"})
        if choice == "ofl__jijun1" then
          room:moveCardTo(judge.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
        else
          player:addToPile("ofl__godzhangliang_fang", judge.card, true, self.name, player.id)
        end
      end
    end
  end,
}
local fangtong = fk.CreateTriggerSkill{
  name = "ofl__fangtong",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      #player:getPile("ofl__godzhangliang_fang") > 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, nil, "#ofl__fangtong-invoke")
    if #card > 0 then
      self.cost_data = {cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 36 - Fk:getCardById(self.cost_data.cards[1]).number
    room:recastCard(self.cost_data.cards, player, self.name)
    if player.dead or #player:getPile("ofl__godzhangliang_fang") == 0 then return end
    room:setPlayerMark(player, "ofl__fangtong-tmp", n)
    local success, dat = room:askForUseActiveSkill(player, "ofl__fangtong_active", "#ofl__fangtong-damage:::"..n, true, nil, false)
    room:setPlayerMark(player, "ofl__fangtong-tmp", 0)
    if success and dat then
      room:moveCardTo(dat.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
      local to = room:getPlayerById(dat.targets[1])
      if not to.dead then
        room:damage {
          from = player,
          to = to,
          damage = 3,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local fangtong_active = fk.CreateActiveSkill{
  name = "ofl__fangtong_active",
  min_card_num = 1,
  target_num = 1,
  expand_pile = "ofl__godzhangliang_fang",
  card_filter = function (self, to_select, selected)
    if table.contains(Self:getPile("ofl__godzhangliang_fang"), to_select) then
      local num = 0
      for _, id in ipairs(selected) do
        num = num + Fk:getCardById(id).number
      end
      return num + Fk:getCardById(to_select).number <= Self:getMark("ofl__fangtong-tmp")
    end
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  feasible = function (self, selected, selected_cards)
    if #selected == 1 and #selected_cards > 0 then
      local num = 0
      for _, id in ipairs(selected_cards) do
        num = num + Fk:getCardById(id).number
      end
      return num == Self:getMark("ofl__fangtong-tmp")
    end
  end,
}
Fk:addSkill(fangtong_active)
godzhangliang:addSkill(jijun)
godzhangliang:addSkill(fangtong)
godzhangliang:addSkill("ofl__sanshou")
Fk:loadTranslationTable{
  ["ofl__godzhangliang"] = "神张梁",
  ["#ofl__godzhangliang"] = "万千",
  ["illustrator:ofl__godzhangliang"] = "王强",

  ["ofl__jijun"] = "集军",
  [":ofl__jijun"] = "当你使用牌指定你为目标后，你可以进行判定，然后选择一项：1.获得此牌；2.将判定牌置于武将牌上，称为“方”。",
  ["ofl__fangtong"] = "方统",
  [":ofl__fangtong"] = "出牌阶段结束时，若有“方”，你可以重铸一张手牌，若你重铸的牌与你的任意“方”点数之和为36，你可以将对应的“方”置入弃牌堆，"..
  "然后对一名其他角色造成3点雷电伤害。",
  ["ofl__godzhangliang_fang"] = "方",
  ["ofl__jijun1"] = "获得判定牌",
  ["ofl__jijun2"] = "将判定牌置为“方”",
  ["#ofl__fangtong-invoke"] = "方统：你可以重铸一张手牌，然后移去与此牌点数之和为36的“方”，对一名角色造成3点雷电伤害！",
  ["ofl__fangtong_active"] = "方统",
  ["#ofl__fangtong-damage"] = "方统：移去点数之和为%arg的“方”，对一名角色造成3点雷电伤害！",

  ["$ofl__jijun1"] = "民军虽散，也可撼树。",
  ["$ofl__jijun2"] = "集天下万民，成百姓万军。",
  ["$ofl__fangtong1"] = "三十六方，雷电烁。",
  ["$ofl__fangtong2"] = "合方三十六统，散太平大道。",
  ["~ofl__godzhangliang"] = "黄天之道，哥哥我们错了吗？",
}

local yanzhengh = General(extension, "yanzhengh", "qun", 4)
local dishi = fk.CreateTriggerSkill{
  name = "ofl__dishi",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:isWounded() and
      not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "ofl__dishi_viewas", "#ofl__dishi-invoke", true,
    {
      bypass_distances = true,
      bypass_times = true,
    })
    if success and dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk:cloneCard("slash")
    card:addSubcards(player:getCardIds("h"))
    card.skillName = self.name
    local use = {
      from = player.id,
      tos = table.map(self.cost_data.targets, function (id) return {id} end),
      card = card,
      extraUse = true,
      additionalDamage = player:getHandcardNum() - 1,
    }
    player.room:useCard(use)
  end,
}
local dishi_viewas = fk.CreateViewAsSkill{
  name = "ofl__dishi_viewas",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card:addSubcards(Self:getCardIds("h"))
    card.skillName = "ofl__dishi"
    return card
  end,
}
local xianxiang = fk.CreateTriggerSkill{
  name = "ofl__xianxiang",
  anim_type = "support",
  events = {fk.Death},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage and data.damage.from == player and #player.room.alive_players > 1 and
      not target:isAllNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#ofl__xianxiang-invoke::"..target.id, self.name, false)
    room:moveCardTo(target:getCardIds("hej"), Card.PlayerHand, to[1], fk.ReasonJustMove, self.name, nil, false, player.id)
  end,
}
Fk:addSkill(dishi_viewas)
yanzhengh:addSkill(dishi)
yanzhengh:addSkill(xianxiang)
Fk:loadTranslationTable{
  ["yanzhengh"] = "严政",
  ["#yanzhengh"] = "",
  ["illustrator:yanzhengh"] = "",

  ["ofl__dishi"] = "地逝",
  [":ofl__dishi"] = "限定技，出牌阶段开始时，若你已受伤，你可以将所有手牌当一张无距离限制且伤害为X的【杀】使用（X为你的手牌数）。",
  ["ofl__xianxiang"] = "献降",
  [":ofl__xianxiang"] = "锁定技，当你杀死一名角色时，你令一名其他角色获得死亡角色区域内的所有牌。",
  ["ofl__dishi_viewas"] = "地逝",
  ["#ofl__dishi-invoke"] = "地逝：你可以将所有手牌当一张无距离限制的【杀】使用，伤害为牌数！",
  ["#ofl__xianxiang-invoke"] = "献降：令一名其他角色获得 %dest 区域内所有牌",
}

local bairao = General(extension, "bairao", "qun", 5)
local xyin = fk.CreateTriggerSkill{
  name = "ofl__xyin",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.extra_data or {}).ofl__xyin
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if not data.to.dead then
      U.askForPlayCard(room, data.to, nil, nil, self.name, "#ofl__xyin-use", {
        bypass_times = true,
        extraUse = true,
      })
    end
  end,

  refresh_events = {fk.BeforeHpChanged},
  can_refresh = function(self, event, target, player, data)
    return data.damageEvent and data.damageEvent.from == player and
      player:inMyAttackRange(target) and target:inMyAttackRange(player)
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.ofl__xyin = true
  end,
}
local xyin_targetmod = fk.CreateTargetModSkill{
  name = "#ofl__xyin_targetmod",
  frequency = Skill.Compulsory,
  main_skill = xyin,
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(xyin) and card and card.trueName == "slash" and
      to and player:inMyAttackRange(to) and to:inMyAttackRange(player)
  end,
}
xyin:addRelatedSkill(xyin_targetmod)
bairao:addSkill(xyin)
Fk:loadTranslationTable{
  ["bairao"] = "白绕",
  ["#bairao"] = "",
  ["illustrator:bairao"] = "",

  ["ofl__xyin"] = "技能",
  [":ofl__xyin"] = "锁定技，你对攻击范围内含有你且你攻击范围内有其的其他角色：使用【杀】无次数限制；当你对这些角色造成伤害后，你摸一张牌，"..
  "然后其选择是否使用一张牌。",
  ["#ofl__xyin-use"] = "技能：你可以使用一张牌",
}

local busi = General(extension, "busi", "qun", 4, 6)
local weiluan = fk.CreateTriggerSkill{
  name = "ofl__weiluan",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      table.contains({Player.Start, Player.Draw, Player.Play}, player.phase)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and not player.dead then
      local mark = player:getMark("@ofl__weiluan")
      if player.phase == Player.Start then
        mark[1] = mark[1] + 1
      elseif player.phase == Player.Draw then
        mark[2] = mark[2] + 1
      elseif player.phase == Player.Play then
        mark[3] = mark[3] + 1
      end
      room:setPlayerMark(player, "@ofl__weiluan", mark)
    end
  end,

  refresh_events = {fk.DrawNCards},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@ofl__weiluan") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n + player:getMark("@ofl__weiluan")[2]
  end,

  on_acquire = function (self, player, is_start)
    player.room:setPlayerMark(player, "@ofl__weiluan", {0, 0, 0})
  end,
}
local weiluan_attackrange = fk.CreateAttackRangeSkill{
  name = "#ofl__weiluan_attackrange",
  correct_func = function (self, from, to)
    if from:getMark("@ofl__weiluan") ~= 0 then
      return from:getMark("@ofl__weiluan")[1]
    end
    return 0
  end,
}
local weiluan_targetmod = fk.CreateTargetModSkill{
  name = "#ofl__weiluan_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@ofl__weiluan") ~= 0 and scope == Player.HistoryPhase then
      return player:getMark("@ofl__weiluan")[3]
    end
  end,
}
local tianpan = fk.CreateTriggerSkill{
  name = "ofl__tianpan",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.FinishJudge},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if data.card.suit == Card.Spade then
      room:notifySkillInvoked(player, self.name, "support")
      if room:getCardArea(data.card) == Card.Processing then
        room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
        if player.dead then return end
      end
      local choices = {"ofl__tianpan1"}
      if player:isWounded() then
        table.insert(choices, "recover")
      end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "ofl__tianpan1" then
        room:changeMaxHp(player, 1)
      else
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    else
      room:notifySkillInvoked(player, self.name, "negative")
      local choice = room:askForChoice(player, {"loseMaxHp", "loseHp"}, self.name)
      if choice == "loseMaxHp" then
        room:changeMaxHp(player, -1)
      else
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
local gaiming = fk.CreateTriggerSkill{
  name = "ofl__gaiming",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (not data.card or data.card.suit ~= Card.Spade) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local move1 = {
      ids = room:getNCards(1),
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    }
    local move2 = {
      ids = {data.card:getEffectiveId()},
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    room:moveCards(move1, move2)
    data.card = Fk:getCardById(move1.ids[1])
    room:sendLog{
      type = "#ChangedJudge",
      from = player.id,
      to = {player.id},
      card = {move1.ids[1]},
      arg = self.name
    }
  end,
}
weiluan:addRelatedSkill(weiluan_attackrange)
weiluan:addRelatedSkill(weiluan_targetmod)
busi:addSkill(weiluan)
busi:addSkill(tianpan)
busi:addSkill(gaiming)
Fk:loadTranslationTable{
  ["busi"] = "卜巳",
  ["#busi"] = "",
  ["illustrator:busi"] = "",

  ["ofl__weiluan"] = "为乱",
  [":ofl__weiluan"] = "锁定技，准备阶段/摸牌阶段/出牌阶段开始时，你进行判定，若结果为♠，你的攻击范围/摸牌阶段摸牌数/使用【杀】次数上限+1。",
  ["ofl__tianpan"] = "天判",
  [":ofl__tianpan"] = "锁定技，当你的判定牌生效后，若结果：为♠，你获得此牌，然后你回复1点体力或加1点体力上限；不为♠，你失去1点体力或减1点体力上限。",
  ["ofl__gaiming"] = "改命",
  [":ofl__gaiming"] = "每回合限一次，当你的判定牌生效前，若结果不为♠，你可以亮出牌堆顶的一张牌代替之。",
  ["@ofl__weiluan"] = "为乱",
  ["ofl__tianpan1"] = "加1点体力上限",
}

local suigu = General(extension, "suigu", "qun", 5)
local tuntians = fk.CreateTriggerSkill{
  name = "ofl__tuntians",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ofl__tuntians", 1)
  end,
}
local tuntians_delay = fk.CreateTriggerSkill{
  name = "#ofl__tuntians_delay",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards, fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    if target == player and player:getMark("@ofl__tuntians") > 0 then
      if event == fk.DrawNCards then
        return true
      elseif event == fk.DamageInflicted then
        return #player.room.logic:getEventsOfScope(GameEvent.Damage, 2, function (e)
          return e.data[1].to == player
        end, Player.HistoryTurn) == 1
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ofl__tuntians")
    if event == fk.DrawNCards then
      room:notifySkillInvoked(player, "ofl__tuntians", "drawcard")
      data.n = data.n + player:getMark("@ofl__tuntians")
    elseif event == fk.DamageInflicted then
      room:notifySkillInvoked(player, "ofl__tuntians", "negative")
      data.damage = data.damage + player:getMark("@ofl__tuntians")
    end
  end,
}
local tuntians_maxcards = fk.CreateMaxCardsSkill{
  name = "#ofl__tuntians_maxcards",
  correct_func = function(self, player)
    return player:getMark("@ofl__tuntians")
  end,
}
local qianjun = fk.CreateActiveSkill{
  name = "ofl__qianjun",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#ofl__qianjun",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      #player:getCardIds("e") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, "@ofl__tuntians", 0)
    room:moveCardTo(player:getCardIds("e"), Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
    room:swapSeat(player, target)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "luanji", nil, true, false)
  end,
}
tuntians:addRelatedSkill(tuntians_delay)
tuntians:addRelatedSkill(tuntians_maxcards)
suigu:addSkill(tuntians)
suigu:addSkill(qianjun)
suigu:addRelatedSkill("luanji")
Fk:loadTranslationTable{
  ["suigu"] = "眭固",
  ["#suigu"] = "",
  ["illustrator:suigu"] = "",

  ["ofl__tuntians"] = "屯天",
  [":ofl__tuntians"] = "锁定技，准备阶段，你令你本局游戏摸牌阶段的摸牌数，手牌上限和每回合首次受到的伤害+1，直到你发动〖迁军〗。",
  ["ofl__qianjun"] = "迁军",
  [":ofl__qianjun"] = "限定技，出牌阶段，你可以交给一名其他角色装备区里的所有牌并与其交换座次，然后你回复1点体力并获得〖乱击〗。",
  ["@ofl__tuntians"] = "屯天",
  ["#ofl__tuntians_delay"] = "屯天",
  ["#ofl__qianjun"] = "迁军：将所有装备交给一名角色并与其交换座次，你回复1点体力并获得〖乱击〗！",
}

local heman = General(extension, "heman", "qun", 5, 6)
local juedian = fk.CreateTriggerSkill{
  name = "ofl__juedian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and
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
    local choice = room:askForChoice(player, {"loseHp", "loseMaxHp", "ofl__juedian_beishui"}, self.name,
      "#ofl__juedian-choice::"..data.to.id)
    local card = Fk:cloneCard("duel")
    card.skillName = self.name
    local use = {
      from = player.id,
      tos = {{data.to.id}},
      card = card,
    }
    if choice ~= "loseMaxHp" then
      room:loseHp(player, 1, self.name)
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
}
local nitian = fk.CreateActiveSkill{
  name = "ofl__nitian",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#ofl__nitian",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
}
local nitian_delay = fk.CreateTriggerSkill{
  name = "#ofl__nitian_delay",
  mute = true,
  events = {fk.CardUsing, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes("ofl__nitian", Player.HistoryTurn) > 0 then
      if event == fk.CardUsing then
        return data.card.trueName == "slash" or data.card:isCommonTrick()
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Finish and
        #player.room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
          local death = e.data[1]
          return death.damage and death.damage.from == player
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ofl__nitian")
    if event == fk.CardUsing then
      room:notifySkillInvoked(player, "ofl__nitian", "offensive")
      data.unoffsetableList = table.map(room.alive_players, Util.IdMapper)
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "ofl__nitian", "negative")
      room:killPlayer({who = player.id})
    end
  end,
}
nitian:addRelatedSkill(nitian_delay)
heman:addSkill(juedian)
heman:addSkill(nitian)
Fk:loadTranslationTable{
  ["heman"] = "何曼",
  ["#heman"] = "截天夜叉",
  ["illustrator:heman"] = "千秋秋千秋",

  ["ofl__juedian"] = "决巅",
  [":ofl__juedian"] = "锁定技，当你每回合首次使用指定唯一目标的牌造成伤害后，你选择一项，然后视为对受伤角色使用一张【决斗】：1.失去1点体力；"..
  "2.减1点体力上限；背水：此【决斗】造成的伤害+1。",
  ["ofl__nitian"] = "逆天",
  [":ofl__nitian"] = "限定技，出牌阶段，令你本回合使用牌不能被抵消；结束阶段，若你本回合未杀死角色，你死亡。",
  ["ofl__juedian_beishui"] = "背水：此【决斗】伤害+1",
  ["#ofl__juedian-choice"] = "决巅：请选择一项，视为对 %dest 视为使用【决斗】",
  ["#ofl__nitian"] = "逆天：令你本回合使用牌不能被抵消，若本回合未杀死角色则死亡！",
  ["#ofl__nitian_delay"] = "逆天",
}

local yudu = General(extension, "yudu", "qun", 4)
local dafu = fk.CreateTriggerSkill{
  name = "ofl__dafu",
  anim_type = "offensive",
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.is_damage_card
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, nil, "#ofl__dafu-invoke::"..data.to..":"..data.card:toLogString()) then
      self.cost_data = {tos = {data.to}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, data.to)
    player.room:getPlayerById(data.to):drawCards(1, self.name)
  end,
}
local jipin = fk.CreateTriggerSkill{
  name = "ofl__jipin",
  anim_type = "control",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getHandcardNum() < data.to:getHandcardNum() and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(target, self.name, nil, "#ofl__jipin-invoke::"..data.to.id) then
      self.cost_data = {tos = {data.to}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCardChosen(target, data.to, "h", self.name, "#ofl__jipin-prey::"..data.to.id)
    room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonPrey, self.name, nil, false, target.id)
    if player.dead or not table.contains(player:getCardIds("h"), card) or #room:getOtherPlayers(player) == 0 then return end
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#ofl__jipin-give:::"..Fk:getCardById(card):toLogString(), self.name, true)
    if #to > 0 then
      room:moveCardTo(card, Card.PlayerHand, to[1], fk.ReasonGive, self.name, nil, false, target.id)
    end
  end,
}
yudu:addSkill(dafu)
yudu:addSkill(jipin)
Fk:loadTranslationTable{
  ["yudu"] = "于毒",
  ["#yudu"] = "",
  ["illustrator:yudu"] = "",

  ["ofl__dafu"] = "打富",
  [":ofl__dafu"] = "当你使用伤害牌指定目标后，你可以令目标角色摸一张牌，然后其不能响应此牌。",
  ["ofl__jipin"] = "济贫",
  [":ofl__jipin"] = "当你对手牌数大于你的角色造成伤害后，你可以获得其一张手牌，然后可以将之交给一名其他角色。",
  ["#ofl__dafu-invoke"] = "打富：是否令 %dest 摸一张牌，其不能响应此%arg？",
  ["#ofl__jipin-invoke"] = "济贫：是否获得 %dest 一张手牌？",
  ["#ofl__jipin-prey"] = "济贫：获得 %dest 一张手牌",
  ["#ofl__jipin-give"] = "济贫：你可以将这张%arg交给一名其他角色",
}

local tangzhou = General(extension, "tangzhou", "qun", 4)
local jukou = fk.CreateActiveSkill{
  name = "ofl__jukou",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function (self)
    return "#"..self.interaction.data
  end,
  interaction = function ()
    return UI.ComboBox {choices = {"ofl__jukou1", "ofl__jukou2"}}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, cards)
    if #selected == 0 then
      if self.interaction.data == "ofl__jukou1" then
        return true
      elseif self.interaction.data == "ofl__jukou2" then
        for _, ids in pairs(Fk:currentRoom():getPlayerById(to_select).special_cards) do
          if #ids > 0 then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@"..self.interaction.data.."-turn", 1)
    if self.interaction.data == "ofl__jukou1" then
      target:drawCards(1, self.name)
    elseif self.interaction.data == "ofl__jukou2" then
      local cards = {}
      for _, ids in pairs(target.special_cards) do
        table.insertTableIfNeed(cards, ids)
      end
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonJustMove, self.name, nil, false, target.id)
    end
  end,
}
local jukou_prohibit = fk.CreateProhibitSkill{
  name = "#ofl__jukou_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@ofl__jukou1-turn") > 0 and card.trueName == "slash" then
      return true
    end
    if player:getMark("@@ofl__jukou2-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
}
local weipan = fk.CreateActiveSkill{
  name = "ofl__weipan",
  anim_type = "control",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 2,
  prompt = "#ofl__weipan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return end
    if #selected == 0 then
      return not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
    elseif #selected == 1 then
      return true
    end
  end,
  feasible = function (self, selected, selected_cards)
    return #selected == 2 and not Fk:currentRoom():getPlayerById(selected[1]):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    target1:showCards(target1:getCardIds("h"))
    if not player.dead then
      player:drawCards(3, self.name)
    end
    if not target2.dead then
      target2:drawCards(3, self.name)
    end
    if target1.dead or target2.dead then return end
    room:addTableMark(target1, "@@ofl__weipan", target2.id)
    room:addTableMark(target2, "@@ofl__weipan", target1.id)
    local cards = table.filter(target2:getCardIds("h"), function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    while not target1.dead and not target2.dead do
      cards = table.filter(cards, function (id)
        local card = Fk:getCardById(id)
        return table.contains(target2:getCardIds("h"), id) and card.is_damage_card and
          target2:canUseTo(card, target1, {bypass_distances = true, bypass_times = true})
      end)
      if #cards > 0 then
        local card = Fk:getCardById(cards[1])
        table.remove(cards, 1)
        room:useCard{
          from = target2.id,
          tos = {{target1.id}},
          card = card,
        }
      else
        break
      end
    end
  end,
}
local weipan_targetmod = fk.CreateTargetModSkill{
  name = "#ofl__weipan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(player:getTableMark("@@ofl__weipan"), to.id)
  end,
}
jukou:addRelatedSkill(jukou_prohibit)
weipan:addRelatedSkill(weipan_targetmod)
tangzhou:addSkill(jukou)
tangzhou:addSkill(weipan)
Fk:loadTranslationTable{
  ["tangzhou"] = "唐周",
  ["#tangzhou"] = "",
  ["illustrator:tangzhou"] = "",

  ["ofl__jukou"] = "举寇",
  [":ofl__jukou"] = "出牌阶段限一次，你可以令一名角色摸一张牌/获得其武将牌上的所有牌，然后其本回合不能使用【杀】/手牌。",
  ["ofl__weipan"] = "违叛",
  [":ofl__weipan"] = "限定技，出牌阶段，你可以选择两名其他角色：展示第一名角色的所有手牌，你与第二名角色各摸三张牌，然后其对第一名角色依次使用"..
  "手牌中所有伤害牌；这两名角色互相使用牌无次数限制直到游戏结束。",
  ["#ofl__jukou1"] = "举寇：令一名角色摸一张牌，其本回合不能使用【杀】",
  ["#ofl__jukou2"] = "举寇：令一名角色获得其武将牌上的牌，其本回合不能使用手牌",
  ["ofl__jukou1"] = "摸一张牌",
  ["ofl__jukou2"] = "获得武将牌上的牌",
  ["@@ofl__jukou1-turn"] = "禁止使用杀",
  ["@@ofl__jukou2-turn"] = "禁止使用手牌",
  ["#ofl__weipan"] = "违叛：选择两名角色，展示第一名角色的手牌，你与第二名角色各摸三张牌，然后后者对前者使用伤害牌！",
  ["@@ofl__weipan"] = "违叛",
}

local bocai = General(extension, "bocai", "qun", 5)
local weijun = fk.CreateTriggerSkill{
  name = "ofl__weijun",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DrawInitialCards, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DrawInitialCards then
        return target == player
      elseif event == fk.CardUsing and (data.card.trueName == "slash" or data.card:isCommonTrick()) then
        if target == player then
          return table.find(player.room.alive_players, function (p)
            return player:getHandcardNum() > p:getHandcardNum()
          end)
        else
          return target:getHandcardNum() > player:getHandcardNum()
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DrawInitialCards then
      room:notifySkillInvoked(player, self.name, "drawcard")
      data.num = data.num + 4
    elseif event == fk.CardUsing then
      data.disresponsiveList = data.disresponsiveList or {}
      if target == player then
        room:notifySkillInvoked(player, self.name, "offensive")
        for _, p in ipairs(room.alive_players) do
          if player:getHandcardNum() > p:getHandcardNum() then
            table.insertIfNeed(data.disresponsiveList, p.id)
          end
        end
      else
        room:notifySkillInvoked(player, self.name, "negative")
        table.insertIfNeed(data.disresponsiveList, player.id)
      end
    end
  end,
}
local yingzhan = fk.CreateTriggerSkill{
  name = "ofl__yingzhan",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "offensive")
    elseif event == fk.DamageInflicted then
      room:notifySkillInvoked(player, self.name, "negative")
    end
    data.damage = data.damage + 1
  end,
}
local cuiji = fk.CreateTriggerSkill{
  name = "ofl__cuiji",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Play and not target.dead and
      player:getHandcardNum() > target:getHandcardNum() and
      player:canUseTo(Fk:cloneCard("thunder__slash"), target, {bypass_distances = true})
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum() - target:getHandcardNum()
    room:setPlayerMark(player, "ofl__cuiji-tmp", n)
    local success, dat = room:askForUseActiveSkill(player, "ofl__cuiji_viewas",
      "#ofl__cuiji-invoke::"..target.id..":"..n, true, {
        bypass_distances = true,
        bypass_times = true,
        must_targets = {target.id},
      })
    room:setPlayerMark(player, "ofl__cuiji-tmp", 0)
    if success and dat then
      self.cost_data = {cards = dat.cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = room:useVirtualCard("thunder__slash", self.cost_data.cards, player, target, self.name, true)
    if use.damageDealt and not player.dead then
      player:drawCards(#self.cost_data.cards, self.name)
    end
  end,
}
local cuiji_viewas = fk.CreateViewAsSkill{
  name = "ofl__cuiji_viewas",
  card_filter = function (self, to_select, selected)
    return table.contains(Self:getCardIds("h"), to_select)-- and #selected < Self:getMark("ofl__cuiji-tmp")
  end,
  view_as = function(self, cards)
    --if #cards ~= Self:getMark("ofl__cuiji-tmp") then return end
    if #cards == 0 then return end
    local card = Fk:cloneCard("thunder__slash")
    card.skillName = "ofl__cuiji"
    card:addSubcards(cards)
    return card
  end,
}
Fk:addSkill(cuiji_viewas)
bocai:addSkill(weijun)
bocai:addSkill(yingzhan)
bocai:addSkill(cuiji)
Fk:loadTranslationTable{
  ["bocai"] = "波才",
  ["#bocai"] = "",
  ["illustrator:bocai"] = "HOOO",

  ["ofl__weijun"] = "围军",
  [":ofl__weijun"] = "锁定技，你的初始手牌数+4，手牌数小于你的角色不能响应你使用的牌，你不能响应手牌数大于你的角色使用的牌。",
  ["ofl__yingzhan"] = "营战",
  [":ofl__yingzhan"] = "锁定技，你造成或受到的属性伤害+1。",
  ["ofl__cuiji"] = "摧击",
  [":ofl__cuiji"] = "其他角色的出牌阶段开始时，若你手牌数大于其，你可以将X张手牌当一张雷【杀】对其使用，"..
  "若你以此法造成了伤害，你摸等量的牌。",
  ["ofl__cuiji_viewas"] = "摧击",
  ["#ofl__cuiji-invoke"] = "摧击：你可以将任意张手牌当雷【杀】对 %dest 使用，若造成伤害你摸等量牌",
}

local chengyuanzhi = General(extension, "chengyuanzhi", "qun", 5)
local wuxin = fk.CreateTriggerSkill{
  name = "ofl__wuxin",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@@ofl__wuxin-turn", 1)
  end,
}
local wuxin_delay = fk.CreateTriggerSkill{
  name = "#ofl__wuxin_delay",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@ofl__wuxin-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ofl__wuxin")
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, "ofl__wuxin", "offensive")
    elseif event == fk.DamageInflicted then
      room:notifySkillInvoked(player, "ofl__wuxin", "negative")
    end
    data.damage = data.damage + player:getMark("@@ofl__wuxin-turn")
    room:setPlayerMark(player, "@@ofl__wuxin-turn", 0)
  end,
}
local qianhu = fk.CreateViewAsSkill{
  name = "ofl__qianhu",
  anim_type = "offensive",
  prompt = "#ofl__qianhu",
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:getCardById(to_select).color == Card.Red and not Self:prohibitDiscard(to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then return end
    local card = Fk:cloneCard("duel")
    card.skillName = self.name
    self.cost_data = cards
    return card
  end,
  before_use = function(self, player, use)
    player.room:throwCard(self.cost_data, self.name, player, player)
  end,
  after_use = function (self, player, use)
    if not player.dead then
      if use.damageDealt and
        table.find(player.room:getOtherPlayers(player, false, true), function (p)
          return use.damageDealt[p.id]
        end) then
        player:drawCards(1, self.name)
      end
    end
  end,
}
wuxin:addRelatedSkill(wuxin_delay)
chengyuanzhi:addSkill(wuxin)
chengyuanzhi:addSkill(qianhu)
Fk:loadTranslationTable{
  ["chengyuanzhi"] = "程远志",
  ["#chengyuanzhi"] = "",
  ["illustrator:chengyuanzhi"] = "HOOO",

  ["ofl__wuxin"] = "武衅",
  [":ofl__wuxin"] = "锁定技，当每回合首次有红色牌进入弃牌堆后，你本回合下次造成或受到的伤害+1。",
  ["ofl__qianhu"] = "前呼",
  [":ofl__qianhu"] = "出牌阶段，你可以弃置两张红色牌视为使用一张【决斗】，若你造成了伤害，你摸一张牌。",
  ["@@ofl__wuxin-turn"] = "造成/受到伤害+1",
  ["#ofl__wuxin_delay"] = "武衅",
  ["#ofl__qianhu"] = "前呼：弃置两张红色牌视为使用【决斗】，若你造成伤害则摸一张牌",
}

local dengmao = General(extension, "dengmao", "qun", 5)
local paoxi = fk.CreateTriggerSkill{
  name = "ofl__paoxi",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.firstTarget then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local info = {}
      local events = player.room.logic:getEventsByRule(GameEvent.UseCard, 2, function (e)
        info = {e.data[1].from, e.data[1].tos}
        return true
      end, turn_event.id)
      if #events < 2 or #info == 0 then return end
      self.cost_data = {}
      if player:getMark("ofl__paoxi1-turn") == 0 then
        if table.contains(AimGroup:getAllTargets(data.tos), player.id) and info[2] and
          table.contains(TargetGroup:getRealTargets(info[2]), player.id) then
          table.insert(self.cost_data, 1)
        end
      end
      if player:getMark("ofl__paoxi2-turn") == 0 then
        if target == player and info[1] == player.id and info[2] then
          table.insert(self.cost_data, 2)
        end
      end
      return #self.cost_data > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for i = 1, 2, 1 do
      if table.contains(self.cost_data, i) then
        room:setPlayerMark(player, "ofl__paoxi"..i.."-turn", 1)
        room:addPlayerMark(player, "@@ofl__paoxi"..i.."-turn", 1)
      end
    end
  end,
}
local paoxi_delay = fk.CreateTriggerSkill{
  name = "#ofl__paoxi_delay",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    if target == player then
      if event == fk.DamageCaused then
        return player:getMark("@@ofl__paoxi2-turn") > 0
      elseif event == fk.DamageInflicted then
        return player:getMark("@@ofl__paoxi1-turn") > 0
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ofl__paoxi")
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, "ofl__paoxi", "offensive")
      data.damage = data.damage + player:getMark("@@ofl__paoxi2-turn")
      room:setPlayerMark(player, "@@ofl__paoxi2-turn", 0)
    elseif event == fk.DamageInflicted then
      room:notifySkillInvoked(player, "ofl__paoxi", "negative")
      data.damage = data.damage + player:getMark("@@ofl__paoxi1-turn")
      room:setPlayerMark(player, "@@ofl__paoxi1-turn", 0)
    end
  end,
}
local houying = fk.CreateViewAsSkill{
  name = "ofl__houying",
  anim_type = "offensive",
  prompt = "#ofl__houying",
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:getCardById(to_select).color == Card.Black and not Self:prohibitDiscard(to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    self.cost_data = cards
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    player.room:throwCard(self.cost_data, self.name, player, player)
  end,
  after_use = function (self, player, use)
    if not player.dead then
      if use.damageDealt and
        table.find(player.room:getOtherPlayers(player, false, true), function (p)
          return use.damageDealt[p.id]
        end) then
        player:drawCards(1, self.name)
      end
    end
  end,
}
local houying_targetmod = fk.CreateTargetModSkill{
  name = "#ofl__houying_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return skill.trueName == "slash_skill" and scope == Player.HistoryPhase and card and table.contains(card.skillNames, "ofl__houying")
  end,
}
houying:addRelatedSkill(houying_targetmod)
paoxi:addRelatedSkill(paoxi_delay)
dengmao:addSkill(paoxi)
dengmao:addSkill(houying)
Fk:loadTranslationTable{
  ["dengmao"] = "邓茂",
  ["#dengmao"] = "",
  ["illustrator:dengmao"] = "HOOO",

  ["ofl__paoxi"] = "咆袭",
  [":ofl__paoxi"] = "锁定技，每回合各限一次，当你连续成为牌/使用牌指定目标后，你本回合下次受到/造成的伤害+1。",
  ["ofl__houying"] = "后应",
  [":ofl__houying"] = "出牌阶段，你可以弃置两张黑色牌并视为使用一张无次数限制的【杀】，若你造成了伤害，你摸一张牌。",
  ["@@ofl__paoxi1-turn"] = "受到伤害+1",
  ["@@ofl__paoxi2-turn"] = "造成伤害+1",
  ["#ofl__houying"] = "后应：弃置两张黑色牌视为使用【杀】，若你造成伤害则摸一张牌",
}

local gaosheng = General(extension, "gaosheng", "qun", 5)
local xiongshi = fk.CreateActiveSkill{
  name = "ofl__xiongshi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#ofl__xiongshi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(Self:getCardIds("h"), to_select)
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):hasSkill(self)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:addToPile(self.name, effect.cards, false, self.name, effect.from)
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      room:handleAddLoseSkills(p, "ofl__xiongshi&", nil, false, true)
    end
  end,
  on_lose = function (self, player, is_death)
    local room = player.room
    if not table.find(room:getOtherPlayers(player), function (p)
      return p:hasSkill(self, true)
    end) then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "-ofl__xiongshi&", nil, false, true)
      end
    end
  end,
}
local xiongshi_active = fk.CreateActiveSkill{
  name = "ofl__xiongshi&",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#ofl__xiongshi&",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(Self:getCardIds("h"), to_select)
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):hasSkill(xiongshi)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:addToPile("ofl__xiongshi", effect.cards, false, "ofl__xiongshi", effect.from)
  end,
}
local difeng = fk.CreateTriggerSkill{
  name = "ofl__difeng",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        local targets = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.PlayerSpecial and move.proposer then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea ~= Card.PlayerSpecial then
                table.insert(targets, move.proposer)
              end
            end
          end
        end
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      else
        if target == player and data.from and not data.from.dead then
          for _, ids in pairs(player.special_cards) do
            if #ids > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    if event == fk.AfterCardsMove then
      for _, id in ipairs(self.cost_data) do
        if not player:hasSkill(self) then return end
        self:doCost(event, player.room:getPlayerById(id), player, data)
      end
    else
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
      if not target.dead then
        target:drawCards(1, self.name)
      end
    else
      local cards = {}
      for _, ids in pairs(player.special_cards) do
        table.insertTableIfNeed(cards, ids)
      end
      local card = room:askForCard(data.from, 1, 1, false, self.name, true, tostring(Exppattern{ id = cards }),
        "#ofl__difeng-invoke:"..player.id..":"..data.to.id, cards)
      if #card > 0 then
        if event == fk.DamageCaused then
        room:notifySkillInvoked(player, self.name, "offensive")
        elseif event == fk.DamageInflicted then
          room:notifySkillInvoked(player,self.name, "negative")
        end
        data.damage = data.damage + 1
        room:moveCardTo(card, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, data.from.id)
      end
    end
  end,
}
Fk:addSkill(xiongshi_active)
gaosheng:addSkill(xiongshi)
gaosheng:addSkill(difeng)
Fk:loadTranslationTable{
  ["gaosheng"] = "高升",
  ["#gaosheng"] = "",
  ["illustrator:gaosheng"] = "",

  ["ofl__xiongshi"] = "凶势",
  [":ofl__xiongshi"] = "每名角色出牌阶段限一次，其可以将一张手牌置于你武将牌上。",
  ["ofl__difeng"] = "地锋",
  [":ofl__difeng"] = "锁定技，当一名角色将牌置于武将牌后，你与其各摸一张牌；你造成或受到伤害时，伤害来源可以弃置你武将牌上一张牌，令此伤害+1。",
  ["ofl__xiongshi&"] = "凶势",
  [":ofl__xiongshi&"] = "出牌阶段限一次，你可以将一张手牌置于高升的武将牌上。",
  ["#ofl__xiongshi"] = "凶势：你可以将一张手牌置于你武将牌上",
  ["#ofl__xiongshi&"] = "凶势：你可以将一张手牌置于高升的武将牌上",
  ["#ofl__difeng-invoke"] = "地锋：是否移去 %src 武将牌上一张牌，令你对 %dest 造成的伤害+1？",
}

local fuyun = General(extension, "fuyun", "qun", 4)
local suiqu = fk.CreateTriggerSkill{
  name = "ofl__suiqu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Discard and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local yes = table.find(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    player:throwAllCards("h")
    if player.dead then return end
    if yes then
      local choices = {"ofl__tianpan1"}
      if player:isWounded() then
        table.insert(choices, "recover")
      end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "ofl__tianpan1" then
        room:changeMaxHp(player, 1)
      else
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
  end,
}
local yure = fk.CreateTriggerSkill{
  name = "ofl__yure",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player.room:getOtherPlayers(player, false) == 0 or
      player:usedSkillTimes(self.name, Player.HistoryGame) > 0 then return end
    local cards = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    cards = table.filter(cards, function(id) return player.room:getCardArea(id) == Card.DiscardPile end)
    cards = U.moveCardsHoldingAreaCheck(player.room, cards)
    if #cards > 0 then
      self.cost_data = {cards = cards}
      return true
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data.cards
    local move = room:askForYiji(player, cards, room:getOtherPlayers(player, false), self.name, 0, #cards,
      "#ofl__yure-give", cards, true)
    local check
    for _, cds in pairs(move) do
      if #cds > 0 then
        check = true
        break
      end
    end
    if check then
      self.cost_data = move
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doYiji(self.cost_data, player.id, self.name)
  end,
}
fuyun:addSkill(suiqu)
fuyun:addSkill(yure)
Fk:loadTranslationTable{
  ["fuyun"] = "浮云",
  ["#fuyun"] = "黄天末代",
  ["illustrator:fuyun"] = "苍月白龙",

  ["ofl__suiqu"] = "随去",
  [":ofl__suiqu"] = "锁定技，所有角色的弃牌阶段，你弃置所有手牌，若至少弃置一张牌，你加1点体力上限或回复1点体力。",
  ["ofl__yure"] = "余热",
  [":ofl__yure"] = "限定技，当你弃置牌后，你可以将所有弃置的牌交给任意名其他角色。",
  ["#ofl__yure-give"] = "余热：你可以将弃置的牌分配给其他角色",
}

local taosheng = General(extension, "taosheng", "qun", 5)
local zainei = fk.CreateActiveSkill{
  name = "ofl__zainei",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 1,
  prompt = "#ofl__zainei",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:addTableMark(player, self.name, effect.tos[1])
  end,
}
local zainei_distance = fk.CreateDistanceSkill{
  name = "#ofl__zainei_distance",
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("ofl__zainei"), to.id) then
      return 1
    end
  end,
}
local zainei_delay = fk.CreateTriggerSkill{
  name = "#ofl__zainei_delay",

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "ofl__zainei", 0)
  end,
}
local hanwei = fk.CreateActiveSkill{
  name = "ofl__hanwei",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  prompt = "#ofl__hanwei",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, to_select, selected)
    return not Fk:getCardById(to_select).is_damage_card
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return Self:distanceTo(Fk:currentRoom():getPlayerById(to_select)) == 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:showCards(effect.cards)
    local cards = table.filter(effect.cards, function (id)
      return table.contains(player:getCardIds("he"), id)
    end)
    if #cards > 0 and not target.dead then
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
    end
    if not player.dead then
      player:drawCards(#effect.cards, self.name)
    end
    cards = table.filter(cards, function (id)
      return table.contains(target:getCardIds("h"), id)
    end)
    while #cards > 0 and not target.dead do
      local use = U.askForUseRealCard(room, target, cards, nil, self.name, "#ofl__hanwei-use", {bypass_times = true}, false, true)
      if use then
        table.removeOne(cards, use.card.id)
      else
        return
      end
    end
  end,
}
zainei:addRelatedSkill(zainei_distance)
zainei:addRelatedSkill(zainei_delay)
taosheng:addSkill(zainei)
taosheng:addSkill(hanwei)
Fk:loadTranslationTable{
  ["taosheng"] = "陶升",
  ["#taosheng"] = "",
  ["illustrator:taosheng"] = "",

  ["ofl__zainei"] = "载内",
  [":ofl__zainei"] = "限定技，出牌阶段，你可以选择一名其他角色，然后你与其距离视为1，直到你进入濒死状态。",
  ["ofl__hanwei"] = "扞卫",
  [":ofl__hanwei"] = "出牌阶段限一次，你可以展示并交给距离为1的一名其他角色任意张非伤害类牌并摸等量的牌，然后其可以使用你交给其的任意张牌。",
  ["#ofl__zainei"] = "载内：选择一名角色，你与其距离视为1直到你进入濒死状态！",
  ["#ofl__hanwei"] = "扞卫：交给距离1一名角色任意张非伤害牌，摸等量牌，其可以使用交给其的牌",
  ["#ofl__hanwei-use"] = "扞卫：你可以使用这些牌",
}

local godhuangfusong = General(extension, "godhuangfusong", "god", 4)
local shice = fk.CreateTriggerSkill{
  name = "ofl__shice",
  switch_skill_name = "ofl__shice",
  anim_type = "switch",
  events = {fk.DamageInflicted, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.DamageInflicted then
        if player:getSwitchSkillState(self.name, false) == fk.SwitchYang and
          data.damageType ~= fk.NormalDamage and
          data.from then
          local getSkills = function (p)
            local skills = {}
            for _, s in ipairs(p.player_skills) do
              if s:isPlayerSkill(p) and s.visible then
                table.insertIfNeed(skills, s.name)
              end
            end
            return skills
          end
          return #getSkills(player) <= #getSkills(data.from)
        end
      elseif event == fk.TargetSpecified then
        if player:getSwitchSkillState(self.name, false) == fk.SwitchYin and
          #TargetGroup:getRealTargets(data.tos) == 1 and not table.contains(data.card.skillNames, self.name) then
          local to = player.room:getPlayerById(data.to)
          return not to.dead and #to:getCardIds("e") > 0
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      local use = U.askForUseVirtualCard(room, player, "fire_attack", nil, self.name,
        "#ofl__shice-yang", true, false, false, false, nil, true)
      if use then
        self.cost_data = use
        return true
      end
    elseif event == fk.TargetSpecified then
      if room:askForSkillInvoke(player, self.name, nil, "#ofl__shice-yin::"..data.to..":"..data.card:toLogString()) then
        self.cost_data = {tos = {data.to}}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      room:useCard(self.cost_data)
      return true
    elseif event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      room:askForDiscard(to, 1, 10, true, self.name, true, ".|.|.|equip", "#ofl__shice-discard:::"..data.card:toLogString())
      local n = #to:getCardIds("e")
      if n > 0 then
        data.additionalEffect = (data.additionalEffect or 0) + n
      end
    end
  end,
}
local podai = fk.CreateTriggerSkill{
  name = "ofl__podai",
  anim_type = "offensive",
  events = {fk.TurnStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not target.dead then
      local choices = {}
      if player:getMark("ofl__podai2-round") == 0 then
        table.insert(choices, "ofl__podai2")
      end
      if player:getMark("ofl__podai1-round") == 0 then
        for _, card in pairs(Fk.all_card_types) do
          if card.type == Card.TypeBasic then
            for _, s in ipairs(target.player_skills) do
              if s:isPlayerSkill(target) and s.visible and target:hasSkill(s) then
                if string.find(Fk:translate(":"..s.name, "zh_CN"), "【"..Fk:translate(card.trueName, "zh_CN").."】") then
                  table.insert(choices, "ofl__podai1")
                  if #choices > 0 then
                    self.cost_data = choices
                    return true
                  end
                end
              end
            end
          end
        end
        for _, s in ipairs(target.player_skills) do
          if s:isPlayerSkill(target) and s.visible and target:hasSkill(s) then
            if table.find({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}, function (str)
              return string.find(Fk:translate(":"..s.name, "zh_CN"), str)
            end) then
              table.insert(choices, "ofl__podai1")
              if #choices > 0 then
                self.cost_data = choices
                return true
              end
            end
          end
        end
      end
      if #choices > 0 then
        self.cost_data = choices
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local choices = self.cost_data
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, self.name,
      "#ofl__podai-invoke::"..target.id, false, {"ofl__podai1", "ofl__podai2", "Cancel"})
    if choice ~= "Cancel" then
      self.cost_data = {tos = {target.id}, choice = choice}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.cost_data.choice.."-round", 1)
    if self.cost_data.choice == "ofl__podai1" then
      local skills = {}
      for _, card in pairs(Fk.all_card_types) do
        if card.type == Card.TypeBasic then
          for _, s in ipairs(target.player_skills) do
            if s:isPlayerSkill(target) and s.visible and target:hasSkill(s) then
              if string.find(Fk:translate(":"..s.name, "zh_CN"), "【"..Fk:translate(card.trueName, "zh_CN").."】") then
                table.insertIfNeed(skills, s.name)
              end
            end
          end
        end
      end
      for _, s in ipairs(target.player_skills) do
        if s:isPlayerSkill(target) and s.visible and target:hasSkill(s) then
          if table.find({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}, function (str)
            return string.find(Fk:translate(":"..s.name, "zh_CN"), str)
          end) then
            table.insertIfNeed(skills, s.name)
          end
        end
      end
      if #skills > 0 then
        local choice = room:askForCustomDialog(player, self.name,
        "packages/utility/qml/ChooseSkillBox.qml", {
          skills, 1, 1, "#ofl__podai-skill::"..target.id, {},
        })
        if choice == "" then
          choice = table.random(skills)
        else
          choice = json.decode(choice)[1]
        end
        room:sendLog{
          type = "#ofl__podai",
          from = player.id,
          to = { target.id },
          arg = choice,
          toast = true,
        }
        room:invalidateSkill(target, choice)
      end
    else
      target:drawCards(3, self.name)
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
godhuangfusong:addSkill(shice)
godhuangfusong:addSkill(podai)
Fk:loadTranslationTable{
  ["godhuangfusong"] = "神皇甫嵩",
  ["#godhuangfusong"] = "厥功至伟",
  ["illustrator:godhuangfusong"] = "王宁",

  ["ofl__shice"] = "势策",
  [":ofl__shice"] = "转换技，①当你受到属性伤害时，若你的技能数不大于伤害来源，你可以防止此伤害并视为使用一张【火攻】；②当你不因此技能使用牌"..
  "指定唯一目标后，你可以令其弃置装备区任意张牌，然后此牌额外结算X次（X为其装备区的牌数）。",
  ["ofl__podai"] = "破怠",
  [":ofl__podai"] = "每轮各限一次，一名角色的回合开始或结束时，你可以选择一顶：1.令其描述中含有基本牌名或数字的一个技能失效；2.令其摸三张牌，"..
  "然后对其造成1点火焰伤害。",
  ["#ofl__shice-yang"] = "势策：你可以防止你受到的伤害，视为使用一张【火攻】",
  ["#ofl__shice-yin"] = "势策：是否令 %dest 弃置任意张装备并使%arg额外结算？",
  ["#ofl__shice-discard"] = "势策：弃置任意张装备，然后此%arg将额外结算你装备区牌数的次数！",
  ["#ofl__podai-invoke"] = "破怠：是否对 %dest 执行一项？",
  ["ofl__podai1"] = "令其一个描述中含有基本牌名或数字的技能失效",
  ["ofl__podai2"] = "令其摸三张牌，对其造成1点火焰伤害",
  ["#ofl__podai-skill"] = "破怠：令 %dest 的一个技能失效！",
  ["#ofl__podai"] = "%from 令 %to 的技能“%arg”失效！"
}

--local godluzhi = General(extension, "godluzhi", "god", 4)
Fk:loadTranslationTable{
  ["godluzhi"] = "神卢植",
  ["#godluzhi"] = "",
  ["illustrator:godluzhi"] = "聚一_L.M.YANG",

  ["ofl__xgan"] = "x干",
  [":ofl__xgan"] = "每个回合结束时，若有xx计算距离发生过变化，你可以令其他两名角色分别视为使用一张基本牌。",
  ["ofl__weix"] = "围x",
  [":ofl__weix"] = "出牌阶段限一次，你可以xx任意张手牌并。",
  ["ofl__xquan"] = "x权",
  [":ofl__xquan"] = "你可以将一张装备牌当未以此法使用过的锦囊牌对体力不小于你的xx角色使用。",
}

--local godzhujun = General(extension, "godzhujun", "god", 4)
Fk:loadTranslationTable{
  ["godzhujun"] = "神朱儁",
  ["#godzhujun"] = "",
  ["illustrator:godzhujun"] = "鱼仔",

  ["ofl__xji"] = "x击",
  [":ofl__xji"] = "出牌阶段限一次，你可以，然后令一名其他角色xx等量张手牌，若：【杀】，你对其造成1点火焰伤害；【闪】，其对；【桃】，你与其各摸两张牌。",
  ["ofl__p"] = "",
  [":ofl__p"] = "锁定技，你的回合内，一名角色使用属性【杀】指定目标后，目标角色。",
  ["ofl__kuixiang"] = "溃降",
  [":ofl__kuixiang"] = "每名角色限一次，。",
}

return extension
