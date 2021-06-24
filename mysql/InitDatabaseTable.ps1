[cmdletbinding()]
param(
    $server,
    $name,
    $pass,
    [switch]$RemoveConfig,
    [switch]$RemoveDatabase
)
# Find root folder
$TopLevel = Get-ChildItem -Filter startserver.ps1 -Path .. -Recurse | Select-Object -ExpandProperty DirectoryName
write-Verbose "Top Level Folder : $TopLevel"
#Delete config file

$configFile = Join-Path  -Path $TopLevel -ChildPath startserver.psd1
# Remove previous config
if($RemoveConfig){
    Remove-Item $configFile -Verbose
}


if(![string]::IsNullOrWhiteSpace($pass)){
    Write-Verbose "A Password was indicated"
}

# If config is not created 
Get-ChildItem -Path $configFile 2> $null || & { '@{ Connection = "Server=' + "'" + $server + "'" +';uid=' + "'" + $name + "'" +';pwd=' + "'" + $pass + "'" +'"}' | Out-File -Path $configFile -Verbose }
Write-Verbose "Configfile : $configFile"
# "startserver.psd1" >> .gitignore
$config = Import-PowerShellDataFile -Path $configFile
add-type -path mysql/MySql.Data.dll

$SQLConnection = New-Object MySql.Data.MySqlClient.MySqlConnection $config.Connection
$SQLConnection.open()
Write-Verbose "Database Found"
$SQLCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$SQLCommand.connection = $SQLConnection
$SQLDataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter
$SQLDataAdapter.SelectCommand=$SQLCommand 

# Remove previous Database
if($RemoveDatabase){
    Write-Verbose "Remove Previous Database"
    $SQLDataAdapter.SelectCommand.CommandText = "DROP DATABASE IF EXISTS heirarchy;";
    $SQLDataAdapter.SelectCommand.ExecuteNonQuery();
}

Write-Verbose "Create Database"
$SQLDataAdapter.SelectCommand.CommandText = "CREATE DATABASE IF NOT EXISTS heirarchy;";
$SQLDataAdapter.SelectCommand.ExecuteNonQuery();

$SQLDataAdapter.SelectCommand.CommandText = "USE heirarchy;";
$SQLDataAdapter.SelectCommand.ExecuteNonQuery();

Write-Verbose "Create Table"
$SQLDataAdapter.SelectCommand.CommandText = "
CREATE TABLE IF NOT EXISTS Relation (
    id INT PRIMARY KEY AUTO_INCREMENT,
    label VARCHAR(50),
    parent INT
);"
$SQLDataAdapter.SelectCommand.ExecuteNonQuery();

Write-Verbose "Display Table form Database"
$SQLDataSet = New-Object System.Data.DataSet
$SQLDataAdapter.SelectCommand.CommandText = "SHOW TABLES;";
$SQLDataAdapter.fill($SQLDataSet)
$SQLDataSet.TABLES