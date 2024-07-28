init()
{
    level thread onPlayerConnect();
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
        player thread onPlayerDisconnect();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    
    loadPlayerData(self);
    self updateRankBonuses();
    
    for(;;)
    {
        self waittill("spawned_player");
        self thread menuOpenListener();
        self updateFOV();
    }
}

onPlayerDisconnect()
{
    self waittill("disconnect");
    savePlayerData(self);
}

savePlayerData(player)
{
    fileName = "playerdata/" + player getGuid() + ".txt";
    fileContent = player.bank_balance + "," + player.rank + "," + player.customFOV;
    writeFile(fileName, fileContent);
}

loadPlayerData(player)
{
    fileName = "playerdata/" + player getGuid() + ".txt";
    if(fileExists(fileName))
    {
        fileContent = readFile(fileName);
        tokens = strTok(fileContent, ",");
        if(tokens.size >= 3)
        {
            player.bank_balance = int(tokens[0]);
            player.rank = int(tokens[1]);
            player.customFOV = int(tokens[2]);
        }
        else
        {
            setDefaultPlayerData(player);
        }
    }
    else
    {
        setDefaultPlayerData(player);
    }
}

setDefaultPlayerData(player)
{
    player.bank_balance = 0;
    player.rank = 1;
    player.customFOV = 100;
}

updateRankBonuses()
{
    damageMult = 1 + (0.05 * (self.rank - 1));
    self setClientDvar("player_damageMultiplier", damageMult);
    
    self.moneyMultiplier = 1 + (0.05 * (self.rank - 1));
}

menuOpenListener()
{
    self endon("disconnect");
    
    for(;;)
    {
        if(self adsButtonPressed() && self meleeButtonPressed())
        {
            self openMenu();
            wait 0.5;
        }
        wait 0.05;
    }
}

addMenuOption(name, func)
{
    option = spawnStruct();
    option.name = name;
    option.func = func;
    self.menu.options[self.menu.options.size] = option;
}

openMenu()
{
    self closeMenu();
    self.menuOpen = true;
    self.menu = spawnStruct();
    self.menu.title = "             Control Panel";
    self.menu.options = [];
    self.menu.cursor = 0;
    
    self addMenuOption("Rank Options", ::openRankSubMenu);
    self addMenuOption("Bank Options", ::openBankSubMenu);
    self addMenuOption("Change FOV", ::changeFOV);
    self addMenuOption("Show Credits", ::showCredits);
    self addMenuOption("AFK Mode", ::toggleAFKMode);
    
    self createMenuHud();
    self thread menuInput();
}

openRankSubMenu()
{
    self closeMenu();
    self.menuOpen = true;
    self.menu = spawnStruct();
    self.menu.title = "             Rank Options";
    self.menu.options = [];
    self.menu.cursor = 0;
    
    self addMenuOption("Rank Up (10000)", ::rankUp);
    self addMenuOption("Show Rank Status", ::showRankStatus);
    self addMenuOption("Check Rank", ::checkRank);
    
    self createMenuHud();
    self thread menuInput();
}

openBankSubMenu()
{
    self closeMenu();
    self.menuOpen = true;
    self.menu = spawnStruct();
    self.menu.title = "             Bank Options";
    self.menu.options = [];
    self.menu.cursor = 0;
    
    self addMenuOption("Deposit 1000", ::depositMoney);
    self addMenuOption("Withdraw 1000", ::withdrawMoney);
    self addMenuOption("Deposit All", ::depositAllMoney);
    self addMenuOption("Withdraw All", ::withdrawAllMoney);
    self addMenuOption("Check Balance", ::checkBalance);
    
    self createMenuHud();
    self thread menuInput();
}

createMenuHud()
{
    self.menu.hud = [];
    
    // Create background with increased size
    self.menu.background = newClientHudElem(self);
    self.menu.background.x = 40;
    self.menu.background.y = 40;
    self.menu.background.alignX = "left";
    self.menu.background.alignY = "top";
    self.menu.background.sort = -1;
    self.menu.background setShader("white", 200, 40 + (self.menu.options.size * 20)); // Increased width and added more height
    self.menu.background.color = (0, 0, 0);
    self.menu.background.alpha = 0.5;
    
    self.menu.hud[0] = newClientHudElem(self);
    self.menu.hud[0].alignX = "left";
    self.menu.hud[0].alignY = "top";
    self.menu.hud[0].x = 50;
    self.menu.hud[0].y = 50;
    self.menu.hud[0].fontScale = 1.5;
    self.menu.hud[0] setText("^6" + self.menu.title);
    
    for(i = 0; i < self.menu.options.size; i++)
    {
        self.menu.hud[i+1] = newClientHudElem(self);
        self.menu.hud[i+1].alignX = "left";
        self.menu.hud[i+1].alignY = "top";
        self.menu.hud[i+1].x = 50;
        self.menu.hud[i+1].y = 70 + (i * 20);
        self.menu.hud[i+1].fontScale = 1.2;
        self.menu.hud[i+1] setText(self getColorForIndex(i) + self.menu.options[i].name);
    }
    
    self updateMenuCursor();
}
updateMenuCursor()
{
    for(i = 0; i < self.menu.options.size; i++)
    {
        if(i == self.menu.cursor)
            self.menu.hud[i+1] setText("^0> ^7" + self getColorForIndex(i) + self.menu.options[i].name);
        else
            self.menu.hud[i+1] setText("  " + self getColorForIndex(i) + self.menu.options[i].name);
    }
}

getColorForIndex(index)
{
    switch(index % 7)
    {
        case 0: return "^1";
        case 1: return "^2";
        case 2: return "^3";
        case 3: return "^4";
        case 4: return "^5";
        case 5: return "^6";
        case 6: return "^7";
        default: return "^7";
    }
}

menuInput()
{
    self endon("disconnect");
    self endon("close_menu");
    
    self.lastInput = 0;
    while(self.menuOpen)
    {
        currentTime = getTime();
        if(self attackButtonPressed() && currentTime - self.lastInput > 150)
        {
            self.menu.cursor++;
            if(self.menu.cursor >= self.menu.options.size)
                self.menu.cursor = self.menu.options.size - 1;  // Limit to last option
            self updateMenuCursor();
            self.lastInput = currentTime;
        }
        else if(self adsButtonPressed() && currentTime - self.lastInput > 150)
        {
            self.menu.cursor--;
            if(self.menu.cursor < 0)
                self.menu.cursor = 0;  // Limit to first option
            self updateMenuCursor();
            self.lastInput = currentTime;
        }
        else if(self jumpButtonPressed() && currentTime - self.lastInput > 200)
        {
            option = self.menu.options[self.menu.cursor];
            self thread [[option.func]]();
            self.lastInput = currentTime;
        }
        else if(self useButtonPressed() && currentTime - self.lastInput > 200)
        {
            if(self.menu.title != "             Control Panel")
            {
                self openMenu(); // This will return to the main menu
            }
            // If it's the main menu, do nothing
            self.lastInput = currentTime;
        }
        else if(self meleeButtonPressed() && currentTime - self.lastInput > 200)
        {
            self closeMenu();
            break;
        }
        
        wait 0.05;
    }
}

closeMenu()
{
    if(isDefined(self.menu))
    {
        for(i = 0; i < self.menu.hud.size; i++)
        {
            if(isDefined(self.menu.hud[i]))
                self.menu.hud[i] destroy();
        }
        if(isDefined(self.menu.background))
            self.menu.background destroy();
    }
    self.menuOpen = false;
    self.menu = undefined;
}

showRankStatus()
{
    rankUps = self.rank - 1;
    damageBonus = rankUps * 5;
    moneyBonus = rankUps * 5;
    
    self iPrintLnBold("Rank Status:");
    self iPrintLn("Times Ranked Up: " + rankUps);
    self iPrintLn("Damage Bonus: +" + damageBonus + "%");
    self iPrintLn("Money Bonus: +" + moneyBonus + "%");
    
    wait 5;
    self openMenu();
}

showCredits()
{
    self iPrintLnBold("^3Daddy ^7Andrew ^2Made ^9It");
    wait 3;
    self openMenu();
}

changeFOV()
{
    self closeMenu();
    self.changingFOV = true;
    
    fovText = newClientHudElem(self);
    fovText.alignX = "center";
    fovText.alignY = "center";
    fovText.x = 0;
    fovText.y = 0;
    fovText.fontScale = 1.5;
    fovText setText("Current FOV: " + self.customFOV + "\nUse [{+attack}] to increase, [{+speed_throw}] to decrease, [{+gostand}] to confirm");
    
    while(self.changingFOV)
    {
        if(self attackButtonPressed())
        {
            self.customFOV += 5;
            if(self.customFOV > 120)
                self.customFOV = 120;
            self updateFOV();
            fovText setText("Current FOV: " + self.customFOV + "\nUse [{+attack}] to increase, [{+speed_throw}] to decrease, [{+gostand}] to confirm");
            wait 0.2;
        }
        else if(self secondaryOffhandButtonPressed())
        {
            self.customFOV -= 5;
            if(self.customFOV < 100)
                self.customFOV = 100;
            self updateFOV();
            fovText setText("Current FOV: " + self.customFOV + "\nUse [{+attack}] to increase, [{+speed_throw}] to decrease, [{+gostand}] to confirm");
            wait 0.2;
        }
        else if(self jumpButtonPressed())
        {
            self.changingFOV = false;
        }
        wait 0.05;
    }
    
    fovText destroy();
    self iPrintLnBold("FOV set to " + self.customFOV);
    savePlayerData(self);
    wait 1;
    self openMenu();
}

updateFOV()
{
    self setClientDvar("cg_fov", self.customFOV);
    self setClientDvar("cg_fovScale", 1.0);
    self setClientDvar("cg_fovMin", self.customFOV);
    self setClientDvar("player_fovScale", 1.0);
    self setClientDvar("player_fovMin", self.customFOV);
    self setClientDvar("cg_fovOuterMultiplier", 1.0);
    
    self iPrintLn("Debug: FOV updated to " + self.customFOV);
}

depositAllMoney()
{
    amount = self.score;
    if(amount > 0)
    {
        self.score -= amount;
        self.bank_balance += amount;
        self iPrintLnBold("Deposited all points: " + amount);
        savePlayerData(self);
    }
    else
    {
        self iPrintLnBold("No points to deposit");
    }
}

withdrawAllMoney()
{
    amount = self.bank_balance;
    if(amount > 0)
    {
        self.score += amount;
        self.bank_balance -= amount;
        self iPrintLnBold("Withdrew all points: " + amount);
        savePlayerData(self);
    }
    else
    {
        self iPrintLnBold("No points in the bank to withdraw");
    }
}

depositMoney()
{
    amount = 1000;
    if(self.score >= amount)
    {
        self.score -= amount;
        self.bank_balance += amount;
        self iPrintLnBold("Deposited " + amount + " points");
        savePlayerData(self);
    }
    else
    {
        self iPrintLnBold("Not enough points to deposit");
    }
}

withdrawMoney()
{
    amount = 1000;
    if(self.bank_balance >= amount)
    {
        self.score += amount;
        self.bank_balance -= amount;
        self iPrintLnBold("Withdrew " + amount + " points");
        savePlayerData(self);
    }
    else
    {
        self iPrintLnBold("Not enough points in the bank");
    }
}

checkBalance()
{
    self iPrintLnBold("Bank Balance: " + self.bank_balance);
}

rankUp()
{
    cost = 10000;
    if(self.bank_balance >= cost)
    {
        self.bank_balance -= cost;
        self.rank++;
        self updateRankBonuses();
        self iPrintLnBold("Ranked up to level " + self.rank);
        self iPrintLnBold("New damage bonus: +" + (self.rank - 1) * 5 + "%");
        self iPrintLnBold("New money bonus: +" + (self.rank - 1) * 5 + "%");
        savePlayerData(self);
    }
    else
    {
        self iPrintLnBold("Not enough points to rank up");
    }
}

checkRank()
{
    self iPrintLnBold("Current Rank: " + self.rank);
    self iPrintLnBold("Damage Bonus: +" + (self.rank - 1) * 5 + "%");
    self iPrintLnBold("Money Bonus: +" + (self.rank - 1) * 5 + "%");
}

awardMoney(amount)
{
    multipliedAmount = int(amount * self.moneyMultiplier);
    self.score += multipliedAmount;
    return multipliedAmount;
}

toggleAFKMode()
{
    if (!isDefined(self.isAFK) || !self.isAFK)
    {
        self.isAFK = true;
        // Remove this line: self iPrintLnBold("AFK Mode: ON");
        self thread afkModeOn();
    }
    else
    {
        self.isAFK = false;
        // Remove this line: self iPrintLnBold("AFK Mode: OFF");
        self thread afkModeOff();
    }
    self closeMenu();
}

afkModeOn()
{
    self endon("disconnect");

    // Enable god mode
    if (!self.god)
    {
        self doGod();
    }

    // Optionally, you can freeze the player in place
    self freezeControls(true);

    // Add a visual indicator in the middle of the screen
    self.afkText = newClientHudElem(self);
    self.afkText.alignX = "center";
    self.afkText.alignY = "center";
    self.afkText.x = 0;
    self.afkText.y = 0;
    self.afkText.fontScale = 1.5;
    self.afkText.alpha = 0.8;
    self.afkText setText("^3AFK MODE ON");

    // Wait for the player to turn off AFK mode
    self waittill("afk_mode_off");
}

afkModeOff()
{
    self notify("afk_mode_off");

    // Remove the visual indicator
    if (isDefined(self.afkText))
    {
        self.afkText destroy();
        self.afkText = undefined;
    }

    // Unfreeze the player if you froze them
    self freezeControls(false);

    // Start the grace period
    self thread afkGracePeriod();
}

afkGracePeriod()
{
    self endon("disconnect");

    // Create a centered HUD element for the grace period message
    graceText = newClientHudElem(self);
    graceText.alignX = "center";
    graceText.alignY = "center";
    graceText.x = 0;
    graceText.y = 50;  // Slightly below the center
    graceText.fontScale = 1.2;
    graceText.alpha = 0.8;
    graceText setText("^3Grace period: 45 seconds");

    // Ensure god mode is on for the grace period
    if (!self.god)
    {
        self doGod();
    }

    wait 45;

    // Disable god mode after grace period if it was enabled by AFK mode
    if (self.god)
    {
        self doGod();
    }

    // Update the grace period message
    graceText setText("^1Grace period ended");
    wait 2;  // Display the message for 2 seconds
    graceText destroy();  // Remove the HUD element
}

doGod()
{
    if(self.god == false)
    {
        self enableInvulnerability();
        // Remove this line: self iPrintln("Godmode: ^2Enabled");
        self.god = true;
    }
    else if(self.god == true)
    {
        self disableInvulnerability();
        // Remove this line: self iPrintln("Godmode: ^1Disabled");
        self.god = false;
    }
}