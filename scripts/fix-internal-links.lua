-- Pandoc Lua 过滤器：修复Markdown内部链接（基于最新规范）
-- 功能：自动修正内部链接以匹配Pandoc生成的标题ID
-- 符合Pandoc 2.17+ Lua过滤器规范

local function to_identifier(str)
  -- 根据Pandoc手册实现标识符生成算法
  -- 1. 转换为小写
  local s = string.lower(str)
  -- 2. 用连字符替换空格和换行
  s = s:gsub("%s+", "-")
  -- 3. 移除非字母数字、非下划线、非连字符的字符（保留非ASCII字符）
  s = s:gsub("[^%w_%-]", "")  -- 使用%-匹配连字符字面值
  -- 4. 压缩连续连字符
  s = s:gsub("-+", "-")
  -- 5. 移除开头/结尾连字符
  s = s:gsub("^-", "")
  s = s:gsub("-$", "")
  -- 6. 处理空标识符
  if s == "" then
    return "section"
  end
  return s
end

local header_ids = {} -- 存储标题ID映射 {规范化ID: 实际ID列表}
local raw_text_to_id = {} -- 新增：存储原始文本到实际ID的映射

-- 处理标题元素：生成标准ID并记录映射
function Header(el)
    local raw_text = pandoc.utils.stringify(el.content)
    local normalized = to_identifier(raw_text)
    
    -- 初始化该规范化ID的记录
    header_ids[normalized] = header_ids[normalized] or {}
    local ids = header_ids[normalized]
    
    -- 生成实际ID（处理重复情况）
    local actual_id
    if #ids == 0 then
        actual_id = normalized
    else
        actual_id = normalized .. "-" .. tostring(#ids)
    end
    
    -- 存储ID映射
    table.insert(ids, actual_id)
    -- 新增：存储原始文本到实际ID的映射
    raw_text_to_id[raw_text] = actual_id
    
    el.identifier = actual_id
    return el
end

-- 处理链接元素：修正内部链接目标
function Link(el)
    local target = el.target
    -- 只处理纯内部链接（以"#"开头且不包含路径分隔符或协议标识）
    if target:sub(1,1) == "#" then
        local anchor = target:sub(2)
        local target_found
        
        -- 优先使用原始锚点文本查找
        if raw_text_to_id[anchor] then
            target_found = raw_text_to_id[anchor]
        else
            -- 原始文本找不到时尝试规范化文本
            local normalized = to_identifier(anchor)
            if header_ids[normalized] then
                -- 检查是否指定了后缀（如"#heading-1"）
                local base, suffix = normalized:match("^(.-)(%-%d+)$")
                
                if suffix then
                    -- 精确匹配带后缀的ID
                    local full_id = base .. suffix
                    for _, id in ipairs(header_ids[base] or {}) do
                        if id == full_id then
                            target_found = full_id
                            break
                        end
                    end
                else
                    -- 无后缀时使用第一个匹配项
                    target_found = header_ids[normalized][1]
                end
            end
        end
        
        -- 更新链接目标
        if target_found then
            el.target = "#" .. target_found
        end
    end
    return el
end

-- 返回过滤器配置
return {
    {Header = Header},
    {Link = Link},
    traverse = 'typewise' -- 先处理标题再处理链接
}