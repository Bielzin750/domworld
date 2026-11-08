-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- Modified for DomWorld, 2026 — see git history for details.
-- Loaded by Main only after the server confirms this player's administrator access.

--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local shared_ui = ReplicatedStorage:WaitForChild("DomWorld"):WaitForChild("UI")
local Theme = require(shared_ui:WaitForChild("Theme"))
local Icons = require(shared_ui:WaitForChild("Icons"))

local AdminPanel = {}
AdminPanel.__index = AdminPanel

local C = Theme.Colors
local FONT = Enum.Font.Gotham
local FONT_MEDIUM = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_NUMERIC = Enum.Font.Code

local function create(class_name: string, props: { [string]: any }, parent: Instance): Instance
	local node = Instance.new(class_name)
	for key, value in props do
		(node :: any)[key] = value
	end
	node.Parent = parent
	return node
end

local function corner(parent: Instance, radius: number?)
	create("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Radii.small) }, parent)
end

local function stroke(parent: Instance, color: Color3?, transparency: number?)
	create("UIStroke", {
		Color = color or C.line,
		Transparency = transparency or 0,
		Thickness = 1,
	}, parent)
end

function AdminPanel.new(initial: any, get_state: RemoteFunction, action_remote: RemoteFunction, world: any)
	local self = setmetatable({}, AdminPanel)
	self.state = initial
	self.shortcut_key = if type(initial.shortcut_key) == "string" then initial.shortcut_key else "F10"
	self.get_state_remote = get_state
	self.action_remote = action_remote
	self.world = world
	self.tab = "CONTA"
	self.selected_user = nil :: number?
	self.selected_owner = nil :: number?
	self.confirm = nil :: string?
	self.confirm_at = 0.0
	self.busy = false
	self._connections = {}
	self:_build()
	return self
end

function AdminPanel._build(self: any)
	local player_gui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local gui = create("ScreenGui", {
		Name = "DomWorldAdmin",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 80,
	}, player_gui) :: ScreenGui
	self.gui = gui
	local panel = create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.90, 0.80),
		BackgroundColor3 = C.surface,
		BorderSizePixel = 0,
		Visible = false,
	}, gui) :: Frame
	corner(panel, Theme.Radii.large)
	stroke(panel, C.lineStrong, 0)
	create("UISizeConstraint", { MinSize = Vector2.new(300, 230), MaxSize = Vector2.new(820, 680) }, panel)
	self.panel = panel
	local header = create("Frame", {
		Name = "Header",
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -24, 0, 40),
		BackgroundTransparency = 1,
	}, panel) :: Frame
	self.header = header
	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, -112, 1, 0),
		Font = FONT_BOLD,
		Text = "DOMWORLD  /  CONTROLE",
		TextColor3 = C.text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)
	local refresh = self:_button(header, "ATUALIZAR", UDim2.new(1, -170, 0, 0), UDim2.fromOffset(76, 40))
	refresh.Activated:Connect(function()
		self:_refresh()
	end)
	local close = self:_button(header, "FECHAR", UDim2.new(1, -78, 0, 0), UDim2.fromOffset(78, 40))
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	local tabs = create("Frame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(12, 56),
		Size = UDim2.new(1, -24, 0, 44),
		BackgroundTransparency = 1,
	}, panel) :: Frame
	self.tabs = tabs
	local tab_layout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, tabs)
	tab_layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	self.tab_buttons = {}
	self.tab_labels = {}
	self.tab_icons = {}
	local tab_icons = {
		CONTA = { name = "wallet", glyph = "◆" },
		MAPA = { name = "map", glyph = "▦" },
		PARTIDA = { name = "schedule", glyph = "◷" },
		REGISTRO = { name = "info", glyph = "≡" },
		EQUIPE = { name = "users", glyph = "◇" },
	}
	local tab_names = { "CONTA", "MAPA", "PARTIDA", "REGISTRO" }
	if self.state.role == "owner" then
		table.insert(tab_names, "EQUIPE")
	end
	for index, tab in tab_names do
		local button = self:_button(tabs, tab, UDim2.new(), UDim2.new(1 / #tab_names, -5, 1, 0))
		button.LayoutOrder = index
		button.Text = ""
		self.tab_buttons[tab] = button
		local spec = tab_icons[tab]
		local sprite = Icons.get(spec.name)
		local icon = if sprite ~= nil
			then create("ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 3),
				Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1,
				Image = sprite.Image,
				ImageRectOffset = sprite.ImageRectOffset,
				ImageRectSize = sprite.ImageRectSize,
				ImageColor3 = C.textMuted,
				ScaleType = Enum.ScaleType.Fit,
			}, button)
			else create("TextLabel", {
				Name = "IconFallback",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 2),
				Size = UDim2.fromOffset(18, 18),
				BackgroundTransparency = 1,
				Font = FONT_BOLD,
				Text = spec.glyph,
				TextColor3 = C.textMuted,
				TextSize = 15,
			}, button)
		self.tab_icons[tab] = icon
		self.tab_labels[tab] = create("TextLabel", {
			Name = "TabLabel",
			Position = UDim2.new(0, 1, 1, -19),
			Size = UDim2.new(1, -2, 0, 16),
			BackgroundTransparency = 1,
			Font = FONT_BOLD,
			Text = tab,
			TextColor3 = C.textMuted,
			TextSize = 10,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, button)
		button.Activated:Connect(function()
			self.tab = tab
			self.confirm = nil
			self:_render()
		end)
	end
	local content = create("ScrollingFrame", {
		Name = "Content",
		Position = UDim2.fromOffset(12, 100),
		Size = UDim2.new(1, -24, 1, -146),
		BackgroundColor3 = C.canvas,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.lineStrong,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, panel) :: ScrollingFrame
	corner(content)
	self.content = content
	local status = create("TextLabel", {
		Name = "Status",
		Position = UDim2.new(0, 12, 1, -38),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundTransparency = 1,
		Font = FONT_MEDIUM,
		Text = "Acesso autorizado pelo servidor.",
		TextColor3 = C.textMuted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, panel) :: TextLabel
	self.status = status
	table.insert(
		self._connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
			if processed or UserInputService:GetFocusedTextBox() ~= nil then
				return
			end
			local shortcut = Enum.KeyCode[self.shortcut_key]
			if shortcut ~= nil and input.KeyCode == shortcut then
				panel.Visible = not panel.Visible
				if panel.Visible then
					self:_refresh()
				end
			end
		end)
	)
	self:_render()
end

function AdminPanel._button(_self: any, parent: Instance, text: string, position: UDim2, size: UDim2): TextButton
	local button = create("TextButton", {
		Position = position,
		Size = size,
		BackgroundColor3 = C.surfaceRaised,
		BorderSizePixel = 0,
		Font = FONT_MEDIUM,
		Text = text,
		TextColor3 = C.text,
		TextSize = 12,
		AutoButtonColor = false,
	}, parent) :: TextButton
	corner(button)
	stroke(button, C.line, 0.15)
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = C.surfaceHigh
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = C.surfaceRaised
	end)
	return button
end

function AdminPanel._clear(self: any)
	self.content:ClearAllChildren()
	corner(self.content)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 12),
	}, self.content)
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 7),
	}, self.content)
end

function AdminPanel._label(self: any, text: string, height: number?, color: Color3?)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -2, 0, height or 26),
		Font = FONT,
		Text = text,
		TextColor3 = color or C.textMuted,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, self.content)
end

function AdminPanel._input(self: any, placeholder: string, initial: string?): TextBox
	local box = create("TextBox", {
		BackgroundColor3 = C.surface,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = FONT_NUMERIC,
		PlaceholderText = placeholder,
		PlaceholderColor3 = C.textDim,
		Text = initial or "",
		TextColor3 = C.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -2, 0, 44),
	}, self.content) :: TextBox
	corner(box)
	stroke(box, C.line, 0.1)
	create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
	return box
end

function AdminPanel._row(self: any): Frame
	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -2, 0, 44),
	}, self.content) :: Frame
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, row)
	return row
end

function AdminPanel._row_button(self: any, row: Frame, text: string, callback: () -> (), width: number?)
	local button = self:_button(row, text, UDim2.new(), UDim2.new(0, width or 132, 1, 0))
	button.Activated:Connect(callback)
	return button
end

function AdminPanel._owner(self: any): any
	local owners = self.state.match.owners or {}
	for _, owner in owners do
		if owner.id == self.selected_owner then
			return owner
		end
	end
	return nil
end

function AdminPanel._render(self: any)
	self:_clear()
	for tab, button in self.tab_buttons do
		local selected = tab == self.tab
		button.BackgroundColor3 = if selected then C.primaryDeep else C.surfaceRaised
		self.tab_labels[tab].TextColor3 = if selected then C.white else C.textMuted
		if self.tab_icons[tab]:IsA("ImageLabel") then
			(self.tab_icons[tab] :: ImageLabel).ImageColor3 = if selected then C.white else C.textMuted
		else
			(self.tab_icons[tab] :: TextLabel).TextColor3 = if selected then C.white else C.textMuted
		end
	end
	if self.tab == "CONTA" then
		self:_render_account()
	elseif self.tab == "MAPA" then
		self:_render_map()
	elseif self.tab == "PARTIDA" then
		self:_render_match()
	elseif self.tab == "EQUIPE" and self.state.role == "owner" then
		self:_render_team()
	else
		self:_render_logs()
	end
end

function AdminPanel._render_account(self: any)
	local players = self.state.players or {}
	self:_label("CONTA · JOGADORES CONECTADOS", 22, C.primary)
	for _, target in players do
		local button = self:_button(
			self.content,
			string.format(
				"%s · %d · %d Stars · %d cosméticos",
				target.name,
				target.user_id,
				target.stars,
				target.cosmetics
			),
			UDim2.new(),
			UDim2.new(1, -2, 0, 36)
		)
		button.TextXAlignment = Enum.TextXAlignment.Left
		create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, button)
		button.BackgroundColor3 = if target.user_id == self.selected_user then C.primaryDeep else C.surfaceRaised
		button.Activated:Connect(function()
			self.selected_user = target.user_id
			self.confirm = nil
			self:_refresh()
		end)
	end
	if #players == 0 then
		self:_label("Nenhum jogador conectado neste servidor.")
		return
	end
	local selected = nil
	for _, target in players do
		if target.user_id == self.selected_user then
			selected = target
			break
		end
	end
	if selected == nil then
		self:_label("Selecione uma conta conectada para consultar ou editar os dados persistidos.")
		return
	end
	local account = self.state.account
	if account == nil or account.user_id ~= selected.user_id then
		self:_label("Carregando perfil persistido…")
		return
	end
	self:_label(string.format("ALVO · %s (%d)", selected.name, selected.user_id), 24, C.text)
	self:_label(
		string.format(
			"STARS · %d disponíveis · %d ganhas em partidas · %d recibos Roblox",
			account.stars,
			account.stars_earned,
			account.receipt_count
		),
		34,
		C.text
	)
	local credit_text = {}
	for id, count in account.credits do
		table.insert(credit_text, string.format("%s: %d", id, count))
	end
	table.sort(credit_text)
	self:_label(
		string.format(
			"INVENTÁRIO · %d cosméticos · %d Arsenal · caixas compradas: %d · skin: %s · bandeira: %s",
			#account.owned,
			#account.unlocks,
			account.crates_bought,
			tostring(account.equipped.skin or "nenhuma"),
			tostring(account.equipped.flag or "nenhuma")
		),
		44
	)
	self:_label(
		"Créditos: "
			.. (if #credit_text > 0 then table.concat(credit_text, " · ") else "nenhum")
			.. string.format(
				" · já pagou Robux: %s · tutorial: %s",
				tostring(account.paid),
				tostring(account.tutorial_paid)
			),
		34
	)
	self:_label(
		"Moedas persistentes: Stars. Ouro existe apenas durante uma partida; gemas, nível e XP não têm campos persistidos neste projeto.",
		42
	)
	if self.state.persistence_available == false then
		self:_label("Sem acesso ao DataStore: alteração válida só nesta sessão", 34, C.warning)
	end
	local amount = self:_input("Stars · inteiro de 0 a 1.000.000.000", "1000")
	local currency_row = self:_row()
	for _, mode in { "add", "remove", "set" } do
		local label = if mode == "add" then "+ ADICIONAR" elseif mode == "remove" then "− REMOVER" else "DEFINIR"
		self:_row_button(currency_row, label, function()
			local n = tonumber(amount.Text)
			if n == nil or n ~= n or n % 1 ~= 0 or n < 0 or n > 1000000000 or n == math.huge then
				self.status.Text = "Informe Stars como inteiro de 0 a 1.000.000.000."
				return
			end
			if mode ~= "add" then
				local key = string.format("stars:%d:%s:%d", selected.user_id, mode, n)
				if self.confirm ~= key or os.clock() - self.confirm_at >= 10 then
					self.confirm = key
					self.confirm_at = os.clock()
					self.status.Text = "Ajuste destrutivo: clique novamente em até 10 segundos para confirmar."
					return
				end
				self.confirm = nil
			end
			self:_invoke({ action = "stars", user_id = selected.user_id, mode = mode, amount = n })
		end, 142)
	end
	local shortcut_row = self:_row()
	for _, shortcut in
		{
			{ label = "+1K", amount = 1000 },
			{ label = "+1M", amount = 1000000 },
			{ label = "+1B", amount = 1000000000 },
		}
	do
		self:_row_button(shortcut_row, shortcut.label, function()
			self:_invoke({ action = "stars", user_id = selected.user_id, mode = "add", amount = shortcut.amount })
		end, 80)
	end
	if account.match_owner_id ~= nil then
		self:_label(string.format("OURO NA PARTIDA · %d", account.match_gold or 0), 26, C.warning)
		local gold_amount = self:_input("Ouro · inteiro de 0 a 1.000.000.000", "1000")
		local gold_row = self:_row()
		for _, mode in { "add", "remove", "set" } do
			local label = if mode == "add" then "+ ADICIONAR" elseif mode == "remove" then "− REMOVER" else "DEFINIR"
			self:_row_button(gold_row, label, function()
				local n = tonumber(gold_amount.Text)
				if n == nil or n ~= n or n % 1 ~= 0 or n < 0 or n > 1000000000 or n == math.huge then
					self.status.Text = "Informe Ouro como inteiro de 0 a 1.000.000.000."
					return
				end
				if mode ~= "add" then
					local key = string.format("account_gold:%d:%s:%d", account.match_owner_id, mode, n)
					if self.confirm ~= key or os.clock() - self.confirm_at >= 10 then
						self.confirm = key
						self.confirm_at = os.clock()
						self.status.Text = "Ajuste destrutivo: clique novamente em até 10 segundos para confirmar."
						return
					end
					self.confirm = nil
				end
				self:_invoke({
					action = "gold",
					mode = mode,
					owner_id = account.match_owner_id,
					amount = n,
				})
			end, 142)
		end
		local gold_shortcuts = self:_row()
		for _, shortcut in
			{
				{ label = "+1K", amount = 1000 },
				{ label = "+1M", amount = 1000000 },
				{ label = "+1B", amount = 1000000000 },
			}
		do
			self:_row_button(gold_shortcuts, shortcut.label, function()
				self:_invoke({
					action = "gold",
					mode = "add",
					owner_id = account.match_owner_id,
					amount = shortcut.amount,
				})
			end, 80)
		end
	else
		self:_label(
			"Ouro de partida: disponível para edição enquanto a conta participa de uma partida multiplayer ativa.",
			34
		)
	end
	self:_label("CATÁLOGO · pesquise e conceda ou revogue itens salvos", 22, C.primary)
	local category_row = self:_row()
	local categories = {
		{ id = "cosmetics", title = "COSMÉTICOS", width = 96 },
		{ id = "arsenal", title = "ARSENAL", width = 82 },
		{ id = "credits", title = "CAIXAS", width = 70 },
	}
	self.account_category = self.account_category or "cosmetics"
	for _, category in categories do
		local button = self:_button(category_row, category.title, UDim2.new(), UDim2.new(0, category.width, 1, 0))
		button.Activated:Connect(function()
			self.account_category = category.id
			self:_render()
		end)
		if self.account_category == category.id then
			button.BackgroundColor3 = C.primaryDeep
		end
	end
	local search = self:_input("Pesquisar no catálogo", self.account_search or "")
	local credit_amount = self:_input("Quantidade de caixas/créditos · máximo 1.000", "1")
	local catalog_frame = create("ScrollingFrame", {
		Name = "AccountCatalog",
		Size = UDim2.new(1, -2, 0, 260),
		BackgroundColor3 = C.canvas,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.lineStrong,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, self.content) :: ScrollingFrame
	corner(catalog_frame)
	local function render_catalog_rows()
		catalog_frame:ClearAllChildren()
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}, catalog_frame)
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) }, catalog_frame)
		local catalog = self.state.account_catalog or { cosmetics = {}, arsenal = {}, credits = {} }
		local entries = catalog[self.account_category] or {}
		local query = string.lower(self.account_search or "")
		local shown = 0
		for _, item in entries do
			if query == "" or string.find(string.lower(item.name .. " " .. item.id), query, 1, true) ~= nil then
				shown += 1
				local row = create(
					"Frame",
					{ BackgroundTransparency = 1, Size = UDim2.new(1, -2, 0, 38) },
					catalog_frame
				) :: Frame
				local title = if self.account_category == "credits"
					then string.format("%s · %d", item.name, item.amount)
					else string.format(
						"%s · %s",
						item.name,
						if item.owned then "possui" else item.kind or "bloqueado"
					)
				create("TextLabel", {
					Size = UDim2.new(1, -150, 1, 0),
					BackgroundTransparency = 1,
					Font = FONT_MEDIUM,
					Text = title,
					TextColor3 = C.text,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				local add_mode = if self.account_category == "credits" then "add" else "grant"
				local remove_mode = if self.account_category == "credits" then "remove" else "revoke"
				local revoke_button: TextButton? = nil
				local revoke_label = if self.account_category == "credits" then "−" else "TIRAR"
				local function invoke_item(mode: string)
					local category_id = if self.account_category == "cosmetics"
						then "cosmetic"
						else self.account_category
					local n = if self.account_category == "credits" then tonumber(credit_amount.Text) else nil
					if
						self.account_category == "credits"
						and (n == nil or n ~= n or n % 1 ~= 0 or n < 1 or n > 1000 or n == math.huge)
					then
						self.status.Text = "Informe uma quantidade inteira entre 1 e 1.000."
						return
					end
					local request = {
						action = "admin_item",
						user_id = selected.user_id,
						category = category_id,
						item_id = item.id,
						mode = mode,
						amount = n,
					}
					local destructive = mode == "revoke" or mode == "remove"
					if destructive then
						local key = string.format(
							"item:%d:%s:%s:%s:%s",
							selected.user_id,
							category_id,
							item.id,
							mode,
							tostring(n)
						)
						if self.confirm ~= key or os.clock() - self.confirm_at >= 10 then
							self.confirm = key
							self.confirm_at = os.clock()
							self.status.Text = "Ação destrutiva: clique novamente em até 10 segundos para confirmar."
							if revoke_button ~= nil then
								revoke_button.Text = "CONFIRMAR"
							end
							self:_invoke(request)
							return
						end
						self.confirm = nil
						if revoke_button ~= nil then
							revoke_button.Text = revoke_label
						end
					end
					self:_invoke(request)
				end
				local grant = self:_button(
					row,
					if self.account_category == "credits" then "+" else "DAR",
					UDim2.new(1, -142, 0, 0),
					UDim2.fromOffset(66, 36)
				)
				grant.Activated:Connect(function()
					invoke_item(add_mode)
				end)
				revoke_button = self:_button(row, revoke_label, UDim2.new(1, -70, 0, 0), UDim2.fromOffset(68, 36))
				revoke_button.Activated:Connect(function()
					invoke_item(remove_mode)
				end)
			end
		end
		if shown == 0 then
			create("TextLabel", {
				Size = UDim2.new(1, -2, 0, 36),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = "Nenhum item corresponde à pesquisa.",
				TextColor3 = C.textMuted,
				TextSize = 11,
			}, catalog_frame)
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		self.account_search = search.Text
		render_catalog_rows()
	end)
	render_catalog_rows()
	local reset_key = "reset:" .. tostring(selected.user_id)
	local reset_row = self:_row()
	local reset_button = self:_button(
		reset_row,
		if self.confirm == reset_key then "CONFIRMAR RESET" else "RESETAR CONTA",
		UDim2.new(),
		UDim2.new(0, 188, 1, 0)
	)
	reset_button.Activated:Connect(function()
		if self.confirm ~= reset_key or os.clock() - self.confirm_at >= 10 then
			self.confirm = reset_key
			self.confirm_at = os.clock()
			reset_button.Text = "CONFIRMAR RESET"
			self.status.Text =
				"Reset destrutivo: clique novamente em até 10 segundos. Snapshot automático será salvo."
			self:_invoke({ action = "reset_account", user_id = selected.user_id })
			return
		end
		self.confirm = nil
		reset_button.Text = "RESETAR CONTA"
		self:_invoke({ action = "reset_account", user_id = selected.user_id })
	end)
end

function AdminPanel._render_map(self: any)
	local match = self.state.match
	self:_label("MAPA · " .. string.upper(tostring(match.stage or "indisponível")), 22, C.primary)
	local owners = match.owners or {}
	if not match.active then
		self:_label(
			"As ferramentas de mapa exigem uma partida multiplayer em andamento. A partida solo roda localmente no cliente.",
			42
		)
		return
	end
	for _, owner in owners do
		local kind = if owner.bot then "BOT" elseif owner.human then "JOGADOR" else "NPC"
		local line = string.format(
			"#%d  %s  ·  %s  ·  %d tropas  ·  %d ouro  ·  %d territórios",
			owner.id,
			owner.name,
			kind,
			owner.troops,
			owner.gold,
			owner.tiles
		)
		local button = self:_button(self.content, line, UDim2.new(), UDim2.new(1, -2, 0, 36))
		button.TextXAlignment = Enum.TextXAlignment.Left
		create("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 8) }, button)
		button.BackgroundColor3 = if owner.id == self.selected_owner then C.primaryDeep else C.surfaceRaised
		button.Activated:Connect(function()
			self.selected_owner = owner.id
			self.confirm = nil
			self:_render()
		end)
	end
	local selected = self:_owner()
	if selected == nil then
		self:_label("Selecione um território/controlador da lista.")
		return
	end
	self:_label("ALVO · #" .. tostring(selected.id) .. " " .. tostring(selected.name), 24, C.text)
	local amount = self:_input("Quantidade de tropas · máximo 1.000.000.000")
	local row = self:_row()
	self:_row_button(row, "DEFINIR TROPAS", function()
		self:_invoke({ action = "set_troops", owner_id = selected.id, amount = tonumber(amount.Text) })
	end, 146)
	local gold_amount = self:_input("Ouro · inteiro de 0 a 1.000.000.000")
	local gold_row = self:_row()
	for _, mode in { "add", "remove", "set" } do
		local label = if mode == "add" then "ADICIONAR" elseif mode == "remove" then "REMOVER" else "DEFINIR"
		self:_row_button(gold_row, label, function()
			local n = tonumber(gold_amount.Text)
			if n == nil or n ~= n or n % 1 ~= 0 or n < 0 or n > 1000000000 or n == math.huge then
				self.status.Text = "Informe Ouro como inteiro de 0 a 1.000.000.000."
				return
			end
			if mode ~= "add" then
				local key = string.format("gold:%d:%s:%d", selected.id, mode, n)
				if self.confirm ~= key or os.clock() - self.confirm_at >= 10 then
					self.confirm = key
					self.confirm_at = os.clock()
					self.status.Text = "Ajuste destrutivo: clique novamente em até 10 segundos para confirmar."
					return
				end
				self.confirm = nil
			end
			self:_invoke({ action = "gold", mode = mode, owner_id = selected.id, amount = n })
		end, 116)
	end
	local gold_shortcuts = self:_row()
	for _, shortcut in
		{
			{ label = "+1K", amount = 1000 },
			{ label = "+1M", amount = 1000000 },
			{ label = "+1B", amount = 1000000000 },
		}
	do
		self:_row_button(gold_shortcuts, shortcut.label, function()
			self:_invoke({ action = "gold", mode = "add", owner_id = selected.id, amount = shortcut.amount })
		end, 80)
	end
	local tile = self:_input("ID de território / tile")
	local row2 = self:_row()
	self:_row_button(row2, "ATRIBUIR AO ALVO", function()
		self:_invoke({ action = "set_tile_owner", tile = tonumber(tile.Text), owner_id = selected.id })
	end, 154)
	self:_row_button(row2, "RETIRAR POSSE", function()
		self:_invoke({ action = "set_tile_owner", tile = tonumber(tile.Text), owner_id = 0 })
	end, 132)
	local row3 = self:_row()
	self:_row_button(row3, "FOCAR CÂMERA", function()
		self:_invoke({ action = "focus_owner", owner_id = selected.id })
	end, 136)
	local kill_text = if self.confirm == "eliminate" and os.clock() - self.confirm_at < 5
		then "CONFIRMAR ELIMINAÇÃO"
		else "ELIMINAR CONTROLADOR"
	self:_row_button(row3, kill_text, function()
		if self.confirm ~= "eliminate" or os.clock() - self.confirm_at >= 5 then
			self.confirm = "eliminate"
			self.confirm_at = os.clock()
			self.status.Text = "Pressione novamente em até 5 segundos para confirmar."
			self:_render()
			return
		end
		self.confirm = nil
		self:_invoke({ action = "eliminate", owner_id = selected.id, killer_id = 0 })
	end, 192)
	if selected.bot then
		local row4 = self:_row()
		local remove_text = if self.confirm == "remove_bot" and os.clock() - self.confirm_at < 5
			then "CONFIRMAR REMOÇÃO"
			else "REMOVER BOT"
		self:_row_button(row4, remove_text, function()
			if self.confirm ~= "remove_bot" or os.clock() - self.confirm_at >= 5 then
				self.confirm = "remove_bot"
				self.confirm_at = os.clock()
				self.status.Text = "Pressione novamente em até 5 segundos para confirmar."
				self:_render()
				return
			end
			self.confirm = nil
			self:_invoke({ action = "remove_bot", owner_id = selected.id })
		end, 146)
	end
	local bot_name = self:_input("Nome de bot · adicionar somente na fase de entrada", "Bot DomWorld")
	local row5 = self:_row()
	self:_row_button(row5, "ADICIONAR BOT", function()
		self:_invoke({ action = "add_bot", name = bot_name.Text })
	end, 144)
end

function AdminPanel._render_team(self: any)
	if self.state.role ~= "owner" then
		return
	end
	self:_label("EQUIPE · ACESSO PERMANENTE", 22, C.primary)
	if self.state.roster_available ~= true then
		self:_label(
			"A lista persistente não está disponível. Verifique o acesso ao DataStore e atualize.",
			42,
			C.warning
		)
		return
	end
	local person = self:_input("Nome de usuário ou UserId", self.team_input or "")
	person:GetPropertyChangedSignal("Text"):Connect(function()
		self.team_input = person.Text
	end)
	local add_row = self:_row()
	self:_row_button(add_row, "ADICIONAR À EQUIPE", function()
		local value = string.gsub(person.Text, "^%s*(.-)%s*$", "%1")
		if value == "" then
			self.status.Text = "Informe um nome de usuário ou UserId."
			return
		end
		local numeric = tonumber(value)
		self:_invoke(
			if numeric ~= nil
				then { action = "team_add", user_id = numeric }
				else { action = "team_add", username = value }
		)
	end, 190)
	local rows = self.state.roster or {}
	if #rows == 0 then
		self:_label("Equipe vazia.")
	end
	for _, entry in rows do
		local row = self:_row()
		local added = if entry.added_at > 0 then os.date("%d/%m/%Y", entry.added_at) else "data desconhecida"
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -154, 1, 0),
			Font = FONT_MEDIUM,
			Text = string.format(
				"%s · %d · desde %s · por %s (%d)",
				entry.username,
				entry.user_id,
				added,
				entry.added_by_name,
				entry.added_by_user_id
			),
			TextColor3 = C.text,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
		local key = "team:" .. tostring(entry.user_id)
		local remove_text = if self.confirm == key then "CONFIRMAR" else "REMOVER"
		self:_row_button(row, remove_text, function()
			if self.confirm ~= key or os.clock() - self.confirm_at >= 10 then
				self.confirm = key
				self.confirm_at = os.clock()
				self.status.Text = "Clique novamente em até 10 segundos para remover este acesso."
				self:_render()
				return
			end
			self.confirm = nil
			self:_invoke({ action = "team_remove", user_id = entry.user_id })
		end, 138)
	end
end

function AdminPanel._render_match(self: any)
	local match = self.state.match
	self:_label("PARTIDA · " .. string.upper(tostring(match.stage or "indisponível")), 24, C.primary)
	self:_label(
		string.format(
			"Tick %s · velocidade %s× · %s",
			tostring(match.tick or 0),
			tostring(match.speed or 1),
			if match.paused then "PAUSADA" else "EM ANDAMENTO"
		),
		30,
		C.text
	)
	local row = self:_row()
	self:_row_button(row, if match.paused then "RETOMAR" else "PAUSAR", function()
		self:_invoke({ action = "pause", paused = not match.paused })
	end, 122)
	self:_label("VELOCIDADE", 20, C.textMuted)
	local speeds = self:_row()
	for _, speed in { 0.5, 1, 2, 3, 5 } do
		self:_row_button(speeds, tostring(speed) .. "×", function()
			self:_invoke({ action = "speed", speed = speed })
		end, 72)
	end
	self:_label(
		"Pause e velocidade atuam somente em partidas multiplayer deste servidor. Reinício, alteração de relógio e encerramento forçado não são oferecidos.",
		52
	)
end

function AdminPanel._render_logs(self: any)
	self:_label("REGISTRO · AÇÕES DESTA SESSÃO", 24, C.primary)
	local lines = {}
	for i = #(self.state.logs or {}), 1, -1 do
		local row = self.state.logs[i]
		table.insert(
			lines,
			string.format(
				"%s  ·  %s (%d)  ·  %s  ·  %s  ·  %s  ·  %s",
				os.date("%H:%M:%S", row.time),
				row.actor,
				row.user_id,
				row.action,
				row.target,
				row.value,
				row.result
			)
		)
	end
	local text = table.concat(lines, "\n")
	if text == "" then
		text = "Nenhuma ação registrada nesta sessão."
	end
	self:_label("Selecione o registro e pressione Ctrl+C para copiar.", 22)
	local box = create("TextBox", {
		BackgroundColor3 = C.surface,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = FONT_NUMERIC,
		MultiLine = true,
		TextEditable = false,
		Text = text,
		TextColor3 = C.text,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -2, 0, math.max(180, math.min(420, #lines * 22))),
	}, self.content)
	corner(box)
	stroke(box, C.line, 0.1)
	local select_all = self:_button(self.content, "SELECIONAR REGISTRO", UDim2.new(), UDim2.fromOffset(176, 34))
	select_all.Activated:Connect(function()
		box:CaptureFocus()
		box.SelectionStart = 1
		box.CursorPosition = #text + 1
	end)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, box)
end

function AdminPanel._invoke(self: any, request: any)
	if self.busy then
		return
	end
	self.busy = true
	self.status.Text = "Enviando ao servidor…"
	task.spawn(function()
		local refresh_after = false
		local ok, result = pcall(function()
			return self.action_remote:InvokeServer(request)
		end)
		if not ok then
			self.status.Text = "O servidor não respondeu à ação."
		elseif type(result) == "table" and result.ok == true then
			self.status.Text = tostring(result.message or "Ação concluída.")
			if request.action == "focus_owner" then
				local focus = self.world and self.world.focus_owner
				if type(focus) == "function" then
					pcall(focus, self.world, request.owner_id)
				end
			end
			refresh_after = true
		else
			self.status.Text = if type(result) == "table" and type(result.message) == "string"
				then result.message
				else "A ação foi recusada pelo servidor."
		end
		self.busy = false
		if refresh_after then
			self:_refresh()
		end
	end)
end

function AdminPanel._refresh(self: any)
	if self.busy then
		return
	end
	self.busy = true
	task.spawn(function()
		local ok, state = pcall(function()
			return self.get_state_remote:InvokeServer(self.selected_user)
		end)
		if ok and type(state) == "table" and state.ok == true then
			self.state = state
			self.shortcut_key = if type(state.shortcut_key) == "string" then state.shortcut_key else self.shortcut_key
			if self.selected_owner == nil and #state.match.owners > 0 then
				self.selected_owner = state.match.owners[1].id
			end
			if self.selected_user == nil and #state.players > 0 then
				self.selected_user = state.players[1].user_id
			end
			self:_render()
		else
			self.status.Text = "A autorização do servidor expirou ou a atualização falhou."
		end
		self.busy = false
	end)
end

return AdminPanel
