# Workstation Bootstrap training aliases
$managedBin = Join-Path $HOME '.workstation-bootstrap\bin'
if (Test-Path -LiteralPath $managedBin -PathType Container) {
    $pathEntries = @($env:Path -split ';' | Where-Object { $_ -and $_ -ne $managedBin })
    $env:Path = (@($managedBin) + $pathEntries) -join ';'
}

Set-Alias k kubectl
function kgp { kubectl get pods @args }
function kgs { kubectl get services @args }
function kgn { kubectl get nodes @args }
function tf { terraform @args }
function dps { docker ps @args }
function dc { docker compose @args }
