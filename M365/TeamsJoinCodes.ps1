$teams = Get-Team
$results = @()

foreach ($team in $teams) {
    $joinCode = (Get-Team -GroupId $team.GroupId).JoinCode
    $results += [PSCustomObject]@{
        TeamName = $team.DisplayName
        JoinCode = $joinCode
    }
}

$results | Export-Csv -Path "PATH To SAVE CSV" -NoTypeInformation