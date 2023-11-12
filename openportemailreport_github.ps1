$Version = "1.20ps"
$smtpserver = "smtp.office365.com"
$smtpport = "587"
   
    
$smtpfrom = "leaderboard@somewhere.net"
$smtpto = "n@somewhere.net"
$sendusername = "leaderboard@somewhere.net"
$sendpassword = "hadtoguesspasswordforemail"

####################################
# Program: openportemailreport.ps1
# By: Von Wallace vonwallace@vonwallace.com
# To run add the following to the login script
# powershell.exe �Noninteractive �Noprofile �Command "C:\support\openportemailreport.ps1"
# Probes selected ports on all host located in kaseya db as gateways and grabs a banner if available
###################################

function HexToString($i) {
    #$r=[System.Convert]::FromHexString($i)
    $r = ""
    for ($n = 0; $n -lt $i.Length; $n += 2)
    { $r += [char][int]("0x" + $i.Substring($n, 2)) }
    return $r
}


function IsPrivateIP($ipp) {
    $ipp = $ipp.trim()
    if ($ipp -Match '(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)') {
       
        return  $true
    }
    else {
        
        
        return  $false
    }
    
}

if ('SslProtocol' -notin (Get-Command Invoke-RestMethod).Parameters.Keys) {
    $currentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__, [Net.SecurityProtocolType]::Tls.value__)
    $newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $currentMaxTls }
    $newTlsTypes | ForEach-Object {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
    }
}

Add-Type @'
public class MyNoValidate {
  private static System.Boolean bypassvalidation(
    System.Object sender,
    System.Security.Cryptography.X509Certificates.X509Certificate certificate,
    System.Security.Cryptography.X509Certificates.X509Chain chain,
    System.Net.Security.SslPolicyErrors sslPolicyErrors
  ) {
    return true;
  }
 
  public static System.Net.Security.RemoteCertificateValidationCallback getcallback() {
    System.Net.Security.RemoteCertificateValidationCallback cb;
 
    cb = new System.Net.Security.RemoteCertificateValidationCallback(
      bypassvalidation
    );
 
    return cb;
  }
}
'@
[System.Net.Security.SslStream]$SslStream = $null
[System.Net.Security.RemoteCertificateValidationCallback]$Callback = $null
$Callback = [MyNoValidate]::getcallback()

$services = @{
    7     = "echo";
    9     = "discard";
    13    = "daytime";
    17    = "qotd";
    19    = "chargen";
    20    = "ftp-data";
    21    = "ftp";
    22    = "ssh";
    23    = "telnet";
    25    = "smtp";
    26    = "rsftp";
    43    = "whois";
    53    = "domain";
    69    = "tftp";
    79    = "finger";
    80    = "http";
    109   = "pop2";
    110   = "pop3";
    111   = "sunrpc";
    113   = "auth";
    115   = "sftp";
    119   = "nntp";
    123   = "ntp";
    135   = "epmap";
    137   = "netbios-ns";
    138   = "netbios-ds";
    139   = "netbios-ssn";
    143   = "imap2";
    161   = "snmp";
    162   = "snmptrap";
    199   = "smux";
    247   = "subntbcst-tftp";
    389   = "ldap";
    443   = "https";
    445   = "microsoft-ds";
    465   = "submissions";
    513   = "login";
    514   = "shell";
    554   = "rtsp";
    587   = "submission";
    631   = "ipp";
    636   = "ldaps";
    902   = "vmware";
    989   = "ftps-data";
    990   = "ftps";
    992   = "telnets";
    993   = "imaps";
    995   = "pop3s";
    1433  = "ms-sql-s";
    1720  = "h323";
    1723  = "pptp";
    1758  = "tftp-mcast";
    1818  = "etftp";
    2525  = "smtp-alt";
    3713  = "tftps";
    3306  = "mysql";
    3389  = "ms-wbt-server";
    4398  = "sonicwall";
    4433  = "sonicwall";
    5432  = "postgresql";
    5500  = "fcp-addr-srvr1";
    5800  = "vnc1";
    5900  = "vnc2";
    8043  = "sonicwall";
    8080  = "http-alt";
    8081  = "sonicwall";
    8888  = "althttpd";
    9000  = "sonicwall";
    9090  = "sonicwall";
    9100  = "jetdirect";
    1080  = "W32.Beagle; WinHole; HLLW.Deadhat;  Webus";
    2745  = "Bagle Virus Backdoor; Beagle";
    3127  = "W32.Mockbot; Solame;  Novarg(Mydoom); W32.HLLW.Deadhat";
    4444  = "sonicwall; Napster; Prosiak; Swift Remote; Blaster.Worm;  W32.HLLW.Donk; W32.Mockbot; W32.Reidana";
    5554  = "W32.Dabber; Sasser";
    8866  = "W32.Beagle";
    9898  = "CrashCool; Dabber";
    12345 = "Amitis; Ashley; Cron/Crontab; Fat Bitch Trojan; GabanBus; Mypic; NetBus; NetBus Toy; NetBus Worm; Pie Bill Gates; Whack Job; X-bill";
    27374 = "Bad Blood; Baste; Ramen; Seeker; SubSeven; Subseven 2.1.4 DefCon 8;  SubSeven Muie; Ttfloader";
    31337 = "Back Orifice; Back Orifice 1.20 Patches; Back Orifice Russian; Baron Night; Beeone; BO Client; BO Facil; BO Spy; BO2; Cron/Crontab;  Emcommander; Freak2k; Freak88; c; Sockdmini; W32.HLLW.Gool"
}
#Test
<#$services = @{
    21     = "ftp";
    80     = "http"
}#>


$report = @"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta name=`"viewport`" content=`"width=device-width,initial-scale=1`">
    <meta charset=`"utf-8`">
    <meta name=`"generator`" content=`"CoffeeCup HTML Editor (www.coffeecup.com)`">
    <meta name=`"dcterms.created`" content=`"Wed, 05 Oct 2022 23:08:13 GMT`">
    <meta name=`"description`" content=`"`">
    <meta name=`"keywords`" content=`"`">
    <title>Open Port Report</title>
    <style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; color: white; background-color: #942925;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
/* Rounded corners for advanced mail clients only */
      @media all and (min-width: 560px) {
        .container {
          border-radius: 8px;
          -webkit-border-radius: 8px;
          -moz-border-radius: 8px;
          -khtml-border-radius: 8px;
        }
      }
.flex-container {
          display: flex;
    flex-wrap: wrap;
    font-size: 13px;
    width: 100%;
    background: #efefef;
    border-radius: 4px;
      }
      .flex-item {
          padding: 10px;
    flex: calc(50% - 35px);
    text-align: left;
    border: 2px solid #bfbfbf;
    margin: 5px;
    background: #dee1e6;
    border-radius: 4px;
      }
      @media (max-width: 560px) {
        .flex-item{
          flex: 100%;
        }
      }
</style>

    
  </head>
<body>

"@    

$report = $report + "<center>"
$report = $report + "<br/><br/><br/>"
$report = $report + "<h1>Open Port Report</h1></center><br/>"
#$report = $report + "<h4>Version: " + $version + "</h4><br>"

$report = $report + "%stats%<br/><br/>"
     
$StartTime = $(get-date)

$report = $report + "<table style=`"width:100%`" class=`"container`">
  <tr>
  <th>Host</th> 
  <th>PTR</th>
  <th>Group</th>
  <th>Cert Expires</th>
      <th>Port</th>
    <th>Is Open</th>
    <th>Service</th>
    <th>Response Time</th>
    <th>Banner</th> 
  </tr>"


$trig_null = ""
#$trig_http = "OPTIONS / HTTP/1.0`r`n`r`n"
$trig_http = "GET / HTTP/1.0`r`n`r`n"
#$trig_http="HEAD /  HTTP/1.0`r`n`r`n";
$trig_mssql = hextostring("100100e000000100d80000000100007100000000000000076c04000000000000e0030000000000000908000056000a006a000a007e0000007e002000be00090000000000d0000400d8000000d8000000000c29c6634200000000c8000000420061006e006e00650072004700720061006200420061006e006e006500720047007200610062004d006900630072006f0073006f0066007400200044006100740061002000410063006300650073007300200043006f006d0070006f006e0065006e00740073003100320037002e0030002e0030002e0031004f00440042004300")
$trig_ldap = hextostring("300c0201016007020103040080003035020102633004000a01000a0100020100020100010100870b6f626a656374436c6173733010040e6e616d696e67436f6e7465787473");
#$trig_smtp="HELO bannergrab.com`r`nHELP`r`nVRFY postmaster`r`nVRFY bannergrab123`r`nEXPN postmaster`r`nQUIT`r`n";
$trig_smtp = "HELO bannergrab.com`r`nHELP`r`nQUIT`r`n"
$trig_fw1admin = "???`r`n?`r`n"
$trig_nbns = hextostring("a2480000000100000000000020434b4141414141414141414141414141414141414141414141414141414141410000210001")
$trig_ntp = hextostring("e30004fa000100000001000000000000000000000000000000000000000000000000000000000000ca9ba3352d7f950b160200010000000000000000160100010000000000000000")
$trig_nntp = "HELP`r`nLIST NEWSGROUPS`r`nQUIT`r`n"
$trig_pop = "QUIT`r`n"
$trig_finger = "root bin lp wheel spool adm mail postmaster news uucp snmp daemon`r`n"
$trig_snmp = hextostring("302902010004067075626c6963a01c0204ffffffff020100020100300e300c06082b060102010101000500302a020100040770726976617465a01c0204fffffffe020100020100300e300c06082b060102010101000500")
$trig_telnet = "`r`r";
$trig_ftp = "HELP`nUSER anonymous`nPASS banner@grab.com`nQUIT`n"
$trig_echo = "Echo`r`n"
$trig_imap = "CAPABILITY`r`n"


$sqlserver = "sqlserverIPforkaseya"
$SQLDBName = "ksubscribers"
try {
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; User ID = $uid; Password = $pwdd;"
    $Connection.Open()

    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection

    $sql = "begin`r`n


        SELECT distinct groupname,connectionGatewayIp FROM ksubscribers.dbo.vAgents_AgentStatus where lastCheckinTime  > DATEADD(day, -14, GETDATE()) order by groupname,connectiongatewayip`r`n"
    $sql = $sql + "END`r`n"
        
    $Command.CommandText = $sql
    $datareader = $Command.ExecuteReader()
    
    $Computernamearray = [System.Collections.ArrayList]::new()
    $groupnamearray = [System.Collections.ArrayList]::new()

    IF ($datareader.HASROWS) {

        while ($datareader.read()) {
            $computernametemp = $datareader[1]
            $groupnametemp = $datareader[0]
            if (IsPrivateIP($computernametemp) ) {}else {
                $null = $Computernamearray.add($computernametemp) 
                $null = $groupnamearray.add($groupnametemp)
            }
        }
    }
}
finally {
    $Connection.Close() 
}
# $Computername="dfwpest.com"
$expiredcount = 0
$totalPortsOpen = 0
$totalPortsClosed = 0
for ($i = 0; $i -lt $Computernamearray.Count; $i++) {
    $Computername = $Computernamearray[$i]
    $groupname = $groupnamearray[$i]
    if ($Computername -ne "" ) {
        try {
            $dnsRecord = Resolve-DnsName -Name $Computername -ErrorAction Stop | Select-Object -ExpandProperty namehost
        }
        catch { $dnsRecord = "NA" }
    
        $services.keys | Sort-object $_ | ForEach-Object {
            $item = $_
            $service = $($services[$_])
            write-host "Host" $Computername "Scanning Port: " $item "Service: " $service
       
            
            $link = ""
            $sslconnection = 0
            $expires = "NA"
            $cb = ""
            $cf = ""
            $certexpiresin = ""

            try {
       
                $rts = ""
       
                $TCPTimeout = 300
               
               $requestStartTime = Get-Date
                
                try {
                    $tcpConnection = new-object System.Net.Sockets.TcpClient
                    $AsyncResult = $tcpConnection.BeginConnect($Computername, $item, $null, $null)
                    $Wait = $AsyncResult.AsyncWaitHandle.WaitOne($TCPtimeout) 
                }
                catch { $Wait = $false }

                If ($Wait) {  
            
                    write-host "Host" $Computername "Port: " $item "Service: " $service "is open"
                    $tcpStream = $tcpConnection.GetStream() 
                        

                    if (443, 4398, 4433, 4444, 995, 993, 990, 992, 636, 465, 115, 989, 1723, 3713, 8043,8081, 9000, 9090 -contains $item ) {
                           
                        
                                                       
                        try {
                            

                            $sslStream = New-Object System.Net.Security.SslStream($tcpStream, $True, $Callback)

                            $sslStream.ReadTimeout = 5000
                            $sslStream.WriteTimeout = 5000
                            $sslStream.AuthenticateAsClient($Computername)
                            #Read the certificate
                            $certinfo = New-Object system.security.cryptography.x509certificates.x509certificate2($sslStream.RemoteCertificate)
                            $expires = $certinfo.GetExpirationDateString().Trim()
                            $template = 'M/d/yyyy h:mm:ss tt'
                            $certExpDate = [DateTime]::ParseExact($expires, $template, [System.Globalization.CultureInfo]::InvariantCulture)
                         
                            
                            [int]$certExpiresIn = ($certExpDate - $(get-date)).Days
                            $certinfo.Dispose()
                            
                            if ($certexpiresin -ge 60) { $cf = "<p style=`"color:green`">" }
                            if ($certexpiresin -le 59) { $cf = "<p style=`"color:blue`">" }
                            if ($certexpiresin -le 30) {
                                $cf = "<p style=`"color:red`">" 
                                $expiredcount = $expiredcount + 1
                            }
                            $cb = "</p>"
                            
                            $expires = $cf + $expires + " (" + $certExpiresIn + " day(s))" + $cb


                        }
                        catch { 
                            write-warning $Error[0]
                        }
                        
                        if ($sslStream.IsAuthenticated) {
                            $newstream = $sslStream
                            $sslconnection = 1
                            write-warning -message "Authenticated"
                        }
                        else {
                            $newstream = $tcpStream
                            write-warning -message "Not Authenticated"
                        }
                        
                    }
                    else { $newstream = $tcpStream }
                    <# SSL Attempt end#>
        
                    $tcpConnection.ReceiveTimeout = 2000;
                    $tcpConnection.SendTimeout = 2000;
           
                    $reader = New-Object System.IO.StreamReader($newstream)
                    $writer = New-Object System.IO.StreamWriter($newstream)
                    $writer.AutoFlush = $true
                   
                    try {
                
                        switch ( $item ) {
                    ({ 80, 443, 631, 4398, 4433, 4444, 8043, 8080,8081, 9000, 9090 -contains $PSItem }) {
                                $writer.WriteLine($trig_http)
                                if ($sslconnection -eq 1) {
                            
                                    $link = "<a href=`"https://$Computername`:$item`" target=`"_blank`">https://$Computername`:$item</a>"
                                }
                                else { $link = "<a href=`"http://$Computername`:$item`" target=`"_blank`">http://$Computername`:$item</a>" }
                                break;
                            }
                    ({ 25, 26, 465, 587 -contains $PSItem }) {
                                $writer.WriteLine($trig_smtp)
                                if ($sslconnection -eq 1) {
                            
                                    $link = "<a href=`"ssh://$Computername`:$item`" target=`"_blank`">ssh://$Computername`:$item</a>"
                                }
                                else { $link = "<a href=`"telnet://$Computername`:$item`" target=`"_blank`">telnet://$Computername`:$item</a>" }
                                break;
                            }
                            ({ 22 -contains $PSItem }) {
                                $link = "<a href=`"ssh://$Computername`:$item`" target=`"_blank`">ssh://$Computername`:$item</a>"
                                break;
                            }
                    
                    ({ 143, 993 -contains $PSItem }) {
                                $writer.WriteLine($trig_imap)
                                if ($sslconnection -eq 1) {
                            
                                    $link = "<a href=`"ssh://$Computername`:$item`" target=`"_blank`">ssh://$Computername`:$item</a>"
                                }
                                else { $link = "<a href=`"telnet://$Computername`:$item`" target=`"_blank`">telnet://$Computername`:$item</a>" }
                                break;
                            }
                    ({ 21, 69, 247, 1758, 1818, 3713 -contains $PSItem }) {
                                $writer.WriteLine($trig_ftp)
                                $link = "<a href=`"ftp://$Computername`:$item`" target=`"_blank`">ftp://$Computername`:$item</a>"
                                break;
                            }
                    ({ 23 -contains $PSItem }) {
                                $writer.WriteLine($trig_telnet)
                                if ($sslconnection -eq 1) {
                            
                                    $link = "<a href=`"ssh://$Computername`:$item`" target=`"_blank`">ssh://$Computername`:$item</a>"
                                }
                                else { $link = "<a href=`"telnet://$Computername`:$item`" target=`"_blank`">telnet://$Computername`:$item</a>" }
                                break;
                            }
                    ({ 109, 110, 995 -contains $PSItem }) {
                                $writer.WriteLine($trig_pop)
                                if ($sslconnection -eq 1) {
                            
                                    $link = "<a href=`"ssh://$Computername`:$item`" target=`"_blank`">ssh://$Computername`:$item</a>"
                                }
                                else { $link = "<a href=`"telnet://$Computername`:$item`" target=`"_blank`">telnet://$Computername`:$item</a>" }
                                break;
                            }
                    ({ 119 -contains $PSItem }) {
                                $writer.WriteLine($trig_nntp)
                                break;
                            }
                    ({ 137 -contains $PSItem }) {
                                $writer.WriteLine($trig_nbns)
                                break;
                            }
                    ({ 389, 636 -contains $PSItem }) {
                                $writer.WriteLine($trig_ldap)
                                break;
                            }
                     ({ 1433 -contains $PSItem }) {
                                $writer.WriteLine($trig_mssql)
                                break;
                            }
                    ({ 162 -contains $PSItem }) {
                                $writer.WriteLine($trig_snmp)
                                break;
                            }
                 
                    ({ 123 -contains $PSItem }) {
                                $writer.WriteLine($trig_ntp)
                                break;
                            }
                     ({ 79 -contains $PSItem }) {
                                $writer.WriteLine($trig_finger)
                                break;
                            }
                     ({ 7, 9 -contains $PSItem }) {
                                $writer.WriteLine($trig_echo)
                                break;
                            }
                     ({ 256 -contains $PSItem }) {
                                $writer.WriteLine($trig_fw1admin)
                                break;
                            }
                            Default {
                                $writer.WriteLine($trig_null)
                                break;
                            }
                        }

                        
                        try {
                            try {
                                while (($reader.Peek() -ne -1) -and ($reader.Peek() -ne 0)) {         
                                    $character = [char]$reader.Read()
                                    if (((([byte][char]$character -ge 32) -and ([byte][char]$character -le 126)) -or (13, 10, 9 -contains [byte][char]$character) )) {
                                        $rts += $character
                                    }
                                    else { $rts += "{0:X2} " -f [byte][char]$character }
                                    
                                }
                            }
                            finally {
                                $rts = $rts -replace '<.*?>', ''
                                $rts = "<textarea rows=`"5`" readonly>" + $rts + "</textarea>" 
                            }
                        }
                        catch {
                            Write-Warning  $Error[0]
                                
                        }
                         
    
                    }
                    catch {
                        Write-Warning  $Error[0]
                            
                    }

                    
                    #$rts = $rts -replace "`r`n", "<br>"          
                    write-host $Computername $rts

                   
                    $requestelapsedTime = $(get-date) - $requestStartTime

                    $requesttotalTime = $requestelapsedTime.TotalMilliseconds.tostring()+" ms"
                    
                   
                    if ($link -eq "") { $link = $Computername }
                    $totalPortsOpen = $totalPortsOpen + 1
                    if ($totalPortsOpen % 2 -eq 0 ) { $BGCOLORT = "lightgrey" } else { $BGCOLORT = "white" }
                    
                    $report = $report + "<tr bgcolor=`"$BGCOLORT`"><td>" + $link + "</td><td>" + $dnsRecord + "</td><td>" + $groupname + "</td><td>" + $expires + "</td><td>" + $item + "</td><td><p style=`"color:red`">Yes</p></td><td>" + $service + "</td><td>"+$requesttotalTime+"</td><td><p style=`"color:blue`">" + $rts + "</p></td></tr>" 
                }
                else { $totalPortsClosed = $totalPortsClosed + 1 }
            }
            finally {
                try {
                    $reader.Close()
                }
                Catch {}
                try {
                    $writer.Close()
                }
                catch {}

                try {
                    $newstream.Close()
                }
                catch {}
                try {
                    $sslStream.Close()
                }
                catch {}
                try {
                    $tcpStream.Close()
                }
                catch {}

                try { 
                    $tcpConnection.Close()
                } 
                catch {}
            }    
        }#end foreach
                
    }#end if
}#end foreach

    
$elapsedTime = $(get-date) - $StartTime

$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
$totalcomputers = $Computernamearray.Count

$stats = "<table border=`"0`" cellpadding=`"0`" cellspacing=`"0`" align=`"center`" bgcolor=`"#FFFFFF`" width=`"560`" style=`"border-collapse: collapse; border-spacing: 0; padding: 0; width: inherit;max-width: 600px;`" class=`"container`">"

$stats = $stats + "<tr><td align=`"center`" valign=`"top`" style=`"border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0; padding-bottom: 3px; padding-left: 15px; padding-right: 15px; width: auto; font-size: 18px; font-weight: 300; line-height: 150%;padding-top: 5px;color: #000000;font-family: sans-serif;`" class=`"subheader`">"
$stats = $stats + "<div class=`"flex-container`">"
$stats = $stats + "<div class=`"flex-item`"><b>Version: </b>" + $version + "</div>"
$stats = $stats + "<div class=`"flex-item`"><b>Time Running: </b>" + $totaltime + "</div>"
$stats = $stats + "<div class=`"flex-item`"><b>Total Gateways Scanned: </b>" + $totalComputers + "</div>"
$stats = $stats + "<div class=`"flex-item`"><b>Total Ports Scanned: </b>" + ($totalPortsopen + $totalPortsClosed) + "</div>"
$stats = $stats + "<div class=`"flex-item`"><b>Total Ports Open: </b>" + $totalPortsOpen + "</div>"
$stats = $stats + "<div class=`"flex-item`"><b>Total Ports Closed: </b>" + $totalPortsClosed + "</div>"
$stats = $stats + "<div class=`"flex-item`"><b>Total Certs Expiring or Expired: </b>" + $expiredcount + "</div>"
$stats = $stats + "</div></td></tr></table>"


$report = $report -replace "%stats%", "$stats"
      

$report = $report + "</table></body></html>"

$message = new-object Net.Mail.MailMessage;
    
$message.From = $smtpfrom;
$message.To.Add($smtpto);
$message.Subject = $strcomputer + " Open Port Report " + (get-date) ;
$message.IsBodyHTML = $true
$message.Body = $report
    
set-Content -Path c:\support\openports.html -Value $report
$smtp = new-object Net.Mail.SmtpClient($smtpserver, $smtpport);
$smtp.EnableSSL = $true;
$smtp.Credentials = New-Object System.Net.NetworkCredential($sendUsername, $sendPassword);
$smtp.send($message);
write-host "Mail Sent to "  $smtpto ; 
