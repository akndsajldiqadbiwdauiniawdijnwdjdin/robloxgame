-- Picture icons for every car ability and item (client only). The art is packed in
-- IconData.luau: base64 of a zstd stream holding
--   [color count][palette RGBA x count][128*128 palette indices]
-- Each icon is decoded once into an EditableImage and shared by every ImageLabel that
-- shows it. If an icon can't be made (unknown id, or the device is out of image
-- memory), the label falls back to the emoji you pass in.
local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")

local IconData = require(script.Parent.IconData)

local Icons = {}

local SIZE = 128
local cache = {} -- [id] = Content | false

-- The decoded picture for `id`, or nil.
function Icons.get(id: string?): Content?
	if not id then
		return nil
	end
	local cached = cache[id]
	if cached ~= nil then
		return cached or nil
	end
	cache[id] = false
	local packed = IconData[id]
	if not packed then
		return nil
	end
	local ok, result = pcall(function()
		local raw = EncodingService:DecompressBuffer(EncodingService:Base64Decode(buffer.fromstring(packed)), Enum.CompressionAlgorithm.Zstd)
		local colors = buffer.readu8(raw, 0)
		local first = 1 + colors * 4
		assert(buffer.len(raw) >= first + SIZE * SIZE, "icon data too short")
		local pixels = buffer.create(SIZE * SIZE * 4)
		for i = 0, SIZE * SIZE - 1 do
			buffer.copy(pixels, i * 4, raw, 1 + buffer.readu8(raw, first + i) * 4, 4)
		end
		local image = AssetService:CreateEditableImage({ Size = Vector2.new(SIZE, SIZE) })
		assert(image, "no image memory left")
		image:WritePixelsBuffer(Vector2.zero, Vector2.new(SIZE, SIZE), pixels)
		return Content.fromObject(image)
	end)
	if not ok then
		warn("[Icons] couldn't build icon", id, result)
		return nil
	end
	cache[id] = result
	return result
end

-- An ImageLabel for icons, with a hidden emoji fallback inside it.
function Icons.view(props): ImageLabel
	local view = Instance.new("ImageLabel")
	view.BackgroundTransparency = 1
	view.ScaleType = Enum.ScaleType.Fit
	for key, value in props do
		if key ~= "Parent" then
			view[key] = value
		end
	end
	local fallback = Instance.new("TextLabel")
	fallback.Name = "Fallback"
	fallback.Size = UDim2.fromScale(1, 1)
	fallback.BackgroundTransparency = 1
	fallback.TextScaled = true
	fallback.Text = ""
	fallback.ZIndex = view.ZIndex
	fallback.Parent = view
	view.Parent = props.Parent
	return view
end

-- Shows icon `id` (or `emoji` if there's no picture). Pass nil to clear it.
function Icons.set(view: ImageLabel, id: string?, emoji: string?)
	local key = (id or "") .. "|" .. (emoji or "")
	if view:GetAttribute("IconKey") == key then
		return
	end
	view:SetAttribute("IconKey", key)
	local content = Icons.get(id)
	local fallback = view:FindFirstChild("Fallback") :: TextLabel?
	if content then
		view.ImageContent = content
		if fallback then
			fallback.Text = ""
		end
	else
		view.Image = ""
		if fallback then
			fallback.Text = emoji or ""
		end
	end
end

-- Shortcut: a new view already showing `id`.
function Icons.label(props, id: string?, emoji: string?): ImageLabel
	local view = Icons.view(props)
	Icons.set(view, id, emoji)
	return view
end

return Icons
