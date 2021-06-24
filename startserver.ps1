Import-Module Pode
Start-PodeServer {
    add-type -path mysql/MySql.Data.dll
    $config = Import-PowerShellDataFile -Path $configFile
    $SQLConnection = New-Object MySql.Data.MySqlClient.MySqlConnection $config.Connection
    $SQLConnection.open()
    $SQLCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
    $SQLCommand.connection = $SQLConnection
    $SQLDataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter
    $SQLDataAdapter.SelectCommand=$SQLCommand 

    $SQLDataAdapter.SelectCommand.CommandText = "USE heirarchy;";
    $SQLDataAdapter.SelectCommand.ExecuteNonQuery();

    $ip = ip -j a | ConvertFrom-Json | Where-Object ifname -eq eth0 | Select-Object -ExpandProperty addr_info | Select-Object -ExpandProperty local -First 1
    #Attach port 8000 to the local machine address and use HTTP protocol
    Add-PodeEndpoint -Address $ip -Port 8000 -Protocol HTTP

    #Get hierachy
    Add-PodeRoute -Method Get -Path '/hierarchy' -ScriptBlock {
        Write-Host "hierarchy"
    }

    # Set AddChild 
    Add-PodeRoute -Method Post -Path '/AddChild' -ScriptBlock {
        Write-Host $WebEvent.Data.test
        try{

        $SQLDataSet = New-Object System.Data.DataSet
        $SQLDataAdapter =$using:SQLDataAdapter 
        $SQLDataAdapter.SelectCommand.CommandText = "SELECT * FROM Relation LIMIT 0";
        Write-Host $SQLDataAdapter.SelectCommand.CommandText
        $SQLDataAdapter.fill($SQLDataSet)
        $row = $SQLDataSet.Tables[0].NewRow()
        $row.label = $WebEvent.Data.label
        $row.parent = $WebEvent.Data.parent
        }catch{
            Write-Host $_.Exception.Message
        }
        Move-PodeResponseUrl -Url '/html'
    }

    # Set child
    Add-PodeRoute -Method Post -Path '/UpdateLabel' -ScriptBlock {
        Write-Host $WebEvent.Data.key
        Write-Host $WebEvent.Data.label
        Move-PodeResponseUrl -Url '/html'
    }

    # html file
    Add-PodeStaticRoute -Path '/html' -Source './html' -Defaults @('index.html')
}
 