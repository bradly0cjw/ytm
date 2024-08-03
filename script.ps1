$data = Get-Content -Path watch-history.json | ConvertFrom-Json

$urls = $data.titleUrl | Select-Object -Unique

[array]::Reverse($urls)

$urls | Out-File history.txt

$lines = Get-Content -Path "history.txt"
$defaultRepeatCount = $lines.Length
$defaultI = 0
$defaultRest = 300
$errorcounter = 0
$commandTemplate = "yt-dlp --mark-watched --simulate --cookies-from-browser firefox "

$repeatCount = [int](Read-Host "Enter the starting value for repeatCount (default: $defaultRepeatCount)")
if (-not $repeatCount) {
    $repeatCount = $defaultRepeatCount
}

$rest = [int](Read-Host "Enter the rest time in seconds (default: 300)")
if (-not $rest) {
    $rest = $defaultRest
}

$i = [int](Read-Host "Enter the starting from line (default: $defaultI)")
if (-not $i) {
    $i = $defaultI
}elseif ($i -lt 0) {
    $i = 0
}
function rest(){
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Out-File -FilePath shelllogs.txt -Append -InputObject "[$currentTime] Hit the request limit. Resting for $rest second(s)..."
    $dotCount = 0
    for ($second = $rest; $second -gt 0; $second--) {
        $hours = [math]::Floor($second / 3600)
        $minutes = [math]::Floor($second / 60)
        $seconds = $second % 60
        $dots = "." * $dotCount
        $space = " " * (7 - $dotCount)
        Write-Host -NoNewline "`rResting for $($hours.ToString().PadLeft(2, '0')):$($minutes.ToString().PadLeft(2, '0')):$($seconds.ToString().PadLeft(2, '0'))$dots$space" -ForegroundColor Magenta
        Start-Sleep -Seconds 1
        $dotCount = ($dotCount + 1) % 7
    }
    Write-Host ""  # To move to the next line after the countdown
}

try {
    while ($i -lt ($repeatCount+1)) {
        #logging
        $commandString = $commandTemplate +$lines[$i]
        $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "Command: $commandString" -ForegroundColor Cyan
        Out-File -FilePath shelllogs.txt -Append -InputObject "[$currentTime] Start  $commandString"
        
        $chunk="Now processing ($i/$repeatCount)"
        Out-File -FilePath ytdlplogs.txt -Append -InputObject "[$currentTime] $chunk"

        Invoke-Expression "$commandString 2>&1 | Tee-Object -FilePath ytdlplogs.txt -Append"
        $logs = Get-Content -Path ytdlplogs.txt
        if ($logs[-3..-1] -match "hit the request limit"){
            rest
        }else{
            if ($logs[-3..-1] -match "ERROR:"){
                $errorcounter++        
            }
            $i++
            $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $percent = [math]::Round(($i / $repeatCount) * 100, 2)
            $errorrate = [math]::Round(($errorcounter / $i) * 100, 2)
            Write-Host "Finished $percent% ($i/$repeatCount) with error rate $errorrate% ($errorcounter/$i)" -ForegroundColor Green
            Out-File -FilePath shelllogs.txt -Append -InputObject "[$currentTime] Finish $commandString`nFinished $percent% ($i/$repeatCount) with error rate $errorrate% ($errorcounter/$i)"
        }
    }
} catch {
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorLog = "[$currentTime] Script interrupted: $_"
    Write-Host $errorLog -ForegroundColor Red
    Out-File -FilePath shelllogs.txt -Append -InputObject $errorLog
} finally {
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $terminationLog = "[$currentTime] Script terminated."
    Write-Host $terminationLog -ForegroundColor Yellow
    Out-File -FilePath shelllogs.txt -Append -InputObject $terminationLog
}
