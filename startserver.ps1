[CmdletBinding()]
param (
    $Port=8086,
    $server=$env:PWSH_DATABASE_SERVER,
    $name=$env:PWSH_DATABASE_NAME,
    $pass=$env:PWSH_DATABASE_PASS,
    [switch]$RemoveConfig,
    [switch]$RemoveDatabase
)

Import-Module Pode.Kestrel
Start-PodeServer {

    . mysql/initDatabase.ps1 -server $using:server -name $using:name -pass $using:pass -RemoveConfig:$using:RemoveConfig -RemoveDatabase:$using:RemoveDatabase
    <#
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
    #>

    $ip = ip -j a | ConvertFrom-Json | Where-Object ifname -eq eth0 | Select-Object -ExpandProperty addr_info | Select-Object -ExpandProperty local -First 1
    #Attach port 8086 to the local machine address and use HTTP protocol
    Add-PodeEndpoint -Address $ip -Port $using:Port -Protocol HTTP

    #Get hierachy
    Add-PodeRoute -Method Get -Path '/hierarchy' -ScriptBlock {
        Write-Host "hierarchy"
        try{
            $SQLDataSet = New-Object System.Data.DataSet
            $SQLDataAdapter = $using:SQLDataAdapter 
            $SQLDataAdapter.SelectCommand.CommandText = "SELECT * FROM Relation";
            $SQLDataAdapter.fill($SQLDataSet)
            # Write-PodeHtmlResponse -value (($SQLDataSet.Tables[0] | Select id, label, parent | ConvertTo-Html) -join "`n")
            Write-PodeTextResponse -value (($SQLDataSet.Tables[0] | Select id, label, parent | ConvertTo-Html) -join "`n") -ContentType "Text/html"
        }catch{
            Write-Host $_.Exception.Message
        }
    }

    # Set AddChild 
    Add-PodeRoute -Method Post -Path '/AddChild' -ScriptBlock {
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
        try{
            $SQLDataSet = New-Object System.Data.DataSet
            $SQLDataAdapter =$using:SQLDataAdapter 
            $SQLDataAdapter.SelectCommand.CommandText = "SELECT * FROM Relation LIMIT 0";
            $SQLDataAdapter.fill($SQLDataSet)
            $row = $SQLDataSet.Tables[0].NewRow()
            $row.id = $WebEvent.Data.key
            $row.label = $WebEvent.Data.label
            $SQLDataSet.Tables[0].Rows.Add($row)
            $CommandBuilder = New-Object MySql.Data.MySqlClient.MySqlCommandBuilder $SQLDataAdapter
            $SQLDataAdapter.UpdateCommand = $CommandBuilder.GetUpdateCommand()
            $execute_count = $SQLDataAdapter.Update($SQLDataSet)
            Write-Host "set " + $row.id + " to " + $row.label
        }catch{
            Write-Host $_.Exception.Message
        }
        Move-PodeResponseUrl -Url '/html'
    }

    # Set Label
    Add-PodeRoute -Method Post -Path '/UpdateParent' -ScriptBlock {
        try{
            $SQLDataSet = New-Object System.Data.DataSet
            $SQLDataAdapter =$using:SQLDataAdapter 
            $SQLDataAdapter.SelectCommand.CommandText = "SELECT * FROM Relation LIMIT 0";
            $SQLDataAdapter.fill($SQLDataSet)
            $row = $SQLDataSet.Tables[0].NewRow()
            $row.id = $WebEvent.Data.key
            $row.parent = $WebEvent.Data.parent
            $SQLDataSet.Tables[0].Rows.Add($row)
            $CommandBuilder = New-Object MySql.Data.MySqlClient.MySqlCommandBuilder $SQLDataAdapter
            $SQLDataAdapter.UpdateCommand = $CommandBuilder.GetUpdateCommand()
            $execute_count = $SQLDataAdapter.Update($SQLDataSet)
            Write-Host "set " + $row.id + " to " + $row.parent
        }catch{
            Write-Host $_.Exception.Message
        }
        Move-PodeResponseUrl -Url '/html'
    }

    # html file
    Add-PodeStaticRoute -Path '/html' -Source './html' -Defaults @('index.html')
}
 