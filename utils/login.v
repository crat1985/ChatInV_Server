module utils

import crypto.sha256

fn (mut app App) login(mut user &User, username string, password string) (string, string) {
	account := app.get_account_by_pseudo(username)
	if sha256.hexhash(account.salt+password) == account.password {
		if app.is_pseudo_connected(username) {
			if user.send_message("1Already connected !") {
				return "Error while sending already connected !", ""
			}
			return "Already connected", ""
		}

		if user.send_message("0Welcome $username !") {
			return "Error while sending welcome", ""
		}
		return "", username
	}

	println("[LOG] ${user.peer_ip() or {"IPERROR"}} => 'Wrong password !'")
	if user.send_message("1Wrong password !") {
		return "Error while sending 'Wrong password' to ${user.peer_ip() or {"IPERROR"}}", ""
	}
	return "Wrong password !", ""
}