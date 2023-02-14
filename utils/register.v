module utils

import rand
import crypto.sha256

fn (mut app App) register(mut user &User, username string, password string) (string, string) {
	if username.contains(" ") || username.contains("\t") || username.contains("\n") {
		return "Pseudo cannot contains spaces !", ""
	}
	mut error := false
	for index, c in username {
		if index == 0 {
			if !c.is_letter() {
				error = true
				break
			}
		} else if !c.is_alnum() && c.ascii_str() != '_' {
			error = true
			break
		}
	}
	if error {
		return "Pseudo must begin with a letter and must contains only letters, numbers and underscores !", ""
	}
	if username.len < 3 || password.len != 64 {
		if user.send_message("1Username or password too short !") {
			return "Error while sending username or password too short !", ""
		}
		return "Username or password too short !", ""
	}
	if app.account_exists(username) {
		if user.send_message("1Account with same username already exists !") {
			return "Error while sending account with same username already exists !", ""
		}
		return "Account with same username already exists !", ""
	}
	mut account := Account{
		username: username
		password: password
		salt: rand.ascii(8)
	}
	account.password = sha256.hexhash(account.salt+account.password)
	app.insert_account(account)
	if user.send_message("0Account $username created !") {
		return "Error while sending welcome", ""
	}
	user.send_message("Welcome $username")
	app.broadcast("$username just created his account !", user)
	return "", username
}