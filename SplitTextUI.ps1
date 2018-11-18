param(
    [Parameter(Mandatory)]
    $targetFile
)

Import-Module $PSSCriptRoot\PSProse.psm1 -Force

Add-Type -AssemblyName presentationframework

$XAML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStartupLocation="CenterScreen"
        Title="Split Text Buddy" Height="850" Width="850">

    <Grid>

        <Grid.ColumnDefinitions>
            <ColumnDefinition/>
            <ColumnDefinition/>
        </Grid.ColumnDefinitions>

        <Grid.RowDefinitions>
            <RowDefinition Height="42"/>
            <RowDefinition/>
            <RowDefinition/>
            <RowDefinition/>
            <RowDefinition Height="250"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Grid.Column="0" Grid.Row="0" Grid.ColumnSpan="2" Margin="3">
            <Button x:Name="btnSelectFile" Content=" Select File " Margin="3" Width="Auto" HorizontalAlignment="Left"/>
            <Button x:Name="btnCopyPowerShell" Content=" Copy PowerShell To Clipboard" Margin="3" Width="Auto" HorizontalAlignment="Left"/>
        </StackPanel>

        <GroupBox Header=" File Contents " Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Margin="3">
            <TextBox x:Name="tbFileContents" Margin="3"
                FontFamily="Consolas"
                FontSize="14"
                AcceptsReturn="True"
                AcceptsTab="True"
                VerticalScrollBarVisibility="Visible"
                HorizontalScrollBarVisibility="Visible"/>
        </GroupBox>

        <GroupBox Header=" Examples " Grid.Row="2" Grid.Column="0" Margin="3">
            <TextBox x:Name="tbExamples" Margin="3"
                FontFamily="Consolas"
                FontSize="14"
                AcceptsReturn="True"
                VerticalScrollBarVisibility="Visible"
                HorizontalScrollBarVisibility="Visible"/>
        </GroupBox>

        <GroupBox Header=" Headers " Grid.Row="2" Grid.Column="1" Margin="3">
            <TextBox x:Name="tbHeaders" Margin="3"
                FontFamily="Consolas"
                FontSize="14"
                AcceptsReturn="True"
                VerticalScrollBarVisibility="Visible"
                HorizontalScrollBarVisibility="Visible"/>
        </GroupBox>

        <GroupBox Header=" Parsed Results " Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="2" Margin="3">
            <TextBox x:Name="tbParsedResults" Margin="3"
                IsReadOnly="True"
                FontFamily="Consolas"
                FontSize="14"
                VerticalScrollBarVisibility="Visible"
                HorizontalScrollBarVisibility="Visible"/>
        </GroupBox>

        <GroupBox Header=" PowerShell " Grid.Row="4" Grid.Column="0" Grid.ColumnSpan="2" Margin="3">
            <TextBox x:Name="tbPowerShell" Margin="3"
                IsReadOnly="True"
                FontFamily="Consolas"
                FontSize="14"
                VerticalScrollBarVisibility="Visible"
                HorizontalScrollBarVisibility="Visible"/>
        </GroupBox>

    </Grid>
</Window>
'@

function DoParse {

    $headers = @()
    $constraints = @(($tbExamples.Text -split "`r`n").trim())

    foreach ($record in $tbHeaders.Text -split "`r`n") {
        $headers += $record
    }

    try {
        $params = @{
            File                      = $targetFile
            Constraints               = $constraints
            Header                    = $headers
            IncludeDelimitersInOutput = $false
        }

        $tbParsedResults.Text = Invoke-SplitText @params | Format-Table | Out-String

        $tbPowerShell.Text = @"
`$constraints = $("'{0}'" -f ($constraints -join ", '"))

`$params = @{
    File = "$(Resolve-Path $targetFile)"
    Constraints = `$constraints
    Header = $("'{0}'" -f $($headers -join ", '"))
}

Invoke-SplitText @params
"@
    }
    catch {

    }
}

$Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$XAML)))

$Window.Title = "Split Text Buddy - [$targetFile]"

$btnCopyPowerShell = $Window.FindName("btnCopyPowerShell")
$tbFileContents = $Window.FindName("tbFileContents")
$tbExamples = $Window.FindName("tbExamples")
$tbHeaders = $Window.FindName("tbHeaders")
$tbParsedResults = $Window.FindName("tbParsedResults")
$tbPowerShell = $Window.FindName("tbPowerShell")

$tbFileContents.Add_TextChanged( { DoParse } )
$tbExamples.Add_TextChanged( { DoParse })
$tbHeaders.Add_TextChanged( { DoParse })

$tbFileContents.Text = Get-Content -raw $targetFile
$btnCopyPowerShell.Add_Click( {
        $tbPowerShell.Text | Clip

        [System.Windows.MessageBox]::Show("Done", "Copy to Clipboard")
    })

$null = $tbExamples.Focus()
[void]$Window.ShowDialog()