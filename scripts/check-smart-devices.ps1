﻿<#
.SYNOPSIS
	Checks the SMART device status
.DESCRIPTION
	This PowerShell script queries the status of the SSD/HDD devices (supporting S.M.A.R.T.) and prints it.
.EXAMPLE
	PS> ./check-smart-devices.ps1
	✅ 1TB Samsung SSD 970 EVO 1TB via NVMe (35°C, 6142h, 34TB read, 64TB written, 770x on/off, v2B2QEXE7, test passed)
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

function Bytes2String([int64]$bytes) {
	if ($bytes -lt 1000) { return "$bytes bytes" }
	$bytes /= 1000
	if ($bytes -lt 1000) { return "$($bytes)KB" }
	$bytes /= 1000
	if ($bytes -lt 1000) { return "$($bytes)MB" }
	$bytes /= 1000
	if ($bytes -lt 1000) { return "$($bytes)GB" }
	$bytes /= 1000
	if ($bytes -lt 1000) { return "$($bytes)TB" }
	$bytes /= 1000
	if ($bytes -lt 1000) { return "$($bytes)PB" }
	$bytes /= 1000
	if ($bytes -lt 1000) { return "$($bytes)EB" }
}

try {
	$result = (smartctl --version)
	if ($lastExitCode -ne "0") { throw "Can't execute 'smartctl' - make sure smartmontools are installed" }

	if ($IsLinux) {
		$devices = $(sudo smartctl --scan-open)
	} else {
		$devices = $(smartctl --scan-open)
	}

	foreach($device in $devices) {
		$array = $device.split(" ")
		$dev = $array[0]
		if ("$dev" -eq "#") {
			continue
		} elseif ($IsLinux) {
			$details = (sudo smartctl --all --json $dev) | ConvertFrom-Json
			$null = (sudo smartctl --test=conveyance $dev)
		} else {
			$details = (smartctl --all --json $dev) | ConvertFrom-Json
			$null = (smartctl --test=conveyance $dev)
		}
		$status = "✅"
		$modelName = $details.model_name
		$protocol = $details.device.protocol
		[int64]$bytes = $details.user_capacity.bytes
		if ($bytes -gt 0) {
			$capacity = "$(Bytes2String $bytes) "
		} else {
			$capacity = ""
		}
		$infos = ""
		if ($details.temperature.current -gt 50) {
			$infos = "$($details.temperature.current)°C TOO HOT"
			$status = "⚠️"
		} elseif ($details.temperature.current -lt 0) {
			$infos = "$($details.temperature.current)°C TOO COLD"
			$status = "⚠️"
		} else {
			$infos = "$($details.temperature.current)°C"
		}
		if ($details.power_on_time.hours -gt 87600) { # 10 years
			$infos += ", $($details.power_on_time.hours)h (!)"
			$status = "⚠️"
		} else {
			$infos += ", $($details.power_on_time.hours)h"
		}
		if ($details.nvme_smart_health_information_log.host_reads) {
			$infos += ", $(Bytes2String ($details.nvme_smart_health_information_log.data_units_read * 512 * 1000)) read"
			$infos += ", $(Bytes2String ($details.nvme_smart_health_information_log.data_units_written * 512 * 1000)) written"
		}
		if ($details.power_cycle_count -gt 100000) { 
			$infos += ", $($details.power_cycle_count)x on/off (!)"
			$status = "⚠️"
		} else {
			$infos += ", $($details.power_cycle_count)x on/off"
		}
		$infos += ", v$($details.firmware_version)"
		if ($details.smart_status.passed) {
			$infos += ", test passed"
		} else {
			$infos += ", test FAILED"
			$status = "⚠️"
		}
		Write-Host "$status $capacity$modelName via $protocol ($infos)"
	}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
