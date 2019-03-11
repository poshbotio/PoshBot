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

        Context "Constructor: String, Int, Message" {

            $ScheduledMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message)

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

            It 'Should have a StartAfter value without passing the argument' {
                $ScheduledMessage.StartAfter | Should not BeNullOrEmpty
            }
        }

        Context "Methods: Init()" {

            $Intervals = @(
                @{
                    Interval = 'Days'
                    MS = 86400000
                },
                @{
                    Interval = 'Hours'
                    MS = 3600000
                },
                @{
                    Interval = 'Minutes'
                    MS = 60000
                },
                @{
                    Interval = 'Seconds'
                    MS = 1000
                }
            )

            foreach ($Type in $Intervals) {
                It "Should calculate milliseconds for single $($Type.Interval) correctly" {
                    $ScheduledMessage = [ScheduledMessage]::new($Type.Interval, 1, $Message)
                    $ScheduledMessage.IntervalMS | Should be (1 * $Type.MS)
                }

                It "Should calculate milliseconds for multiple $($Type.Interval) correctly" {
                    $ScheduledMessage = [ScheduledMessage]::new($Type.Interval, 5, $Message)
                    $ScheduledMessage.IntervalMS | Should be (5 * $Type.MS)
                }
            }

        }

        Context "Method: HasElapsed()" {
            $ElapsedMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message, (Get-Date).AddHours(-5))
            $ScheduledMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message, (Get-Date).AddHours(5))

            It 'Should return true when past the StartAfter DateTime' {
                $ElapsedMessage.HasElapsed() | Should be $true
            }

            It 'Should return false when before the StartAfter DateTime' {
                $ScheduledMessage.HasElapsed() | Should Not be $true
            }

            It 'TimesExecuted should be 1 after executing' {
                $ElapsedMessage.TimesExecuted | Should be 1
            }

        }

        Context "Method: Disable()" {
            $ScheduledMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message, (Get-Date))

            It 'Disables the instance when called' {
                $ScheduledMessage.Disable()
                $SceduleMessage.Enabled | Should Not be $true
            }

            It 'Does not throw an error when being called on an already-disabled instance' {
                $ScheduledMessage.Disable()
                $ScheduledMessage.Enabled | Should Not be $true
            }
        }

        Context "Method: Enable()" {
            $ScheduledMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message, (Get-Date))

            It 'Enables the instance when called' {
                $ScheduledMessage.Disable()
                $ScheduledMessage.Enable()
                $ScheduledMessage.Enabled | Should be $true
            }

            It 'Does not throw an error when being called on an already-enabled instance' {
                $ScheduledMessage.Enable()
                $ScheduledMessage.Enabled | Should be $true
            }
        }

        Context "Method: RecalculateStartAfter()" {
            It 'Should increase the StartAfter property by IntervalMS' {
                $ScheduledMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message, (Get-Date))

                $StartingValue = $ScheduledMessage.StartAfter
                $ScheduledMessage.RecalculateStartAfter()

                (New-TimeSpan $StartingValue $ScheduledMessage.StartAfter).TotalDays | Should Be 1
            }

            It 'Should not reschedule a run before the current time' {
                $currentDate = (Get-Date).ToUniversalTime();
                $startAfter = $currentDate.AddDays(-5);
                $ScheduledMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message, $startAfter)

                $ScheduledMessage.RecalculateStartAfter();

                $ScheduledMessage.StartAfter | Should Not BeLessThan $currentDate
            }

            It 'Should only move StartAfter value forward' {
                $StartingValue = (Get-Date).AddDays($daysDifference).ToUniversalTime()
                $ScheduledMessage = [ScheduledMessage]::new($Interval, $TimeValue, $Message, $StartingValue)

                $ScheduledMessage.RecalculateStartAfter()

                $ScheduledMessage.StartAfter | Should Be $StartingValue.AddDays(1)
            }
        }

    }

}
