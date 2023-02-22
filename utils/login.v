module utils

import crypto.sha256
import time

fn (mut app App) login(mut user &User, username string, password string) !Account {
	account := app.get_account_by_pseudo(username)
	if sha256.hexhash(account.salt+sha256.hexhash(password)) == account.password {
		if app.is_pseudo_connected(username) {
			return error("Already connected")
		}
		message := Message{
			message: "0Welcome $username !"
			author_id: 0
			receiver_id: account.id
			timestamp: time.now().microsecond
		}
		user.send_encrypted_message(message, false, mut app) or {
			return error("Error while sending welcome")
		}
		return account
	}

	return error("Wrong password !")
}