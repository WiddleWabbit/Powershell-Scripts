﻿Get-Process | Where-Object {$_.Name -like "*openvpn*"} | Stop-Process