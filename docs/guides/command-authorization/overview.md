
# Command Authorization

PoshBot includes a simple yet effect Role Based Access Control (RBAC) model that you can apply to your bot commands.
While it would be great if everyone could execute everything, many commands in your ChatOps environment may be sensitive in nature or particularly powerful, requiring an extra degree of control over who can execute what.

PoshBot uses the concept of **permissions**, **roles**, and **groups** to optionally control execution of commands. It is the union of these constructs and the **user** that secures the command.
