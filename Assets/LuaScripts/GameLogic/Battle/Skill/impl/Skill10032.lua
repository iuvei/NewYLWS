local BattleEnum = BattleEnum
local StatusGiver = StatusGiver
local StatusFactoryInst = StatusFactoryInst
local FixMul = FixMath.mul
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMod = FixMath.mod
local FixSub = FixMath.sub
local FixAbs = FixMath.abs
local FixFloor = FixMath.floor
local CtlBattleInst = CtlBattleInst
local ActorManagerInst = ActorManagerInst
local FixNormalize = FixMath.Vector3Normalize
local FixNewVector3 = FixMath.NewFixVector3
local IsInCircle = SkillRangeHelper.IsInCircle
local FixIntMul = FixMath.muli
local ACTOR_ATTR = ACTOR_ATTR

local SkillBase = require "GameLogic.Battle.Skill.SkillBase"
local Skill10032 = BaseClass("Skill10032", SkillBase)

function Skill10032:Perform(performer, target, performPos, special_param)
    if not performer or not target then
        return
    end

    -- 破胆狂击    阶段3：敌人造成伤害减半状态叠加时重置

    -- 张飞向前突进，对{a}米内物防最低的敌人发动一次猛击，造成{X1}（+{e}%物攻)点物理伤害，并将其击退{b}米。
    -- 之后猛锤地面，令附近敌人小幅度后退{c}米。

    -- 张飞向前突进，对{a}米内物防最低的敌人发动一次猛击，造成{X2}（+{e}%物攻)点物理伤害，并将其击退{b}米。
    -- 之后猛锤地面，令附近敌人小幅度后退{c}米。

    -- 张飞向前突进，对{a}米内物防最低的敌人发动一次猛击，造成{X3}（+{e}%物攻)点物理伤害，并将其击退{b}米。
    -- 之后猛锤地面，令附近敌人小幅度后退{c}米,并在接下来的{d}秒内，对张飞造成的伤害减半。

    -- 张飞向前突进，对{a}米内物防最低的敌人发动一次猛击，造成{X4}（+{e}%物攻)点物理伤害，并将其击退{b}米。
    -- 之后猛锤地面，令附近敌人小幅度后退{c}米,并在接下来的{d}秒内，对张飞造成的伤害减半。

    -- 张飞向前突进，对{a}米内物防最低的敌人发动一次猛击，造成{X5}（+{e}%物攻)点物理伤害，并将其击退{b}米。
    -- 之后猛锤地面，令附近敌人小幅度后退{c}米,并在接下来的{d}秒内，对张飞造成的伤害减半。

    -- 张飞向前突进，对{a}米内物防最低的敌人发动一次猛击，造成{X6}（+{e}%物攻)点物理伤害，并将其击退{b}米。
    -- 之后猛锤地面，令附近敌人小幅度后退{c}米,并在接下来的{d}秒内，对张飞造成的伤害减半。


    if special_param.keyFrameTimes == 1 then -- 冲到敌人面前
        local movehelper = performer:GetMoveHelper()
        if movehelper then
            local dir = target:GetPosition() - performer:GetPosition()
            dir.y = 0

            local distance = FixAbs(FixSub(dir:Magnitude(), target:GetRadius()))
            
            local moveTargetPos = FixNormalize(dir)
            moveTargetPos:Mul(distance)
            moveTargetPos:Add(performer:GetPosition())
            
            local speed = FixDiv(distance, 0.20)
            local pathHandler = CtlBattleInst:GetPathHandler()
            if pathHandler then
                local x,y,z = performer:GetPosition():GetXYZ()
                local x2, y2, z2 = moveTargetPos:GetXYZ()
                local hitPos = pathHandler:HitTest(x, y, z, x2, y2, z2)
                if hitPos then
                    moveTargetPos:SetXYZ(hitPos.x , performer:GetPosition().y, hitPos.z)
                end
            end

            local performerID = performer:GetActorID()
            local targetID = target:GetActorID()
            movehelper:Stop()
            movehelper:Start({ moveTargetPos }, speed, nil, true)
        end
    elseif special_param.keyFrameTimes == 2 then
        local judge = Formular.AtkRoundJudge(performer, target, BattleEnum.HURTTYPE_PHY_HURT, true)
        if Formular.IsJudgeEnd(judge) then
            return  
        end

        local injure = Formular.CalcInjure(performer, target, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:X())
        if injure > 0 then
            local giver = StatusGiver.New(performer:GetActorID(), 10032)
            local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                judge, special_param.keyFrameTimes)
            self:AddStatus(performer, target, status)

            target:OnBeatBack(performer, self:B())
        end
    elseif special_param.keyFrameTimes == 3 then
        local ctlBattle = CtlBattleInst
        ActorManagerInst:Walk(
            function(tmpTarget)
                if not ctlBattle:GetLogic():IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                    return
                end
    
                if not IsInCircle(performer:GetPosition(), self:C(), tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
                    return
                end

                local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
                if Formular.IsJudgeEnd(judge) then
                  return  
                end

                local injure = Formular.CalcInjure(performer, tmpTarget, self.m_skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self:Y())
                if injure > 0 then
                    local giver = StatusGiver.New(performer:GetActorID(), 10032)
                    local status = StatusFactoryInst:NewStatusHP(giver, FixMul(-1, injure), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL, 
                                                                                                                        judge, special_param.keyFrameTimes)
                    self:AddStatus(performer, tmpTarget, status)
                    BattleCameraMgr:Shake()
                end

                if self.m_level >= 3 then
                    local zhangfeiDefStatus = performer:GetStatusContainer():GetZhangfeiDef()
                    if not zhangfeiDefStatus then
                        local giver = StatusGiver.New(performer:GetActorID(), 10032)
                        zhangfeiDefStatus = StatusFactoryInst:NewStatusZhangFeiDef(giver, FixIntMul(self:D(), 1000), 0.5)
                        self:AddStatus(performer, performer, zhangfeiDefStatus)
                    end
                    zhangfeiDefStatus:AddDefTargetID(tmpTarget:GetActorID())
                end
            end
        )
    end
end


-- function Skill10032:SelectSkillTarget(performer, target)
--     if not performer or not target then
--         return
--     end

--     local minPhyDef = 999999
--     local newTarget = false

--     local ctlBattle = CtlBattleInst
--     ActorManagerInst:Walk(
--         function(tmpTarget)
--             if not tmpTarget or not tmpTarget:IsLive() then
--                 return
--             end

--             if not ctlBattle:GetLogic():IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
--                 return
--             end

--             if not IsInCircle(performer:GetPosition(), self:A(), tmpTarget:GetPosition(), tmpTarget:GetRadius()) then
--                 return
--             end

--             local phyDef = tmpTarget:GetData():GetAttrValue(ACTOR_ATTR.FIGHT_PHY_DEF)
--             if phyDef < minPhyDef then
--                 minPhyDef = phyDef
--                 newTarget = tmpTarget
--             end
--         end
--     )

--     if newTarget then
--         return newTarget, newTarget:GetPosition()
--     end
--     return nil, nil
-- end

return Skill10032