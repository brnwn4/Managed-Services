<#

Author: Brandon Wong

Purpose: This script will print out the app service plan CPU averages and CPU max over the course of a Month for any/all given subscription

Last Updated: 4/26/2021 - Working and reporting correctly

#>

# Path to save CSV in
$reportPath = ".\asp_cpu_usage.csv"
# Add CSV Headers
Add-Content -Path $reportPath -Value "SubscriptionName,ResourceGroupName,ASP_Name,Average_CPU,Max CPU"
# Function for creating/updating CSV
function UpdateCSV($item) {
    Add-Content -Path $reportPath -Value "$($item.subscription_name),$($item.rg_name),$($item.asp_name),$($item.average_cpu),$($item.max_cpu)"
}

# List subs here
$subs = @(
    "Subcription Name Here"
)

# get current date so that we can use it as the "End Date"
$et = Get-date
# Minus 7 days from current day to set start date a week ago
$st = $et.AddDays(-30)

# Set Context and Collect all App Services in Subscription
foreach ($sub in $subs) {
    # Set Context to Sub
    set-azcontext -Subscription $sub
    # Add all ASPs to $asps
    $asps = get-azappserviceplan
    foreach ($asp in $asps) {
        $id = $asp.Id
        # Pull CPU data over the last week
        $metricaverage = Get-AzMetric -ResourceId $id -MetricName "CpuPercentage" -AggregationType Average -StartTime $st -EndTime $et -TimeGrain 12:00:00 
        # Add all CPU data to a list
        $metricavgs = $metricaverage.data.average
        # Do some math to calculate the Average CPU over the week from the above list
        $metricaveragetotal = ($metricavgs | Measure-Object -Average)
        # Pull CPU data over the last week
        $metricmax = Get-AzMetric -ResourceId $id -MetricName "CpuPercentage" -AggregationType Maximum -StartTime $st -EndTime $et -TimeGrain 12:00:00
        # Add all CPU data to a list
        $metricmaxs = $metricmax.data.Maximum
        # Do some math to calculate the Max CPU over the week from the above list
        $metricmaxtotal = ($metricmaxs | Measure-Object -Maximum)
        # Update the CSV with details
        UpdateCSV -item @{
            "subscription_name" = $sub
            "rg_name"           = $asp.ResourceGroup
            "asp_name"          = $asp.Name
            "average_cpu"       = $metricaveragetotal.Average
            "max_cpu"           = $metricmaxtotal.maximum
        }
    }
}
