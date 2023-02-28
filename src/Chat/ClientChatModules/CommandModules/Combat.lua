local PlayersService = game:GetService("Players")

local COMBAT_COMMANDS = {"/combat ", "/cc ", "# "}

function IsCombatCommand(message)
	for i = 1, #COMBAT_COMMANDS do
		local combatCommand = COMBAT_COMMANDS[i]
		if string.sub(message, 1, combatCommand:len()):lower() == combatCommand then
			return true
		end
	end
	return false
end

local combatStateMethods = {}
combatStateMethods.__index = combatStateMethods

local util = require(script.Parent:WaitForChild("Util"))

local CombatCustomState = {}

function combatStateMethods:EnterCombatChat()
	self.CombatChatEntered = true
	self.MessageModeButton.Size = UDim2.new(0, 1000, 1, 0)
	self.MessageModeButton.Text = "[Combat]"
	self.MessageModeButton.TextColor3 = self:GetCombatChatColor()

	local xSize = self.MessageModeButton.TextBounds.X
	self.MessageModeButton.Size = UDim2.new(0, xSize, 1, 0)
	self.TextBox.Size = UDim2.new(1, -xSize, 1, 0)
	self.TextBox.Position = UDim2.new(0, xSize, 0, 0)
	self.OriginalCombatText = self.TextBox.Text
	self.TextBox.Text = " "
end

function combatStateMethods:TextUpdated()
	local newText = self.TextBox.Text
	if not self.CombatChatEntered then
		if IsCombatCommand(newText) then
			self:EnterCombatChat()
		end
	else
		if newText == "" then
			self.MessageModeButton.Text = ""
			self.MessageModeButton.Size = UDim2.new(0, 0, 0, 0)
			self.TextBox.Size = UDim2.new(1, 0, 1, 0)
			self.TextBox.Position = UDim2.new(0, 0, 0, 0)
			self.TextBox.Text = ""
			---Implement this when setting cursor positon is a thing.
			---self.TextBox.Text = self.OriginalTeamText
			self.CombatChatEntered = false
			---Temporary until setting cursor position...
			self.ChatBar:ResetCustomState()
			self.ChatBar:CaptureFocus()
		end
	end
end

function combatStateMethods:GetMessage()
	if self.CombatChatEntered then
		return "/cc " ..self.TextBox.Text
	end
	return self.TextBox.Text
end

function combatStateMethods:ProcessCompletedMessage()
	return false
end

function combatStateMethods:Destroy()
	self.MessageModeConnection:disconnect()
	self.Destroyed = true
end

function combatStateMethods:GetCombatChatColor()
	return Color3.fromRGB(35, 76, 142)
end

function CombatCustomState.new(ChatWindow, ChatBar, ChatSettings)
	local obj = setmetatable({}, combatStateMethods)
	obj.Destroyed = false
	obj.ChatWindow = ChatWindow
	obj.ChatBar = ChatBar
	obj.ChatSettings = ChatSettings
	obj.TextBox = ChatBar:GetTextBox()
	obj.MessageModeButton = ChatBar:GetMessageModeTextButton()
	obj.OriginalTeamText = ""
	obj.CombatChatEntered = false

	obj.MessageModeConnection = obj.MessageModeButton.MouseButton1Click:connect(function()
		local chatBarText = obj.TextBox.Text
		if string.sub(chatBarText, 1, 1) == " " then
			chatBarText = string.sub(chatBarText, 2)
		end
		obj.ChatBar:ResetCustomState()
		obj.ChatBar:SetTextBoxText(chatBarText)
		obj.ChatBar:CaptureFocus()
	end)

	obj:EnterCombatChat()

	return obj
end

function ProcessMessage(message, ChatWindow, ChatBar, ChatSettings)
	if ChatBar.TargetChannel == "Combat" then
		return
	end

	if IsCombatCommand(message) then
		return CombatCustomState.new(ChatWindow, ChatBar, ChatSettings)
	end
	return nil
end

return {
	[util.KEY_COMMAND_PROCESSOR_TYPE] = util.IN_PROGRESS_MESSAGE_PROCESSOR,
	[util.KEY_PROCESSOR_FUNCTION] = ProcessMessage
}
