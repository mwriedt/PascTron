program PascTron;
uses SwinGame, sgTypes, SysUtils, sgNetworking, TerminalUserInput;

const
	TAILARRAYSIZE = 49; //Sets how many dots will be in the tail of any ship
	CONSTSCREENHEIGHT = 800; //Sets the screen height
	CONSTSCREENWIDTH = 1200; //Sets the screen width
	REDXPOS = Round(CONSTSCREENWIDTH / 5) * 1; // The Red ships x spawn position
	REDYPOS = Round(CONSTSCREENHEIGHT / 2); //The Red ships y spawn position
	BLUEXPOS = Round(CONSTSCREENWIDTH / 5) * 2; // ''
	BLUEYPOS = Round(CONSTSCREENHEIGHT / 2);// ''
	GREENXPOS = Round(CONSTSCREENWIDTH / 5) * 3;//''
	GREENYPOS = Round(CONSTSCREENHEIGHT / 2);//''
	YELLOWXPOS = Round(CONSTSCREENWIDTH / 5) * 4;//''
	YELLOWYPOS = Round(CONSTSCREENHEIGHT / 2);//''
	XYOFFSET = 8;//This offset if so that the tail is drawn from the middle of the circle.

type
///
/// Purpose: This is used to store the current gamemode such as when the game is paused or the game is in the menu
///
	GameType = ( Menu, Pause, Player2, Player3, Player4, LANGame);

///
///	Purpose : This stores the data for the movement of the ships with the x,y(Position) and update the x,y position with the xSpeed,ySpeed variables
/// Variables : x(Used to store x position), y(Used to store y position)
///
	MovementData = record
		x : Integer;
		y : Integer;
	end;
///
/// Purpose : Used to store the x and y location of each segment of the tail that follows the player
/// Variables : x(Used to store x position), y(Used to store y position), bmp(Used to store the bmp image for a tail dot)
///
	TailData = record
		x : Integer;
		y : Integer;
		bmp: Bitmap;
	end;
///
/// Purpose : Used to store the movement of the ship, these values are later passed into the MovementData record for simpler code
/// Variables : xSpeed(Amount the ship is moving in the x direction), ySpeed(Amount the ship is moving in the y direction)
///
	SpeedData = record
		xSpeed : Integer;
		ySpeed : Integer;
	end;
///
/// Purpose : Since the ship can move in 16 different directions, each direction is stored in a different part of this array to minimize the code length
///
	MovementArray = array[0..15] of SpeedData;
///
/// Purpose : This array sets the length of the tail that will follow the ship
///
	TailArray = array[0..TAILARRAYSIZE] of TailData;
///
/// Purpse: This stores a players control and if that key is down or not.
/// Variables: keys(A KeyCode, such as LeftKey, used to determine which key), down(Used to store a true/false if the determned key is down or not)
///
	ShipControls = record
		keys : KeyCode;
		down : Boolean;
	end;
///
/// This stores all of the players controls, up, left and right
///
	ControlsArray = array[0..2] of ShipControls;

///
/// Purpose: This stores all data relating to the ship except for the score of a ship.
/// Variables: location(This is the x,y position of the ship), tail(this stores an array of x,y,bmp variables for the tail dots) directionArray(This is used for the movment
/// of the ship), tailCount(This is used as a counting variable to count to however long the tail is set to be), bearing(This is an integer value to be put into the directionArray),
/// identifier(This is used to store the name of the ship), timer(This is used to limit the speed a player can turn), controls(This stores the controls for a player, such as up,
/// left and right), bmp(This is used to store the bmp image for a ship)
///
	ShipData = record
		location : MovementData;
		tail : TailArray;
		directionArray : MovementArray;
		tailCount : Integer;
		bearing : Integer;
		identifier : String;
		timer : Integer;
		controls : ControlsArray;
		bmp : Bitmap;
	end;

///
/// Purpose: This is used the store the ShipData and the score data together
/// Variables: ship(This is just ShipData), score(This is used to count each players score)
///
	PlayerData = record
		ship : ShipData;
		score : Integer;
	end;
///
/// Purpose: This is used to store all data related to the gamemode
/// Variables : mode(This is a GameType variable to store that), numOfPlayers(This is used to store the number of players playing the game, such as if you select 2 player mode,
/// this variable will equal 1(because a machine counts from 0), to set the limit of the CheckHit array)
///
	GameState = record
		 mode : GameType;
		 numOfPlayers : Integer;
	end;
///
/// This stores all of the data for all of the players in the game.
///
	PlayerArray = array[0..3] of PlayerData;

	ClientData = record
		ip : String;
		access : Connection;
		identifier  : Integer;
	end;

	ConnectionArray = array of Connection;

	HostData = record
		server : ServerSocket;
		connections : ConnectionArray;
		players : Integer;
	end;

///
/// Purpose: This is used to store all data in the game
/// Variable: players(This is a variable of PLayerData), state(This is a variable of GameState)
///
	GameData = record
		players : PlayerArray;
		host : HostData;
		client : ClientData;
		state : GameState;
	end;

///
/// Purpose: This is used to check if a ship hits a tail, two ships are passed into the function and then it checks if the first ship has hit the second ships tail(by
/// using the for loop to check each dot of the tail),if they have hit, the function returns a Boolean value of True.
///

function Hit(ship, tailData : ShipData): Boolean;
var
	i : Integer;
begin
	for i:=0 to TAILARRAYSIZE do
	begin
		result := BitmapCollision(ship.bmp, ship.location.x, ship.location.y, tailData.tail[i].bmp, tailData.tail[i].x + XYOFFSET, tailData.tail[i].y + XYOFFSET);
		if result = true then exit; ///If a ship hits a tail, then the program will exit this function and return the true result
	end;
end;

///
/// Purpose: This is used to load in all of the resources for the game, such as the images and the fonts
///

procedure LoadResources();
begin
	LoadBitmapNamed('BlueShip', 'BlueShip.png');
	LoadBitmapNamed('BlueTail', 'BlueTail.png');
	LoadBitmapNamed('RedShip', 'RedShip.png');
	LoadBitmapNamed('RedTail', 'RedTail.png');
	LoadBitmapNamed('GreenShip', 'GreenShip.png');
	LoadBitmapNamed('GreenTail', 'GreenTail.png');
	LoadBitmapNamed('YellowShip', 'YellowShip.png');
	LoadBitmapNamed('YellowTail', 'YellowTail.png');
	LoadFontNamed('ScoreFont', 'Retro.ttf', 14);
	LoadFontNamed('TitleFont', 'Tr2n.ttf', 80);
	LoadFontNamed('OptionFont', 'Flynn Hollow.otf', 50);
end;

///
/// Purpose: This is to draw a ship x and y location.
///

procedure DrawShip(ship : ShipData);
begin
	DrawBitmap(ship.bmp, ship.location.x, ship.location.y);
end;

///
/// Purpose: This draws a single tail dot, but since this is called from within a for loop this essentially draws the entire tail
///

procedure DrawTailDot(ship : ShipData; i : Integer);
begin
	DrawBitmap(ship.tail[i].bmp, ship.tail[i].x + XYOFFSET, ship.tail[i].y + XYOFFSET);
end;

///
/// Purpose : This function initialises the MovementArray array with all of the values that it needs throughout the program,
/// each value in the array corresponds to a direction that the ship will travel, with 16 in total.
///

procedure InitialiseMovementArray(var intialMovementArray : MovementArray);
var
	i, j: Integer;
begin
	for i:=0 to High(MovementArray) do // This sets the values for each xSpeed inside the array, there is no real pattern so this is the best method
	begin
		case i of
			0,8: intialMovementArray[i].xSpeed := 0;
			1,7: intialMovementArray[i].xSpeed := 2;
			2,3,5,6: intialMovementArray[i].xSpeed := 3;
			4: intialMovementArray[i].xSpeed := 4;
			12: intialMovementArray[i].xSpeed := -4;
			9,15: intialMovementArray[i].xSpeed := -2;
			10,11,13,14: intialMovementArray[i].xSpeed := -3;
		end;
	end;
	for j:=0 to High(MovementArray) do
	begin
		case j of
			0: intialMovementArray[j].ySpeed := -4; // And this sets all of the ySpeed values.
			8: intialMovementArray[j].ySpeed := 4;
			4,12: intialMovementArray[j].ySpeed := 0;
			5,11: intialMovementArray[j].ySpeed := 2;
			6,7,9,10: intialMovementArray[j].ySpeed := 3;
			3,13: intialMovementArray[j].ySpeed := -2;
			1,2,14,15: intialMovementArray[j].ySpeed := -3;
		end;
	end;
end;

///
/// Purpse : This updates the position of the oldest dot in the TailArray, the oldest dot is then set to where the ship is currently.
///

procedure SetTailDot(ship : ShipData; var setTailPos : TailData);
begin
	setTailPos.x  := ship.location.x;
	setTailPos.y := ship.location.y;
end;

///
/// Purpose : This calls for the ships tail to be drawn, one dot at a time, but since the for loop goes to the TAILARRAYSIZE, this draws the whole tail.
///

procedure DrawTailArray(const ship : ShipData);
var
	i : Integer;
begin
	for i:=0 to TAILARRAYSIZE do
	begin
		DrawTailDot(ship, i);
	end;
end;

///
/// Purpose : This sets the initial values for the array of the tail.
///

procedure InitialiseTailArray(x, y : Integer; var populateTail : TailArray);
var
	i : Integer;
begin
	for i:=0 to High(populateTail) do
	begin
		populateTail[i].x := x;
		populateTail[i].y := y;
	end;
end;

///
/// Purpose: This is for the ship to be able to  across the screen when it goes off of the edge of the screen
///

procedure WrapCharacter(var ship : ShipData);
begin
	if ship.location.x < -BitmapWidth(ship.bmp) then //offscreen left
	begin
		ship.location.x := ScreenWidth();
	end
	else if ship.location.x > ScreenWidth() then //offscreen right
	begin
		ship.location.x := -BitmapWidth(ship.bmp);
	end;

	if ship.location.y < -BitmapHeight(ship.bmp) then //offscreen top
	begin
		ship.location.y := ScreenHeight();
	end
	else if ship.location.y > ScreenHeight() then //offscreen bottom
	begin
		ship.location.y := -BitmapWidth(ship.bmp);
	end;
end;

///
/// Purpose: This is to reset the values of the booleans associated to the keys for each player
///

procedure ClearKeys(var game : GameData);
var
	i, j : Integer;
begin
	for i:=0 to (game.state.numOfPlayers - 1) do //For the number of players playing
	begin
		for j:=0 to 2 do // The amount of controls each player has.
		begin
			game.players[i].ship.controls[j].down := false;
		end;
	end;
end;

///
/// Purpose: This is to check what keys have been pressed by every player in the game, if a players key is pressed, the assigned boolean value is set to true
/// , this is to allow the program to know which buttons have been pressed, so that it doesnt miss any player inputs.
///

procedure CheckKeys(var game : GameData);
var
	i, j, k : Integer;
begin
	ClearKeys(game); //Resets the keys booleans to false
	for i:=0 to game.state.numOfPlayers - 1 do if game.players[i].score >= 5 then exit; //If any player has won the game, the game is over and players cannot move.
	for k:=0 to game.state.numOfPlayers - 1 do /// For the amount of players in the game
	begin
		for j:=0 to 2 do// This then checks each players key to see if it is down or not
		begin
			if KeyDown(KeyCode(game.players[k].ship.controls[j].keys)) then
			begin
				game.players[k].ship.controls[j].down := true;
			end;
		end;
	end;
end;

///
/// Purpose : This handles all of the movement for the ship in this game, in this procedure it checks if the user is either
/// pressing the left or right key(or the assigned movement keys for that player) and moves the ship accordingly, the player
/// can also double their speed by holding fowards or the assigned boost button for the player
///

procedure HandleMovement(var ship : ShipData; handleDirectionArray : MovementArray);
begin
	ship.timer := ship.timer + 1;
	if ship.timer > 1 then
	begin
		ship.timer := 0;

		if ship.controls[0].down = true then //left
		begin
			ship.bearing := ship.bearing- 1; //This  changes the value for the bearing which is then used inside the MovementArray, so changing the bearing will change the direction a player moves
			if ship.bearing = -1 then ship.bearing := 15;
		end;

		if ship.controls[1].down = true then ///right
		begin
			ship.bearing := ship.bearing + 1;
			if ship.bearing = 16 then ship.bearing := 0;
		end;
	end;

	if ship.controls[2].down = true then //up
	begin
		handleDirectionArray[ship.bearing].xSpeed := handleDirectionArray[ship.bearing].xSpeed * 2;
		handleDirectionArray[ship.bearing].ySpeed := handleDirectionArray[ship.bearing].ySpeed * 2;
	end;

	ship.location.x := ship.location.x + handleDirectionArray[ship.bearing].xSpeed; //Even if the player doesnt input any controls the ship will continue to move in the direction they are facing.
	ship.location.y := ship.location.y + handleDirectionArray[ship.bearing].ySpeed;
	WrapCharacter(ship);
	DrawShip(ship);
end;

///
/// Purpose: This is used to handle all of the procedures for a ship, each players data is passed into this procedure and then this call of the related procedures
/// to draw and run the ship.
///

procedure ShipEvents(var ship : ShipData);
begin
	SetTailDot(ship, ship.tail[ship.tailCount]);
	DrawTailArray(ship);
	HandleMovement(ship, ship.directionArray);
	ship.tailCount := ship.tailCount + 1;
	if ship.tailCount= TAILARRAYSIZE + 1 then ship.tailCount:=0;
end;


///
/// Purpose: This initialises all of the data for each ship, this is a very messy and ugly procedure but it cannot be reduced because each value for each ship is different.
///

procedure InitialiseShip(var ship : ShipData);
var
	u : Integer;
begin
	for u:=0 to TAILARRAYSIZE do
	begin
		if ship.identifier = 'blue' then ship.tail[u].bmp := BitmapNamed('BlueTail');
		if ship.identifier = 'red' then ship.tail[u].bmp := BitmapNamed('RedTail');
		if ship.identifier = 'green' then ship.tail[u].bmp := BitmapNamed('GreenTail');
		if ship.identifier = 'yellow' then ship.tail[u].bmp := BitmapNamed('YellowTail');
	end;
	ship.timer := 0;
	ship.tailCount := 0;
	ship.bearing := 0;
	InitialiseMovementArray(ship.directionArray);
	case ship.identifier of
	'blue':
		begin
			ship.bmp := BitmapNamed('BlueShip');
			InitialiseTailArray(BLUEXPOS, BLUEYPOS, ship.tail);
			ship.location.x := BLUEXPOS;
			ship.location.y := BLUEYPOS;
			ship.controls[0].keys := FKey; //f key
			ship.controls[1].keys := HKey;//h key
			ship.controls[2].keys := TKey;//t key
		end;
	'red':
		begin
			ship.bmp := BitmapNamed('RedShip');
			InitialiseTailArray(REDXPOS, REDYPOS, ship.tail);
			ship.location.x := REDXPOS;
			ship.location.y := REDYPOS;
			ship.controls[0].keys := AKey; //a key
			ship.controls[1].keys := DKey;//d key
			ship.controls[2].keys := WKey;//w key
		end;
	'green':
		begin
			ship.bmp := BitmapNamed('GreenShip');
			InitialiseTailArray(GREENXPOS, GREENYPOS, ship.tail);
			ship.location.x := GREENXPOS;
			ship.location.y := GREENYPOS;
			ship.controls[0].keys := JKey; //j key
			ship.controls[1].keys := LKey;//l key
			ship.controls[2].keys := IKey;//i key
		end;
	'yellow':
		begin
			ship.bmp := BitmapNamed('YellowShip');
			InitialiseTailArray(YELLOWXPOS, YELLOWYPOS, ship.tail);
			ship.location.x := YELLOWXPOS;
			ship.location.y := YELLOWYPOS;
			ship.controls[0].keys := LeftKey; //left key
			ship.controls[1].keys := RightKey;//right key
			ship.controls[2].keys := UpKey;//up key
	end;
	end;
end;

///
/// Purpose: This is to simplfy the code by grouping all of the initialisation procedures together
///

procedure InitialiseGame(var ship: ShipData);
begin
	LoadResources();
	InitialiseShip(ship);
end;

///
/// Purpose: This resets all of the data from within the game, such as the scores, the players bearings and positions, everything.
///

procedure ResetGame(var game : GameData);
var
	i : Integer;
begin
	game.state.mode := Menu;
	game.players[0].ship.identifier := 'blue';
	game.players[1].ship.identifier := 'red';
	game.players[2].ship.identifier := 'green';
	game.players[3].ship.identifier := 'yellow';
	game.state.numOfPlayers := 1;
	for i:=0 to 3 do
	begin
		game.players[i].score := 0;
		InitialiseGame(game.players[i].ship);
	end;
end;

///
/// Purpose: Only the host will call this procedure, when called, the host will broadcase the message of 'd' + the player who killed someone + the player who died
/// then the host will initialise the ship and add the score locally.
///

procedure SendLANHit(var game : GameData; playerAlive : Integer; playerDead : Integer);
begin
	BroadcastMessage('d' + IntToStr(playerAlive) + IntToStr(playerDead)); //Sends the message to the clients, this is so that only the host handles the collsions as not every client can due to lag
	game.players[playerAlive].score := game.players[playerAlive].score + 1; // Adds a score to a player
	InitialiseShip(game.players[playerDead].ship); //Resets the ship that got hit.
end;

///
/// Purpose: This is for the clients to call, if the message recieved from the host starts with a 'd', this procedure will run and it will reset a ship and add a score to a player depending on the message
///

procedure ProcessLANHit(var game : GameData; var message : String);
begin
	game.players[StrToInt(message[2])].score := game.players[StrToInt(message[2])].score + 1; //Adds a score to the second character of the message
	InitialiseShip(game.players[StrToInt(message[3])].ship); // Resets the player from the first character of the message.
end;

///
/// Purpose: This draws all of the interface required during a game.
///

procedure DrawInterface(var game : GameData);
begin
	if ((game.state.mode <> Menu) and (game.state.mode <> Pause)) then //This draws the scores in the top left corner of the screen.
	begin
		case game.state.numOfPlayers of
			2: DrawText('-SCORE- Blue: ' + IntToStr(game.players[0].score) + '  Red: ' + IntToStr(game.players[1].score) , ColorWhite, 'ScoreFont', 0, 0);
			3: DrawText('-SCORE- Blue: ' + IntToStr(game.players[0].score) + '  Red: ' + IntToStr(game.players[1].score) + '  Green: ' + IntToStr(game.players[2].score), ColorWhite, 'ScoreFont', 0, 0);
			4: DrawText('-SCORE- Blue: ' + IntToStr(game.players[0].score) + '  Red: ' + IntToStr(game.players[1].score) + '  Green: ' + IntToStr(game.players[2].score) + '  Yellow: ' + IntToStr(game.players[3].score), ColorWhite, 'ScoreFont', 0, 0);
		end;
	end;
	if game.players[0].score >= 5 then//If blue won
	begin
		DrawText('BLUE WINS', ColorCyan, 'OptionFont', (CONSTSCREENWIDTH / 2) - 200 , (CONSTSCREENHEIGHT / 2) - 300);
		DrawText('Press Enter to return to Menu', ColorCyan, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 100);
		if KeyDown(ReturnKey) then
		begin
			ResetGame(game);
		end;
		exit;
	end;

	if game.players[1].score>= 5 then//If red won
	begin
		DrawText('RED WINS', ColorRed, 'OptionFont', (CONSTSCREENWIDTH / 2) - 200 , (CONSTSCREENHEIGHT / 2) - 300);
		DrawText('Press Enter to return to Menu', ColorRed, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 100);
		if KeyDown(ReturnKey) then
		begin
			ResetGame(game);
		end;
		exit;
	end;

	if game.players[2].score >= 5 then//If green won
	begin
		DrawText('GREEN WINS', ColorLightGreen, 'OptionFont', (CONSTSCREENWIDTH / 2) - 200 , (CONSTSCREENHEIGHT / 2) - 300);
		DrawText('Press Enter to return to Menu', ColorLightGreen, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 100);
		if KeyDown(ReturnKey) then
		begin
			ResetGame(game);
		end;
		exit;
	end;

	if game.players[3].score >= 5 then//If yellow won
	begin
		DrawText('YELLOW WINS', ColorYellow, 'OptionFont', (CONSTSCREENWIDTH / 2) - 200 , (CONSTSCREENHEIGHT / 2) - 300);
		DrawText('Press Enter to return to Menu', ColorYellow, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 100);
		if KeyDown(ReturnKey) then
		begin
			ResetGame(game);
		end;
		exit;
	end;
	if KeyDown(EscapeKey) and (game.state.mode <> Menu) then 	game.state.mode := Pause; //If the player clicks the EscapeKey during a game, then the game will pause
end;



///
/// Purpose: This will call the Hit function to see if there has been a collision, if so there will be +1 added to the certain ships score.
///

procedure CheckHit(var game : GameData);
var
	i : Integer;
	j : Integer;
begin
	if (game.state.mode = Menu) or (game.state.mode = Pause) then exit;
	for i:=0 to (game.state.numOfPlayers - 1) do ///This is to loop through every ship
	begin
		for j:=0 to (game.state.numOfPlayers - 1) do // And this also loops through every ship, so this will essentially have every combination of ships passed into the Hit function.
		begin
			if Hit(game.players[i].ship, game.players[j].ship) then
			begin
				if not (game.players[i].ship.identifier = game.players[j].ship.identifier) then //If the players ship has hit their own tail then the code will ignore the result.
				begin
					if game.state.mode = LANGame then //If the game mode is in LAN
					begin
						if game.client.identifier = 0 then SendLANHit(game, j,i); // If you are the host call SendLANHit
					end
					else
					begin
						game.players[j].score := game.players[j].score + 1; //The ship that killed the other ship will get +1 score.
						InitialiseShip(game.players[i].ship); // The ship that died will respawn at their original spawn point
					end;
				end;
			end;
		end;
	end;
end;

///
/// Purpose: If the player selects the 2 player mode, only 2 players ships procedures will be run
///

procedure Mode2Player(var game : GameData);
begin
	ShipEvents(game.players[0].ship);
	ShipEvents(game.players[1].ship);
end;

///
/// Purpose: If the player selects the 3 player mode, only 3 players ships procedures will be run
///

procedure Mode3Player(var game : GameData);
begin
	Mode2Player(game);
	ShipEvents(game.players[2].ship);
end;

///
/// Purpose: If the player selects the 4 player mode, aall 4 players ships procedures will be run
///

procedure Mode4Player(var game : GameData);
begin
	Mode3Player(game);
	ShipEvents(game.players[3].ship);
end;

///
/// Purpose: This is the main menu of the game, it will check what button the player presses and then carry out its acions accordingly
///

procedure SelectGameMode(var gameMode : GameState; var storeGameMode : GameType);
begin
	DrawText('PascTron', ColorCyan, 'TitleFont', (CONSTSCREENWIDTH / 2) - 220 , (CONSTSCREENHEIGHT / 2) - 300);
	DrawText('Press 1 ; Local 2 Player Mode', ColorRed, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 50);
	DrawText('Press 2 ; Local 3 Player Mode', ColorLightGreen, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 100);
	DrawText('Press 3 ; Local 4 PLayer Mode', ColorYellow, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 150);
	DrawText('Press 4 ; LAN Mode', ColorPurple, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 200);
	DrawText('Press 5 ; Exit Game', ColorOrange, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 250);
	if KeyTyped(KeyCode(Num1Key)) then
	begin
		gameMode.mode := Player2;
		gameMode.numOfPlayers := 2;
	end;
	if KeyTyped(KeyCode(Num2Key)) then
	begin
		gameMode.mode := Player3;
		gameMode.numOfPlayers := 3;
	end;
	if KeyTyped(KeyCode(Num3Key)) then
	begin
		gameMode.mode := Player4;
		gameMode.numOfPlayers := 4;
	end;
	if KeyTyped(KeyCode(Num4Key)) then
	begin
		gameMode.mode := LANGame;
	end;
	if KeyTyped(KeyCode(Num5Key)) then Halt;
	storeGameMode := gameMode.mode; //This variable is used to store the gamemode that the game is in, this is later used in the PausedGame procedure where you can resume your game.
end;

///
/// Purpose: This will pause the game, but the data for every player will not be lost or change. The game will continue right where it left off when they resume the game.
///

procedure PausedGame(var game : GameData; var storeGameMode : GameType);
begin
	DrawText('PascTron', ColorCyan, 'TitleFont', (CONSTSCREENWIDTH / 2) - 220 , (CONSTSCREENHEIGHT / 2) - 300);
	DrawText('Paused', ColorCyan, 'TitleFont', (CONSTSCREENWIDTH / 2) - 220 , (CONSTSCREENHEIGHT / 2) - 150);
	DrawText('Press 1 ; Resume Game', ColorRed, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 50);
	DrawText('Press 2 ; Return to Menu', ColorLightGreen, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 100);
	DrawText('Press 3 ; Exit Game', ColorYellow, 'OptionFont', (CONSTSCREENWIDTH / 2) - 500 , (CONSTSCREENHEIGHT / 2) + 150);
	if KeyTyped(KeyCode(Num1Key)) then game.state.mode := storeGameMode; //This will return to the game mode that they chose at the main menu.
	if KeyTyped(KeyCode(Num2Key)) then ResetGame(game); // This returns to the main menu
	if KeyTyped(KeyCode(Num3Key)) then Halt; // This quits the game
end;

///
/// Purpose: This is to check the local keys on a player, all players use the same controls and thus share this procedure
///

procedure CheckLANKeys(var ship : ShipData; var game : GameData);
var
	message : String;
	i : Integer;
begin
	for i:=0 to game.state.numOfPlayers - 1 do if game.players[i].score >= 5 then exit; //If any player has won the game, the game is over and players cannot move.
	BroadcastMessage(IntToStr(game.client.identifier) + IntToStr(ship.location.x) + ',' + IntToStr(ship.location.y)); //This will broadcast your position to every client if you are the host and if you are a client it will send the message to the host.
	if KeyDown(KeyCode(LeftKey)) then //left
	begin
		ship.controls[0].down := true; //The boolean associated with this key is set to true which is then later used in HandleMovement
	end;
	if KeyDown(KeyCode(RightKey)) then ///right
	begin
		ship.controls[1].down := true;
	end;
	if KeyDown(KeyCode(UpKey)) then //up
	begin
		ship.controls[2].down := true;
	end;
end;

///
/// Purpose: This is used to process the messages recieved by any player, the message is passed in and then the data is taken out of it.
///

procedure ProcessLANMovement(var game : GameData; message : String);
var
	i : Integer;
	commaIdx : Integer;
	x, y : Integer;
	xString, yString : String; //3342,1091
begin
	if message[1] = IntToStr(game.client.identifier) then exit; //If the first character of the message is the same as the ships identifier, it will exit so that the message is not processed on clients twice.
	xString := '';
	yString := '';
	for i := 1 to Length(message) - 1 do if message[i + 1] = ',' then commaIdx := i; //This find the location of the comma in the message
	for i := 1 to commaIdx - 1 do xString := xString + message[i + 1]; // From the second character to before the comma, this will be concatenated into the x position
	for i := commaIdx + 1  to Length(message) - 1 do yString := yString + message[i + 1]; //From after the comma to the length of the message, this will be concatenated into the y position
	if TryStrToInt(xString, x) then x:= StrToInt(xString); //If the message can be turned into a Integer, it will be
	if TryStrToInt(yString, y) then y:= StrToInt(yString);
	game.players[StrToInt(message[1])].ship.location.x := x; //This changes the location of the players depending on the message
	game.players[StrToInt(message[1])].ship.location.y := y;
end;

///
/// Purpose: This is for the host to use, this will loop until no messages are left, the message is read, then since this is the host, the message will be broadcast back to all clients so that the other clients can get the message.
/// Once that the message has been broadcast, the host will then process the message and with that update the positions of
///

procedure CheckHostKeys(var game : GameData);
var
	message : String;
begin
	repeat
		CheckNetworkActivity(); //This is the ProcessEvents of networking, it checks for any network activity.
		if HasMessages() then // If there is a message waiting
		begin
			message := ReadMessageData(game.host.server); //assign the message to a variable
			BroadcastMessage(message); //The host needs to send the message to the other clients so that everyone can get the message
			ProcessLANMovement(game, message); //Process the message and change the location of the ship.
		end;
	until not (HasMessages());//If there are no more messages to process, this can end
end;

///
/// Purpose: This is for every client to use, this will loop until no messages are waiting to be sent, once a message is recieved, it will be assigned to a variable, checked, if it starts with a 'd' then it is a death message
/// otherwise it is a position message.
///

procedure CheckClientKeys(var game : GameData);
var
	message : String;
begin
	repeat
		CheckNetworkActivity();
		if HasMessages() then
		begin
			message := ReadMessageData(game.client.access);
			case message[1] of //Since the host can send two types of messages, position messages and death messages, you need to have a case statement to decide what to do with that message.
				'd': ProcessLANHit(game, message); //If the message starts with a 'd', then it is a death message and will go to the ProcessLANHit
				else
				begin
					ProcessLANMovement(game, message); //If the message does not start with a 'd' then it must be a position message
				end;
			end;
		end;
	until not (HasMessages());
end;

///
/// Purpose: If you are the host, this will be called inside of a loop
///

procedure HostLoop(var game : GameData);
begin
	CheckHostKeys(game);//Host loop calls host procedure
end;

///
/// If you are a client. this will be called inside of a loop.
///

procedure ClientLoop(var game : GameData);
begin
	CheckNetworkActivity();// To check for connection status
	CheckClientKeys(game); //Client loop calls client procedure
	if not ConnectionOpen(game.client.access) then Reconnect(game.client.access); //If a client has disconnected, this will attempt to reconnect
end;

///
/// If the game is in LANMode (The player clicked '4' at the menu) This procedure will be looped.
///

procedure LanMode(var game : GameData; option : Integer);
var
	i : Integer;
begin
	ClearKeys(game); // Resets all keys
	case option of // Depending on what they chose during the load of the game
		1: HostLoop(game);
		2: ClientLoop(game);
	end;
	CheckLANKeys(game.players[game.client.identifier].ship, game); //Both host and clients need these procedures, so they are called after the host or client loop procedure.
	for i:=0 to (game.state.numOfPlayers - 1) do
	begin
		ShipEvents(game.players[i].ship);
	end;
end;

///
/// This will check what game mode has been selected and then will choose which procedure to run from that choice
///

procedure PlayGame(var game : GameData; var storeGameMode : GameType; option : Integer);
var
	i : Integer;
begin
	case game.state.mode of
		Menu : SelectGameMode(game.state, storeGameMode);
		Pause : PausedGame(game, storeGameMode);
		Player2 :
			begin
				CheckKeys(game); //Since every game mode except LANGame needs CheckKeys(), it must be called multiple times
				Mode2Player(game);
			end;
		Player3 :
			begin
				CheckKeys(game);
				Mode3Player(game);
			end;
		Player4 :
			begin
				CheckKeys(game);
				Mode4Player(game);
			end;
		LANGame : LanMode(game, option);
	end;
	CheckHit(game); //Every game mode uses these procedures so they can be called here.
	DrawInterface(game);
end;

///
/// Purpose: This is a very, very important procedure, without this the LAN will not work. This procedure is to set up all of the prerequisite information required for the LAN mode to work.
///

procedure SetLAN(var game : GameData; var option : Integer);
var
 messageHost : String; //Just to define the difference between the messages from and to the Host/Client.
 messageClient : String;
begin
	game.client.identifier := 0; //The host will be the blue ship always and the first ship, this is for other procedures and simplicity.
	WriteLn('Please complete host set up first');
	WriteLn('1 : Host connection');
	WriteLn('2 : Client Connection');
	WriteLn('3 : Local Game');
	option := ReadInteger('Choose: ');
	case option of
		1: //If they pick '1', this means that they are the host of the server
		begin
			CloseAllServers(); //Close any servers still open just in case
			game.host.server :=  CreateServer('PascTronServer', 25585, TCP); //This creates the server and assigns it into the host record. The port and transport protocol are preset so that it is easier for users to set up.
			while ((game.host.players < 2) or (game.host.players > 4)) do //There can only be 2 to 4 players
			begin
				game.host.players := ReadInteger('How many players(2 to 4): ');
				SetLength(game.host.connections, game.host.players); //This sets the length of the array depending on how many players there are.
			end;
			WriteLn('You are the Blue Ship');
			repeat
				begin
					CheckNetworkActivity(); //Checks for any network activity, here, we are searching for connections.
					if ServerHasNewConnection(game.host.server) then //If there is a new connection
					begin
						WriteLn('Connection Detected');
						messageHost := (IntToStr(game.state.numOfPlayers) + IntToStr(game.host.players)); //Prepares a message to be sent to the host, this message contains the which player the client will be and the number of player in the game.
						game.host.connections[game.state.numOfPlayers - 1] := LastConnection(game.host.server); //This assigns the connection to the connections array
						SendMessageTo(messageHost, game.host.connections[game.state.numOfPlayers - 1]);// This sends the message to that connection inside the array.
						game.state.numOfPlayers += 1; //This adds one to the numOfPlayers, so that the next connection is given a different ship etc.
					end;
				end;
			until (game.state.numOfPlayers = game.host.players); //Until the amount of connections is the amount the host specified, the host will not launch the game window.
			ClearMessages(game.host.server); //Clear any left over messages.
		end;
		2:
		begin
			game.client.ip := ReadString('Input Ip: '); //The only value the user needs to input is the IP of the host
			game.client.access := OpenConnection(game.client.ip, 25585); //The client then attempts to connect to the host with the IP
			Delay(100); //Delay the program, this is so that the host can process the connection recieved and then send a message to the client, the delay guarentees that the message can be recieved.
			CheckNetworkActivity(); // Check for the message.
			if HasMessages(game.client.access) then
			begin
				messageClient := ReadMessageData(game.client.access); //Read the messages data
				game.client.identifier := StrToInt(messageClient[1]); //The player the client will be.
				game.state.numOfPlayers := StrToInt(messageClient[2]); //The amount of players the host has defined.
				case messageClient[1] of //Dpeending on the message, the client will recieve a difference message here, but this tells them what colour ship they will be in the LAN mode.
					'1': WriteLn('You are the Red Ship');
					'2': WriteLn('You are the Green Ship');
					'3': WriteLn('You are the Yellow Ship');
				end;
				ClearMessages(game.client.access); //Clears any left over messages
			end;
		end;
		3: //If they dont want to play LAN mode.
	end;
end;

///
/// Purpose: This is the main procedure, this will open the games window and other essential procedures, such as the repeat until loop which will run the games code.
///

procedure Main();
var
	storeGameMode : GameType;
	game : GameData;
	option : Integer;
begin
	ResetGame(game); //Initially resets the game, this initallises all values.
	SetLAN(game, option);
	OpenGraphicsWindow('PascTRON', CONSTSCREENWIDTH, CONSTSCREENHEIGHT);
	game.state.mode := Menu; // This is initialises the game mode to the Main Menu state
	LoadMusicNamed('TronGame','TronGame.ogg'); // credits for songs : https://www.youtube.com/watch?v=9e4uYashDuw
	PlayMusic(MusicNamed('TronGame')); //Plays the awesome music
	repeat
		ClearScreen(ColorBlack);
		PlayGame(game, storeGameMode, option);
		ProcessEvents();
		RefreshScreen(60);
	until WindowCloseRequested(); // Until the player closes the windown this loop will continue to run.
	CloseAllConnections(); //Once the game is closed, close any open connections
	CloseAllServers();// Ant open servers.
end;

begin
	Main();
end.
