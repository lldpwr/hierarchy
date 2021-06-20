Import-Module Pode
Start-PodeServer {
    #Attach port 8000 to the local machine address and use HTTP protocol
    Add-PodeEndpoint -Address localhost -Port 8000 -Protocol HTTP

    #Get hierachy
    Add-PodeRoute -Method Get -Path '/herarchie' -ScriptBlock {
        Write-Host "Hierarchie"
    }

    # Set Parent 
    Add-PodeRoute -Method Post -Path '/parent' -ScriptBlock {
        Write-Host $WebEvent.Data
    }

    # html file
    Add-PodeStaticRoute -Path '/' -Source './html'
}
 