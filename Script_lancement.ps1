# V0.1
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Utilisateurs valides
$script:validUsers = @{
    "admin" = "Password123"
    "stmichel" = "Annecy"
}

function Show-LoginWPF {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Connexion" Height="250" Width="400" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#f0f4f8">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <TextBlock Text="Authentification requise" FontSize="18" FontWeight="Bold" Margin="0,0,0,20" Grid.Row="0" HorizontalAlignment="Center"/>
        <StackPanel Grid.Row="1" Orientation="Vertical" Margin="0,0,0,10">
            <Label Content="Identifiant :"/>
            <TextBox Name="UserBox" Width="250"/>
            <Label Content="Mot de passe :" Margin="0,10,0,0"/>
            <PasswordBox Name="PassBox" Width="250"/>
        </StackPanel>
        <TextBlock Name="ErrorMsg" Foreground="Red" FontWeight="Bold" Grid.Row="2" Height="25"/>
        <Button Name="LoginBtn" Content="Connexion" Width="120" Height="35" Grid.Row="3" HorizontalAlignment="Center" Background="#2a72d4" Foreground="White" FontWeight="Bold"/>
    </Grid>
</Window>
"@
    $window = [Windows.Markup.XamlReader]::Parse($xaml)
    $userBox = $window.FindName("UserBox")
    $passBox = $window.FindName("PassBox")
    $loginBtn = $window.FindName("LoginBtn")
    $errorMsg = $window.FindName("ErrorMsg")
    $authenticated = [ref]$false

    $loginBtn.Add_Click({
        $u = $userBox.Text
        $p = $passBox.Password
        if ($script:validUsers.ContainsKey($u) -and $p -eq $script:validUsers[$u]) {
            $authenticated.Value = $true
            $window.Close()
        } else {
            $errorMsg.Text = "Identifiants incorrects."
        }
    })
    $window.ShowDialog() | Out-Null
    return $authenticated.Value
}

function Show-ChoiceWPF {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Sélection des scripts" Height="250" Width="400" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#f0f4f8">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Text="Choisissez les analyses à effectuer :" FontSize="16" FontWeight="Bold" Margin="0,0,0,10" Grid.Row="0" HorizontalAlignment="Center"/>
        <StackPanel Grid.Row="1" Orientation="Vertical" HorizontalAlignment="Center">
            <CheckBox Name="NmapBox" Content="Scan Nmap (découverte, ports, vulnérabilités)" FontSize="14" Margin="0,5"/>
            <CheckBox Name="PingBox" Content="Audit PingCastle (Active Directory)" FontSize="14" Margin="0,5"/>
        </StackPanel>
        <Button Name="RunBtn" Content="Lancer les analyses" Width="160" Height="35" Grid.Row="2" HorizontalAlignment="Center" Background="#2a72d4" Foreground="White" FontWeight="Bold"/>
    </Grid>
</Window>
"@
    $window = [Windows.Markup.XamlReader]::Parse($xaml)
    $nmapBox = $window.FindName("NmapBox")
    $pingBox = $window.FindName("PingBox")
    $runBtn = $window.FindName("RunBtn")
    $selected = @()
    $runBtn.Add_Click({
        if (-not $nmapBox.IsChecked -and -not $pingBox.IsChecked) {
            [System.Windows.MessageBox]::Show("Veuillez sélectionner au moins un outil.", "Erreur", 'OK', 'Error')
            return
        }
        if ($nmapBox.IsChecked) { $selected += "nmap" }
        if ($pingBox.IsChecked) { $selected += "pingcastle" }
        $window.Close()
    })
    $window.ShowDialog() | Out-Null
    return $selected
}

function Show-ProgressWPF {
    param($jobs)
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Exécution des analyses..." Height="150" Width="400" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#f0f4f8">
    <StackPanel Margin="20">
        <TextBlock Text="Veuillez patienter pendant l'exécution des scripts..." FontSize="14" Margin="0,0,0,10"/>
        <ProgressBar Name="ProgBar" Height="25" IsIndeterminate="True"/>
    </StackPanel>
</Window>
"@
    $window = [Windows.Markup.XamlReader]::Parse($xaml)
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({
        $allDone = $true
        foreach ($job in $jobs) {
            if ($job.State -eq 'Running') { $allDone = $false }
        }
        if ($allDone) {
            $timer.Stop()
            $window.Close()
        }
    })
    $timer.Start()
    $window.ShowDialog() | Out-Null
}

function Show-ResultWPF {
    param($results)
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Résultat des analyses" Height="220" Width="420" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#f0f4f8">
    <StackPanel Margin="20">
        <TextBlock Text="Analyses terminées !" FontSize="16" FontWeight="Bold" Margin="0,0,0,10"/>
        <TextBox Name="ResultBox" Height="80" FontFamily="Consolas" FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
        <Button Name="CloseBtn" Content="Fermer" Width="100" Height="30" HorizontalAlignment="Center" Background="#2a72d4" Foreground="White" FontWeight="Bold" Margin="0,10,0,0"/>
    </StackPanel>
</Window>
"@
    $window = [Windows.Markup.XamlReader]::Parse($xaml)
    $resultBox = $window.FindName("ResultBox")
    $resultBox.Text = ($results -join "`r`n")
    $window.FindName("CloseBtn").Add_Click({ $window.Close() })
    $window.ShowDialog() | Out-Null
}

# === MAIN ===
if (-not (Show-LoginWPF)) {
    [System.Windows.MessageBox]::Show("Connexion échouée. Fin du script.", "Erreur", 'OK', 'Error')
    exit 1
}

$choices = Show-ChoiceWPF
if (-not $choices -or $choices.Count -eq 0) {
    [System.Windows.MessageBox]::Show("Aucun script sélectionné. Fin du script.", "Info", 'OK', 'Information')
    exit 0
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jobs = @()
$results = @()

if ($choices -contains "nmap") {
    $jobs += Start-Job -ScriptBlock {
        $path = Join-Path $using:scriptDir "Script_nmap.ps1"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path
    } -Name "Nmap"
}

if ($choices -contains "pingcastle") {
    $jobs += Start-Job -ScriptBlock {
        $path = Join-Path $using:scriptDir "Script_pingcastle.ps1"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path
    } -Name "PingCastle"
}

Show-ProgressWPF $jobs

foreach ($job in $jobs) {
    $job | Receive-Job -Wait -AutoRemoveJob | Out-Null
    if ($job.State -eq 'Completed') {
        $results += "[$($job.Name)] Terminé avec succès."
    } else {
        $results += "[$($job.Name)] Erreur ou interrompu."
    }
}

Show-ResultWPF $results
