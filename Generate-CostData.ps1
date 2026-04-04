# ============================================================
# Generate Azure Cost Data - JSON for Dashboard
# ============================================================

$tenantId = $env:TENANT_ID
$clientId = $env:AZURE_CLIENT_ID
$clientSecret = $env:AZURE_CLIENT_SECRET

# Auth
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://management.azure.com/.default"
}
$token = (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Body $tokenBody).access_token
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

$subscriptions = @(
    @{ Name = "sub-idf-01"; Id = $env:SUB_IDF_01 },
    @{ Name = "sub-lille-01"; Id = $env:SUB_LILLE_01 },
    @{ Name = "sub-lyon-01"; Id = $env:SUB_LYON_01 },
    @{ Name = "sub-marseille-01"; Id = $env:SUB_MARSEILLE_01 },
    @{ Name = "sub-nantes-01"; Id = $env:SUB_NANTES_01 },
    @{ Name = "sub-temp-01"; Id = $env:SUB_TEMP_01 }
)

$today = Get-Date
$mtdStart = (Get-Date -Day 1).ToString("yyyy-MM-dd")
$mtdEnd = $today.ToString("yyyy-MM-dd")
$prevMonthStart = (Get-Date -Day 1).AddMonths(-1).ToString("yyyy-MM-dd")
$prevMonthEnd = (Get-Date -Day 1).AddDays(-1).ToString("yyyy-MM-dd")

function Get-CostForSub($subId, $startDate, $endDate, $groupByRG = $false) {
    $uri = "https://management.azure.com/subscriptions/$subId/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
    
    $dataset = @{
        granularity = "None"
        aggregation = @{ totalCost = @{ name = "PreTaxCost"; function = "Sum" } }
    }
    
    if ($groupByRG) {
        $dataset.grouping = @(@{ type = "Dimension"; name = "ResourceGroupName" })
    }
    
    $body = @{
        type       = "Usage"
        timeframe  = "Custom"
        timePeriod = @{ from = $startDate; to = $endDate }
        dataset    = $dataset
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
        return $response.properties
    }
    catch {
        Write-Warning "Erreur sur sub $subId : $($_.Exception.Message)"
        return $null
    }
}

$subsCosts = @()
$allRGs = @()
$totalMTD = 0
$totalPrev = 0

foreach ($sub in $subscriptions) {
    Write-Output "📊 $($sub.Name)..."
    
    $mtd = Get-CostForSub -subId $sub.Id -startDate $mtdStart -endDate $mtdEnd
    $mtdCost = if ($mtd -and $mtd.rows.Count -gt 0) { [math]::Round($mtd.rows[0][0], 2) } else { 0 }
    
    $prev = Get-CostForSub -subId $sub.Id -startDate $prevMonthStart -endDate $prevMonthEnd
    $prevCost = if ($prev -and $prev.rows.Count -gt 0) { [math]::Round($prev.rows[0][0], 2) } else { 0 }
    
    $totalMTD += $mtdCost
    $totalPrev += $prevCost
    
    $subsCosts += @{ name = $sub.Name; mtd = $mtdCost; previous = $prevCost }
    
    $rgs = Get-CostForSub -subId $sub.Id -startDate $mtdStart -endDate $mtdEnd -groupByRG $true
    if ($rgs -and $rgs.rows.Count -gt 0) {
        foreach ($row in $rgs.rows) {
            if ($row[0] -gt 0) {
                $allRGs += @{
                    subscription = $sub.Name
                    name         = if ($row[1]) { $row[1] } else { "Unknown" }
                    cost         = [math]::Round($row[0], 2)
                }
            }
        }
    }
}

$topRGs = $allRGs | Sort-Object { $_.cost } -Descending | Select-Object -First 10
$delta = if ($totalPrev -gt 0) { [math]::Round((($totalMTD - $totalPrev) / $totalPrev) * 100, 1) } else { 0 }

$output = @{
    lastUpdated   = $today.ToString("yyyy-MM-dd HH:mm")
    totalMTD      = [math]::Round($totalMTD, 2)
    totalPrevious = [math]::Round($totalPrev, 2)
    delta         = $delta
    subscriptions = $subsCosts
    topRGs        = $topRGs
}

$output | ConvertTo-Json -Depth 10 | Out-File -FilePath "data/costs.json" -Encoding UTF8
Write-Output "✅ data/costs.json generated"