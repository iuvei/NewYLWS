local Type_RectTransform = typeof(CS.UnityEngine.RectTransform)
local UIUtil = UIUtil
local table_insert = table.insert
local table_sort = table.sort

local EmailInfo = require("DataCenter/EmailData/EmailInfo")

local UIEmailItemPrefabPath = "UI/Prefabs/Email/UIEmailItem.prefab"
local UIEmailItem = require "UI.UIEmail.View.UIEmailItem"

local CommonAwardItem = require "UI.Common.CommonAwardItem"
local CommonAwardItemPrefab = TheGameIds.CommonAwardItemPrefab
local AwardIconParamClass = require "DataCenter.AwardData.AwardIconParam"

local base = UIBaseView
local UIEmailView = BaseClass("UIEmailView", UIBaseView)

function UIEmailView:OnCreate()
    base.OnCreate(self)
    
    self:InitView()
end

function UIEmailView:OnAddListener()
	base.OnAddListener(self)
	-- UI消息注册
    self:AddUIListener(UIMessageNames.MN_MAIL_RSP_MAILREAD, self.RspMailRead)
    self:AddUIListener(UIMessageNames.MN_MAIL_RSP_TAKEATTACH, self.RspTakeAttack)
    self:AddUIListener(UIMessageNames.MN_MAIL_RSP_TAKEATTACHLIST, self.RspTakeAttackList)
    self:AddUIListener(UIMessageNames.MN_MAIL_ITEM_ONSELECT, self.ItemOnSelect)
    self:AddUIListener(UIMessageNames.MN_MAIL_DELETEEMEIL, self.EmailDelete)
end

function UIEmailView:OnRemoveListener()
	base.OnRemoveListener(self)
	-- UI消息注销
    self:RemoveUIListener(UIMessageNames.MN_MAIL_RSP_MAILREAD, self.RspMailRead)
    self:RemoveUIListener(UIMessageNames.MN_MAIL_RSP_TAKEATTACH, self.RspTakeAttack)
    self:RemoveUIListener(UIMessageNames.MN_MAIL_RSP_TAKEATTACHLIST, self.RspTakeAttackList)
    self:RemoveUIListener(UIMessageNames.MN_MAIL_ITEM_ONSELECT, self.ItemOnSelect)
    self:RemoveUIListener(UIMessageNames.MN_MAIL_DELETEEMEIL, self.EmailDelete)
end


function UIEmailView:ItemOnSelect(item, index) -- 选中左侧邮件列表
    if self.m_currSelectItem then
        if self.m_currSelectItem:GetMailSeq() == item:GetMailSeq() then
            return
        end

        self.m_leftItemInfoList[self.m_currSelectItem:GetMailIndex()].isSelelct = false
        self.m_currSelectItem:OnNoSelect()
    end

    self.m_leftItemInfoList[item:GetMailIndex()].isSelelct = true
    self.m_currSelectItem = item
    if self.m_currSelectItem then
        self.m_currSelectItem:OnClick()
    end
end

function UIEmailView:RspMailRead(msgInfo) -- 读取邮件内容
    self:UpdateRightContainer(msgInfo)
    if self.m_currSelectItem then
        self.m_currSelectItem:ReadEmail()
    end
end

function UIEmailView:RspTakeAttack(emailInfo, msg) -- 领取附件
    if self.m_currSelectItem then
        self.m_currSelectItem:OnNoSelect()
        self.m_currSelectItem = false
    end

    self:ShowAward(msg.attach_list)
    self:UpdateEmaileData(emailInfo)
end

function UIEmailView:RspTakeAttackList(emailInfo, msg) -- 一键领取附件
    local awardList = {}
    for _, mail_attach in ipairs(msg.mail_attach_list) do
        for _, attach in ipairs(mail_attach.attach_list) do
            table_insert(awardList, attach)
        end
    end

    if self.m_currSelectItem then
        self.m_currSelectItem:OnNoSelect()
        self.m_currSelectItem = false
    end
    
    self:ShowAward(awardList)
    self:UpdateEmaileData(emailInfo)
end

function UIEmailView:ShowAward(list) 
    local awardList = PBUtil.ParseAwardList(list)

    if awardList and #awardList > 0 then
        local uiData = {
            openType = 1,
            awardDataList = awardList
        }
        UIManagerInst:OpenWindow(UIWindowNames.UIGetAwardPanel, uiData)
    end
end

function UIEmailView:EmailDelete(msgInfo) -- 删除邮件
    if self.m_currSelectItem then
        self.m_currSelectItem:OnNoSelect()
        self.m_currSelectItem = false
    end
    self:UpdateEmaileData(msgInfo)
end

function UIEmailView:InitView()
    self.m_rightTopTitleText, self.m_rightTopValidTimeText, self.m_rightMiddleContentText = -- 右侧 邮件title/有效期/邮件内容
    UIUtil.GetChildTexts(self.transform, {
        "winPanel/rightContainer/rightTopContainer/fromText",
        "winPanel/rightContainer/rightTopContainer/validTimeText",
        "winPanel/rightContainer/rightMiddleContainer/itemContentScrollView/Viewport/contentText",
    })
    
    self.m_receiveBtnText, self.m_oneKeyReceiveBtnText, self.m_attachmentText, self.m_attachmentTextLine = -- 右侧 邮件title/有效期/邮件内容
    UIUtil.GetChildTexts(self.transform, {
        "winPanel/rightContainer/rightMiddleContainer/receive_BTN/Text",
        "winPanel/oneKeyReceive_BTN/Text",
        "winPanel/rightContainer/rightMiddleContainer/fujian",
        "winPanel/rightContainer/rightMiddleContainer/fujian/text",
    })

    self.m_deleteBtn, 
    self.m_receiveBtn, 
    self.m_oneKeyReceiveBtn, 
    self.m_backBtn = -- 删除/领取附件/一键领取/返回 按钮
    UIUtil.GetChildTransforms(self.transform, {
        "winPanel/rightContainer/rightTopContainer/deleteBtn", 
        "winPanel/rightContainer/rightMiddleContainer/receive_BTN", 
        "winPanel/oneKeyReceive_BTN",
        "blackBg"
    })

    local onClick = UILogicUtil.BindClick(self, self.OnClick)
    UIUtil.AddClickEvent(self.m_deleteBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_receiveBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_oneKeyReceiveBtn.gameObject, onClick)
    UIUtil.AddClickEvent(self.m_backBtn.gameObject, UILogicUtil.BindClick(self, self.OnClick, 0))
    
    -- 邮件内容可视控件
    self.m_middleContent = UIUtil.FindComponent(self.transform, Type_RectTransform, "winPanel/rightContainer/rightMiddleContainer/itemContentScrollView/Viewport")

    -- 右侧容器/没有邮件默认图片/       -- 目前暂时没用到 self.m_receiveImageTr 已领取图片
    self.m_rightContainerTr, self.m_noSelectImageTr, self.m_receiveBtnTr, 
    self.m_receiveImageTr, self.m_attachmentTr = 
    UIUtil.GetChildTransforms(self.transform, {
        "winPanel/rightContainer",
        "winPanel/noSelectImage", 
        "winPanel/rightContainer/rightMiddleContainer/receive_BTN", 
        "winPanel/rightContainer/rightMiddleContainer/receiveImage", 
        "winPanel/rightContainer/rightMiddleContainer/fujian",
    })

    -- 左右侧附件滑动控件
    self.m_rightItemContentTr, self.m_leftItemContentTr = 
    UIUtil.GetChildTransforms(self.transform, {
        "winPanel/rightContainer/rightMiddleContainer/itemScrollView/Viewport/ItemContent",
        "winPanel/leftContainer/ItemScrollView/Viewport/ItemContent",
    })
    self.m_leftItemList = {}
    self.m_scrollView = self:AddComponent(LoopScrowView, "winPanel/leftContainer/ItemScrollView/Viewport/ItemContent", Bind(self, self.UpdateDataTaskItem), false)
    -- self.m_oneKeyReceiveButton = UIUtil.FindComponent(self.m_oneKeyReceiveBtn, typeof(CS.UnityEngine.UI.Button))
    
    self.m_awardSeq = 0
    self.m_emailSeq = 0
    self.m_bagItemSeq = 0

    self.m_emailAttachList = {}
    self.m_currSelectItem = false
    self.m_isScaled = false
end

function UIEmailView:OnEnable(...)
    base.OnEnable(self, ...)
    local order, msg_obj = ...

    self.m_receiveBtnText.text = Language.GetString(1338)
    self.m_oneKeyReceiveBtnText.text = Language.GetString(2474)
    self.m_attachmentText.text = Language.GetString(2475)
    self.m_attachmentTextLine.text = Language.GetString(2476)

    if not msg_obj then
        print('========not UIEmailView msg_obj=========')
        return
    end

    self:UpdateEmaileData(msg_obj.mail_list)
end

function UIEmailView:OnDisable()
    self:Release()
	base.OnDisable(self)
end

function UIEmailView:OnDestroy()
    UIUtil.RemoveClickEvent(self.m_deleteBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_receiveBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_oneKeyReceiveBtn.gameObject)
    UIUtil.RemoveClickEvent(self.m_backBtn.gameObject)

    self:Release()
    base.OnDestroy(self)
end

function UIEmailView:Release()
    if self.m_awardSeq > 0 then
        UIGameObjectLoader:GetInstance():CancelLoad(self.m_awardSeq)
        self.m_awardSeq = 0
    end

    if self.m_emailSeq > 0 then
        UIGameObjectLoader:GetInstance():CancelLoad(self.m_emailSeq)
        self.m_emailSeq = 0
    end

    if self.m_bagItemSeq > 0 then
        UIGameObjectLoader:GetInstance():CancelLoad(self.m_bagItemSeq)
        self.m_bagItemSeq = 0
    end

    self.m_awardSeq = 0
    self.m_emailSeq = 0
    self.m_bagItemSeq = 0

    if #self.m_emailAttachList > 0 then
        self:OnReleaseItem(self.m_emailAttachList)
    end

    if #self.m_leftItemList > 0 then
        self:OnReleaseItem(self.m_leftItemList)
    end

    self.m_leftItemList = {}
    self.m_leftItemInfoList = {}
    self.m_emailAttachList = {}
    self.m_currSelectItem = nil
    self.m_isScaled = false
end

function UIEmailView:UpdateEmaileData(msg_obj) -- 左侧邮件列表
    self.m_leftItemInfoList = {}

    local mailList = msg_obj
    if mailList and #mailList > 0 then
        table_sort(mailList, function(item1, item2)
            return item1.send_time < item2.send_time
        end) 

        local count = #mailList
        if count > 0 then
            for i = 1,count do
                local emailInfo = EmailInfo.New()
                emailInfo.sender = mailList[i].sender
                emailInfo.send_time = mailList[i].send_time
                emailInfo.is_read = mailList[i].is_read
                emailInfo.mail_seq = mailList[i].mail_seq
                emailInfo.attach_count = mailList[i].attach_count
                emailInfo.isSelelct = false

                table_insert(self.m_leftItemInfoList, emailInfo)
            end

            if #self.m_leftItemList <= 0 then
                self.m_emailSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
                UIGameObjectLoader:GetInstance():GetGameObjects(self.m_emailSeq, UIEmailItemPrefabPath, 8, function(objs)
                    self.m_emailSeq = 0
                    if objs then
                        for i = 1, #objs do
                            local emailItem = UIEmailItem.New(objs[i], self.m_leftItemContentTr, UIEmailItemPrefabPath)
                            table_insert(self.m_leftItemList, emailItem)
    
                            self.m_scrollView:UpdateView(true, self.m_leftItemList, self.m_leftItemInfoList)
                            if i == 1 then
                                self.m_leftItemInfoList[1].isSelelct = true
                                self.m_leftItemInfoList[1].is_read = 1
                                self.m_currSelectItem = emailItem
                            end
                        end
                    end
                end)
            else
                if #self.m_leftItemInfoList > 0 then
                    self.m_leftItemInfoList[1].isSelelct = true
                    self.m_leftItemInfoList[1].is_read = 1
                    self.m_currSelectItem = self.m_leftItemList[1]
                else
                    self.m_currSelectItem = nil
                end
                self.m_scrollView:UpdateView(true, self.m_leftItemList, self.m_leftItemInfoList)
            end
        else
            self.m_currSelectItem = nil
        end
    else
        self.m_rightContainerTr.gameObject:SetActive(false)
        self.m_noSelectImageTr.gameObject:SetActive(true)
        self.m_oneKeyReceiveBtn.gameObject:SetActive(false)

        self.m_scrollView:UpdateView(true, self.m_leftItemList, self.m_leftItemInfoList)
    end
end

function UIEmailView:SortAllEmailItem(itemArrayA)
	table_sort(itemArrayA, function(itemA, itemB)
		return itemA:GetMailSeq() > itemB:GetMailSeq()
    end)

    for k,v in pairs(itemArrayA) do
        table_insert(self.m_leftItemList, v)
    end

    for i,item in pairs(self.m_leftItemList) do
        if item then
            item:SetSiblingIndex(i)
        end
    end

    self.m_leftItemList[1]:OnClick()
end

function UIEmailView:SortEmailItem(itemArrayA, needSetInex)
	table_sort(itemArrayA, function(itemA, itemB)
		return itemA:GetMailSeq() < itemB:GetMailSeq()
    end)

    if needSetInex then
        for i,item in pairs(itemArrayA) do
            if item then
                item:SetSiblingIndex(i)
            end
        end
    end
end

function UIEmailView:UpdateRightContainer(emailInfo) -- 右侧邮件内容
    self:OnReleaseItem(self.m_emailAttachList)
    self.m_emailAttachList = {}

    if not emailInfo then
        self.m_noSelectImageTr.gameObject:SetActive(true)
        self.m_rightContainerTr.gameObject:SetActive(false)
        return
    else
        self.m_noSelectImageTr.gameObject:SetActive(false)
        self.m_rightContainerTr.gameObject:SetActive(true)
    end

    local attachList = emailInfo.attach_list -- todo 奖励列表
    local attachCount = #attachList
    if attachList and attachCount > 0 then
        self.m_bagItemSeq = UIGameObjectLoader:GetInstance():PrepareOneSeq()
        UIGameObjectLoader:GetInstance():GetGameObjects(self.m_bagItemSeq, CommonAwardItemPrefab,attachCount, function(objs)
            self.m_bagItemSeq = 0
            if objs then
                for i = 1, #objs do
                    local emailAttachItem = CommonAwardItem.New(objs[i], self.m_rightItemContentTr, CommonAwardItemPrefab)
                    table_insert(self.m_emailAttachList, emailAttachItem)
                    
                    local itemIconParam = AwardIconParamClass.New(attachList[i].item_id, attachList[i].count)
                    emailAttachItem:UpdateData(itemIconParam)
                end
            end
        end)

        self.m_rightItemContentTr.localPosition = Vector2.New(0,0) -- 置顶    

        self.m_oneKeyReceiveBtn.gameObject:SetActive(true)
        -- self.m_oneKeyReceiveButton.interactable = true
        -- self.m_deleteBtn.gameObject:SetActive(false)
        self.m_receiveBtnTr.gameObject:SetActive(true)
        self.m_attachmentTr.gameObject:SetActive(true)

        if self.m_isScaled then
            local tmpSizeDelta = self.m_middleContent.sizeDelta
            self.m_middleContent.sizeDelta = Vector2.New(tmpSizeDelta.x, tmpSizeDelta.y / 1.6)
            self.m_isScaled = false
        end

        self.m_rightTopValidTimeText.text = ""
    else
        self.m_receiveBtnTr.gameObject:SetActive(false)
        -- self.m_oneKeyReceiveButton.interactable = false
        self.m_oneKeyReceiveBtn.gameObject:SetActive(false)
        self.m_deleteBtn.gameObject:SetActive(true)
        self.m_attachmentTr.gameObject:SetActive(false)
        self.m_rightItemContentTr.sizeDelta = Vector2.New(1, 1.5)

        if not self.m_isScaled then
            local tmpSizeDelta = self.m_middleContent.sizeDelta
            self.m_middleContent.sizeDelta = Vector2.New(tmpSizeDelta.x, tmpSizeDelta.y * 1.6)
            self.m_isScaled = true
        end

        self.m_rightTopValidTimeText.text = Language.GetString(2470)
    end

    self.m_rightMiddleContentText.text = emailInfo.content
    self.m_rightTopTitleText.text = emailInfo.title
end

function UIEmailView:OnReleaseItem(itemList)
    if itemList and #itemList > 0 then
        for i, v in ipairs(itemList) do
            v:Delete()
        end
    end
end

function UIEmailView:UpdateDataTaskItem(item, realIndex)
    if self.m_leftItemInfoList then
        if item and realIndex > 0 and realIndex <= #self.m_leftItemInfoList then
            local info = self.m_leftItemInfoList[realIndex]
            item:UpdateData(info, realIndex, info.isSelelct)
        end
    end
end

function UIEmailView:OnClick(go)
    if go.name == "blackBg" then
        Player:GetInstance():GetEmailMgr():SetEmailRedPoint()
        self:CloseSelf()
    elseif go.name == "deleteBtn" then
        self:ReqDeleteEmail()
    elseif go.name == "receive_BTN" then
        self:ReqTakeAttach()

    elseif go.name == "oneKeyReceive_BTN" then
        self:ReqTakeAttachList()
    end
end

function UIEmailView:ReqEnHanceAtk()
    local msg_id = MsgIDDefine.WORLDBOSS_REQ_ENHANCE_ATK
	local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UIEmailView:RsqBuyFightBossTime()
    local msg_id = MsgIDDefine.WORLDBOSS_REQ_BUY_FIGHT_BOSS_TIME
	local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UIEmailView:ReqBossRankList()
    local msg_id = MsgIDDefine.COMMONRANK_REQ_WORLD_BOSS_RANK
	local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UIEmailView:ReqTakeAttach()
    local msg_id = MsgIDDefine.MAIL_REQ_TAKE_ATTACH
    local msg = (MsgIDMap[msg_id])()
    msg.mail_seq = self.m_currSelectItem:GetMailSeq()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UIEmailView:ReqTakeAttachList()
    local msg_id = MsgIDDefine.MAIL_REQ_TAKE_ATTACH_LIST
    local msg = (MsgIDMap[msg_id])()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end

function UIEmailView:ReqDeleteEmail()
    local msg_id = MsgIDDefine.MAIL_REQ_DELETE_MAIL
    local msg = (MsgIDMap[msg_id])()
    msg.mail_seq = self.m_currSelectItem:GetMailSeq()
	HallConnector:GetInstance():SendMessage(msg_id, msg)
end
return UIEmailView



 --[[   --------------按照是否已读，有没有附件排序，  保留-----------------------------
        local count = #mailList
        local loadList = {}
        local delayLoadList = {} -- 已读没有附件
        local delayLoadCount = 0
        local delayLoadList1 = {} -- 已读有附件
        for i=1,count do
            if mailList[i].is_read == 1 then
                if mailList[i].attach_count <= 0 then
                    table_insert(delayLoadList, mailList[i])
                else
                    table_insert(delayLoadList1, mailList[i])
                end

                delayLoadCount = delayLoadCount + 1
            else
                table_insert(loadList, mailList[i])
            end
        end

        if delayLoadCount > 0 then
            for _,mailInfo in pairs(delayLoadList1) do
                if mailInfo then
                    table_insert(loadList, mailInfo)
                end
            end

            for _,mailInfo in pairs(delayLoadList) do
                if mailInfo then
                    table_insert(loadList, mailInfo)
                end
            end
        end
-----------------------------------------------------------------]]--












