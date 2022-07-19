function sendMail {
    param($To, $From, $Subject, $Body, $smtpServer)
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $From
    $msg.To.Add($To)
    $msg.Subject = $Subject
    $msg.IsBodyHtml = 1
    $msg.Body = $Body
    $smtp.Send($msg)
    }
    
    $ipaddress = Get-NetIpAddress
    sendMail -To "human@email.com" -From "robot@email.com" -Subject "This is a test email from" -Body "Testing 1,2,3 from [add domain name]" -smtpServer smtp.serverName.com