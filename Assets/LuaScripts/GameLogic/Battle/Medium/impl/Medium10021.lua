local table_insert = table.insert
local FixDiv = FixMath.div
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixIntMul = FixMath.muli
local FixNormalize = FixMath.Vector3Normalize

local StatusFactoryInst = StatusFactoryInst
local BattleEnum = BattleEnum
local IsInRect = SkillRangeHelper.IsInRect
local Formular = Formular
local ActorManagerInst = ActorManagerInst
local CtlBattleInst = CtlBattleInst

local LinearFlyToPointMedium = require("GameLogic.Battle.Medium.impl.LinearFlyToPointMedium")
local Medium10021 = BaseClass("Medium10021", LinearFlyToPointMedium)

function Medium10021:__init()
    self.m_enemyList = {}  --id[]
end

function Medium10021:ArriveDest()
    if self.m_param.keyFrame == 3 then
        local performer = self:GetOwner()
        if not performer then
            return
        end

        performer:Reset10021BeatBackTargetID()
    end

    self.m_enemyList = nil
end

function Medium10021:OnMove(dir)
    -- 阶段1：只推后不打断；阶段2：如果敌人中了第一道浪，则在中第二道时被浮空，中第三道时被击飞{b}米。也就是说，第二和第三道浪已经有了控制能力
    local battleLogic = CtlBattleInst:GetLogic()
    local skillCfg = self:GetSkillCfg()

    local performer = self:GetOwner()
    if not performer then
        return
    end

    if not battleLogic or not skillCfg or not self.m_skillBase then
        return
    end


    local normalizedDir = FixNormalize(self.m_param.targetPos - performer:GetPosition())
    normalizedDir:Mul(0.5)
    normalizedDir:Add(self.m_position)
    local performDir = FixNormalize(self.m_param.targetPos - performer:GetPosition())
    local halfDis2 = FixDiv(skillCfg.dis1, 2)
    ActorManagerInst:Walk(
        function(tmpTarget)
            local targetID = tmpTarget:GetActorID()

            if self.m_enemyList[targetID] then
                return
            end

            if not battleLogic:IsEnemy(performer, tmpTarget, BattleEnum.RelationReason_SKILL_RANGE) then
                return
            end

            if not IsInRect(tmpTarget:GetPosition(), 0, halfDis2, 1, normalizedDir, performDir) then
                return
            end

            self.m_enemyList[targetID] = true

            local judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_PHY_HURT, true)
            if Formular.IsJudgeEnd(judge) then
                return
            end

            local injure = Formular.CalcInjure(performer, tmpTarget, skillCfg, BattleEnum.HURTTYPE_PHY_HURT, judge, self.m_skillBase:X())
            if injure > 0 then
                injure = FixIntMul(injure, performer:GetInjureMul(tmpTarget))

                local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure, -1), BattleEnum.HURTTYPE_PHY_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                        judge, self.m_param.keyFrame)
                self:AddStatus(performer, tmpTarget, status)
            end

            judge = Formular.AtkRoundJudge(performer, tmpTarget, BattleEnum.HURTTYPE_MAGIC_HURT, true)
            if not Formular.IsJudgeEnd(judge) then
                local injure2 = Formular.CalcInjure(performer, tmpTarget, skillCfg, BattleEnum.HURTTYPE_MAGIC_HURT, judge, self.m_skillBase:Y())
                if injure2 > 0 then
                    injure2 = FixIntMul(injure2, performer:GetInjureMul(tmpTarget))

                    local status = StatusFactoryInst:NewStatusHP(self.m_giver, FixMul(injure2, -1), BattleEnum.HURTTYPE_MAGIC_HURT, BattleEnum.HPCHGREASON_BY_SKILL,
                            judge, self.m_param.keyFrame)
                    self:AddStatus(performer, tmpTarget, status)
                end
            end

            tmpTarget:OnBeatBack(performer, self.m_skillBase:A())
            local skilllevel = self.m_skillBase:GetLevel()
            if skilllevel >= 2 and performer:BeatFlyByTargetID(targetID) then
                if self.m_param.keyFrame == 2 then
                    tmpTarget:OnBeatFly(BattleEnum.ATTACK_WAY_IN_SKY, performer:GetPosition(), 0, 500)
                elseif self.m_param.keyFrame == 3 then
                    tmpTarget:OnBeatFly(BattleEnum.ATTACK_WAY_FLY_AWAY, performer:GetPosition(), self.m_skillBase:B())
                end
            end

            if skilllevel >= 6 and self.m_param.keyFrame == 3 then 
                local statusFear = StatusFactoryInst:NewStatusFear(self.m_giver, FixIntMul(self.m_skillBase:C(), 1000))
                self:AddStatus(performer, tmpTarget, statusFear)
            end

            performer:Add10021BeatBackTargetID(targetID)
        end
    )
end


return Medium10021