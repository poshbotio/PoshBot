
# A card is a special type of response with specific formatting
class Card : Response {
    [string]$Summary
    [string]$Title
    [string]$FallbackText
    [string]$Link
    [string]$ImageUrl
    [string]$ThumbnailUrl
    [hashtable]$Fields
}
