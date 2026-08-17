@{
    SystemPackages = @(
        @{ Id = 'Git.Git'; Command = 'git' },
        @{ Id = 'GitHub.cli'; Command = 'gh' },
        @{ Id = 'Microsoft.PowerShell'; Command = 'pwsh' },
        @{ Id = 'Python.Python.3.13'; Command = 'python' },
        @{ Id = 'astral-sh.uv'; Command = 'uv' },
        @{ Id = 'GoLang.Go'; Command = 'go' },
        @{ Id = 'jqlang.jq'; Command = 'jq' },
        @{ Id = 'MikeFarah.yq'; Command = 'yq' },
        @{ Id = 'BurntSushi.ripgrep.MSVC'; Command = 'rg' },
        @{ Id = 'Starship.Starship'; Command = 'starship' }
    )
}
