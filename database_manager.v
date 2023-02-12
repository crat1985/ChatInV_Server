module main

import db.sqlite
import crypto.sha256
import rand
import utils
import os

fn main() {
	mut db := sqlite.connect("accounts.db") or {
		panic(err)
	}
	sql db {
		create table utils.Account
	}

	for {
		mut command := os.input("> ")
		command = command.to_lower()
		if command == "help" || command == "?" {
			println("Commands :")
			println("help/? => Display this help.")
			println("list => Display all accounts.")
			println("     -a => Display all infos about each account.")
			println("exit => Exit the program.")
		}
		if command == "exit" {
			break
		}
		if command.starts_with("list") {
			mut verbose := false
			if command.ends_with("-a") {
				verbose = true
			}
			for account in sql db {
				select from utils.Account
			} {
				println("------------------------------")
				println("Account n°${account.id}")
				println("Username : ${account.username}")
				if verbose {
					println("Password : ${account.password}")
					println("Salt : ${account.salt}")
				}
			}
		}
	}

	salt := rand.ascii(8)
	password := sha256.hexhash(salt+sha256.hexhash("mdr"))
	account := utils.Account{
		username: 'Riccardo'
		password: password
		salt: salt
	}
	sql db {
		insert account into utils.Account
	}
}