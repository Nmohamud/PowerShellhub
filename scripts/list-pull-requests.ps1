﻿<#
.SYNOPSIS
        Lists all pull requests
.DESCRIPTION
        This PowerShell script lists all pull requests for a Git repository.
.PARAMETER RepoDir
        Specifies the file path to the local Git repository (default is working directory).
.EXAMPLE
        PS> ./list-pull-requests.ps1 C:\MyRepo
.LINK
        https://github.com/fleschutz/PowerShell
.NOTES
        Author: Markus Fleschutz | License: CC0
#>

param([string]$RepoDir = "$PWD")

try {
        Write-Progress "(1/3) Searching for Git executable...  "
        $null = (git --version)
        if ($lastExitCode -ne 0) { throw "Can't execute 'git' - make sure Git is installed and available" }

        Write-Progress "(2/3) Checking local repository..."
        if (!(Test-Path "$RepoDir" -pathType container)) { throw "Can't access folder: $RepoDir" }
        $RepoDirName = (Get-Item "$RepoDir").Name

        Write-Progress "(3/3) Fetching latest updates..."
        & git -C "$RepoDir" fetch --all --force --quiet
        if ($lastExitCode -ne 0) { throw "'git fetch --all' failed with exit code $lastExitCode" }
	Write-Progress -completed "Done."

	" "
	"Commit ID                                       Reference"
	"---------                                       ---------"
	& git -C "$RepoDir" ls-remote origin 'pull/*/head'
	if ($lastExitCode -ne 0) { throw "'git ls-remote' failed with exit code $lastExitCode" }
	exit 0 # success
} catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
}
