Connect-SPOCSOM -Username adminchase@jtcc.edu -Url https://johntyler.sharepoint.com/sites/Group_Drive
$items=(Get-SPOListItems Documents -IncludeAllProperties $true -Recursive | where {$_.FSObjType -eq 0}).FileRef

$arr=@()
for($i=0;$i -lt $items.Count; $i++){$arr+=(Get-SPOFileByServerRelativeUrl -ServerRelativeUrl $items[$i])}
foreach($ar in $arr){ if($ar.CheckedOutByUser.LoginName -eq "i:0#.f|membership|ngartrell@jtcc.edu") {$ar.ServerRelativeUrl}}