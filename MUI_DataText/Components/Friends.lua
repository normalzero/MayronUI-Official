local _, namespace = ...;

-- luacheck: ignore MayronUI self 143 631
local tk, _, em, _, obj, L = MayronUI:GetCoreComponents();
local ComponentsPackage = namespace.ComponentsPackage;

local LABEL_PATTERN = L["Friends"]..": |cffffffff%u|r";
local convert = {WTCG = "HS", Pro = "OW"};

local ToggleFriendsFrame, GetNumFriends, GetFriendInfo = _G.ToggleFriendsFrame, _G.GetNumFriends, _G.GetFriendInfo;
local BNGetNumFriends, BNGetFriendInfo = _G.BNGetNumFriends, _G.BNGetFriendInfo;

-- Register and Import Modules -------

local Friends = ComponentsPackage:CreateClass("Friends", nil, "IDataTextComponent");

-- Local Functions -------------------

local CreateLabel;
do
    local onLabelClickFunc;

     function CreateLabel(contentFrame, slideController)
        local label = tk:PopFrame("Button", contentFrame);

        label.name = label:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        label.name:SetPoint("LEFT", 6, 0);
        label.name:SetPoint("RIGHT", -10, 0);
        label.name:SetWordWrap(false);
        label.name:SetJustifyH("LEFT");

        if (not onLabelClickFunc) then
            onLabelClickFunc = function(self)
                _G.ChatFrame1EditBox:SetAttribute("tellTarget", self.id);
                _G.ChatMenu_SetChatType(_G.ChatFrame1, "SMART_WHISPER");
                slideController:Start(slideController.Static.FORCE_RETRACT);
            end
        end

        label:SetScript("OnClick", onLabelClickFunc);

        return label;
    end
end

-- Friends Module --------------

MayronUI:Hook("DataTextModule", "OnInitialize", function(self)
    self:RegisterDataModule("friends", Friends);
end);

function Friends:__Construct(data, settings, dataTextModule, slideController)
    data.settings = settings;
    data.slideController = slideController;

    -- set public instance properties
    self.MenuContent = _G.CreateFrame("Frame");
    self.MenuLabels = obj:PopTable();
    self.TotalLabelsShown = 0;
    self.HasLeftMenu = true;
    self.HasRightMenu = false;
    self.Button = dataTextModule:CreateDataTextButton();
end

function Friends:SetEnabled(data, enabled)
    data.enabled = enabled;

    if (enabled) then
        data.handler = em:CreateEventHandler("FRIENDLIST_UPDATE", function()
            if (not self.Button) then return; end
            self:Update();
        end);

        self.Button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    else
        if (data.handler) then
            data.handler:Destroy();
            data.handler = nil;
        end

        self.Button:RegisterForClicks("LeftButtonUp");
    end
end

function Friends:IsEnabled(data)
    return data.enabled;
end

function Friends:Update(data, refreshSettings)
    if (refreshSettings) then
        data.settings:Refresh();
    end

    local totalOnline = 0;

    for i = 1, BNGetNumFriends() do
        if ((select(8, BNGetFriendInfo(i)))) then
            totalOnline = totalOnline + 1;
        end
    end

    for i = 1, GetNumFriends() do
        if ((tk.select(5, GetFriendInfo(i)))) then
            totalOnline = totalOnline + 1;
        end
    end

    self.Button:SetText(tk.string.format(LABEL_PATTERN, totalOnline));
end

function Friends:Click(data, button)
    if (button == "RightButton") then
        ToggleFriendsFrame();
        return;
    end

    if (select(2, GetNumFriends()) == 0 and tk.select(2, BNGetNumFriends()) == 0) then
        return true;
    end

    local r, g, b = tk:GetThemeColor();
    local totalLabelsShown = 0;

    -- Battle.Net friends
    for i = 1, BNGetNumFriends() do
        local _, realName, _, _, _, _, client, online, _, isAFK, isDND = BNGetFriendInfo(i);

        if (online) then
            totalLabelsShown = totalLabelsShown + 1;

            local status = (isAFK and "|cffffe066[AFK] |r") or (isDND and "|cffff3333[DND] |r") or "";
            local label = self.MenuLabels[totalLabelsShown] or CreateLabel(self.MenuContent, data.slideController);
            self.MenuLabels[totalLabelsShown] = label;

            label.id = realName;
            label:SetNormalTexture(1);
            label:GetNormalTexture():SetColorTexture(r * 0.4, g * 0.4, b * 0.4, 0.2);
            label:SetHighlightTexture(1);
            label:GetHighlightTexture():SetColorTexture(r * 0.4, g * 0.4, b * 0.4, 0.4);

            if (not client or client == "App") then
                client = "";
            else
                client = convert[client] or client;
                client = tk.string.format(" (%s)", client);
            end

            label.name:SetText(tk.string.format("%s%s%s", status , realName, client));
        end
    end

    -- WoW Friends (non-Battle.Net)
    for i = 1, GetNumFriends() do
        local name, level, class, _, online, status = GetFriendInfo(i);

        if (online) then
            local classFileName = tk:GetIndex(tk.Constants.LOCALIZED_CLASS_NAMES, class) or class;

            if (status:trim() == "<Away") then
                status = " |cffffe066[AFK]|r";
            elseif (status:trim() == "<DND>") then
                status = " |cffff3333[DND]|r";
            else
                status = tk.Strings.Empty;
            end

            totalLabelsShown = totalLabelsShown + 1;

            local label = self.MenuLabels[totalLabelsShown] or CreateLabel(self.MenuContent, data.slideController);
            self.MenuLabels[totalLabelsShown] = label; -- old: numBNFriends + i

            label.id = name;
            label:SetNormalTexture(1);
            label:GetNormalTexture():SetColorTexture(0, 0, 0, 0.2);
            label:SetHighlightTexture(1);
            label:GetHighlightTexture():SetColorTexture(0.2, 0.2, 0.2, 0.4);
            label.name:SetText(tk.string.format("%s%s %s ",
                tk:GetClassColoredString(classFileName, name), status, level));
        end
    end

    self.TotalLabelsShown = totalLabelsShown;
end