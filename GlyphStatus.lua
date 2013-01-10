-----------------------------------------------------------------------------
-- GlyphStatus (c) 2011-2012 Rikard Glans (rikard@ecx.se)
----------------------------------------------------------------------------
local f = CreateFrame("Frame", "GlyphStatus");
f:RegisterEvent("ADDON_LOADED");
f:RegisterEvent("GLYPH_ADDED");
f:RegisterEvent("GLYPH_REMOVED");
f:RegisterEvent("GLYPH_UPDATED");
f:RegisterEvent("USE_GLYPH");
f:RegisterEvent("VARIABLES_LOADED");
f:RegisterEvent("PLAYER_ENTERING_WORLD");

local NDEBUG = false;

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
              else
                self:Update();
              end
          end
)

function f:GetPlayer(player)
  local char = string.lower((player or UnitName("player")) .. "@" .. GetRealmName());

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
  local txt = 0;

  if(not string.find(char, "@")) then
    char = f:GetPlayer(char);
  end

  if(not GSDB[char]) then
    self:Print(string.format("DEBUG: %s not found.", char));
    self:Help();
    return(1);
  end

  self:Printf("%s is missing the following glyphs:", char);
  for _, glyph in pairs(GSDB[char]) do
    if(glyph and glyph.name) then
      self:Debug("glyph.name: " .. glyph.name);

      if(glyph.link) then
        txt = c+1 .. ": " .. glyph.link;
      else
        txt = c+1 .. ": " .. glyph.name;
      end

      self:Print(txt);

      c = c + 1;
    end
  end

  if(c == 0) then
    self:Printf("%s knows 'em all, yay!", char);
  else
    self:Printf("Glyphs missing: %d", c);
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
  SELECTED_CHAT_FRAME:AddMessage(msg);
end

function f:Printf(msg, ...)
  SELECTED_CHAT_FRAME:AddMessage(msg:format(...));
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

