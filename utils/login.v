module utils

import crypto.sha256
import time

fn (mut app App) login(mut user &User, username string, password string) (string, Account) {
	account := app.get_account_by_pseudo(username)
	if sha256.hexhash(account.salt+password) == account.password {
		if app.is_pseudo_connected(username) {
			message := Message{
				message: "1Already connected !"
				author_id: 0
				receiver_id: -1
				timestamp: time.now().microsecond
			}
			if user.send_message(message, true, mut app) {
				return "Error while sending already connected !", Account{}
			}
			return "Already connected", Account{}
		}
		message := Message{
			message: "0Welcome $username !"
			author_id: 0
			receiver_id: account.id
			timestamp: time.now().microsecond
		}
		if user.send_message(message, true, mut app) {
			return "Error while sending welcome", Account{}
		}
		return "", account
	}

	println("[LOG] ${user.peer_ip() or {"IPERROR"}} => 'Wrong password !'")
	message := Message{
		message: "1Wrong password !"
		author_id: 0
		receiver_id: -1
		timestamp: time.now().microsecond
	}
	if user.send_message(message, true, mut app) {
		return "Error while sending 'Wrong password' to ${user.peer_ip() or {"IPERROR"}}", Account{}
	}
	return "Wrong password !", Account{}
}