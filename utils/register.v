module utils

import rand
import crypto.sha256
import time

fn (mut app App) register(mut user &User, username string, password string) !Account {
	if username.contains(" ") || username.contains("\t") || username.contains("\n") {
		return error("Pseudo cannot contains spaces !")
	}
	mut pseudo_error := false
	for index, c in username {
		if index == 0 {
			if !c.is_letter() {
				pseudo_error = true
				break
			}
		} else if !c.is_alnum() && c.ascii_str() != '_' {
			pseudo_error = true
			break
		}
	}
	if pseudo_error {
		return error("Pseudo must begin with a letter and must contains only letters, numbers and underscores !")
	}
	if username.len < 3 || password.len < 8 {
		message := Message{
			message: "1Username or password too short !"
			author_id: 0
			receiver_id: -1
			timestamp: time.now().microsecond
		}
		user.send_encrypted_message(message, false, mut app) or {
			return error("Error while sending username or password too short !")
		}
		return error("Username or password too short !")
	}
	if app.account_exists(username) {
		message := Message{
			message: "1Account with same username already exists !"
			author_id: 0
			receiver_id: -1
			timestamp: time.now().microsecond
		}
		user.send_encrypted_message(message, false, mut app) or {
			return error("Error while sending account with same username already exists !")
		}
		return error("Account with same username already exists !")
	}
	mut account := Account{
		username: username
		password: sha256.hexhash(password)
		salt: rand.ascii(8)
		created: time.now().microsecond
	}
	account.password = sha256.hexhash(account.salt+account.password)
	app.insert_account(account)
	mut message := Message{
		message: "0Account $username created !"
		author_id: 0
		receiver_id: account.id
		timestamp: time.now().microsecond
	}
	user.send_encrypted_message(message, false, mut app) or {
		return error("Error while sending welcome")
	}
	message = Message{
		message: "Welcome $username !"
		author_id: 0
		receiver_id: account.id
		timestamp: time.now().microsecond
	}
	user.send_encrypted_message(message, true, mut app) or {
		return err
	}
	message = Message{
		message: "$username just created his account !"
		author_id: 0
		receiver_id: 0
		timestamp: time.now().microsecond
	}
	account = app.get_account_by_pseudo(account.username)
	app.broadcast(message, user)
	return account
}