
# Out custom attribute that external modules can decorate
# command with. This controls the command behavior when imported
Add-Type -TypeDefinition @"
namespace PoshBot {

    public enum TriggerType {
        Command,
        Event,
        Regex,
        Timer
    }

    public class BotCommand : System.Attribute {
        public string CommandName { get; set; }
        public bool HideFromHelp { get; set; }
        public string Regex { get; set; }
        public string MessageType { get; set; }
        public string MessageSubtype { get; set; }
        public string[] Permissions { get; set; }

        private TriggerType _triggerType = TriggerType.Command;
        private bool _command = true;
        private bool _keepHistory = true;

        public TriggerType TriggerType {
            get { return _triggerType; }
            set { _triggerType = value; }
        }

        public bool Command {
            get { return _command; }
            set { _command = value; }
        }

        public bool KeepHistory {
            get { return _keepHistory; }
            set { _keepHistory = value; }
        }
    }

    public class FromConfig : System.Attribute {
        public string Name { get; set; }

        public FromConfig() {}

        public FromConfig(string Name) {
            this.Name = Name;
        }
    }
}
"@
