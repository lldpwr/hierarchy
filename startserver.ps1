Import-Module Pode
Start-PodeServer {
    $ip = ip -j a | ConvertFrom-Json | Where-Object ifname -eq eth0 | Select-Object -ExpandProperty addr_info | Select-Object -ExpandProperty local -First 1
    #Attach port 8000 to the local machine address and use HTTP protocol
    Add-PodeEndpoint -Address $ip -Port 8000 -Protocol HTTP

    #Get hierachy
    Add-PodeRoute -Method Get -Path '/hierarchy' -ScriptBlock {
        Write-Host "hierarchy"
    }

    # Set Parent 
    Add-PodeRoute -Method Post -Path '/parent' -ScriptBlock {
        Write-Host $WebEvent.Data.keys
    }

    # html file
    Add-PodeStaticRoute -Path '/' -Source './html' -Defaults @('index.html')
}
 