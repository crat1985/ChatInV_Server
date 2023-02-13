module utils

import crypto.sha256
import rand

pub fn (mut app App) ask_credentials(mut user &User) (string, string) {
	for {
		mut credentials := []u8{len: 1024}
		mut length := user.read(mut credentials) or {
			eprintln(err)
			return "Cannot read credentials", ""
		}
		//removing null bytes
		credentials = credentials[..length]
		mut data := credentials.bytestr()
		//getting mode
		if data.len < 10 {
			if user.send_message("1Bad credentials") {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		length = data[..5].int()
		data = data[5..]
		if data.len < length {
			if user.send_message("1Bad credentials") {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		credentials = data[..length].bytes()
		if credentials.len == 0 {
			if user.send_message("1Bad credentials") {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		mode := credentials[0].ascii_str()
		credentials = credentials[1..]
		//getting username length
		username_length := credentials[..2].bytestr().int()
		credentials = credentials[2..]
		if credentials.len < username_length {
			if user.send_message("1Bad credentials") {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		// getting username
		username := credentials[0..username_length].bytestr()
		credentials = credentials[username_length..]
		//getting password length
		if credentials.len < 2 {
			if user.send_message("1Bad credentials") {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		password_length := credentials[0..2].bytestr().int()
		credentials = credentials[2..]
		//getting password
		if credentials.len < password_length {
			if user.send_message("1Bad credentials") {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		password := credentials[..password_length].bytestr()
		if mode == "l" {
			error, pseudo, stop := app.login(mut user, username, password)
			if stop { return error, pseudo }
			continue
		}
		if mode == "r" {
			$if private ? {
				if user.send_message("1The server is private ! Cannot create an account !") {
					return "Failed to send \"the server is private ! Cannot create an account !\"", ""
				}
				return "The server is private ! Cannot create an account !", ""
			} $else {
				error, pseudo, stop := app.register(mut user,  username, password)
				if stop {
					return error, pseudo
				}
				continue
			}
		}
		break
	}
	return "This should never happens", ""
}

fn (mut app App) login(mut user &User, username string, password string) (string, string, bool) {
	for {
		account := app.get_account_by_pseudo(username)
		if sha256.hexhash(account.salt+password) == account.password {
			if app.is_pseudo_connected(username) {
				if user.send_message("1Already connected !") {
					return "Error while sending already connected !", "", true
				}
				return "Already connected", "", false
			}

			if user.send_message("0Welcome $username") {
				return "Error while sending welcome", "", true
			}
			return "", username, true
		}

		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => 'Wrong password !'")
		if user.send_message("1Wrong password !") {
			return "Error while sending 'Wrong password' to ${user.peer_ip() or {"IPERROR"}}", "", true
		}
		return "Wrong password !", "", false
	}
	return "This should never append !", "", true
}

fn (mut app App) register(mut user &User, pseudo string, password string) (string, string, bool) {
	username := pseudo.trim_space()
	mut error := false
	for index, i in username {
		if index == 0 {
			if !i.is_letter() {
				error = true
				break
			}
		} else if !i.is_alnum() && i != '_'.u8() {
			error = true
		}
	}
	if error {
		return "Pseudo must begin with a letter and must contains only letters, numbers and underscores !", "", false
	}
	if username.len < 3 || password.len < 8 {
		if user.send_message("1Username or password too short !") {
			return "Error while sending username or password too short !", "", true
		}
		return "Username or password too short !", "", false
	}
	if app.account_exists(username) {
		if user.send_message("1Account with same username already exists !") {
			return "Error while sending account with same username already exists !", "", true
		}
		return "Account with same username already exists !", "", false
	}
	mut account := Account{
		username: username
		password: password
		salt: rand.ascii(8)
	}
	account.password = sha256.hexhash(account.salt+account.password)
	app.insert_account(account)
	if user.send_message("0Account $username created !") {
		return "Error while sending welcome", "", true
	}
	user.send_message("Welcome $username")
	app.broadcast("$username just created his account !", user)
	return "", username, true
}

fn (mut app App) is_pseudo_connected(username string) bool {
	for user in app.users {
		if user.pseudo == username {
			return true
		}
	}
	return false
}