open Discord

let data =
  SlashCommandBuilder.make()
  ->SlashCommandBuilder.setName("Verify Members")
  ->SlashCommandBuilder.setDescription(
    "Assigns the BrightId role to all users who have been verified previously",
  )
