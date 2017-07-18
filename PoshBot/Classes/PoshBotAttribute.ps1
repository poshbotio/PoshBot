
# Out custom attribute that external modules can decorate
# command with. This controls the command behavior when imported
# https://msdn.microsoft.com/en-us/library/84c42s56(v=vs.110).aspx

Add-Type -TypeDefinition @"
namespace PoshBot {

    public enum TriggerType {
        Command,
        Event,
        Regex,
        Timer
    }

    public class BotCommand : System.Attribute {

        private string _commandName;
        private string[] _aliases;
        private string[] _permissions;
        private bool _hideFromHelp;
        private string _regex;
        private string _messageType;
        private string _messageSubtype;
        private TriggerType _triggerType = TriggerType.Command;
        private bool _command = true;
        private bool _keepHistory = true;

        public BotCommand() {}

        public virtual string CommandName {
            get { return _commandName; }
            set { _commandName = value; }
        }

        public virtual string[] Aliases {
            get { return _aliases; }
            set { _aliases = value; }
        }

        public virtual string[] Permissions {
            get { return _permissions; }
            set { _permissions = value; }
        }

        public virtual bool HideFromHelp {
            get { return _hideFromHelp; }
            set { _hideFromHelp = value; }
        }

        public virtual string Regex {
            get { return _regex; }
            set { _regex = value; }
        }

        public virtual string MessageType {
            get { return _messageType; }
            set { _messageType = value; }
        }

        public virtual string MessageSubtype {
            get { return _messageSubtype; }
            set { _messageSubtype = value; }
        }

        public virtual TriggerType TriggerType {
            get { return _triggerType; }
            set { _triggerType = value; }
        }

        public virtual bool Command {
            get { return _command; }
            set { _command = value; }
        }

        public bool KeepHistory {
            get { return _keepHistory; }
            set { _keepHistory = value; }
        }
    }

    public class FromConfig : System.Attribute {

        private string _name;

        public FromConfig() {}

        public FromConfig(string Name) {
            this.Name = Name;
        }

        public virtual string Name {
            get { return _name; }
            set { _name = value; }
        }
    }
}
"@
