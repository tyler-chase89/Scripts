# Check if CrowdStrike Falcon Sensor is installed
$csSensor = Get-CrowdStrikeFalconSensor

if ($csSensor -ne $null) {
    Write-Output "Compliant"
} else {
    Write-Output "Non-compliant"
}