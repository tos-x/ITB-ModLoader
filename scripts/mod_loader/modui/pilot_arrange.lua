--[[
	Adds a new entry to the "Mod Content" menu, allowing to arrange
	pilots in a specific order, changing which ones become available
	for selection in the hangar.
--]]

local MAX_PILOTS = 13
local hangarBackdrop = sdlext.getSurface({ path = "resources/mods/ui/pilot-arrange-hangar.png" })
local pilotSurfaces = {}
-- copy of the list before we make any changes to it
local PilotListDefault = shallow_copy(PilotList)

function loadPilotsOrder()
	local order = {}

	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, function(obj)
		for k, v in ipairs(obj.pilotOrder or {}) do
			order[v] = k
		end
	end)
	for k, v in ipairs(PilotListExtended) do
		if order[v] == nil then
			order[v] = 10000 + k
		end
	end
	table.sort(PilotListExtended,function(a,b)
		return order[a] < order[b]
	end)
end

function savePilotsOrder()
	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, function(obj)
		obj.pilotOrder = PilotList
	end)
end

local function getOrCreatePilotSurface(pilotId)
	local surface = pilotSurfaces[pilotId]
	if not surface then
		surface = sdlext.getSurface({
			path = "img/portraits/pilots/"..pilotId..".png",
			scale = 2
		})
		pilotSurfaces[pilotId] = surface
	end

	return surface
end

local function createUi()
	local pilotButtons = {}

	local onExit = function(self)
		PilotList = {}

		for i = 1, MAX_PILOTS do
			PilotList[i] = pilotButtons[i].pilotId
		end

		savePilotsOrder()
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local portraitW = 122 + 8
		local portraitH = 122 + 8
		local gap = 16
		local cellW = portraitW + gap
		local cellH = portraitH + gap

		local frametop = Ui()
			:width(0.8):height(0.8)
			:posCentered()
			:caption(modApi:getText("PilotArrange_FrameTitle"))
			:decorate({ DecoFrameHeader(), DecoFrame() })
			:addTo(ui)

		local scrollarea = UiScrollArea()
			:width(1):height(1)
			:padding(24)
			:addTo(frametop)

		local placeholder = Ui()
			:pospx(-cellW, -cellH)
			:widthpx(portraitW):heightpx(portraitH)
			:decorate({ })
			:addTo(scrollarea)

		local portraitsPerRow = math.floor(ui.w * frametop.wPercent / cellW)
		frametop
			:width((portraitsPerRow * cellW + scrollarea.padl + scrollarea.padr) / ui.w)
			:posCentered()

		local draggedElement
		local function rearrange()
			local index = list_indexof(pilotButtons, placeholder)
			if index ~= nil and draggedElement ~= nil then
				local col = math.floor(draggedElement.x / cellW + 0.5)-1
				local row = math.floor(draggedElement.y / cellH + 0.5)
				local desiredIndex = 1 + col + row * portraitsPerRow
				if desiredIndex < 1 then desiredIndex = 1 end
				if desiredIndex > #pilotButtons then desiredIndex = #pilotButtons end

				if desiredIndex ~= index then
					table.remove(pilotButtons, index)
					table.insert(pilotButtons, desiredIndex, placeholder)
				end
			end

			for i = 1, #pilotButtons do
				local col = (i) % portraitsPerRow
				local row = math.floor((i) / portraitsPerRow)
				local button = pilotButtons[i]

				button:pospx(cellW * col, cellH * row)
				if button == placeholder then
					placeholderIndex = i
				end
			end

			if placeholderIndex ~= nil and draggedElement ~= nil then

			end
		end

		local function refreshPilotButtons()
			for i = 1, #pilotButtons do
				local col = (i) % portraitsPerRow
				local row = math.floor((i) / portraitsPerRow)
				local button = pilotButtons[i]

				button:pospx(cellW * col, cellH * row)
			end
		end

		local function addDefaultButton()
			local bheight = 40
			local button = Ui()
				:widthpx(portraitW):heightpx(bheight)
				:pospx(0, (portraitH - 2*bheight) * 0.3)
				:settooltip("Set default pilot order.")
				:decorate({
					DecoButton(),
					DecoAlign(9),
					DecoText("Default"),
				})
				:addTo(scrollarea)

			button.onclicked = function()
				table.sort(pilotButtons, function(a, b)
					-- get index in default order, nil otherwise
					local indexA = list_indexof(PilotListDefault, a.pilotId)
					local indexB = list_indexof(PilotListDefault, b.pilotId)
					-- replace nil (modloader) and -1 (modApiExt) with a large value so it goes after vanilla
					indexA = (not indexA or indexA == -1) and 10000 or indexA
					indexB = (not indexB or indexB == -1) and 10000 or indexB

					-- equal means they are non-vanilla, so sort by ID
					if indexA == indexB then
						return a.pilotId < b.pilotId
					end
					-- unequal means one is vanilla, order vanilla
					return indexA < indexB
				end)

				refreshPilotButtons()
				return true
			end
		end

		local function addRandomButton()
			local bheight = 40

			local button = Ui()
				:widthpx(portraitW):heightpx(bheight)
				:pospx(0, (portraitH - 2*bheight) * 0.6+bheight)
				:settooltip("Randomize Pilot order.")
				:decorate({
					DecoButton(),
					DecoAlign(9),
					DecoText("Randomize"),
				})
				:addTo(scrollarea)

			button.onclicked = function()
				for i = #pilotButtons, 2, -1 do
					local j = math.random(i)
					pilotButtons[i], pilotButtons[j] = pilotButtons[j], pilotButtons[i]
				end

				refreshPilotButtons()
				return true
			end
		end

		local function addHangarBackdrop(i)
			local col = (i) % portraitsPerRow
			local row = math.floor((i) / portraitsPerRow)

			local button = Ui()
				:widthpx(portraitW):heightpx(portraitH)
				:pospx(cellW * col, cellH * row)
				:decorate({
					DecoAlign(0,-4),
					DecoSurface(hangarBackdrop)
				})
				:addTo(scrollarea)
		end

		local function addPilotButton(i, pilotId)
			local pilot = _G[pilotId]
			local col = (i) % portraitsPerRow
			local row = math.floor((i) / portraitsPerRow)

			local surface = getOrCreatePilotSurface(pilotId)
			local button = Ui()
				:widthpx(portraitW):heightpx(portraitH)
				:pospx(cellW * col, cellH * row)
				:settooltip(pilot.Name)
				:decorate({
					DecoButton(),
					DecoAlign(-4),
					DecoSurface(surface)
				})
				:addTo(scrollarea)

			button:registerDragMove()
			button.pilotId = pilotId

			pilotButtons[i] = button

			button.startDrag = function(self, mx, my, btn)
				UiDraggable.startDrag(self, mx, my, btn)

				draggedElement = self
				placeholder.x = self.x
				placeholder.y = self.y

				local index = list_indexof(pilotButtons, self)
				if index ~= nil then
					pilotButtons[index] = placeholder
				end

				self:bringToTop()
				rearrange()
			end

			button.stopDrag = function(self, mx, my, btn)
				UiDraggable.stopDrag(self, mx, my, btn)

				local index = list_indexof(pilotButtons, placeholder)
				if index ~= nil and draggedElement ~= nil then
					pilotButtons[index] = draggedElement
				end

				placeholder:pospx(-2 * cellW, -2 * cellH)

				draggedElement = nil

				rearrange()
			end

			button.dragMove = function(self, mx, my)
				UiDraggable.dragMove(self, mx, my)

				rearrange()
			end
		end

		addDefaultButton()
		addRandomButton()

		local dupes = {}
		for i = 1, #PilotListExtended do
			local pilotId = PilotListExtended[i]
			if not dupes[pilotId] then
				dupes[pilotId] = 1
				addPilotButton(#pilotButtons + 1, pilotId)
			end
		end
		for i = 1, MAX_PILOTS do
			addHangarBackdrop(i)
		end

	end)
end

function ArrangePilots()
	loadPilotsOrder()

	createUi()
end

sdlext.addHangarEnteredHook(function(screen)
	if not arrangePilotsButton.disabled then
		arrangePilotsButton.disabled = true
		arrangePilotsButton.tip = modApi:getText("PilotArrange_ButtonTooltip_Off")
	end
end)