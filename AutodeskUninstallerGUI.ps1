#Requires -Version 5.1
<#
.SYNOPSIS
    Autodesk Universal Uninstaller v5.5 - GUI Edition
.DESCRIPTION
    PowerShell WPF graphical interface for the Autodesk Complete Uninstaller.
    Provides a modern dark-themed UI to manage all uninstallation operations.
.NOTES
    Run via LaunchGUI.bat for automatic admin elevation.
#>

# ============================================================
# ADMIN CHECK & SELF-ELEVATION
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ============================================================
# WPF ASSEMBLIES
# ============================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================
# GLOBAL VARIABLES
# ============================================================
$script:BatPath = Join-Path $PSScriptRoot "autodesk_complete_uninstaller.bat"
$script:LogDir = Join-Path ([Environment]::GetFolderPath('Desktop')) "Autodesk_Uninstaller"
$script:IsRunning = $false
$script:CurrentProcess = $null
$script:CurrentChildProcessId = $null
$script:CurrentJob = $null
$script:ScannedProducts = @()

# ============================================================
# XAML DEFINITION
# ============================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Autodesk &#x5B8C;&#x5168;&#x5378;&#x8F7D;&#x5DE5;&#x5177; v5.11"
        Width="1100" Height="720"
        MinWidth="900" MinHeight="600"
        WindowStartupLocation="CenterScreen"
        Background="#000000"
        FontFamily="Segoe UI, Open Sans"
        ResizeMode="CanResizeWithGrip">

    <Window.Resources>
        <!-- Ghost Button (secondary CTA on dark backgrounds) -->
        <Style x:Key="GhostButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#80FFFFFF"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1EAEDB"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="#1EAEDB"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1585A8"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="#1585A8"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#555555"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="#313131"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Sidebar Button -->
        <Style x:Key="SidebarButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#C0C0C0"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,12"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                Margin="4,2" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#202020"/>
                                <Setter Property="Foreground" Value="#FFC000"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#181818"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#555555"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Danger Sidebar Button -->
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource SidebarButton}">
            <Setter Property="Foreground" Value="#FF6B7A"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                Margin="4,2" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#331A1F"/>
                                <Setter Property="Foreground" Value="#FF4757"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#4D2530"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#555555"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Warning Sidebar Button -->
        <Style x:Key="WarningButton" TargetType="Button" BasedOn="{StaticResource SidebarButton}">
            <Setter Property="Foreground" Value="#FFAD57"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                Margin="4,2" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#3D2F1F"/>
                                <Setter Property="Foreground" Value="#FFA502"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#4D3925"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#555555"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Gold CTA Button (primary action) -->
        <Style x:Key="ActionButton" TargetType="Button">
            <Setter Property="Background" Value="#FFC000"/>
            <Setter Property="Foreground" Value="#000000"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="24,10"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#917300"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#6B5600"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="#313131"/>
                                <Setter Property="Foreground" Value="#7D7D7D"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Danger Action Button -->
        <Style x:Key="DangerActionButton" TargetType="Button" BasedOn="{StaticResource ActionButton}">
            <Setter Property="Background" Value="#FF4757"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#CC2535"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#A01A28"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="#313131"/>
                                <Setter Property="Foreground" Value="#7D7D7D"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ScrollBar Style -->
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="8"/>
            <Setter Property="Background" Value="Transparent"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="260"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- LEFT SIDEBAR -->
        <Border Grid.Column="0" Grid.RowSpan="2" Background="#181818">
            <DockPanel>
                <!-- Header -->
                <StackPanel DockPanel.Dock="Top" Margin="16,20,16,10">
                    <TextBlock Text="AUTODESK" FontSize="11" FontWeight="Bold" Foreground="#FFC000"
                               Margin="0,0,0,2"/>
                    <TextBlock Text="&#x5B8C;&#x5168;&#x5378;&#x8F7D;&#x5DE5;&#x5177;" FontSize="17" FontWeight="SemiBold" Foreground="White" Margin="0,0,0,2"/>
                    <TextBlock Text="v5.11 | 2015-2026+ | WIN10/11" FontSize="10" Foreground="#7D7D7D"/>
                    <Border Height="1" Background="#202020" Margin="0,12,0,4"/>
                </StackPanel>

                <!-- Bottom info -->
                <StackPanel DockPanel.Dock="Bottom" Margin="16,4,16,16">
                    <Border Height="1" Background="#202020" Margin="0,4,0,12"/>
                    <Button x:Name="btnOpenLog" Style="{StaticResource SidebarButton}" Padding="8,6" FontSize="11">
                        <TextBlock><Run Foreground="#7D7D7D" Text="&#x1F4C2; "/><Run Text="&#x6253;&#x5F00;&#x65E5;&#x5FD7;&#x6587;&#x4EF6;&#x5939;"/></TextBlock>
                    </Button>
                    <TextBlock Text="&#x65E5;&#x5FD7;: &#x684C;&#x9762;\Autodesk_Uninstaller" FontSize="9" Foreground="#555555"
                               Margin="12,4,0,0" TextWrapping="Wrap"/>
                </StackPanel>

                <!-- Menu Buttons -->
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,4,0,0">
                    <StackPanel>
                        <TextBlock Text="&#x64CD;&#x4F5C;" FontSize="10" FontWeight="Bold" Foreground="#7D7D7D"
                                   Margin="20,8,0,6"/>

                        <Button x:Name="btnScan" Style="{StaticResource SidebarButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F50D; "/><Run Text="&#x626B;&#x63CF;&#x5DF2;&#x5B89;&#x88C5;&#x8F6F;&#x4EF6;"/></TextBlock>
                        </Button>

                        <Button x:Name="btnUninstallSel" Style="{StaticResource SidebarButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F4E6; "/><Run Text="&#x5378;&#x8F7D;&#x9009;&#x4E2D;&#x4EA7;&#x54C1;"/></TextBlock>
                        </Button>

                        <Border Height="1" Background="#202020" Margin="16,6"/>

                        <TextBlock Text="&#x6E05;&#x7406;" FontSize="10" FontWeight="Bold" Foreground="#7D7D7D"
                                   Margin="20,4,0,6"/>

                        <Button x:Name="btnFullClean" Style="{StaticResource DangerButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F525; "/><Run Text="&#x5B8C;&#x5168;&#x5378;&#x8F7D; + &#x6DF1;&#x5EA6;&#x6E05;&#x7406;"/></TextBlock>
                        </Button>

                        <Button x:Name="btnDeepClean" Style="{StaticResource WarningButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F9F9; "/><Run Text="&#x4EC5;&#x6DF1;&#x5EA6;&#x6E05;&#x7406;"/></TextBlock>
                        </Button>

                        <Border Height="1" Background="#202020" Margin="16,6"/>

                        <TextBlock Text="&#x5DE5;&#x5177;" FontSize="10" FontWeight="Bold" Foreground="#7D7D7D"
                                   Margin="20,4,0,6"/>

                        <Button x:Name="btnVerify" Style="{StaticResource SidebarButton}">
                            <TextBlock><Run FontSize="15" Text="&#x2705; "/><Run Text="&#x6700;&#x7EC8;&#x9A8C;&#x8BC1;"/></TextBlock>
                        </Button>

                        <Button x:Name="btnRestore" Style="{StaticResource SidebarButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F4BE; "/><Run Text="&#x521B;&#x5EFA;&#x8FD8;&#x539F;&#x70B9;"/></TextBlock>
                        </Button>

                        <Button x:Name="btnRemnants" Style="{StaticResource SidebarButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F50E; "/><Run Text="&#x641C;&#x7D22;&#x6B8B;&#x7559;&#x6587;&#x4EF6;"/></TextBlock>
                        </Button>

                        <Button x:Name="btnAudit" Style="{StaticResource SidebarButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F4CB; "/><Run Text="&#x7CFB;&#x7EDF;&#x5B8C;&#x6574;&#x5BA1;&#x8BA1;"/></TextBlock>
                        </Button>

                        <Border Height="1" Background="#202020" Margin="16,6"/>

                        <TextBlock Text="&#x6545;&#x969C;&#x6392;&#x67E5;" FontSize="10" FontWeight="Bold" Foreground="#7D7D7D"
                                   Margin="20,4,0,6"/>

                        <Button x:Name="btnFixErr" Style="{StaticResource WarningButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F527; "/><Run Text="&#x4FEE;&#x590D; Error 103"/></TextBlock>
                        </Button>

                        <Button x:Name="btnFixReboot" Style="{StaticResource WarningButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F504; "/><Run Text="&#x4FEE;&#x590D;&#x91CD;&#x542F;&#x6302;&#x8D77;"/></TextBlock>
                        </Button>

                        <Button x:Name="btnBackup" Style="{StaticResource SidebarButton}">
                            <TextBlock><Run FontSize="15" Text="&#x1F4C1; "/><Run Text="&#x5907;&#x4EFD;&#x6A21;&#x677F;"/></TextBlock>
                        </Button>
                    </StackPanel>
                </ScrollViewer>
            </DockPanel>
        </Border>

        <!-- RIGHT CONTENT AREA -->
        <Grid Grid.Column="1" Margin="0">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Content Header -->
            <Border Grid.Row="0" Background="#202020" Padding="24,16">
                <DockPanel>
                    <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button x:Name="btnStop" Style="{StaticResource DangerActionButton}"
                                Content="&#x23F9; &#x505C;&#x6B62;" Padding="16,8" FontSize="12" Visibility="Collapsed"/>
                        <Button x:Name="btnClear" Style="{StaticResource GhostButton}"
                                Content="&#x6E05;&#x7A7A;&#x8F93;&#x51FA;" Margin="8,0,0,0"/>
                    </StackPanel>
                    <StackPanel>
                        <TextBlock x:Name="txtHeader" Text="&#x6B22;&#x8FCE;&#x4F7F;&#x7528;" FontSize="20" FontWeight="SemiBold" Foreground="White"/>
                        <TextBlock x:Name="txtSubHeader" Text="&#x8BF7;&#x4ECE;&#x5DE6;&#x4FA7;&#x83DC;&#x5355;&#x9009;&#x62E9;&#x4E00;&#x4E2A;&#x64CD;&#x4F5C;&#x5F00;&#x59CB;&#x3002;"
                                   FontSize="12" Foreground="#7D7D7D" Margin="0,4,0,0"/>
                    </StackPanel>
                </DockPanel>
            </Border>

            <!-- Content Body -->
            <Grid Grid.Row="1">
                <!-- Welcome Panel -->
                <Border x:Name="panelWelcome" Visibility="Visible" Padding="24,40">
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Text="&#x1F3E2;" FontSize="64" HorizontalAlignment="Center" Margin="0,0,0,16"/>
                        <TextBlock Text="AUTODESK &#x5B8C;&#x5168;&#x5378;&#x8F7D;&#x5DE5;&#x5177;" FontSize="22" FontWeight="SemiBold"
                                   Foreground="White" HorizontalAlignment="Center"/>
                        <TextBlock Text="&#x5F7B;&#x5E95;&#x6E05;&#x9664;&#x6240;&#x6709; AUTODESK &#x4EA7;&#x54C1;&#x53CA;&#x6B8B;&#x7559;" FontSize="13"
                                   Foreground="#7D7D7D" HorizontalAlignment="Center" Margin="0,8,0,24"/>

                        <Border Background="#202020" Padding="24,20" MaxWidth="500" Margin="0,0,0,16">
                            <StackPanel>
                                <TextBlock Text="&#x5FEB;&#x901F;&#x5165;&#x95E8;" FontSize="14" FontWeight="SemiBold"
                                           Foreground="#FFC000" Margin="0,0,0,12"/>
                                <TextBlock Foreground="#C0C0C0" FontSize="12" TextWrapping="Wrap" LineHeight="22">
                                    <Run FontWeight="SemiBold" Foreground="#FFC000">1.</Run>
                                    <Run> &#x70B9;&#x51FB;</Run><Run FontWeight="SemiBold" Foreground="White"> &#x626B;&#x63CF; </Run>
                                    <Run>&#x68C0;&#x6D4B;&#x5DF2;&#x5B89;&#x88C5;&#x7684; AUTODESK &#x8F6F;&#x4EF6;</Run>
                                    <LineBreak/>
                                    <Run FontWeight="SemiBold" Foreground="#FFC000">2.</Run>
                                    <Run> &#x9009;&#x62E9;</Run><Run FontWeight="SemiBold" Foreground="White"> &#x5378;&#x8F7D;&#x9009;&#x4E2D;&#x4EA7;&#x54C1; </Run>
                                    <Run>&#x6216;</Run><Run FontWeight="SemiBold" Foreground="#FF6B7A"> &#x5B8C;&#x5168;&#x5378;&#x8F7D;</Run>
                                    <LineBreak/>
                                    <Run FontWeight="SemiBold" Foreground="#FFC000">3.</Run>
                                    <Run> &#x8FD0;&#x884C;</Run><Run FontWeight="SemiBold" Foreground="White"> &#x6700;&#x7EC8;&#x9A8C;&#x8BC1; </Run>
                                    <Run>&#x786E;&#x8BA4;&#x6E05;&#x7406;&#x5B8C;&#x6210;</Run>
                                </TextBlock>
                            </StackPanel>
                        </Border>

                        <Border Background="#202020" Padding="16,12" MaxWidth="500">
                            <TextBlock Foreground="#FF6B7A" FontSize="11" TextWrapping="Wrap" TextAlignment="Center">
                                <Run FontWeight="SemiBold">&#x91CD;&#x8981;&#x63D0;&#x793A;&#xFF1A;</Run>
                                <Run> &#x6267;&#x884C;&#x6E05;&#x7406;&#x64CD;&#x4F5C;&#x524D;&#xFF0C;&#x8BF7;&#x5148;&#x521B;&#x5EFA;&#x7CFB;&#x7EDF;&#x8FD8;&#x539F;&#x70B9;&#x3002;</Run>
                            </TextBlock>
                        </Border>
                    </StackPanel>
                </Border>

                <!-- Console Output Panel -->
                <Border x:Name="panelConsole" Visibility="Collapsed" Margin="2,0,2,2">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <StackPanel x:Name="actionPanel" Grid.Row="0" Orientation="Horizontal"
                                    Margin="24,12,24,8"/>

                        <!-- Output Console -->
                        <Border Grid.Row="1" Background="#181818" Margin="16,4,16,16"
                                BorderBrush="#202020" BorderThickness="1">
                            <RichTextBox x:Name="rtbOutput" Background="Transparent" Foreground="#F5F5F5"
                                         FontFamily="Cascadia Mono, Consolas, Courier New" FontSize="12"
                                         IsReadOnly="True" BorderThickness="0" Padding="12,8"
                                         VerticalScrollBarVisibility="Auto"
                                         HorizontalScrollBarVisibility="Auto">
                                <RichTextBox.Resources>
                                    <Style TargetType="{x:Type Paragraph}">
                                        <Setter Property="Margin" Value="0,1,0,1"/>
                                    </Style>
                                </RichTextBox.Resources>
                                <FlowDocument>
                                    <Paragraph>
                                        <Run Foreground="#7D7D7D" Text="&#x5C31;&#x7EEA;&#x3002;&#x8BF7;&#x9009;&#x62E9;&#x4E00;&#x4E2A;&#x64CD;&#x4F5C;&#x5F00;&#x59CB;..."/>
                                    </Paragraph>
                                </FlowDocument>
                            </RichTextBox>
                        </Border>
                    </Grid>
                </Border>

                <!-- Products List Panel -->
                <Border x:Name="panelProducts" Visibility="Collapsed" Margin="2,0,2,2">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <!-- Search & Actions -->
                        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="24,12,24,8">
                            <Button x:Name="btnStartScan" Style="{StaticResource ActionButton}" Content="&#x1F504; &#x5F00;&#x59CB;&#x626B;&#x63CF;" Margin="0,0,8,0"/>
                            <Button x:Name="btnUninstallChecked" Style="{StaticResource DangerActionButton}" Content="&#x1F5D1; &#x5378;&#x8F7D;&#x9009;&#x4E2D;&#x9879;"
                                    Margin="0,0,8,0" IsEnabled="False"/>
                            <Button x:Name="btnSelectAll" Style="{StaticResource GhostButton}" Content="&#x5168;&#x9009;" Margin="0,0,4,0"/>
                            <Button x:Name="btnSelectNone" Style="{StaticResource GhostButton}" Content="&#x53D6;&#x6D88;&#x5168;&#x9009;"/>
                        </StackPanel>

                        <!-- Products ListView -->
                        <Border Grid.Row="1" Background="#181818" Margin="16,4,16,4"
                                BorderBrush="#202020" BorderThickness="1">
                            <ListView x:Name="lvProducts" Background="Transparent" Foreground="#F5F5F5"
                                      BorderThickness="0" Padding="4"
                                      ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                                <ListView.ItemContainerStyle>
                                    <Style TargetType="ListViewItem">
                                        <Setter Property="Background" Value="Transparent"/>
                                        <Setter Property="Foreground" Value="#F5F5F5"/>
                                        <Setter Property="Padding" Value="8,6"/>
                                        <Setter Property="Margin" Value="2,1"/>
                                        <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
                                        <Setter Property="Template">
                                            <Setter.Value>
                                                <ControlTemplate TargetType="ListViewItem">
                                                    <Border x:Name="border" Background="{TemplateBinding Background}"
                                                            Padding="{TemplateBinding Padding}">
                                                        <GridViewRowPresenter
                                                            VerticalAlignment="{TemplateBinding VerticalContentAlignment}"
                                                            SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}"
                                                            Content="{TemplateBinding Content}"
                                                            Columns="{Binding Path=View.Columns, RelativeSource={RelativeSource AncestorType=ListView}}"/>
                                                    </Border>
                                                    <ControlTemplate.Triggers>
                                                        <Trigger Property="IsMouseOver" Value="True">
                                                            <Setter TargetName="border" Property="Background" Value="#1E1E1E"/>
                                                        </Trigger>
                                                        <Trigger Property="IsSelected" Value="True">
                                                            <Setter TargetName="border" Property="Background" Value="#2A2A2A"/>
                                                        </Trigger>
                                                    </ControlTemplate.Triggers>
                                                </ControlTemplate>
                                            </Setter.Value>
                                        </Setter>
                                    </Style>
                                </ListView.ItemContainerStyle>
                                <ListView.View>
                                    <GridView>
                                        <GridViewColumn Width="40">
                                            <GridViewColumn.CellTemplate>
                                                <DataTemplate>
                                                    <CheckBox IsChecked="{Binding IsSelected, Mode=TwoWay}"
                                                              VerticalAlignment="Center"/>
                                                </DataTemplate>
                                            </GridViewColumn.CellTemplate>
                                        </GridViewColumn>
                                        <GridViewColumn Header="&#x5E8F;&#x53F7;" Width="45" DisplayMemberBinding="{Binding Index}"/>
                                        <GridViewColumn Header="&#x7C7B;&#x578B;" Width="60" DisplayMemberBinding="{Binding Type}"/>
                                        <GridViewColumn Header="&#x4EA7;&#x54C1;&#x540D;&#x79F0;" Width="380" DisplayMemberBinding="{Binding Name}"/>
                                        <GridViewColumn Header="&#x7248;&#x672C;" Width="100" DisplayMemberBinding="{Binding Version}"/>
                                        <GridViewColumn Header="&#x4F18;&#x5148;&#x7EA7;" Width="65" DisplayMemberBinding="{Binding Priority}"/>
                                    </GridView>
                                </ListView.View>
                            </ListView>
                        </Border>

                        <!-- Product count -->
                        <TextBlock x:Name="txtProductCount" Grid.Row="2" Margin="24,4,24,12" FontSize="12" Foreground="#7D7D7D"
                                   Text="&#x5C1A;&#x672A;&#x626B;&#x63CF;&#x3002;&#x70B9;&#x51FB; '&#x5F00;&#x59CB;&#x626B;&#x63CF;' &#x5F00;&#x59CB;&#x68C0;&#x6D4B;&#x3002;"/>
                    </Grid>
                </Border>
            </Grid>
        </Grid>

        <!-- BOTTOM STATUS BAR -->
        <Border Grid.Row="1" Grid.Column="1" Background="#181818" Padding="20,8">
            <DockPanel>
                <TextBlock x:Name="txtAdminBadge" DockPanel.Dock="Right" Foreground="#2ED573" FontSize="11"
                           VerticalAlignment="Center" Margin="12,0,0,0">
                    <Run Text="&#x1F6E1; "/>
                    <Run Text="&#x7BA1;&#x7406;&#x5458;&#x6A21;&#x5F0F;"/>
                </TextBlock>
                <ProgressBar x:Name="progressBar" DockPanel.Dock="Right" Width="180" Height="6"
                             Margin="12,0" VerticalAlignment="Center"
                             Background="#202020" Foreground="#FFC000" BorderThickness="0"
                             Visibility="Collapsed"/>
                <TextBlock x:Name="txtStatus" Foreground="#7D7D7D" FontSize="11" VerticalAlignment="Center"
                           Text="&#x5C31;&#x7EEA;"/>
            </DockPanel>
        </Border>
    </Grid>
</Window>
"@

# ============================================================
# CREATE WINDOW
# ============================================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get all named controls
$controls = @{}
$xaml.SelectNodes("//*[@*[contains(translate(name(),'X','x'),'x:Name')]]") | ForEach-Object {
    $name = $_.Attributes["x:Name"].Value
    $controls[$name] = $window.FindName($name)
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Write-Console {
    param(
        [string]$Text,
        [string]$Color = "#F5F5F5",
        [switch]$Bold,
        [switch]$NewLine
    )
    $rtb = $controls['rtbOutput']
    $doc = $rtb.Document

    # Strip ANSI escape codes
    $cleanText = $Text -replace '\x1B\[[0-9;]*[a-zA-Z]', ''

    if ([string]::IsNullOrEmpty($cleanText) -and -not $NewLine) { return }

    $para = $doc.Blocks | Select-Object -Last 1
    if (-not $para -or $NewLine) {
        $para = New-Object System.Windows.Documents.Paragraph
        $para.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)
        $doc.Blocks.Add($para)
    }

    $run = New-Object System.Windows.Documents.Run
    $run.Text = $cleanText
    $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
    if ($Bold) { $run.FontWeight = [System.Windows.FontWeights]::Bold }
    $para.Inlines.Add($run)

    $rtb.ScrollToEnd()
}

function Clear-Console {
    $rtb = $controls['rtbOutput']
    $rtb.Document.Blocks.Clear()
}

function Set-UIState {
    param([bool]$Running)

    $script:IsRunning = $Running
    $enabled = -not $Running

    $controls['btnScan'].IsEnabled = $enabled
    $controls['btnUninstallSel'].IsEnabled = $enabled
    $controls['btnFullClean'].IsEnabled = $enabled
    $controls['btnDeepClean'].IsEnabled = $enabled
    $controls['btnVerify'].IsEnabled = $enabled
    $controls['btnRestore'].IsEnabled = $enabled
    $controls['btnRemnants'].IsEnabled = $enabled
    $controls['btnAudit'].IsEnabled = $enabled
    $controls['btnFixErr'].IsEnabled = $enabled
    $controls['btnFixReboot'].IsEnabled = $enabled
    $controls['btnBackup'].IsEnabled = $enabled

    if ($Running) {
        $controls['btnStop'].Visibility = 'Visible'
        $controls['progressBar'].Visibility = 'Visible'
        $controls['progressBar'].IsIndeterminate = $true
    } else {
        $controls['btnStop'].Visibility = 'Collapsed'
        $controls['progressBar'].Visibility = 'Collapsed'
        $controls['progressBar'].IsIndeterminate = $false
    }
}

function Show-Panel {
    param([string]$PanelName)

    $controls['panelWelcome'].Visibility = 'Collapsed'
    $controls['panelConsole'].Visibility = 'Collapsed'
    $controls['panelProducts'].Visibility = 'Collapsed'

    $controls[$PanelName].Visibility = 'Visible'
}

function Set-Header {
    param([string]$Title, [string]$Subtitle)
    $controls['txtHeader'].Text = $Title
    $controls['txtSubHeader'].Text = $Subtitle
}

function Set-Status {
    param([string]$Text, [string]$Color = "#7D7D7D")
    $controls['txtStatus'].Text = $Text
    $controls['txtStatus'].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
}

function Stop-TrackedChildProcess {
    if (-not $script:CurrentChildProcessId) {
        return $false
    }

    try {
        Stop-Process -Id $script:CurrentChildProcessId -Force -ErrorAction Stop
        return $true
    } catch {
        return $false
    } finally {
        $script:CurrentChildProcessId = $null
    }
}

function Convert-InputSequenceToCmdExpression {
    param(
        [string]$InputSequence,
        [string]$CommandPath
    )

    $lines = @($InputSequence -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($lines.Count -eq 0) {
        return "`"$CommandPath`" 2>&1"
    }

    $echoCommands = $lines | ForEach-Object { "echo $_" }
    return "( $($echoCommands -join ' & ') ) | `"$CommandPath`" 2>&1"
}

function Write-CommandOutputLine {
    param([string]$Line)

    if ([string]::IsNullOrEmpty($Line)) { return }

    $color = "#C0C0C0"
    $bold = $false

    if ($Line -match '\[OK\]|done\.|deleted\.|SUCCESS|COMPLETE|OK$') {
        $color = "#2ED573"
    } elseif ($Line -match '\[FAIL\]|FAIL|FAILED|ERROR|LOCKED') {
        $color = "#FF4757"
        $bold = $true
    } elseif ($Line -match '\[SKIP\]|SKIP|WARN|WARNING') {
        $color = "#FFA502"
    } elseif ($Line -match '\[INFO\]|Scanning|Phase|Progress|===') {
        $color = "#FFC000"
    } elseif ($Line -match '^\s*\[[\d]+\]|^\s*No\.') {
        $color = "#C0C0C0"
    } elseif ($Line -match '------|========') {
        $color = "#555555"
    }

    Write-Console $Line -Color $color -Bold:$bold -NewLine
}

function Start-PolledJob {
    param(
        [scriptblock]$JobScript,
        [object[]]$ArgumentList = @(),
        [int]$IntervalMs = 200,
        [scriptblock]$OnData,
        [scriptblock]$OnCompleted,
        [scriptblock]$OnFailed
    )

    $job = Start-Job -ScriptBlock $JobScript -ArgumentList $ArgumentList
    $script:CurrentJob = $job

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds($IntervalMs)

    $timer.Add_Tick({
        try {
            $items = @(Receive-Job -Job $job -ErrorAction SilentlyContinue)
            foreach ($item in $items) {
                if ($OnData) {
                    & $OnData $item
                }
            }

            if ($job.State -in @('Completed', 'Failed', 'Stopped')) {
                if ($job.State -eq 'Completed') {
                    $remaining = @(Receive-Job -Job $job -ErrorAction SilentlyContinue)
                    foreach ($item in $remaining) {
                        if ($OnData) {
                            & $OnData $item
                        }
                    }

                    if ($OnCompleted) {
                        & $OnCompleted $job
                    }
                } else {
                    $reason = $null
                    if ($job.ChildJobs.Count -gt 0 -and $job.ChildJobs[0].JobStateInfo.Reason) {
                        $reason = $job.ChildJobs[0].JobStateInfo.Reason.Message
                    }
                    if (-not $reason) {
                        $reason = "后台作业已停止。"
                    }

                    if ($OnFailed) {
                        & $OnFailed $reason $job.State
                    }
                }

                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
                if ($script:CurrentJob -eq $job) {
                    $script:CurrentJob = $null
                }
                $timer.Stop()
            }
        } catch {
            if ($OnFailed) {
                & $OnFailed $_.Exception.Message 'Failed'
            }

            if ($job) {
                Stop-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            }
            if ($script:CurrentJob -eq $job) {
                $script:CurrentJob = $null
            }
            $timer.Stop()
        }
    }.GetNewClosure())

    $timer.Start()
    return $job
}

function Run-BatCommand {
    param(
        [string]$InputSequence,
        [string]$Description = "正在执行操作..."
    )

    if ($script:IsRunning) {
        [System.Windows.MessageBox]::Show("有操作正在运行中，请等待完成或先停止当前操作。",
            "操作进行中", 'OK', 'Warning')
        return
    }

    if (-not (Test-Path $script:BatPath)) {
        [System.Windows.MessageBox]::Show("找不到文件: $($script:BatPath)`n`n请确保 .bat 文件与本脚本在同一文件夹中。",
            "文件未找到", 'OK', 'Error')
        return
    }

    Set-UIState -Running $true
    Set-Status $Description "#FFC000"
    Clear-Console
    Write-Console "[$([datetime]::Now.ToString('HH:mm:ss'))] $Description" -Color "#FFC000" -Bold -NewLine
    Write-Console ("=" * 60) -Color "#202020" -NewLine
    Write-Console "" -NewLine

    $cmdExpression = Convert-InputSequenceToCmdExpression -InputSequence $InputSequence -CommandPath $script:BatPath
    $script:LastExitCode = $null

    try {
        Start-PolledJob -JobScript {
            param($command, $workingDir)
            Set-Location $workingDir
            cmd.exe /c $command | ForEach-Object { "LINE|$_" }
            "EXITCODE|$LASTEXITCODE"
        } -ArgumentList @($cmdExpression, $PSScriptRoot) -IntervalMs 100 `
            -OnData {
                param($item)
                $text = [string]$item
                if ($text -like 'LINE|*') {
                    Write-CommandOutputLine $text.Substring(5)
                } elseif ($text -like 'EXITCODE|*') {
                    $script:LastExitCode = [int]$text.Substring(9)
                }
            } `
            -OnCompleted {
                Write-Console "" -NewLine
                Write-Console ("=" * 60) -Color "#202020" -NewLine
                if ($script:LastExitCode -eq 0) {
                    Write-Console "[$([datetime]::Now.ToString('HH:mm:ss'))] 操作已成功完成。(退出码: $($script:LastExitCode))" -Color "#2ED573" -Bold -NewLine
                    Set-Status "已成功完成" "#2ED573"
                } else {
                    Write-Console "[$([datetime]::Now.ToString('HH:mm:ss'))] 操作已结束。(退出码: $($script:LastExitCode))" -Color "#FFA502" -Bold -NewLine
                    Set-Status "已完成，退出码 $($script:LastExitCode)" "#FFA502"
                }

                $script:CurrentChildProcessId = $null
                Set-UIState -Running $false
                $script:CurrentProcess = $null
            } `
            -OnFailed {
                param($reason, $state)
                Write-Console "错误: $reason" -Color "#FF4757" -Bold -NewLine
                $script:CurrentChildProcessId = $null
                Set-UIState -Running $false
                Set-Status "发生错误" "#FF4757"
            }.GetNewClosure() | Out-Null
    } catch {
        Write-Console "错误: $($_.Exception.Message)" -Color "#FF4757" -Bold -NewLine
        Set-UIState -Running $false
        Set-Status "发生错误" "#FF4757"
    }
}

function Run-DirectCommand {
    param(
        [string]$Command,
        [string]$Description = "正在运行..."
    )

    if ($script:IsRunning) {
        [System.Windows.MessageBox]::Show("有操作正在运行中。", "忙碌", 'OK', 'Warning')
        return
    }

    Set-UIState -Running $true
    Set-Status $Description "#FFC000"
    Clear-Console
    Write-Console "[$([datetime]::Now.ToString('HH:mm:ss'))] $Description" -Color "#FFC000" -Bold -NewLine
    Write-Console ("=" * 60) -Color "#202020" -NewLine
    Write-Console "" -NewLine

    $script:LastExitCode = $null

    try {
        Start-PolledJob -JobScript {
            param($command, $workingDir)
            Set-Location $workingDir
            cmd.exe /c "$command 2>&1" | ForEach-Object { "LINE|$_" }
            "EXITCODE|$LASTEXITCODE"
        } -ArgumentList @($Command, $PSScriptRoot) -IntervalMs 100 `
            -OnData {
                param($item)
                $text = [string]$item
                if ($text -like 'LINE|*') {
                    Write-CommandOutputLine $text.Substring(5)
                } elseif ($text -like 'EXITCODE|*') {
                    $script:LastExitCode = [int]$text.Substring(9)
                }
            } `
            -OnCompleted {
                Write-Console "" -NewLine
                Write-Console ("=" * 60) -Color "#202020" -NewLine
                if ($script:LastExitCode -eq 0) {
                    Write-Console "[$([datetime]::Now.ToString('HH:mm:ss'))] 完成。" -Color "#2ED573" -Bold -NewLine
                    Set-Status "就绪" "#7D7D7D"
                } else {
                    Write-Console "[$([datetime]::Now.ToString('HH:mm:ss'))] 已结束。(退出码: $($script:LastExitCode))" -Color "#FFA502" -Bold -NewLine
                    Set-Status "退出码 $($script:LastExitCode)" "#FFA502"
                }
                $script:CurrentChildProcessId = $null
                Set-UIState -Running $false
                $script:CurrentProcess = $null
            } `
            -OnFailed {
                param($reason, $state)
                Write-Console "错误: $reason" -Color "#FF4757" -Bold -NewLine
                $script:CurrentChildProcessId = $null
                Set-UIState -Running $false
                Set-Status "错误" "#FF4757"
            }.GetNewClosure() | Out-Null
    } catch {
        Write-Console "错误: $($_.Exception.Message)" -Color "#FF4757" -Bold -NewLine
        Set-UIState -Running $false
        Set-Status "错误" "#FF4757"
    }
}

function Scan-Products {
    if ($script:IsRunning) {
        [System.Windows.MessageBox]::Show("有操作正在运行中。", "忙碌", 'OK', 'Warning')
        return
    }

    Set-UIState -Running $true
    Set-Status "正在扫描 Autodesk 产品..." "#FFC000"
    $controls['lvProducts'].Items.Clear()
    $controls['txtProductCount'].Text = "正在扫描..."
    $script:ScannedProducts = @()
    $products = [System.Collections.Generic.List[object]]::new()
    $scanOnData = {
        param($item)
        if ($null -ne $item) {
            $products.Add($item) | Out-Null
        }
    }.GetNewClosure()

    $scanOnCompleted = {
        $script:ScannedProducts = @($products)

        $controls['lvProducts'].Items.Clear()
        foreach ($p in $script:ScannedProducts) {
            $controls['lvProducts'].Items.Add($p) | Out-Null
        }

        $count = $script:ScannedProducts.Count
        $controls['txtProductCount'].Text = "共发现 $count 个 Autodesk 产品。"
        $controls['btnUninstallChecked'].IsEnabled = ($count -gt 0)

        Set-UIState -Running $false
        Set-Status "发现 $count 个产品" $(if ($count -gt 0) { "#FFA502" } else { "#2ED573" })
    }.GetNewClosure()

    Start-PolledJob -JobScript {
        function Get-UninstallRegistryPaths {
            $paths = [System.Collections.Generic.List[object]]::new()
            $paths.Add([PSCustomObject]@{
                Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
                DeduplicateByName = $false
            }) | Out-Null

            if ([Environment]::Is64BitOperatingSystem) {
                $paths.Add([PSCustomObject]@{
                    Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                    DeduplicateByName = $true
                }) | Out-Null
            }

            return $paths
        }

        function Get-AutodeskProductsFromRegistryPath {
            param(
                [string]$RegistryPath,
                [hashtable]$SeenNames,
                [bool]$DeduplicateByName
            )

            $items = [System.Collections.Generic.List[object]]::new()

            try {
                if (-not (Test-Path $RegistryPath)) {
                    return $items
                }

                foreach ($productKey in Get-ChildItem $RegistryPath -ErrorAction SilentlyContinue) {
                    try {
                        if (-not $productKey) { continue }

                        $publisher = [string]$productKey.GetValue('Publisher', '')
                        $name = [string]$productKey.GetValue('DisplayName', '')
                        if ([string]::IsNullOrWhiteSpace($name) -or $publisher -notmatch 'Autodesk') {
                            continue
                        }

                        if ($DeduplicateByName -and $SeenNames.ContainsKey($name)) {
                            continue
                        }
                        $SeenNames[$name] = $true

                        $version = [string]$productKey.GetValue('DisplayVersion', '')
                        if ([string]::IsNullOrWhiteSpace($version)) {
                            $version = "N/A"
                        }

                        $uninstStr = [string]$productKey.GetValue('UninstallString', '')
                        $type = "MSI"
                        if ($uninstStr -and ($uninstStr -match 'Installer\.exe' -or $uninstStr -match 'AdskUninstallHelper')) {
                            $type = "ODIS"
                        }

                        $prio = 3
                        if ($name -match 'Enabler|Plugin|Add-in|Addon|Content Pack|Language|Service Pack|Object') { $prio = 1 }
                        if ($name -match 'Material Library Medium Resolution|Base Resolution') { $prio = 5 }
                        if ($name -match 'Material Library Medium') { $prio = 4 }
                        if ($name -match 'Desktop App') { $prio = 6 }
                        if ($name -match 'Single Sign') { $prio = 7 }
                        if ($name -match 'Genuine') { $prio = 8 }

                        $items.Add([PSCustomObject]@{
                            Type = $type
                            Name = $name
                            Version = $version
                            Priority = $prio
                            UninstallString = $uninstStr
                            RegistryKey = $productKey.Name
                            IsSelected = $false
                        }) | Out-Null
                    } catch {}
                }

                return $items
            } catch {
                return $items
            }
        }

        $count = 0
        $seen = @{}

        foreach ($regPathInfo in Get-UninstallRegistryPaths) {
            foreach ($item in Get-AutodeskProductsFromRegistryPath -RegistryPath $regPathInfo.Path -SeenNames $seen -DeduplicateByName $regPathInfo.DeduplicateByName) {
                $count++
                $item | Add-Member -NotePropertyName Index -NotePropertyValue $count
                $item
            }
        }
    } -IntervalMs 200 `
        -OnData $scanOnData `
        -OnCompleted $scanOnCompleted `
        -OnFailed {
            param($reason, $state)
            $controls['txtProductCount'].Text = "扫描失败: $reason"
            Write-Console "扫描失败: $reason" -Color "#FF4757" -Bold -NewLine
            Set-UIState -Running $false
            Set-Status "扫描失败" "#FF4757"
        }.GetNewClosure() | Out-Null
}

function Uninstall-SelectedProducts {
    $selected = @($controls['lvProducts'].Items | Where-Object { $_.IsSelected })

    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("未选择任何产品。请勾选要卸载的产品。",
            "未选择", 'OK', 'Information')
        return
    }

    $names = ($selected | ForEach-Object { "  - $($_.Name)" }) -join "`n"
    $result = [System.Windows.MessageBox]::Show(
        "即将卸载 $($selected.Count) 个产品:`n`n$names`n`n此操作不可撤销。是否继续?",
        "确认卸载", 'YesNo', 'Warning')

    if ($result -ne 'Yes') { return }

    Show-Panel 'panelConsole'
    Set-Header "正在卸载选中产品" "已排队 $($selected.Count) 个产品等待卸载"
    Set-UIState -Running $true
    Set-Status "正在卸载..." "#FFA502"
    Clear-Console

    Write-Console "[$([datetime]::Now.ToString('HH:mm:ss'))] 开始选择性卸载 $($selected.Count) 个产品" -Color "#FFC000" -Bold -NewLine
    Write-Console ("=" * 60) -Color "#202020" -NewLine

    $script:CurrentChildProcessId = $null
    $completionState = [PSCustomObject]@{
        Message = $null
    }
    $uninstallOnData = {
        param($item)
        $msg = [string]$item
        $parts = $msg -split '\|', 2
        $type = $parts[0]
        $text = if ($parts.Count -gt 1) { $parts[1] } else { "" }

        switch ($type) {
            'PID'    {
                if ($text -and $text -ne '0') {
                    $script:CurrentChildProcessId = [int]$text
                } else {
                    $script:CurrentChildProcessId = $null
                }
            }
            'HEADER' { Write-Console "" -NewLine; Write-Console $text -Color "White" -Bold -NewLine; Write-Console ("-" * 50) -Color "#202020" -NewLine }
            'INFO'   { Write-Console "  $text" -Color "#FFC000" -NewLine }
            'OK'     { Write-Console "  $text" -Color "#2ED573" -Bold -NewLine }
            'FAIL'   { Write-Console "  $text" -Color "#FF4757" -Bold -NewLine }
            'WARN'   { Write-Console "  $text" -Color "#FFA502" -NewLine }
            'SPACE'  { Write-Console "" -NewLine }
            'DONE'   {
                $completionState.Message = $text
                Write-Console "" -NewLine
                Write-Console ("=" * 60) -Color "#202020" -NewLine
                Write-Console "[$([datetime]::Now.ToString('HH:mm:ss'))] 完成: $text" -Color "#2ED573" -Bold -NewLine
                Write-Console "" -NewLine
                Write-Console "提示: 再次运行「扫描」确认已卸载产品，然后运行「深度清理」清除残留。" -Color "#7D7D7D" -NewLine
            }
        }
    }.GetNewClosure()

    $uninstallOnCompleted = {
        Set-UIState -Running $false
        $script:CurrentChildProcessId = $null
        if ($completionState.Message) {
            Set-Status "卸载完成: $($completionState.Message)" "#2ED573"
        } else {
            Set-Status "卸载已结束" "#2ED573"
        }
    }.GetNewClosure()

    Start-PolledJob -JobScript {
        param($products)
        function Get-UninstallRegistryPaths {
            $paths = [System.Collections.Generic.List[object]]::new()
            $paths.Add([PSCustomObject]@{
                Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
                DeduplicateByName = $false
            }) | Out-Null

            if ([Environment]::Is64BitOperatingSystem) {
                $paths.Add([PSCustomObject]@{
                    Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                    DeduplicateByName = $true
                }) | Out-Null
            }

            return $paths
        }

        function Get-AutodeskProductsFromRegistryPath {
            param(
                [string]$RegistryPath,
                [hashtable]$SeenNames,
                [bool]$DeduplicateByName
            )

            $items = [System.Collections.Generic.List[object]]::new()

            try {
                if (-not (Test-Path $RegistryPath)) {
                    return $items
                }

                foreach ($productKey in Get-ChildItem $RegistryPath -ErrorAction SilentlyContinue) {
                    try {
                        if (-not $productKey) { continue }

                        $publisher = [string]$productKey.GetValue('Publisher', '')
                        $name = [string]$productKey.GetValue('DisplayName', '')
                        if ([string]::IsNullOrWhiteSpace($name) -or $publisher -notmatch 'Autodesk') {
                            continue
                        }

                        if ($DeduplicateByName -and $SeenNames.ContainsKey($name)) {
                            continue
                        }
                        $SeenNames[$name] = $true

                        $version = [string]$productKey.GetValue('DisplayVersion', '')
                        if ([string]::IsNullOrWhiteSpace($version)) {
                            $version = "N/A"
                        }

                        $uninstStr = [string]$productKey.GetValue('UninstallString', '')
                        $type = "MSI"
                        if ($uninstStr -and ($uninstStr -match 'Installer\.exe' -or $uninstStr -match 'AdskUninstallHelper')) {
                            $type = "ODIS"
                        } elseif ($uninstStr -match 'Setup\.exe') {
                            $type = "Setup"
                        }

                        $items.Add([PSCustomObject]@{
                            Type = $type
                            Name = $name
                            Version = $version
                            UninstallString = $uninstStr
                        }) | Out-Null
                    } catch {}
                }

                return $items
            } catch {
                return $items
            }
        }

        function Get-RemainingSelectedProducts {
            param([string[]]$TargetNames)

            $seen = @{}
            $items = [System.Collections.Generic.List[object]]::new()

            foreach ($regPathInfo in Get-UninstallRegistryPaths) {
                foreach ($item in Get-AutodeskProductsFromRegistryPath -RegistryPath $regPathInfo.Path -SeenNames $seen -DeduplicateByName $regPathInfo.DeduplicateByName) {
                    if ($TargetNames -contains $item.Name) {
                        $items.Add($item) | Out-Null
                    }
                }
            }

            return $items
        }

        function Convert-UninstallStringToCommand {
            param([string]$CommandLine)

            if ([string]::IsNullOrWhiteSpace($CommandLine)) {
                return $null
            }

            $match = [regex]::Match(
                $CommandLine.Trim(),
                '^(?:"(?<qexe>[^"]+)"|(?<uexe>\S+))(?<args>.*)$'
            )

            if (-not $match.Success) {
                return $null
            }

            $filePath = if ($match.Groups['qexe'].Success) {
                $match.Groups['qexe'].Value
            } else {
                $match.Groups['uexe'].Value
            }

            [PSCustomObject]@{
                FilePath = $filePath
                Arguments = $match.Groups['args'].Value.Trim()
            }
        }

        function Invoke-TrackedProcess {
            param(
                [string]$FilePath,
                [string[]]$Arguments = @()
            )

            $script:TrackedExitCode = $null
            $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -PassThru -NoNewWindow 2>$null
            "PID|$($process.Id)"
            $process.WaitForExit()
            $script:TrackedExitCode = $process.ExitCode
            "PID|0"
        }

        function Split-CommandLineArgs {
            param([string]$CommandLine)
            if ([string]::IsNullOrWhiteSpace($CommandLine)) { return @() }
            $list = [System.Collections.Generic.List[string]]::new()
            $regex = [regex]'(?:"([^"]*)"|(\S+))'
            foreach ($m in $regex.Matches($CommandLine)) {
                if ($m.Groups[1].Success) {
                    $list.Add($m.Groups[1].Value)
                } else {
                    $list.Add($m.Groups[2].Value)
                }
            }
            return $list.ToArray()
        }

        function Invoke-SelectedProductUninstall {
            param($prod)

            $script:LastUninstallSucceeded = $false

            if (-not $prod.UninstallString) {
                "WARN|未找到卸载命令，已跳过。"
                return
            }

            try {
                $us = [string]$prod.UninstallString

                if ($prod.Type -eq 'ODIS') {
                    "INFO|[ODIS] 正在运行卸载程序..."
                    $installerExe = "C:\Program Files\Autodesk\AdODIS\V1\Installer.exe"
                    if (Test-Path $installerExe) {
                        $odisArgsStr = ($us -replace '.*Installer\.exe', '').Trim()
                        if ($odisArgsStr -notmatch '(^|\s)-q(\s|$)') { $odisArgsStr += ' -q' }
                        $odisArgs = Split-CommandLineArgs $odisArgsStr
                        Invoke-TrackedProcess -FilePath $installerExe -Arguments $odisArgs
                        if ($script:TrackedExitCode -eq 0) {
                            "OK|卸载成功。"
                            $script:LastUninstallSucceeded = $true
                        } else {
                            "FAIL|ODIS 卸载失败 (退出码: $($script:TrackedExitCode))"
                        }
                    } else {
                        "FAIL|ODIS Installer.exe 未找到"
                    }
                    return
                }

                if ($us -match 'MsiExec') {
                    if ($us -match '\{([0-9A-Fa-f\-]+)\}') {
                        $guid = $Matches[0]
                        "INFO|[MSI] msiexec /x $guid /qn /norestart"
                        Invoke-TrackedProcess -FilePath "msiexec.exe" -Arguments @('/x', $guid, '/qn', '/norestart')
                        if ($script:TrackedExitCode -ne 0) {
                            "WARN|静默卸载失败，改为基本界面重试..."
                            Invoke-TrackedProcess -FilePath "msiexec.exe" -Arguments @('/x', $guid, '/qb', '/norestart')
                        }

                        if ($script:TrackedExitCode -eq 0) {
                            "OK|卸载成功。"
                            $script:LastUninstallSucceeded = $true
                        } else {
                            "FAIL|MSI 卸载失败 (退出码: $($script:TrackedExitCode))"
                        }
                    } else {
                        "WARN|无法从 UninstallString 中提取 GUID。"
                    }
                    return
                }

                if ($us -match 'Setup\.exe') {
                    $command = Convert-UninstallStringToCommand -CommandLine $us
                    if (-not $command) {
                        "FAIL|无法解析 Setup.exe 卸载命令。"
                        return
                    }

                    $setupArgs = @()
                    if ($command.Arguments) { $setupArgs += Split-CommandLineArgs $command.Arguments }
                    if ($command.Arguments -notmatch '(^|\s)/q(\s|$)') { $setupArgs += '/q' }

                    "INFO|[LEGACY] 运行 Setup.exe..."
                    Invoke-TrackedProcess -FilePath $command.FilePath -Arguments $setupArgs
                    if ($script:TrackedExitCode -eq 0) {
                        "OK|卸载成功。"
                        $script:LastUninstallSucceeded = $true
                    } else {
                        "FAIL|Setup 卸载失败 (退出码: $($script:TrackedExitCode))"
                    }
                    return
                }

                $genericCommand = Convert-UninstallStringToCommand -CommandLine $us
                if (-not $genericCommand) {
                    "FAIL|无法解析卸载命令。"
                    return
                }

                $genericArgs = @()
                if ($genericCommand.Arguments) { $genericArgs += Split-CommandLineArgs $genericCommand.Arguments }
                if ($genericCommand.Arguments -notmatch '--mode\s+unattended') {
                    $genericArgs += '--mode'
                    $genericArgs += 'unattended'
                }

                "INFO|[通用] 运行: $($genericCommand.FilePath) $($genericArgs -join ' ')"
                Invoke-TrackedProcess -FilePath $genericCommand.FilePath -Arguments $genericArgs
                if ($script:TrackedExitCode -eq 0) {
                    "OK|卸载成功。"
                    $script:LastUninstallSucceeded = $true
                } else {
                    "FAIL|卸载返回退出码 $($script:TrackedExitCode)"
                }
            } catch {
                "FAIL|错误: $($_.Exception.Message)"
            }
        }

        $targetNames = @($products | ForEach-Object { $_.Name } | Select-Object -Unique)
        $pendingProducts = @($products)
        $RETRY_MAX = 3
        $retryNum = 0
        $previousRemaining = [int]::MaxValue

        do {
            $PASS_NUM = $retryNum + 1
            if ($PASS_NUM -eq 1) {
                "INFO|=== Pass 1 of 4: Initial uninstall ==="
            } else {
                "INFO|=== Pass $PASS_NUM of 4: Retry uninstall ==="
            }

            foreach ($prod in $pendingProducts) {
                "HEADER|正在卸载: $($prod.Name)"
                Invoke-SelectedProductUninstall -prod $prod
                "SPACE|"
            }

            $remainingProducts = @(Get-RemainingSelectedProducts -TargetNames $targetNames)

            if ($remainingProducts.Count -eq 0) {
                break
            }

            if ($retryNum -ge $RETRY_MAX) {
                "WARN|最大重试次数已到，仍有 $($remainingProducts.Count) 个产品留在注册表中。"
                break
            }

            if ($PASS_NUM -gt 1 -and $remainingProducts.Count -ge $previousRemaining) {
                "WARN|重试后没有进一步进展，仍有 $($remainingProducts.Count) 个产品留在注册表中。"
                break
            }

            $previousRemaining = $remainingProducts.Count
            $pendingProducts = $remainingProducts
            $retryNum++

            "INFO|5 秒后开始第 $($retryNum + 1) 轮重试..."
            Start-Sleep -Seconds 5
        } while ($true)

        if (-not $remainingProducts) { $remainingProducts = @() }
        $remainingNames = @($remainingProducts | ForEach-Object { $_.Name } | Select-Object -Unique)
        $successCount = $targetNames.Count - $remainingNames.Count

        "PID|0"
        "DONE|$successCount 个成功, $($remainingNames.Count) 个仍需处理"
    } -ArgumentList @(, $selected) -IntervalMs 300 `
        -OnData $uninstallOnData `
        -OnCompleted $uninstallOnCompleted `
        -OnFailed {
            param($reason, $state)
            Write-Console "卸载失败: $reason" -Color "#FF4757" -Bold -NewLine
            $script:CurrentChildProcessId = $null
            Set-UIState -Running $false
            Set-Status "卸载失败" "#FF4757"
        }.GetNewClosure() | Out-Null
}

# ============================================================
# EVENT HANDLERS
# ============================================================

# --- Scan ---
$controls['btnScan'].Add_Click({
    Show-Panel 'panelProducts'
    Set-Header "扫描已安装软件" "检测系统中所有 Autodesk 产品"
    Scan-Products
})

# --- Start Scan button in products panel ---
$controls['btnStartScan'].Add_Click({
    Scan-Products
})

# --- Select All / Deselect All ---
$controls['btnSelectAll'].Add_Click({
    foreach ($item in $controls['lvProducts'].Items) {
        $item.IsSelected = $true
    }
    $controls['lvProducts'].Items.Refresh()
})

$controls['btnSelectNone'].Add_Click({
    foreach ($item in $controls['lvProducts'].Items) {
        $item.IsSelected = $false
    }
    $controls['lvProducts'].Items.Refresh()
})

# --- Uninstall Selected (sidebar) ---
$controls['btnUninstallSel'].Add_Click({
    if ($script:ScannedProducts.Count -eq 0) {
        Show-Panel 'panelProducts'
        Set-Header "卸载选中产品" "请先扫描，然后选择要卸载的产品"
        Scan-Products
        return
    }
    Show-Panel 'panelProducts'
    Set-Header "卸载选中产品" "勾选要卸载的产品"
})

# --- Uninstall Checked button ---
$controls['btnUninstallChecked'].Add_Click({
    Uninstall-SelectedProducts
})

# --- Full Uninstall + Deep Clean ---
$controls['btnFullClean'].Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "完全卸载 + 深度清理`n`n将执行以下操作:`n" +
        "  - 停止所有 Autodesk 服务和进程`n" +
        "  - 卸载所有 Autodesk 产品`n" +
        "  - 删除所有 Autodesk 文件夹`n" +
        "  - 清理注册表、服务、计划任务、防火墙规则`n" +
        "  - 移除许可证和缓存数据`n`n" +
        "此操作不可逆！请先备份自定义模板。`n`n" +
        "点击「是」继续。",
        "完全清理 - 确认", 'YesNo', 'Warning')

    if ($result -ne 'Yes') { return }

    $confirm2 = [System.Windows.MessageBox]::Show(
        "最终确认`n`n确定要从系统中移除所有 Autodesk 产品和数据吗?",
        "最后机会", 'YesNo', 'Exclamation')

    if ($confirm2 -ne 'Yes') { return }

    Show-Panel 'panelConsole'
    Set-Header "完全卸载 + 深度清理" "正在移除所有 Autodesk 产品和痕迹..."

    # First scan products, then pipe "1" to scan, wait, then "3" and "YES" and "N" (no installer cleanup) and "N" (no restore point)
    Run-BatCommand -InputSequence "1`nX`n3`nYES`nN`nN`nN" -Description "完全卸载 + 深度清理 (所有阶段)"
})

# --- Deep Clean Only ---
$controls['btnDeepClean'].Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "仅深度清理`n`n跳过产品卸载，但移除所有残留:`n" +
        "  - 共享组件`n  - 文件夹和文件`n  - 注册表项`n" +
        "  - 服务、计划任务、防火墙规则`n  - 许可证和缓存数据`n`n" +
        "是否继续?",
        "深度清理 - 确认", 'YesNo', 'Warning')

    if ($result -ne 'Yes') { return }

    Show-Panel 'panelConsole'
    Set-Header "仅深度清理" "正在移除所有 Autodesk 残留..."
    Run-BatCommand -InputSequence "4`nYES`nN`nN" -Description "深度清理 - 正在移除残留"
})

# --- Final Verification ---
$controls['btnVerify'].Add_Click({
    Show-Panel 'panelConsole'
    Set-Header "最终验证" "12 项深度系统扫描"
    Run-BatCommand -InputSequence "5`n" -Description "正在运行 12 项验证扫描..."
})

# --- Create Restore Point ---
$controls['btnRestore'].Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "是否创建系统还原点?`n`n" +
        "这可以让你在需要时回滚系统更改。`n" +
        "注意: Windows 每 24 小时限制创建一个还原点。",
        "创建还原点", 'YesNo', 'Question')

    if ($result -ne 'Yes') { return }

    Show-Panel 'panelConsole'
    Set-Header "创建还原点" "正在创建 Windows 系统还原点..."
    Run-BatCommand -InputSequence "6`nY`nX`n0" -Description "正在创建系统还原点..."
})

# --- Search Remnants ---
$controls['btnRemnants'].Add_Click({
    Show-Panel 'panelConsole'
    Set-Header "搜索残留文件" "在系统中搜索所有 Autodesk 残留"
    Run-BatCommand -InputSequence "7`nX`n0" -Description "正在搜索 Autodesk 残留 (11 项扫描)..."
})

# --- Full System Audit ---
$controls['btnAudit'].Add_Click({
    Show-Panel 'panelConsole'
    Set-Header "系统完整审计" "预览所有将被移除的内容"
    Run-BatCommand -InputSequence "8`nX`n0" -Description "正在运行系统完整审计..."
})

# --- Fix Error 103 ---
$controls['btnFixErr'].Add_Click({
    Show-Panel 'panelConsole'
    Set-Header "修复 Error 103" "诊断和修复 ODIS 安装器问题"
    Run-BatCommand -InputSequence "10`nX`n0" -Description "正在诊断 Error 103 / ODIS 问题..."
})

# --- Fix Restart Pending ---
$controls['btnFixReboot'].Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "修复重启挂起`n`n清除所有待处理的重启标志:`n" +
        "  - RebootRequired 注册表键`n" +
        "  - PendingFileRenameOperations`n" +
        "  - UpdateExeVolatile 标志`n" +
        "  - MsiSystemRebootPending 状态`n`n" +
        "此操作无需重启即可清除重启挂起状态。`n`n是否继续？",
        "修复重启挂起", 'YesNo', 'Question')

    if ($result -ne 'Yes') { return }

    Show-Panel 'panelConsole'
    Set-Header "修复重启挂起" "正在清除待处理的重启标志..."
    Run-BatCommand -InputSequence "11`nX`n0" -Description "正在修复重启挂起状态..."
})

# --- Backup Templates ---
$controls['btnBackup'].Add_Click({
    Show-Panel 'panelConsole'
    Set-Header "备份模板" "正在备份自定义模板和设置..."
    Run-BatCommand -InputSequence "12`nX`n0" -Description "正在备份 Autodesk 模板..."
})

# --- Stop button ---
$controls['btnStop'].Add_Click({
    $childStopped = Stop-TrackedChildProcess

    if ($script:CurrentJob -and $script:CurrentJob.State -eq 'Running') {
        try {
            Stop-Job -Job $script:CurrentJob -ErrorAction SilentlyContinue | Out-Null
            Remove-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
            $script:CurrentJob = $null
            Write-Console "" -NewLine
            Write-Console "[已停止] 操作被用户取消。" -Color "#FF4757" -Bold -NewLine
            if ($childStopped) {
                Write-Console "已终止当前卸载进程。" -Color "#FFA502" -NewLine
            }
            Set-UIState -Running $false
            Set-Status "被用户停止" "#FF4757"
        } catch {
            Write-Console "无法停止后台作业: $($_.Exception.Message)" -Color "#FF4757" -NewLine
        }
    }
    elseif ($script:CurrentProcess -and -not $script:CurrentProcess.HasExited) {
        try {
            $script:CurrentProcess.Kill()
            $script:CurrentProcess = $null
            Write-Console "" -NewLine
            Write-Console "[已停止] 操作被用户取消。" -Color "#FF4757" -Bold -NewLine
            Set-UIState -Running $false
            Set-Status "被用户停止" "#FF4757"
        } catch {
            Write-Console "无法停止进程: $($_.Exception.Message)" -Color "#FF4757" -NewLine
        }
    }
})

# --- Clear Output ---
$controls['btnClear'].Add_Click({
    Clear-Console
    Write-Console "输出已清空。" -Color "#7D7D7D" -NewLine
})

# --- Open Log Folder ---
$controls['btnOpenLog'].Add_Click({
    if (-not (Test-Path $script:LogDir)) {
        New-Item -Path $script:LogDir -ItemType Directory -Force | Out-Null
    }
    Start-Process "explorer.exe" -ArgumentList $script:LogDir
})

# --- Window closing ---
$window.Add_Closing({
    if ($script:IsRunning) {
        $result = [System.Windows.MessageBox]::Show(
            "有操作仍在运行中。确定要关闭吗?`n`n后台操作将被终止。",
            "操作进行中", 'YesNo', 'Warning')

        if ($result -ne 'Yes') {
            $_.Cancel = $true
            return
        }

        if ($script:CurrentProcess -and -not $script:CurrentProcess.HasExited) {
            try { $script:CurrentProcess.Kill() } catch {}
        }
        [void](Stop-TrackedChildProcess)
        if ($script:CurrentJob -and $script:CurrentJob.State -eq 'Running') {
            try {
                Stop-Job -Job $script:CurrentJob -ErrorAction SilentlyContinue | Out-Null
                Remove-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
})

# ============================================================
# SHOW WINDOW
# ============================================================
$window.ShowDialog() | Out-Null

