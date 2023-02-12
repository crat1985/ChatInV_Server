module main

import db.sqlite
import crypto.sha256
import rand
import os

[table: 'account']
pub struct Account {
	pub mut:
	id int [primary; sql: serial]
	username string [nonnull]
	password string [nonnull]
	salt string [nonnull]
}

fn main() {
	mut db := sqlite.connect("accounts.db") or {
		panic(err)
	}
	sql db {
		create table Account
	}

	for {
		mut command := os.input("> ")
		command_lower := command.to_lower()
		if command_lower == "help" || command == "?" {
			println("Commands :")
			println("help/? => Display this help.")
			println("list => Display all accounts.")
			println("     -a => Display all infos about each account.")
			println("add <username> <password> => Add an account to the database.")
			println("exit => Exit the program.")
		}
		if command_lower == "exit" {
			break
		}
		if command_lower.starts_with("list") {
			mut verbose := false
			if command.ends_with("-a") {
				verbose = true
			}
			for account in sql db {
				select from Account
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
		if command_lower.starts_with("add ") {
			command = command[4..]
			if command.len < 7 {
				println("Syntax : add <username> <password>")
				continue
			}
			infos := command.split(" ")
			if infos.len < 2 {
				println("Syntax : add <username> <password>")
				continue
			}
			username := infos[0]
			if username.len < 3 {
				println("Length of username must be greater than 2 !")
				continue
			}
			password := infos[1]
			mut error := false
			for i, c in username {
				if i == 0 {
					if !c.is_letter() {
						error = true
						break
					}
				} else {
					if !c.is_alnum() && c != "_".u8() {
						error = true
						break
					}
				}
			}
			if error {
				println("Username must begin with a letter and contains only letters, numbers and underscores !")
				continue
			}
			if password.len < 8 {
				println("Password must be at least 8 characters long !")
				continue
			}
			insert_account(username, password, db)
		}
	}
}

fn insert_account(username string, clear_password string, db sqlite.DB) {
	salt := rand.ascii(8)
	password := sha256.hexhash(salt+sha256.hexhash(clear_password))
	account := Account{
		username: username
		password: password
		salt: salt
	}
	sql db {
		insert account into Account
	}

	println("Successfully added account in the database !")
}