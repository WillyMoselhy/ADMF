﻿<#
# Example:
Register-PSFTeppScriptblock -Name "ADMF.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

Register-PSFTeppScriptblock -Name 'ADMF.Context.Store' -ScriptBlock {
	(Get-AdmfContextStore).Name
}