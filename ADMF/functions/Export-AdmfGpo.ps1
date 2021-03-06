﻿function Export-AdmfGpo
{
	<#
	.SYNOPSIS
		Creates an export of GPO objects for use in the Domain Management module.
	
	.DESCRIPTION
		Creates an export of GPO objects for use in the Domain Management module.
		Use this command to record new GPO data for the module.
	
	.PARAMETER Path
		The path to which to export the GPOs.
	
	.PARAMETER GpoObject
		The GPO objects to export.
		Only accepts output of Get-GPO

	.PARAMETER Domain
		The domain to export from.
	
	.EXAMPLE
		PS C:\> Get-GPO -All | Where-Object DisplayName -like 'AD-D-SEC-T0*' | Export-AdmfGpo -Path .

		Exports all GPOs named like 'AD-D-SEC-T0*' to the current path
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	Param (
		[PsfValidateScript('ADMF.Validate.Path', ErrorString = 'ADMF.Validate.Path')]
		[Parameter(Mandatory = $true)]
		[string]
		$Path,

		[PsfValidateScript('ADMF.Validate.Type.Gpo', ErrorString = 'ADMF.Validate.Type.Gpo')]
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		$GpoObject,

		[string]
		$Domain = $env:USERDNSDOMAIN
	)
	
	begin
	{
		$resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem -SingleItem
		$backupCmd = { Backup-GPO -Path $resolvedPath -Domain $Domain }
		$backupGPO = $backupCmd.GetSteppablePipeline()
		$backupGPO.Begin($true)

		[System.Collections.ArrayList]$gpoData = @()
		$exportID = (New-Guid).ToString()
	}
	process
	{
		foreach ($gpoItem in $GpoObject) {
			$exportData = $backupGPO.Process(($gpoItem | Select-PSFObject 'ID as GUID'))
			$data = [PSCustomObject]@{
				DisplayName = $gpoItem.DisplayName
				Description = $gpoItem.Description
				ID = "{$($exportData.ID.ToString().ToUpper())}"
				ExportID = $exportID
			}
			$null = $gpoData.Add($data)
		}
	}
	end
	{
		$backupGPO.End()
		$gpoData | ConvertTo-Json | Set-Content "$resolvedPath\exportData.json"

		# Remove hidden attribute, top prevent issues with copy over WinRM
		foreach ($fsItem in (Get-ChildItem -Path $resolvedPath -Recurse -Force)) {
			$fsItem.Attributes = $fsItem.Attributes -band [System.IO.FileAttributes]::Directory
		}
	}
}
