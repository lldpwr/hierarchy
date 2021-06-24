Import-Module Pode
Start-PodeServer {
    add-type -path mysql/MySql.Data.dll
    $SQLConnection = New-Object MySql.Data.MySqlClient.MySqlConnection "Server=localhost;uid=pode;pwd=')9ij{pok';"
    $SQLConnection.open()
    $SQLCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
    $SQLCommand.connection = $SQLConnection
    $SQLDataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter
    $SQLDataAdapter.SelectCommand=$SQLCommand 

    $ip = ip -j a | ConvertFrom-Json | Where-Object ifname -eq eth0 | Select-Object -ExpandProperty addr_info | Select-Object -ExpandProperty local -First 1
    #Attach port 8000 to the local machine address and use HTTP protocol
    Add-PodeEndpoint -Address $ip -Port 8000 -Protocol HTTP

    #Get hierachy
    Add-PodeRoute -Method Get -Path '/hierarchy' -ScriptBlock {
        Write-Host "hierarchy"
    }

    # Set Parent 
    Add-PodeRoute -Method Post -Path '/parent' -ScriptBlock {
        Write-Host $WebEvent.Data.test
        try{

        $SQLDataSet = New-Object System.Data.DataSet
        $SQLDataAdapter =$using:SQLDataAdapter 
        $SQLDataAdapter.SelectCommand.CommandText = "SELECT * FROM Relation LIMIT 0";
        Write-Host $SQLDataAdapter.SelectCommand.CommandText
        $SQLDataAdapter.fill($SQLDataSet)
        $row = $SQLDataSet.Tables[0].NewRow()
        $row.user = $WebEvent.Data.test
        $row.parent = 0
        }catch{
            Write-Host $_.Exception.Message
        }
        Move-PodeResponseUrl -Url '/html'
    }

    # Set child
    Add-PodeRoute -Method Post -Path '/child' -ScriptBlock {
        Write-Host $WebEvent.Data.test
        Move-PodeResponseUrl -Url '/html'
    }

    # html file
    Add-PodeStaticRoute -Path '/html' -Source './html' -Defaults @('index.html')
}
 