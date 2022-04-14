local AUTH = table.freeze{
	login = 'admin',
	password = 'NVNS58kx5sSQNtTx'
};

local Players = game:GetService('Players');
local HttpService = game:GetService('HttpService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local BroadcastLabel = workspace:WaitForChild('Broadcaster').SurfaceGui.TextLabel;

local BuyRequest: RemoteFunction = ReplicatedStorage:WaitForChild('Buy');
local GetCoinRequest: RemoteFunction = ReplicatedStorage:WaitForChild('Get');
local GetDataRequest: RemoteFunction = ReplicatedStorage:WaitForChild('GetData');

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function enc(data)
	return ((data:gsub('.', function(x) 
		local r,b='',x:byte()
		for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c=0
		for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end

local Database = {};

local types = {
	broadcast = {
		Cost = 5,
		Callback = function(player, message)
			BroadcastLabel.Text = player.Name.. ': ' ..message;
		end
	},
	death = {
		Cost = 100,
		Callback = function(player)
			local humanoid = player.Character:FindFirstChild('Humanoid');

			if (humanoid) then
				humanoid.Health = 0;
				BroadcastLabel.Text = player.Name.. ': is dead.';
			else
				BroadcastLabel.Text = player.Name.. ': unable to kill player.';
			end
		end
	}
}

BuyRequest.OnServerInvoke = function(player, type, ...)
	local playerData = Database[player.UserId];
	local chosenType = types[type];

	if (chosenType) then
		if (playerData.fartCoins >= chosenType.Cost) then
			playerData.fartCoins -= chosenType.Cost;
			chosenType.Callback(player, ...);
		end
	end

	local jsonData = HttpService:JSONEncode(playerData);

	local success = HttpService:PostAsync(
		'http://localhost:8000/player-data/update-fartCoins/'..player.UserId,
		jsonData, Enum.HttpContentType.ApplicationJson, false, {
			Authorization = 'Basic '..enc(AUTH.login..':'..AUTH.password)
		}
	);

	if (success) then
		print('Successfully updated player data.');
		return playerData.fartCoins;
	else
		warn('Failed to update player data.');
		return false;
	end
end

GetDataRequest.OnServerInvoke = function(player)
	local playerData = Database[player.UserId];

	if (playerData) then
		return {
			fartCoins = playerData.fartCoins
		};
	else
		warn('Failed to get cached player data.');
		return false;
	end
end

GetCoinRequest.OnServerEvent:Connect(function(player, value)
	Database[player.UserId].fartCoins += value;
	print('Gave '..value..' coins to '..player.Name..'. '..Database[player.UserId].fartCoins..' coins total.');
end);

Players.PlayerAdded:Connect(function(player)
	local response = HttpService:GetAsync(
		'http://localhost:8000/player-data/'..player.UserId, true, {
			['Authorization'] = 'Basic '..enc(AUTH.login..':'..AUTH.password)
		});
	local data = HttpService:JSONDecode(response);

	if data then
		Database[player.UserId] = data;
		print('Successfully retrieved player data.');
		print(data);
	else
		error('There was an error in the database server.');
	end
end);

Players.PlayerRemoving:Connect(function(player)
	local data = Database[player.UserId];

	local jsonData = HttpService:JSONEncode(data);

	local success = HttpService:PostAsync(
		'http://localhost:8000/player-data/update-fartCoins/'..player.UserId,
		jsonData, Enum.HttpContentType.ApplicationJson, false, {
			Authorization = 'Basic '..enc(AUTH.login..':'..AUTH.password)
		}
	);

	if (success) then
		print('Successfully saved player data.');
	end
end);