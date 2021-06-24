Import-Module Pode
Start-PodeServer {
    add-type -path mysql/MySql.Data.dll
    $config = Import-PowerShellDataFile -Path startserver.psd1
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
        try{
            $SQLDataSet = New-Object System.Data.DataSet
            $SQLDataAdapter = $using:SQLDataAdapter 
            $SQLDataAdapter.SelectCommand.CommandText = "SELECT * FROM Relation";
            $SQLDataAdapter.fill($SQLDataSet)
            Write-PodeHtmlResponse ($SQLDataSet.Tables[0] | Select id, label, parent | ConvertTo-Html)
        }catch{
            Write-Host $_.Exception.Message
        }
    }

    # Set AddChild 
    Add-PodeRoute -Method Post -Path '/AddChild' -ScriptBlock {
        Write-Host $WebEvent.Data.test
        try{
            $SQLDataSet = New-Object System.Data.DataSet
            $SQLDataAdapter =$using:SQLDataAdapter 
            $SQLDataAdapter.SelectCommand.CommandText = "SELECT * FROM Relation LIMIT 0";
            $SQLDataAdapter.fill($SQLDataSet)
            $row = $SQLDataSet.Tables[0].NewRow()
            $row.label = $WebEvent.Data.label
            $row.parent = $WebEvent.Data.parent
            $SQLDataSet.Tables[0].Rows.Add($row)
            $CommandBuilder = New-Object MySql.Data.MySqlClient.MySqlCommandBuilder $SQLDataAdapter
            $SQLDataAdapter.InsertCommand = $CommandBuilder.GetInsertCommand()
            $execute_count = $SQLDataAdapter.Update($SQLDataSet)
            Write-Host "add " + $row.label + " related to " + $row.parent
        }catch{
            Write-Host $_.Exception.Message
        }
        Move-PodeResponseUrl -Url '/html'
    }

    # Set Label
    Add-PodeRoute -Method Post -Path '/UpdateLabel' -ScriptBlock {
        Write-Host $WebEvent.Data.key
        Write-Host $WebEvent.Data.label
        Move-PodeResponseUrl -Url '/html'
    }

    # Set Label
    Add-PodeRoute -Method Post -Path '/UpdateParent' -ScriptBlock {
        Write-Host $WebEvent.Data.key
        Write-Host $WebEvent.Data.label
        Move-PodeResponseUrl -Url '/html'
    }

    # html file
    Add-PodeStaticRoute -Path '/html' -Source './html' -Defaults @('index.html')
}
 