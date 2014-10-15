-----------------------------------------------------------------------------
-- GlyphStatus (c) 2011-2014 Rikard Glans (rikard@ecx.se)
----------------------------------------------------------------------------
-- Created: 2013-01-10 12:24:14
-- Time-stamp: <2014-10-15 22:30:39>
----------------------------------------------------------------------------
local NDEBUG = false;

local f = CreateFrame("Frame", "GlyphStatus");
f:RegisterEvent("ADDON_LOADED");
f:RegisterEvent("GLYPH_ADDED");
f:RegisterEvent("GLYPH_REMOVED");
f:RegisterEvent("GLYPH_UPDATED");
f:RegisterEvent("USE_GLYPH");
f:RegisterEvent("VARIABLES_LOADED");
f:RegisterEvent("PLAYER_ENTERING_WORLD");

f:SetScript("OnEvent",
function(self, event, ...)
  if(event == "ADDON_LOADED") then
    self:UnregisterEvent("ADDON_LOADED");

    _G.SLASH_GLYPHSTATUS1 = "/gs";
    _G.SLASH_GLYPHSTATUS2 = "/ngs";
    _G.SLASH_GLYPHSTATUS3 = "/glyphstatus";
    _G.SlashCmdList["GLYPHSTATUS"] = function(...) self:SlashCMD(...); end;
  elseif(event == "VARIABLES_LOADED") then
    self:UnregisterEvent("VARIABLES_LOADED");

    self.player = self:GetPlayer();
    self.class = self:GetClass();

    if(not GSDB) then
      GSDB = {};
    end

    if(not GSDB[self.player]) then
      self:Update();
    end

    self:Setup();
  else
    self:Update();
  end
end
)

function f:Setup()
  local LIST_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
  };

  f.ListFrame = CreateFrame("Frame", "GlyphStatusFrame", UIParent, "DialogBoxFrame");
  f.ListFrame:Hide();
  f.ListFrame:SetWidth(540);
  f.ListFrame:SetHeight(380);
  f.ListFrame:SetPoint("CENTER");
  f.ListFrame:SetFrameStrata("DIALOG");
  f.ListFrame:SetBackdrop(LIST_BACKDROP);
  f.ListFrame:SetMovable(true);
  f.ListFrame:EnableMouse(true);
  f.ListFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
      self:StartMoving();
      self.isMoving = true;
    end
  end)
  f.ListFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
      self:StopMovingOrSizing();
      self.isMoving = false;
    end
  end)
  f.ListFrame:SetScript("OnHide", function(self)
    if(self.isMoving) then
      self:StopMovingOrSizing();
      self.isMoving = false;
    end
  end)

  f.ListFrame_ScrollFrame = CreateFrame("ScrollFrame", "GlyphStatusListFrame_ScrollFrame", f.ListFrame, "UIPanelScrollFrameTemplate");
  f.ListFrame_ScrollFrame:SetPoint("TOP", -10, -30);
  f.ListFrame_ScrollFrame:SetWidth(f.ListFrame:GetWidth()-50);
  f.ListFrame_ScrollFrame:SetHeight(f.ListFrame:GetHeight()-80);

  f.ListFrame_ScrollText = CreateFrame("EditBox", "GlyphStatusListFrame_ScrollText", f.ListFrame_ScrollFrame);
  f.ListFrame_ScrollText:SetWidth(f.ListFrame_ScrollFrame:GetWidth()-50);
  f.ListFrame_ScrollText:SetHeight(f.ListFrame_ScrollFrame:GetHeight());
  f.ListFrame_ScrollText:SetAutoFocus(false);
  f.ListFrame_ScrollText:SetMultiLine(true);
  f.ListFrame_ScrollText:SetFontObject(ChatFontNormal);
  f.ListFrame_ScrollText:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end)

  f.ListFrame_Title = f.ListFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");

  f.ListFrame_ScrollFrame:SetScrollChild(f.ListFrame_ScrollText);

  tinsert(UISpecialFrames, "GlyphStatusFrame");
end

function f:GetPlayer(player)
  local char = string.lower((player or UnitName("player")) .. "@" .. GetRealmName():gsub("%W", ""));

  return(char);
end

function f:GetClass(player)
  local class = string.lower(select(2, UnitClass("player")));

  return(class);
end

function f:Update()
  db = {};
  db.faction = UnitFactionGroup("player");
  db.level = tostring(UnitLevel("player"));

  for i = 1, GetNumGlyphs() do
    local name, _, isKnown, _, id, link = GetGlyphInfo(i);

    if(name ~= "header" and isKnown == false) then
      g       = {};
      g.name  = name;
      g.known = isKnown;
      g.id    = id;
      g.link  = link;

      table.insert(db, g);
    end
  end

  GSDB[self.player] = db;
end

function f:List(char)
  local c = 0;

  if(not string.find(char, "@")) then
    char = f:GetPlayer(char);
  end

  if(not GSDB[char]) then
    self:Printf("%s not found.", char);
    self:Help();
    return(1);
  end

  f.ListFrame_ScrollText:SetText("");

  local title = "GlyphStatus - " .. char .. "'s missing glyphs";
  f.ListFrame_Title:SetText(title);
  f.ListFrame_Title:SetPoint("TOPLEFT", ((f.ListFrame:GetWidth() - f.ListFrame_Title:GetStringWidth()) / 2), -5);

  for _, glyph in pairs(GSDB[char]) do
    if(glyph and glyph.name) then
      self:Debug("glyph.name: " .. glyph.name);

      f.ListFrame_ScrollText:Insert(glyph.name .. "\n");

      c = c + 1;
    end
  end

  if(c == 0) then
    self:Printf("%s knows 'em all, yay!", char);
  else
    f.ListFrame:Show();
  end
end

function f:SlashCMD(str)
  local cmd = string.lower(str);

  if(not cmd or cmd == "" or cmd == "help" or cmd == "h") then
    self:Help();
  elseif(cmd == "_z") then -- Zap
    GSDB = {};
  elseif(cmd == "_u") then -- Update
    self:Update();
  elseif(cmd == "me") then
    self:List(self:GetPlayer());
  else
    self:List(cmd);
  end
end

function f:Help()
  self:Print("Usage: /gs <character>");
end

function f:Print(msg)
  SELECTED_CHAT_FRAME:AddMessage("[GlyphStatus] " .. msg);
end

function f:Printf(msg, ...)
  SELECTED_CHAT_FRAME:AddMessage("[GlyphStatus] " .. msg:format(...));
end

function f:Debug(msg)
  if(NDEBUG) then
    SELECTED_CHAT_FRAME:AddMessage("[GlyphStatus DEBUG] " .. msg);
  end
end

function f:Debugf(msg, ...)
  if(NDEBUG) then
    SELECTED_CHAT_FRAME:AddMessage("[GlyphStatus DEBUG] " .. msg:format(...));
  end
end

