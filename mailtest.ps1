$mailservers = Resolve-DNSName -type mx -name gmail.com | select -Property NameExchange
Foreach ($server in $mailServers) {
    Write-Host $server.NameExchange
}