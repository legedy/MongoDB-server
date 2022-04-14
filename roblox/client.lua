local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local BuyRequest: RemoteFunction = ReplicatedStorage:WaitForChild('Buy');
local GetCoinRequest: RemoteFunction = ReplicatedStorage:WaitForChild('Get');
local GetDataRequest: RemoteFunction = ReplicatedStorage:WaitForChild('GetData');

local Player = Players.LocalPlayer;

local Data = {};

local Frame = script.Parent.Frame;

local function retry(func, ...)
	local success, msg = pcall(func, ...);
	return success, msg;
end

local function updateCoin(coins)
	Data.fartCoins = coins;
	Frame.Coins.Text = 'FartCoins: '..coins;
end

for i = 1, 5 do
	print('Attempt: ' .. i);
	local success, data = retry(function()
		return GetDataRequest:InvokeServer();
	end);

	if (success) then
		Data = data;
		updateCoin(Data.fartCoins);
		print('Successfully retrieved data.');
	break; end
end

Frame.Death.MouseButton1Click:Connect(function()
	local coins = BuyRequest:InvokeServer('death');
	updateCoin(coins);
	print('Fart Coins: ' .. coins);
end);

Frame.Broadcast.MouseButton1Click:Connect(function()
	local coins = BuyRequest:InvokeServer('broadcast', Frame.TextBox.Text);
	updateCoin(coins);
	print('Fart Coins: ' .. coins);
end);

Frame.GetCoin.MouseButton1Click:Connect(function()
	local number = tonumber(Frame.TextBox.Text);

	if (number) then
		GetCoinRequest:FireServer(number);
		updateCoin(Data.fartCoins+number);
	else
		warn('Unable to convert text to number.');
	end
end);