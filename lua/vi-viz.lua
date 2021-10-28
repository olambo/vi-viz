local vizStack = {}
local vizLine = 1
local vizInd = 0
local vizOnKeyword = false
local vizWord = ''
local esc = vim.api.nvim_replace_termcodes('<esc>',true,false,true)

local function getNowNormalizedSelection(cursor)
  local cline, ccol = cursor[1], cursor[2] + 1
  local vline, vcol = vim.fn.line('v'), vim.fn.col('v')

  local sline, scol = vline, vcol
  local eline, ecol = cline, ccol

  local lines = vim.api.nvim_buf_get_lines(0, sline - 1, eline, 0)
  local line1 = lines[1]
  local startText = nil
  if line1 then
    startText = string.sub(lines[1], scol, ecol)
  end

  local tv = {}
  tv["ccol"] = ccol
  tv["sline"] = sline
  tv["eline"] = eline
  tv["scol"] = scol
  tv["ecol"] = ecol
  tv["stext"] = startText
  tv["lineText"] = line1
  return tv
end

local function normalizedVisualSel(setCur)
  local modeInfo = vim.api.nvim_get_mode()
  local mode = modeInfo.mode

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cline, ccol = cursor[1], cursor[2] + 1
  local vline, vcol = vim.fn.line('v'), vim.fn.col('v')
  -- if necessary, fix the orientation so cursor is at end
  if mode == 'v' or mode == 'V' then
    if ccol <= vcol or cline < vline then vim.cmd('normal! o') end
  else 
    -- visual block
    if cline < vline and ccol <= vcol then vim.cmd('normal! o') 
    elseif cline < vline and ccol > vcol then vim.cmd('normal! Oo') 
    elseif ccol < vcol then vim.cmd('normal! O') 
    end
  end
  return getNowNormalizedSelection(vim.api.nvim_win_get_cursor(0))
end

local function vizInsert()
  normalizedVisualSel()
  vim.api.nvim_input('o' .. esc .. 'i')
end

local function vizAppend()
  normalizedVisualSel()
  vim.api.nvim_input(esc .. 'a')
end

local function existsIn(val, tab)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

local function isKeyword()
  vizWord = vim.fn.expand("<cword>")
  vizInd = vim.fn.strridx(vim.fn.getline('.'), vim.fn.expand("<cword>"), vim.fn.col('.') - 1)
  vizOnKeyword = (vizInd >= 0 and (vizInd + vim.fn.strlen(vim.fn.expand("<cword>"))) >= (vim.fn.col('.') - 1))
end

local function vizIsMoved(tv)
  local tv1 = normalizedVisualSel()
  return tv1, tv['scol'] ~= tv1['scol'] or tv['ecol'] ~= tv1['ecol']
end

local function vizMoved(tv, who)
  local tv1, isMoved = vizIsMoved(tv)
  if not isMoved then return false end
  vizLine = tv1['sline']
  local viz = {}
  viz["scol"] = tv1['scol']
  viz["ecol"] = tv1['ecol']
  table.insert(vizStack, viz) 
  return true
end

local function vizQuotes(chrcol, txt, chr, tv) 
  -- is this an escaped quote
  if chrcol > 1 and string.sub(txt, chrcol-1, chrcol-1) == '\\' then return 0 end
  -- have we already got instances of this type of quote
  local stext = tv['stext']
  local _, quotecnt = string.gsub(stext, chr, "")
  local _, quoteminus = string.gsub(stext, '\\' .. chr, "")
  if quotecnt-quoteminus > 1 then return 0 end
  local ecol = tv['ecol']

  local achr, bchr, toright = '', string.sub(txt, ecol, ecol), 0
  for i = ecol+1, string.len(txt), 1 do 
    achr, bchr = bchr, string.sub(txt, i, i)
    if bchr == chr and achr ~= '\\' then 
      toright = i - ecol
      break
    end
  end
  return toright
end

local function vizExpand()
  local t = {'\'', '"', '`', '(', '[', '{'}
  local quotes = {"'", '"', '`'}
  local tv = normalizedVisualSel()

  if (tv['sline'] ~= tv['eline']) then return end

  if ( tv['scol'] == tv['ecol'] ) then 
    vizStack = {}
    local viz = {}
    viz["scol"] = tv['scol']
    viz["ecol"] = tv['ecol']
    table.insert(vizStack, viz) 

    local chr = vim.fn.matchstr(vim.fn.getline('.'), '\\%' .. vim.fn.col('.') .. 'c.') 
    local kwRegex = vim.regex([[\k]])
    if kwRegex:match_str(chr) then
      vim.cmd('normal! iw')
      if (vizMoved(tv)) then return end
    end
  end
  local txt = tv['lineText']
  local col = tv['scol'] - 1
  for i = col, 1, -1 do 
    local chr = string.sub(txt, i, i)
    if (existsIn(chr, t)) then 
      if (existsIn(chr, quotes)) then 
        -- 2i<quote> fails after word is selected, when quotes are unmatched
        local toright = vizQuotes(i, txt, chr, tv)
        if toright > 0 then 
          local toleft = col + 1 - i
          vim.cmd('normal! o' .. toleft .. 'h')
          vim.cmd('normal! o' .. toright .. 'l')
        end
      else
        vim.cmd('normal! a' .. chr)
      end
      if vizMoved(tv, 'textobject') then return end
    end
    if (i == 1) then
      vim.cmd('normal! $ho^')
      if vizMoved(tv, 'short line') then return end
    end
  end
  vim.cmd('normal! ip') 
end

local function vizExpand1Chr()
  local tv = normalizedVisualSel()
  local ccol, scol = tv["ccol"], tv["scol"] 
  vim.cmd('normal! ohol')
end

local function vizContract1Chr()
  local tv = normalizedVisualSel()
  local ccol, scol = tv["ccol"], tv["scol"] 
  vim.cmd('normal! oloh')
end

local function vizContract()
  local viz = table.remove(vizStack)
  if (viz == nil) then return end
  local scol = viz['scol']
  local ecol = viz['ecol']
  local tv = normalizedVisualSel()
  if (tv['sline'] ~= tv['eline']) then 
    vim.cmd('normal! ' .. esc .. 'v')
  end
  local ccol = tv['ccol']
  vim.cmd('normal! o') 
  vim.fn.setpos(".", {0, vizLine, scol})
  vim.cmd('normal! o')
  vim.fn.setpos(".", {0, vizLine, ecol})
end

local function getInput()
  local curline = vim.fn.getline('.')
  vim.fn.inputsave()
  local pattern = vim.fn.input('vi-viz>')
  vim.fn.inputrestore()
  return pattern
end

local function squareBracketOpen()  
    return [===[\[]===]
end
local function squareBracketClose ()
    return [===[\]]===]
end

local function getOp(chr, isSearchTerm)
  if chr == '[' or chr == ']' then
    if isSearchTerm then
      return squareBracketOpen(), squareBracketClose()
    else 
      return '[', ']'
    end
  elseif chr == '<' or chr == '>' then
    return '<', '>'
  elseif chr == '{' or chr == '}' then
    return '{', '}'
  elseif chr == '(' or chr == ')' then
    return '(', ')'
  elseif chr == '(' or chr == ')' then
    return '(', ')'
  elseif chr == '"' then
    return '"', '"'
  elseif chr == "'" then
    return "'", "'"
  elseif chr == "`" then
    return "`", "`"
  elseif chr == ';' then --todo: and isSearchTerm then
    return '', ''
  elseif chr == '' and not isSearchTerm then 
    return '', ''
  elseif chr == '.' then --todo: and isSearchTerm then
    return '.', '.'
  end
  return '?', '?'
end

local function vizChange(chr)
  local tv = normalizedVisualSel()
  local txt, col = tv["stext"], tv["scol"]
  if not txt or txt == '' then return end

  local command = 'c'
  if vizOnKeyword and vizWord == txt  then
    command = esc .. "ciw"
  end
  vim.api.nvim_feedkeys(command, 'n', false)
  -- vim.cmd('mess clear')
  -- print("vizchange command", command)
end

local function oneTxtChange(chr)
  local tv = normalizedVisualSel()
  local txt, col = tv["stext"], tv["scol"]
  if not txt or txt == '' then return end
  local txtLen = string.len(txt)
  local xsm, xtxt, xem = string.sub(txt, 1, 1), txt, string.sub(txt, string.len(txt))
  local osm, oem = getOp(xsm, true)
  local sm, em = getOp(chr, false)

  if sm == '?' or (sm == ";" and osm == "?") then return end
  if sm == '?' or (sm == "" and osm == "?") then return end
  if (osm == '?' or oem == '?') and osm ~= oem then return end
  if osm ~= '?' then xtxt = string.sub(txt, 2, string.len(txt)-1) end

  local command = 'c' .. sm .. xtxt .. em 
  if vizOnKeyword and vizWord == xtxt and osm .. oem == '??' then
    command = esc .. "ciw" .. sm .. xtxt .. em
  end
  vim.api.nvim_feedkeys(command, 'n', false)
  vim.api.nvim_feedkeys(esc,'n',false)
  -- vim.cmd('mess clear')
  -- print("oneTxtChange command", command)
end

local function patternChange(chr, patternType)
  local tv = normalizedVisualSel()
  local txt, col = tv["stext"], tv["scol"]
  if not txt or txt == '' then return end
  local txtLen = string.len(txt)
  local xsm, xtxt, xem = string.sub(txt, 1, 1), txt, string.sub(txt, string.len(txt))
  local osm, oem = getOp(xsm, true)

  local sm, em = getOp(chr, false)
  if sm == '?' or (sm == ";" and osm == "?") then return end
  if (osm == '?' or oem == '?') and osm ~= oem then return end
  if osm ~= '?' then xtxt = string.sub(txt, 2, string.len(txt)-1) end
  if chr == '.' then
    if osm == '?' or oem == '?' then
      osm, oem = '', ''
    end
    sm, em = osm, oem 
  end
  
  local mstr
  if patternType == 't' then
    xtxt = string.gsub(xtxt, "%[", squareBracketOpen())
    xtxt = string.gsub(xtxt, "%]", squareBracketClose())
    mstr = [[s/]] .. osm .. [[\(]] .. xtxt.. [[\)]] .. oem  .. '/' .. sm .. [[\1]]  .. em .. '/gIc' 
  elseif osm == '?' then
    mstr = [[s/\%]] .. col .. 'c' .. [[\(.\{]] .. txtLen .. [[}\)]]  .. '/' .. sm .. [[\1]]  .. em .. '/c' 
  else 
    mstr = [[s/\%]] .. col .. 'c' .. osm .. [[\([^]] .. osm ..[[]*\)]] .. oem .. '/' .. sm .. [[\1]] .. em .. '/c'
  end
  -- vim.cmd('mess clear')
  -- print('PatternChange: mstr', mstr, 'txt=', txt, 'osm=', osm, 'lineText=', tv["lineText"])
  vim.api.nvim_input(':' .. mstr)
end

local function vizPatternTxt()
  patternChange('.', 't')
  vim.api.nvim_input('<left><left><left><left>')
end

local function vizPattern()
  local modeInfo = vim.api.nvim_get_mode()
  local mode = modeInfo.mode
  local pattern = getInput()
  local chr1 = string.sub(pattern, 1, 1)
  if mode ~= 'v' and chr1 ~= 't' then 
    patternChange(pattern, chr1) -- todo: logic here
  elseif chr1 == 'p' or chr1 == 't' then
    patternChange(string.sub(pattern, 2), chr1)
  else
    oneTxtChange(pattern)
  end
end

local function vizInit()
  vizStack = {}
  isKeyword()
  vim.cmd('normal! ' .. esc .. 'v')
  local modeInfo = vim.api.nvim_get_mode()
  local mode = modeInfo.mode
  vizExpand()
end

local function vizStatus()
  print("vi-viz status is ok")
end

return {
  vizInit = vizInit,
  vizExpand = vizExpand,
  vizContract = vizContract,
  vizExpand1Chr = vizExpand1Chr,
  vizContract1Chr = vizContract1Chr,
  vizPattern = vizPattern,
  vizChange = vizChange,
  vizInsert = vizInsert,
  vizAppend = vizAppend,
  vizStatus = vizStatus,
}
