-- ================================================================
--  KeyVault — Sistema de Key com Wind UI v2
--  Cole no Delta e execute
-- ================================================================

local HttpService  = game:GetService("HttpService")
local Players      = game:GetService("Players")
local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")

-- ================================================================
--  CONFIG
-- ================================================================
local BIN_ID = "69bce0feaa77b81da9ffb9ee"
local URL    = "https://api.jsonbin.io/v3/b/" .. BIN_ID .. "/latest"

-- ================================================================
--  CARREGA WIND UI v2
-- ================================================================
local WindUI
local ok, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
end)

if not ok then
    warn("[KeyVault] Falha ao carregar Wind UI: " .. tostring(err))
    return
end

-- ================================================================
--  FUNÇÃO: Busca key válida no jsonbin
-- ================================================================
local function getValidKey()
    local success, result = pcall(function()
        return HttpService:GetAsync(URL, true)
    end)
    if not success then return nil end
    local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, result)
    if not ok2 then return nil end
    if decoded and decoded.record and decoded.record.key then
        return decoded.record.key
    end
    return nil
end

-- ================================================================
--  CRIA JANELA WIND UI v2
-- ================================================================
local Window = WindUI:CreateWindow({
    Title       = "KeyVault",
    Icon        = "lock",
    Author      = "Sistema de Key",
    Folder      = "KeyVault",
    Size        = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme       = "Dark",
    Background  = true,
    Acrylic     = true,
    MenuOpen    = true,
})

local TabKey  = Window:Tab({ Title = "Key",  Icon = "key-round" })
local TabInfo = Window:Tab({ Title = "Info", Icon = "info"       })

-- ================================================================
--  TAB KEY
-- ================================================================
local SecKey = TabKey:Section({ Title = "Verificação de Acesso", Side = "Left" })

-- Guarda referência do TextBox do Input
local keyTextBox = nil
local keyInput   = ""

-- Cria o Input e tenta pegar o TextBox interno
local inputObj = SecKey:Input({
    Title       = "Sua Key",
    Description = "Cole a key e pressione Verificar",
    Placeholder = "XXXX-XXXX-XXXX-XXXXXXXXXXXX",
    Callback    = function(value)
        keyInput = value
    end,
})

-- Tenta pegar o TextBox diretamente da GUI pra não depender só do Callback
task.defer(function()
    -- percorre a PlayerGui procurando TextBoxes dentro da janela WindUI
    for _, gui in ipairs(playerGui:GetChildren()) do
        for _, tb in ipairs(gui:GetDescendants()) do
            if tb:IsA("TextBox") and tb.PlaceholderText == "XXXX-XXXX-XXXX-XXXXXXXXXXXX" then
                keyTextBox = tb
                break
            end
        end
    end
end)

-- Status
local statusParagraph = SecKey:Paragraph({
    Title   = "Status",
    Content = "Aguardando verificação...",
})

-- ================================================================
--  BOTÃO VERIFICAR
-- ================================================================
local isChecking = false

SecKey:Button({
    Title       = "✓ Verificar Key",
    Description = "Clique para validar sua key",
    Callback    = function()
        if isChecking then return end

        -- Pega o texto do TextBox direto se possível, senão usa o keyInput do Callback
        local typed = keyInput
        if keyTextBox then
            typed = keyTextBox.Text
        end
        typed = typed:gsub("^%s+", ""):gsub("%s+$", "") -- trim espaços

        if typed == "" then
            WindUI:Notify({
                Title   = "Campo Vazio",
                Content = "Cole sua key no campo acima antes de verificar.",
                Icon    = "alert-circle",
                Time    = 4,
            })
            return
        end

        isChecking = true

        WindUI:Notify({
            Title   = "Verificando...",
            Content = "Consultando o servidor, aguarde.",
            Icon    = "loader",
            Time    = 3,
        })

        task.spawn(function()
            local validKey = getValidKey()

            if validKey == nil then
                WindUI:Notify({
                    Title   = "Erro de Conexão",
                    Content = "Não foi possível verificar a key. Verifique sua internet.",
                    Icon    = "wifi-off",
                    Time    = 6,
                })

            elseif typed == validKey then
                -- ✅ KEY CORRETA
                WindUI:Notify({
                    Title   = "✓ Acesso Liberado!",
                    Content = "Key válida! Carregando script...",
                    Icon    = "check-circle",
                    Time    = 4,
                })

                task.wait(1.5)
                Window:Destroy()

                -- Executa o script principal
                loadstring(game:HttpGet("https://raw.githubusercontent.com/danielsan75008-ux/Teste-/refs/heads/main/E%20vc%20e%20corno"))()

            else
                -- ❌ KEY ERRADA
                WindUI:Notify({
                    Title   = "Key Invalid",
                    Content = "🇧🇷 Key invalida vá até o nosso Discord pegar a versão atualizada\n🇺🇸 Invalid key, go to our Discord server to get the updated version.",
                    Icon    = "x-circle",
                    Time    = 20,
                })
            end

            isChecking = false
        end)
    end,
})

-- ================================================================
--  TAB INFO
-- ================================================================
local SecInfo = TabInfo:Section({ Title = "Sobre o Sistema", Side = "Left" })

SecInfo:Paragraph({
    Title   = "Como funciona?",
    Content = "Este sistema verifica sua key em tempo real. Quando o dono atualizar a key pelo painel, a antiga para de funcionar imediatamente.",
})

SecInfo:Paragraph({
    Title   = "Key Inválida?",
    Content = "Se sua key não funcionar, pode ter sido alterada. Entre no Discord para obter a versão atualizada.",
})

SecInfo:Paragraph({
    Title   = "KeyVault System",
    Content = "Powered by jsonbin.io • Wind UI v2",
})
