function BlockQuote (el)
    local begin_raw = pandoc.RawBlock('latex', '\\begin{fancyquote}')
    local end_raw = pandoc.RawBlock('latex', '\\end{fancyquote}')
  
    -- Create a new list of blocks
    local new_blocks = pandoc.Blocks{}
  
    -- Append the 'begin' raw block
    new_blocks:insert(begin_raw)
  
    -- Append each block from the original content
    for _, block in ipairs(el.content) do
      new_blocks:insert(block)
    end
  
    -- Append the 'end' raw block
    new_blocks:insert(end_raw)
  
    return new_blocks
  end