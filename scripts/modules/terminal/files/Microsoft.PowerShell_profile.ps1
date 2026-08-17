# Workstation Bootstrap training aliases
Set-Alias k kubectl
function kgp { kubectl get pods @args }
function kgs { kubectl get services @args }
function kgn { kubectl get nodes @args }
function tf { terraform @args }
function dps { docker ps @args }
function dc { docker compose @args }
