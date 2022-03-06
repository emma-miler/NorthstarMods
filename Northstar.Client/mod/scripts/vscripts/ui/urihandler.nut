untyped

globalize_all_functions

void function ShowURIDialog() {
    DialogData dialogData
	dialogData.header = "#NS_INVITE_JOIN_HEADER"
	dialogData.image = $"rui/menu/fd_menu/upgrade_northstar_chassis"
	dialogData.message = Localize("#NS_INVITE_JOIN_BODY", NSGetInviteServerName())
	AddDialogButton( dialogData, "#YES", NSAcceptInvite)
	AddDialogButton( dialogData, "#NO", NSDeclineInvite)
	OpenDialog( dialogData )
}

void function GenerateInviteSuccesDialog( DialogData randomParamIGuess ) {
	DialogData dialogData
	dialogData.header = "#NS_GENERATE_INVITE_SUCCESS"
	dialogData.ruiMessage.message = "#NS_GENERATE_INVITE_SUCCESS_MESSAGE"

	AddDialogButton( dialogData, "#OK" )

	OpenDialog( dialogData )
}

void function doGenerateServerInvite(bool link) {
	int res = NSGenerateServerInvite(link)
	if (res == 0) {
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

void function GenerateServerInvite( var unused ) {
	doGenerateServerInvite(true)
}

void function GenerateJoinDialog( bool succes ) {
	DialogData dialogData
	if (succes) {
		dialogData.header = "#NS_GENERATE_INVITE_SUCCESS"
		dialogData.ruiMessage.message = "#NS_GENERATE_INVITE_SUCCESS_MESSAGE"
	}
	else {
		dialogData.header = "#NS_GENERATE_INVITE_FAILURE"
		dialogData.ruiMessage.message = "#NS_GENERATE_INVITE_FAILURE_MESSAGE"
	}


	AddDialogButton( dialogData, "#OK" )

	OpenDialog( dialogData )
}

void function TryJoinInvite( var unused ) {
	NSTryJoinInvite(Hud_GetUTF8Text(Hud_GetChild( GetMenu( "JoinInviteMenu" ), "EnterInviteBox")))
}