# Path to save CSV in
$reportPath = "FILE PATH"
# Add CSV Headers
Add-Content -Path $reportPath -Value "SubscriptionName,ResourceGroupName,SQL_Server,DB_Name,Average_DTU,Max_DTU"
function UpdateCSV($item) {
    Add-Content -Path $reportPath -Value "$($item.subscription_name),$($item.rg_name),$($item.SQL_Server),$($item.db_name),$($item.average_dtu),$($item.max_dtu)"
}


$subs = @()

# get current date so that we can use it as the "End Date"
$et = Get-date
# Minus 7 days from current day to set start date a week ago
$st = $et.AddDays(-30)

foreach ($sub in $subs) {
    set-azcontext -subscription $sub
    $sqlServers = Get-AzSqlserver
    foreach ($server in $sqlServers) {
        $dbs = Get-AzSqlDatabase -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName
        foreach ($db in $dbs) {
            $id = $db.ResourceId
            # Pull CPU data over the last week
            $metricaverage = Get-AzMetric -ResourceId $id -MetricName "dtu_consumption_percent" -AggregationType Average -StartTime $st -EndTime $et -TimeGrain 12:00:00 
            # Add all CPU data to a list
            $metricavgs = $metricaverage.data.average
            # Do some math to calculate the Average CPU over the week from the above list
            $metricaveragetotal = ($metricavgs | Measure-Object -Average)
            # Pull CPU data over the last week
            $metricmax = Get-AzMetric -ResourceId $id -MetricName "dtu_consumption_percent" -AggregationType Maximum -StartTime $st -EndTime $et -TimeGrain 12:00:00
            # Add all CPU data to a list
            $metricmaxs = $metricmax.data.Maximum
            # Do some math to calculate the Max CPU over the week from the above list
            $metricmaxtotal = ($metricmaxs | Measure-Object -Maximum)
            # Update the CSV with details
            UpdateCSV -item @{
                "subscription_name" = $sub
                "rg_name"           = $db.ResourceGroup
                "SQL_Server"        = $server.ServerName
                "db_name"           = $db.DatabaseName
                "average_dtu"       = $metricaveragetotal.Average
                "max_dtu"           = $metricmaxtotal.maximum
            }
        }
    }
}
