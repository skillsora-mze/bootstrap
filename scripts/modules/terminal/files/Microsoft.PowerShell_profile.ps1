# Workstation Bootstrap training aliases
$managedBin = Join-Path $HOME '.workstation-bootstrap\bin'
$rdBin = Join-Path $HOME '.rd\bin'
$priorityPaths = @($managedBin, $rdBin) | Where-Object { Test-Path -LiteralPath $_ -PathType Container }
$pathEntries = @($env:Path -split ';' | Where-Object { $_ -and $priorityPaths -notcontains $_ })
if ($priorityPaths.Count -gt 0) {
    $env:Path = (@($priorityPaths) + $pathEntries) -join ';'
}

Set-Alias k kubectl
function kgp { kubectl get pods @args }
function kgs { kubectl get services @args }
function kgn { kubectl get nodes @args }
function tf { terraform @args }
function dps { docker ps @args }
function dc { docker compose @args }
