local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == "cpp"
end

function source:get_completions(_, callback)
  local template_path = "C:/Users/egod1/proj/ps/.template/atcoder.cpp"
  if vim.fn.filereadable(template_path) ~= 1 then
    callback({ items = {} })
    return
  end

  callback({
    items = {
      {
        label = "atcoder",
        detail = ".template/atcoder.cpp",
        kind = require("blink.cmp.types").CompletionItemKind.Snippet,
        insertText = table.concat(vim.fn.readfile(template_path), "\n"),
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      },
    },
  })
end

return source
