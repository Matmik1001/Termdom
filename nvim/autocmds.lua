-- ══════════════════════════════════════════════════════════════════
--  TERMDOM — Neovim Auto-Compilation Autocmds
--  File: ~/.config/nvim/lua/config/autocmds.lua  (append or merge)
--
--  Compiles C, C++, Rust on BufWritePost (save).
--  Output is shown in a split terminal at the bottom.
--  Each filetype gets a smart compile command that handles:
--    C/C++ → g++/gcc with -std=c++20 -Wall -Wextra -g
--    Rust  → cargo build (project-aware) or rustc (single file)
--    Java  → javac
-- ══════════════════════════════════════════════════════════════════

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- ── Helper: run a shell command in a bottom split terminal ────────
local function compile_in_terminal(cmd, label)
  label = label or "Build"

  -- Close any existing build terminal
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:find("termdom_build") then
        vim.api.nvim_buf_delete(buf, { force = true })
        break
      end
    end
  end

  -- Open a new bottom split terminal
  vim.cmd("botright 12split")
  vim.cmd("terminal " .. cmd)

  -- Rename the buffer so we can find/close it next time
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "termdom_build_" .. tostring(buf))

  -- Style the terminal buffer
  vim.cmd("setlocal nonumber norelativenumber signcolumn=no")
  vim.wo.winhighlight = "Normal:NormalFloat"

  -- Auto-scroll to bottom
  vim.cmd("normal! G")

  -- Map 'q' and <Esc> to close the build window
  vim.keymap.set("n", "q",   "<cmd>bd!<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>bd!<CR>", { buffer = buf, silent = true })

  -- Return focus to the source file window
  vim.cmd("wincmd p")

  vim.notify(
    string.format("[Termdom] %s running…", label),
    vim.log.levels.INFO,
    { title = "Auto-Compile" }
  )
end

-- ── Helper: find project root by walking up the dir tree ──────────
local function find_root(markers)
  local path = vim.fn.expand("%:p:h")
  while path ~= "/" do
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(path .. "/" .. marker) == 1 or
         vim.fn.isdirectory(path .. "/" .. marker) == 1 then
        return path
      end
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  return nil
end

-- ══════════════════════════════════════════════════════════════════
--  C Auto-Compile
-- ══════════════════════════════════════════════════════════════════
local c_group = augroup("TermdomAutoCompileC", { clear = true })

autocmd("BufWritePost", {
  group   = c_group,
  pattern = "*.c",
  callback = function()
    local src    = vim.fn.expand("%:p")
    local stem   = vim.fn.expand("%:t:r")
    local dir    = vim.fn.expand("%:p:h")
    local out    = dir .. "/" .. stem

    -- Prefer Makefile if one exists in project root
    local make_root = find_root({ "Makefile", "makefile" })
    local cmd

    if make_root then
      cmd = string.format("cd '%s' && make 2>&1", make_root)
    else
      cmd = string.format(
        "gcc -std=c11 -Wall -Wextra -g -o '%s' '%s' 2>&1 && echo '✓ Build OK: %s'",
        out, src, stem
      )
    end

    compile_in_terminal(cmd, "C Build")
  end,
})

-- ══════════════════════════════════════════════════════════════════
--  C++ Auto-Compile
-- ══════════════════════════════════════════════════════════════════
local cpp_group = augroup("TermdomAutoCompileCPP", { clear = true })

autocmd("BufWritePost", {
  group   = cpp_group,
  pattern = { "*.cpp", "*.cc", "*.cxx" },
  callback = function()
    local src  = vim.fn.expand("%:p")
    local stem = vim.fn.expand("%:t:r")
    local dir  = vim.fn.expand("%:p:h")
    local out  = dir .. "/" .. stem

    local cmake_root = find_root({ "CMakeLists.txt" })
    local make_root  = find_root({ "Makefile", "makefile" })
    local cmd

    if cmake_root then
      -- CMake project: build in build/ dir
      cmd = string.format(
        "cd '%s' && cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON 2>&1 && cmake --build build 2>&1 && echo '✓ CMake Build OK'",
        cmake_root
      )
    elseif make_root then
      cmd = string.format("cd '%s' && make 2>&1", make_root)
    else
      cmd = string.format(
        "g++ -std=c++20 -Wall -Wextra -Wpedantic -g -o '%s' '%s' 2>&1 && echo '✓ Build OK: %s'",
        out, src, stem
      )
    end

    compile_in_terminal(cmd, "C++ Build")
  end,
})

-- ══════════════════════════════════════════════════════════════════
--  Rust Auto-Compile
-- ══════════════════════════════════════════════════════════════════
local rust_group = augroup("TermdomAutoCompileRust", { clear = true })

autocmd("BufWritePost", {
  group   = rust_group,
  pattern = "*.rs",
  callback = function()
    local src        = vim.fn.expand("%:p")
    local stem       = vim.fn.expand("%:t:r")
    local cargo_root = find_root({ "Cargo.toml" })
    local cmd

    if cargo_root then
      -- Cargo project: use cargo check (fast) on every save, full build on demand
      cmd = string.format(
        "cd '%s' && cargo check 2>&1 && echo '✓ Cargo check OK'",
        cargo_root
      )
    else
      local out = vim.fn.expand("%:p:h") .. "/" .. stem
      cmd = string.format(
        "rustc '%s' -o '%s' 2>&1 && echo '✓ Build OK: %s'",
        src, out, stem
      )
    end

    compile_in_terminal(cmd, "Rust Build")
  end,
})

-- ══════════════════════════════════════════════════════════════════
--  Java Auto-Compile
-- ══════════════════════════════════════════════════════════════════
local java_group = augroup("TermdomAutoCompileJava", { clear = true })

autocmd("BufWritePost", {
  group   = java_group,
  pattern = "*.java",
  callback = function()
    local src = vim.fn.expand("%:p")
    local dir = vim.fn.expand("%:p:h")
    local cmd = string.format(
      "javac -d '%s' '%s' 2>&1 && echo '✓ Compiled OK'",
      dir, src
    )
    compile_in_terminal(cmd, "Java Build")
  end,
})

-- ══════════════════════════════════════════════════════════════════
--  Manual build keymap  <leader>b → rebuild current file/project
-- ══════════════════════════════════════════════════════════════════
vim.keymap.set("n", "<leader>b", function()
  -- Re-trigger the BufWritePost autocmd by faking a write event
  vim.cmd("doautocmd BufWritePost " .. vim.fn.expand("%"))
end, { desc = "[Termdom] Manual build", silent = true })

-- ══════════════════════════════════════════════════════════════════
--  Cargo run keymap  <leader>r → cargo run in terminal split
-- ══════════════════════════════════════════════════════════════════
vim.keymap.set("n", "<leader>r", function()
  local cargo_root = find_root({ "Cargo.toml" })
  if cargo_root then
    compile_in_terminal(string.format("cd '%s' && cargo run 2>&1", cargo_root), "Cargo Run")
  else
    local src  = vim.fn.expand("%:p")
    local stem = vim.fn.expand("%:t:r")
    local out  = vim.fn.expand("%:p:h") .. "/" .. stem
    local ext  = vim.fn.expand("%:e")
    local cmd
    if ext == "cpp" or ext == "cc" then
      cmd = string.format("g++ -std=c++20 -o '%s' '%s' && '%s'", out, src, out)
    elseif ext == "c" then
      cmd = string.format("gcc -o '%s' '%s' && '%s'", out, src, out)
    else
      cmd = string.format("./'%s'", out)
    end
    compile_in_terminal(cmd, "Run")
  end
end, { desc = "[Termdom] Run binary / cargo run", silent = true })
