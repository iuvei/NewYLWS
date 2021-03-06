local base = require("UnitTest.SyncTestBase")
local GameUtility = CS.GameUtility
local table_insert = table.insert
local Random = Mathf.Random
local YuanMenTest = BaseClass("YuanMenTest", base)

function YuanMenTest:__init()
    self:RegisterHandler(MsgIDDefine.YUANMEN_RSP_YUANMEN_PANNEL, Bind(self, self.RspPanel)) 
    self:RegisterHandler(MsgIDDefine.YUANMEN_RSP_YUANMEN_FINISH, Bind(self, self.RspBattleFinish))
    self:RegisterHandler(MsgIDDefine.YUANMEN_RSP_YUANMEN_BATTLE, Bind(self, self.RspYuanmenCopy), 0)
end

function YuanMenTest:Start()
    base.Start(self)

    self:ResetState()
end

function YuanMenTest:RspExecCmd()
    self:ReqPanel()
end

function YuanMenTest:ReqPanel()
    local msg_id = MsgIDDefine.YUANMEN_REQ_YUANMEN_PANNEL
    local msg = (MsgIDMap[msg_id])()

    HallConnector:GetInstance():SendMessage(msg_id,msg)
end

function YuanMenTest:RspPanel(msg_obj) 
    if not msg_obj then 
        return 
    end 
    
    print("****************YuanMenTest id : " .. msg_obj.yuanmen_copy_list[1].yuanmen_id)
    self:ReqEnterYuanmenCopy(msg_obj.yuanmen_copy_list[1].yuanmen_id)
end 

function YuanMenTest:ReqEnterYuanmenCopy(yuanmen_id)
	local msg_id = MsgIDDefine.YUANMEN_REQ_YUANMEN_BATTLE
    local msg = (MsgIDMap[msg_id])()
    msg.yuanmen_id = yuanmen_id
    local buzhenID = Utils.GetBuZhenIDByBattleType(BattleEnum.BattleType_YUANMEN)
    PBUtil.ConvertLineupDataToProto(buzhenID, msg.buzhen_info, self:GenerateLineupData(BattleEnum.BattleType_YUANMEN))

	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function YuanMenTest:RspYuanmenCopy(msg_obj)
    local result = msg_obj.result
    if result ~= 0 then
        self:End()
		return
    end
    
    local copyID = msg_obj.battle_info.copy_id
	local battleid = msg_obj.battle_info.battle_id
	local leftFormation = msg_obj.battle_info.left_formation
	local rightFormation = msg_obj.battle_info.right_formation
	local randSeeds = msg_obj.battle_info.battle_random_seeds
	local cmdList = msg_obj.battle_info.cmd_list

    CtlBattleInst:InitBattle(BattleEnum.BattleType_YUANMEN, randSeeds, battleid)
    CtlBattleInst:InitCommandQueue(cmdList)
    local enterParam = BattleProtoConvert.ConvertYuanmenProto(copyID, tonumber(msg_obj.battle_info.param1), tonumber(msg_obj.battle_info.param2), 
        leftFormation, msg_obj.battle_info.yuanmen_battle)
    CtlBattleInst.m_battleLogic:OnEnterParam(enterParam)
    
    self:SwitchScene(SceneConfig.BattleScene)
    self:StartFight()
    -- coroutine.start(self.StartFight, self)
    self:ReqBattleFinish()
end


-- function YuanMenTest:OnFightEnd()
--     self:ReqBattleFinish()
-- end

function YuanMenTest:ReqBattleFinish()
    local msg_id = MsgIDDefine.YUANMEN_REQ_YUANMEN_FINISH
    local msg = (MsgIDMap[msg_id])()
    msg.yuanmen_id = CtlBattleInst.m_battleLogic:GetBattleParam().yuanmenID
    local frameCmdList = CtlBattleInst:GetFrameCmdList()
    PBUtil.ConvertCmdListToProto(msg.battle_info.cmd_list, frameCmdList)
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function YuanMenTest:RspBattleFinish(msg_obj)
	local result = msg_obj.result
	if result ~= 0 then
		return
    end
    
    local isEqual = self:CompareBattleResult(msg_obj.battle_result)
    if isEqual then
        self:End()
    else
        Logger.LogError("Do not sync, report frame data to server")
        self:SaveBattleInfo()
        self:ReqReportFrameData()
    end
end

function YuanMenTest:SaveBattleInfo()
    GameUtility.SafeWriteAllText("./FrameDebug/YuanMen" .. CtlBattleInst.m_battleLogic:GetBattleID() .. ".txt", 
            "yuanmenID:" ..  CtlBattleInst.m_battleLogic:GetBattleParam().yuanmenID .. ", wujiang:" .. self.m_lineupData.roleSeqList[1] .. 
            "|" .. self.m_lineupData.roleSeqList[2] .. "|" .. self.m_lineupData.roleSeqList[3] .. "|" .. self.m_lineupData.roleSeqList[4] ..
            "|" .. self.m_lineupData.roleSeqList[5] .. " , dragonID: " .. self.m_lineupData.summon)
end

return YuanMenTest