
InModuleScope PoshBot {

    Describe CommandParser {

        Context 'Return object' {

            it 'Is a [ParsedCommand] object' {
                $msg = [Message]::new()
                $msg.Text = 'about'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.PSObject.TypeNames[0] | should be 'ParsedCommand'
            }
            it 'Has original command string' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.CommandString | should be 'foo --bar baz'
            }

            it 'Has a datetime stamp' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Time | should beoftype datetime
            }

            it 'Has message to/from' {
                $msg = [Message]::new()
                $msg.Text = 'foo'
                $msg.To = 'U3839FJDY'
                $msg.From = 'C938FJEUI'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.To | should be 'U3839FJDY'
                $parsedCommand.From | should be 'C938FJEUI'
            }

            it 'Has original message' {
                $msg = [Message]::new()
                $msg.Text = 'foo'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.OriginalMessage.PSObject.TypeNames[0] | should be 'Message'
                $parsedCommand.OriginalMessage.Text | should be 'foo'
            }
        }

        context 'Parsed Logic' {

            it 'Parses simple command' {
                $msg = [Message]::new()
                $msg.Text = 'status'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'status'
                $parsedCommand.Version | should benullorempty
            }

            it 'Parses simple command with version' {
                $msg = [Message]::new()
                $msg.Text = 'status:1.2.3'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'status'
                $parsedCommand.Version | should be '1.2.3'
            }

            it 'Parses fully qualified command' {
                $msg = [Message]::new()
                $msg.Text = 'builtin:status'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should be 'builtin'
                $parsedCommand.Command | should be 'status'
                $parsedCommand.Version | should benullorempty
            }

            it 'Parses fully qualified command with version' {
                $msg = [Message]::new()
                $msg.Text = 'builtin:status:0.5.0'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should be 'builtin'
                $parsedCommand.Command | should be 'status'
                $parsedCommand.Version | should be '0.5.0'
            }

            it 'Parses command with single named parameter' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.NamedParameters.bar | should be 'baz'
            }

            it 'Parses command with multiple named parameters' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar baz --asdf qwerty --number 42'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.NamedParameters.keys.count | should be 3
                $parsedCommand.NamedParameters.bar | should be 'baz'
                $parsedCommand.NamedParameters.asdf | should be 'qwerty'
                $parsedCommand.NamedParameters.number | should beoftype int
                $parsedCommand.NamedParameters.number | should be 42
            }

            it 'Parses command with an array value' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar "baz", "asdf", "qwerty"'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.NamedParameters.Keys.Count | should be 1
                $parsedCommand.NamedParameters.bar.Count | should be 3
                $parsedCommand.NamedParameters.bar[0] | should be 'baz'
                $parsedCommand.NamedParameters.bar[1] | should be 'asdf'
                $parsedCommand.NamedParameters.bar[2] | should be 'qwerty'
            }

            it 'Parses positional parameters' {
                $msg = [Message]::new()
                $msg.Text = 'foo bar baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.PositionalParameters.Count | should be 2
                $parsedCommand.PositionalParameters[0] | should be 'bar'
                $parsedCommand.PositionalParameters[1] | should be 'baz'
            }

            It 'Parses switch parameters' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar --baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.NamedParameters.Keys.Count | should be 2
                $parsedCommand.NamedParameters.bar | should be $true
                $parsedCommand.NamedParameters.baz | should be $true
            }

            It 'Parses complex command' {
                $msg = [Message]::new()
                $msg.Text = 'myplugin:foo:1.0.0 "pos1" 12345 --bar baz --asdf "qwerty", "42" --named3 3333'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should be 'myplugin'
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should be '1.0.0'
                $parsedCommand.NamedParameters.Keys.Count | should be 3
                $parsedCommand.NamedParameters.bar | should be 'baz'
                $parsedCommand.NamedParameters.asdf.Count | should be 2
                $parsedCommand.NamedParameters.asdf[0] | should be 'qwerty'
                $parsedCommand.NamedParameters.asdf[1] | should be 42
                $parsedCommand.NamedParameters.named3 | should be 3333
                $parsedCommand.PositionalParameters.Count | should be 2
                $parsedCommand.PositionalParameters[0] | should be 'pos1'
                $parsedCommand.PositionalParameters[1] | should be 12345
            }

            It 'Parses command with @mentions' {
                $msg = [Message]::new()
                $msg.Text = 'givekarma @devblackops 100'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.PositionalParameters.Count | should be 2
                $parsedCommand.PositionalParameters[0] | should be '@devblackops'
                $parsedCommand.PositionalParameters[1] | should be 100
            }

            It "Doesn't replace '--' in command string values, only parameter names" {
                $msg = [Message]::new()
                $msg.Text = "shorten --url 'http://abc--123-asdf--qwerty.mydomain.tld:()"
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.NamedParameters['url'] | should be 'http://abc--123-asdf--qwerty.mydomain.tld:()'
            }
        }
    }
}
