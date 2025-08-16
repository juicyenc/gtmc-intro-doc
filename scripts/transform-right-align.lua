-- right_align_filter_v2.lua

function RawBlock (block)
    -- Only act on HTML raw blocks
    if block.format == 'html' then
      -- Get the full text content of the raw block
      local content = block.text
  
      -- Perform a global search and replace for the HTML tags
      -- The gsub function is robust and handles multiple replacements
      content = content:gsub('<div align="right">', '\\begin{flushright}')
      content = content:gsub('</div>', '\\end{flushright}')
  
      -- Create a new RawBlock with the modified LaTeX content
      -- This new block has a 'latex' format, so it will be preserved in the output
      return pandoc.RawBlock('latex', content)
    end
    
    -- If it's not an HTML block we're interested in, do nothing
    return nil
  end