private ["_invehicle","_isplayernearby","_playerObj","_myGroup","_id","_playerUID","_playerName","_characterID","_timeout","_message","_magazines","_playerPos"];
_playerUID = _this select 0;
_playerName = _this select 1;
_playerObj = nil;
_playerPos = [];
{
	if ((getPlayerUID _x) == _playerUID) exitWith { _playerObj = _x; _playerPos = getPosATL _playerObj;};
} forEach playableUnits;

if (isNil "_playerObj") exitWith {
	diag_log format["%1: nil player object, _this:%2", __FILE__, _this];
};

diag_log format["get: %1 (%2), sent: %3 (%4)",typeName (getPlayerUID _playerObj), getPlayerUID _playerObj, typeName _playerUID, _playerUID];

if (!isNull _playerObj) then {

	_characterID =	_playerObj getVariable ["CharacterID","0"];
	_timeout = _playerObj getVariable["combattimeout",0];

	_invehicle = false;

	if (vehicle _playerObj != _playerObj) then {
		_playerObj action ["eject", vehicle _playerObj];
		_invehicle = true;
	};

	if ((_timeout - time) > 0) then {

		_playerObj setVariable["NORRN_unconscious",true, true];
		_playerObj setVariable["unconsciousTime",300,true];
	
		diag_log format["COMBAT LOGGED: %1 (%2)", _playerName,_timeout];
		//diag_log format["SET UNCONCIOUSNESS: %1", _playerName];
	
		// Message whole server when player combat logs
		_message = format["PLAYER COMBAT LOGGED: %1",_playerName];
		[nil,nil,"per",rTITLETEXT,_message,"PLAIN DOWN"] call RE;
	};

	diag_log format["DISCONNECT: %1 (%2) Object: %3, _characterID: %4", _playerName,_playerUID,_playerObj,_characterID];

	_id = [_playerUID,_characterID,2] spawn dayz_recordLogin;

	if (alive _playerObj) then {

		_isplayernearby = (DZE_BackpackGuard and!_invehicle and ({(isPlayer _x) and (alive _x)} count (_playerPos nearEntities ["AllVehicles", 5]) > 1));

		// prevent saving more than 20 magazine items
		_magazines = [(magazines _playerObj),20] call array_reduceSize;

		[_playerObj,_magazines,true,true,_isplayernearby] call server_playerSync;
		
		// maybe not needed just testing
		_playerObj removeAllMPEventHandlers "mphit";
		
		_myGroup = group _playerObj;
		deleteVehicle _playerObj;
		deleteGroup _myGroup;
	} else {
		//Update Vehicle
		{ 
			[_x,"gear"] call server_updateObject;
		} foreach (nearestObjects [_playerPos, dayz_updateObjects, 10]);
	};
};