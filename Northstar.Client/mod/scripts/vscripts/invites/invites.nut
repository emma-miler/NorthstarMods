untyped

global function NSPullInvites
global function InitInviteSystem
global function GenerateServerInvite
global function ShowURIDialog
global function testrunner
global function AskInstallURIHandler

struct
{
	var menu
	var enterPasswordBox
	var enterPasswordDummy
	var connectButton
	var inviteJoinMenu
	var inviteEntryBox
	var cancelConnection
} file

struct
{
	var index
    var id
    var password
    var type
	var name
	var requires_password
} storedInvite

void function InitInviteSystem() {
	AddMenu( "JoinInviteMenu", $"resource/ui/menus/ns_joininvite.menu", InitInviteMenu, "#MENU_CONNECT" )
	AddMenu( "ConnectWithPasswordMenuInvite", $"resource/ui/menus/connect_password.menu", InitConnectPasswordMenu, "#MENU_CONNECT" )
	InitConnectPasswordMenu()
	NSPullInvites()
}

void function testrunner() {
	thread AskInstallURIHandler()
}

void function AskInstallURIHandler() {
	if (!NSCheckURIHandlerInstall()) {
		while (!NSAllowShowInvite()) {
			WaitFrame()
		}
		wait 0.1
		DialogData dialogData
		dialogData.header = "#NS_INVITE_JOIN_HEADER"
		dialogData.image = $"rui/menu/fd_menu/upgrade_northstar_chassis"
		dialogData.message = "#NS_URIHANDLER_PROMPT"
		AddDialogButton( dialogData, "#YES", installURIHandler )
		AddDialogButton( dialogData, "#NO", declineURIHandler )
		AddDialogButton( dialogData, "#DONT_ASK_AGAIN", declineURIHandlerAlways )
		OpenDialog( dialogData )
	}
}

void function installURIHandler() {
	NSDoInstallURIHandler()
}
void function declineURIHandler() {}
void function declineURIHandlerAlways() {
	SetConVarBool("ns_dont_ask_install_urihandler", true)
}

void function OnConnectWithPasswordMenuOpenedInvite()
{
	UI_SetPresentationType( ePresentationType.KNOWLEDGEBASE_SUB )

	Hud_SetText( Hud_GetChild( file.menu, "Title" ), "#MENU_TITLE_CONNECT_PASSWORD" )
	Hud_SetText( file.connectButton, "#MENU_CONNECT_MENU_CONNECT" )
	Hud_SetText( file.enterPasswordBox, "" )
	Hud_SetText( file.enterPasswordDummy, "" )
}

void function InitInviteMenu()
{
	file.inviteJoinMenu = GetMenu( "JoinInviteMenu" )
	AddMenuFooterOption( file.inviteJoinMenu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
	var connectButton = Hud_GetChild( file.inviteJoinMenu, "ConnectButton" )
	Hud_AddEventHandler( connectButton, UIE_CLICK, LoadInviteAndJoin )
	file.inviteEntryBox = Hud_GetChild(file.inviteJoinMenu, "EnterInviteBox" )
}

void function InitConnectPasswordMenu()
{
	file.menu = GetMenu( "ConnectWithPasswordMenuInvite" )

	file.enterPasswordBox = Hud_GetChild( file.menu, "EnterPasswordBox" )
	file.enterPasswordDummy = Hud_GetChild( file.menu, "EnterPasswordBoxDummy" )
	file.connectButton = Hud_GetChild( file.menu, "ConnectButton" )

	AddMenuEventHandler( file.menu, eUIEvent.MENU_OPEN, OnConnectWithPasswordMenuOpenedInvite )
	AddMenuFooterOption( file.menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )

	AddButtonEventHandler( file.connectButton, UIE_CLICK, ConnectWithPasswordInvite )

	AddButtonEventHandler( file.enterPasswordBox, UIE_CHANGE, UpdatePasswordLabelInvite )
}



void function NSPullInvites() {
    bool has_invite = NSHasStoredInvite()
    if (has_invite) {

		if ( !NSIsRequestingServerList() )
			NSClearRecievedServerList()
			NSRequestServerList()
			thread wait_to_show_invite()
    }
}

void function wait_to_show_invite() {
	while (!NSAllowShowInvite() || NSIsRequestingServerList()) {
		WaitFrame()
	}
	try {
		table test = NSPullInviteFromNative()
		storedInvite.index = test.index
		storedInvite.id = test.id
		storedInvite.password = test.password
		storedInvite.type = test.type
		storedInvite.name = test.name
		storedInvite.requires_password = test.requires_password

		ShowURIDialog(true)
	}
	catch (ex) {
		ShowURIDialog(false, expect string(ex))
	}
}

void function ShowURIDialog(bool succes, string error = "")
{
    DialogData dialogData
	if ( succes )
	{
		dialogData.menu = GetMenu( "AnnouncementDialog" )
		dialogData.header = "#NS_INVITE_JOIN_HEADER"
		dialogData.image = $"ui/menu/common/ticket_icon"
		dialogData.message = Localize( "#NS_INVITE_JOIN_BODY", storedInvite.name )
		if ( storedInvite.requires_password )
			AddDialogButton( dialogData, "#YES", ShowPasswordDialogBeforeJoin )
		else
			AddDialogButton( dialogData, "#YES", TryAcceptInviteRunner )
		AddDialogButton( dialogData, "#NO", NSDeclineInvite )
		OpenDialog( dialogData )
	}
	else
	{
		dialogData.header = "#NS_INVITE_JOIN_FAILURE_HEADER"
		dialogData.image = $"ui/menu/common/dialog_error"
		dialogData.message = Localize( "#NS_INVITE_JOIN_FAILURE_BODY", error )
		AddDialogButton( dialogData, "#OK" )
		OpenDialog( dialogData )
	}
}

void function ShowPasswordDialogBeforeJoin() { AdvanceMenu( GetMenu( "ConnectWithPasswordMenuInvite" ) ) }

void function LoadInviteAndJoin( var button ) {
	if ( !NSIsRequestingServerList() )
		NSClearRecievedServerList()
		NSRequestServerList()
	thread WaitLoadAndJoin()
}

void function WaitLoadAndJoin() {
	while (!NSAllowShowInvite() || NSIsRequestingServerList()) {
		WaitFrame()
	}
	try {
		NSParseInvite( Hud_GetUTF8Text( file.inviteEntryBox ) )
	}
	catch (ex) {
		ShowURIDialog(false, expect string(ex))
	}
}

void function UpdatePasswordLabelInvite( var n )
{
	string hiddenPSWD
	for ( int i = 0; i < Hud_GetUTF8Text( file.enterPasswordBox ).len(); i++ )
		hiddenPSWD += "*"
	Hud_SetText( file.enterPasswordDummy, hiddenPSWD )
}

void function ConnectWithPasswordInvite( var button )
{

	if ( GetTopNonDialogMenu() == file.menu && Hud_GetUTF8Text(file.enterPasswordBox) != "" ) {
		TryAcceptInviteRunner()
	}
}

void function TryAcceptInviteRunner() {
	thread TryAcceptInvite()
}

void function TryAcceptInvite()
{
	if ( NSIsAuthenticatingWithServer() )
		return

	print( "trying to authenticate with server " + storedInvite.name + " with password " + Hud_GetUTF8Text( file.enterPasswordBox ) )

	NSTryAuthWithServer( storedInvite.index, Hud_GetUTF8Text( file.enterPasswordBox ) )

	ToggleConnectingHUD( true )
	while ( NSIsAuthenticatingWithServer() && !file.cancelConnection )
	{
		WaitFrame()
	}

	ToggleConnectingHUD( false )

	if ( file.cancelConnection )
	{
		file.cancelConnection = false
		return
	}

	file.cancelConnection = false
	NSSetLoading( true )

	if ( NSWasAuthSuccessful() )
	{
		bool modsChanged

		array<string> requiredMods
		for ( int i = 0; i < NSGetServerRequiredModsCount( storedInvite.index ); i++ )
			requiredMods.append( NSGetServerRequiredModName( storedInvite.index, i ) )

		// unload mods we don't need, load necessary ones and reload mods before connecting
		foreach ( string mod in NSGetModNames() )
		{
			if ( NSIsModRequiredOnClient( mod ) )
			{
				modsChanged = modsChanged || NSIsModEnabled( mod ) != requiredMods.contains( mod )
				NSSetModEnabled( mod, requiredMods.contains( mod ) )
			}
		}

		// only actually reload if we need to since the uiscript reset on reload lags hard
		if ( modsChanged )
			ReloadMods()

		NSConnectToAuthedServer()
	}
	else
	{
		DialogData dialogData
		dialogData.header = "#ERROR"
		dialogData.message = "Authentication Failed"
		dialogData.image = $"ui/menu/common/dialog_error"

		#if PC_PROG
			AddDialogButton( dialogData, "#DISMISS" )

			AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )
		#endif // PC_PROG
		AddDialogFooter( dialogData, "#B_BUTTON_DISMISS_RUI" )

		OpenDialog( dialogData )
	}
}

void function GenerateInviteSuccesDialog( DialogData randomParamIGuess )
{
	DialogData dialogData
	dialogData.header = "#NS_GENERATE_INVITE_SUCCESS"
	dialogData.ruiMessage.message = "#NS_GENERATE_INVITE_SUCCESS_MESSAGE"

	AddDialogButton( dialogData, "#OK" )

	OpenDialog( dialogData )
}

void function doGenerateServerInvite(bool link)
{
	string res = NSGenerateServerInvite(  )
	if (res == "") {
		DialogData dialogData
		dialogData.header = "#NS_INVITE_GENERATE_FAILURE_HEADER"
		dialogData.ruiMessage.message = "NS_GENERATE_INVITE_SUCCESS_BODY"

		AddDialogButton( dialogData, "#OK" )

		OpenDialog( dialogData )
	}
	else {
		DialogData dialogData
		dialogData.header = "#NS_INVITE_GENERATE_SUCCESS_HEADER"
		dialogData.ruiMessage.message = "NS_INVITE_GENERATE_SUCCESS_BODY"

		AddDialogButton( dialogData, "#OK" )

		OpenDialog( dialogData )
	}
}

void function GenerateServerInvite( var unused )
{
	doGenerateServerInvite(true)
}

void function CreateJoinErrorDialog()
{
	NSDeclineInvite()
	DialogData dialogData
	dialogData.header = "#NS_INVITE_JOIN_FAILURE_HEADER"
	dialogData.ruiMessage.message = Localize( "#NS_INVITE_JOIN_FAILURE_BODY", "NSGetLastInviteError()" )
	AddDialogButton( dialogData, "#OK" )

	OpenDialog( dialogData )
}

void function ToggleConnectingHUD( bool vis )
{
	foreach (e in GetElementsByClassname( file.menu, "connectingHUD" ) ) {
		Hud_SetEnabled( e, vis )
		Hud_SetVisible( e, vis )
	}
	// if ( vis ) Hud_SetFocused( Hud_GetChild( file.menu, "ConnectingButton" ) )
}