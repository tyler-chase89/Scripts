$file = Export-TransportRuleCollection

[System.IO.File]::WriteAllBytes('C:\Path\To\Your\Output\ExchangeTransportRules.xml', $file.FileData)