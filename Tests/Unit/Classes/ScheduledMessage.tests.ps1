InModuleScope PoshBot {

    Describe ScheduledMessage {
        # Mock a message
        $msg = [Message]::new()
        $msg.Id = 1
        $msg.Text = "This is a test message"

        # Call constructor
        $Interval = 'Days'
        $TimeValue = 1
        $Message = $msg
        $StartAfter = (Get-Date).AddMinutes(1)

        Context "Constructor: String, Int, Message, DateTime" {

            $ScheduledMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message, $StartAfter)

            It 'TimeInterval should match argument' {
                $ScheduledMessage.TimeInterval | Should be $Interval
            }

            It 'TimeValue should match argument' {
                $ScheduledMessage.TimeValue | Should be $TimeValue
            }

            It 'Message Id should be 1' {
                $ScheduledMessage.Message.Id | Should be 1
            }
            It 'Message Text should match argument' {
                $ScheduledMessage.Message.Text | Should match $msg.Text
            }

            It 'StartAfter value should match argument converted to UTC' {
                $ScheduledMessage.StartAfter | Should be $StartAfter.ToUniversalTime()
            }
        }

        Context "Methods" {

        }

    }

}
