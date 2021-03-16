#!/bin/bash
write_index()
{
cat >> index.js << EOF
const { join } = require("path");
const CustomClient = require("./CustomClient");

const bot = new CustomClient();

(async () => {
    bot.loadCommands(join(__dirname, "commands"))
    bot.loadEvents(join(__dirname, "events"))
    bot.login()
})()
EOF
}
write_config()
{
	cat >> config.json << EOF
{
    "token": "insert bot token here",
    "prefix": "!",
	"owners": ["12345"]
}
EOF
}
write_custom_client()
{
cat >> CustomClient.js << EOF
const { Collection, Client } = require("discord.js");
const { lstatSync, readdirSync } = require("fs");
const { join } = require("path");
const { prefix, token } = require("./config.json")

class CustomClient extends Client {
	constructor() {
		super({
			partials: ["USER", "CHANNEL", "GUILD_MEMBER", "MESSAGE", "REACTION"],
		});
		this.commands = new Collection();
		this.prefix = prefix;
		this.owners = ["788927424166756363"];
	}
  	login(){
    	return super.login(token).catch((O_o) => console.log("Did you put your own token in config.json?"))
  	}
	loadCommands(dir){
		const files = readdirSync(dir);
		for (const file of files) {
			const stat = lstatSync(join(dir, file));
			if (stat.isDirectory()) {
				this.loadCommands(join(dir, file));
			} else {
				if (file.endsWith(".js")) {
					const command = require(join(dir, file));
					console.log("Loading command: " + command.name);
					this.commands.set(command.name, command);
				}
			}
		}
	}
	loadEvents(dir) {
		const files = readdirSync(join(dir));
		for (const file of files) {
			const stat = lstatSync(join(dir, file));
			if (stat.isDirectory()) {
				this.loadEvents(join(dir, file));
			} else {
				if (file.endsWith(".js")) {
					const event = require(join(dir, file));
					const eventName = file.split(".")[0];
					console.log("Loading event: " + eventName);
					super.on(eventName, event.bind(null, this));
				}
			}
		}
	}
} 

module.exports = CustomClient;
EOF
}
write_ping_command()
{
	cat >> ping.js << EOF
const { MessageEmbed } = require("discord.js")
module.exports = {
	name: "ping",
	aliases: ["ping"],
	async execute(bot, message, args){
		let embed = new MessageEmbed()
			.setColor("RED")
			.setTitle("Pong!")
			.setDescription("API Latency: " + bot.ws.ping + "ms");
		message.channel.send(embed);
	}
}
EOF
}
write_ready_event()
{
	cat >> ready.js << EOF
module.exports = (bot) => {
	console.log("Logged in as", bot.user.tag);
}
EOF
}
write_message_event()
{
		cat >> message.js << EOF
module.exports = (bot, message) => {
	const { prefix } = bot;
	if (!message.content.startsWith(prefix) || message.author.bot) return;

	const args = message.content.slice(prefix.length).trim().split(/ +/);
	const commandName = args.shift().toLowerCase();
	const command = bot.commands.get(commandName)
		|| bot.commands.find(cmd => cmd.aliases && cmd.aliases.includes(commandName));
	if (!command) return;
	try {
		command.execute(bot, message, args)
	} catch (error) {
		console.log(error)
		message.reply("There was an error running the command.")
	}
}
EOF
}
file_exists()
{
	FILE="$1"
if [ -f "$FILE" ]; then
	echo "$FILE exists -> Please remove $FILE before running again"
		exit
fi
}
dir_exists(){
	FILE="$1"
if [ -d "$FILE" ]; then
	echo "Directory \"$FILE\" exists -> Please remove $FILE directory before running again"
		exit
fi
}
init(){
	dir_exists src
	file_exists start.sh
	npm init -y
	npm i discord.js
}

init
mkdir "src"
printf "node src/index.js" >> start.sh
chmod +x start.sh
cd src
write_config
write_index
write_custom_client
mkdir "commands"
mkdir "events"
cd commands
write_ping_command
cd ../events
write_ready_event
write_message_event
echo "Now edit config.json, then run ./start.sh!"
