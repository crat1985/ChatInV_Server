module utils

import crypto.sha256
import rand

pub fn (mut app App) ask_credentials(mut user &User) (string, string) {
	for {
		mut credentials := []u8{len: 1024}
		length := user.read(mut credentials) or {
			eprintln(err)
			return "Cannot read credentials", ""
		}
		//removing null bytes
		credentials = credentials[0..length]
		//getting mode
		if credentials.len < 10 {
			user.write_string("1Bad credentials") or {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		mode := credentials[0].ascii_str()
		credentials = credentials[1..]
		//getting username length
		username_length := credentials[0..2].bytestr().int()
		credentials = credentials[2..]
		if credentials.len < username_length {
			user.write_string("1Bad credentials") or {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		// getting username
		username := credentials[0..username_length].bytestr()
		credentials = credentials[username_length..]
		//getting password length
		if credentials.len < 2 {
			user.write_string("1Bad credentials") or {
				return "Error while sending bad credentials !", ""
			}
			continue
		}
		password_length := credentials[0..2].bytestr().int()
		credentials = credentials[2..]
		//getting password
		if credentials.len < password_length {
			user.write_string("1Bad credentials") or {
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
				user.write_string("1The server is private ! Cannot create an account !") or {
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

	}
	return "This should never happens", ""
}

fn (mut app App) login(mut user &User, username string, password string) (string, string, bool) {
	for {
		account := app.get_account_by_pseudo(username)
		if sha256.hexhash(account.salt+password) == account.password {
			if app.is_pseudo_connected(username) {
				user.write_string("1Already connected !") or {
					return "Error while sending already connected !\n", "", true
				}
				return "Already connected\n", "", false
			}

			user.write_string("0Welcome $username") or {
				return "Error while sending welcome\n", "", true
			}
			return "", username, false
		}

		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => 'Wrong password !'")
		user.write_string("1Wrong password !\n") or {
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
		user.write_string("1Username or password too short !\n") or {
			return "Error while sending username or password too short !", "", true
		}
		return "Username or password too short !", "", false
	}
	if app.account_exists(username) {
		user.write_string("1Account with same username already exists !\n") or {
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
	user.write_string("0Account $username created !") or {
		return "Error while sending welcome\n", "", true
	}
	app.broadcast("$username just created his account !".bytes(), user)
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