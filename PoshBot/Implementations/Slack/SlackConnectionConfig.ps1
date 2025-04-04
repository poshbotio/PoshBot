class SlackConnectionConfig : ConnectionConfig {
    [securestring]$WebSocketToken
    [securestring]$BotToken
}
