module utils

import db.sqlite
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
		mode := credentials[0].ascii_str()
		credentials = credentials[1..]
		//getting username length
		username_length := credentials[0..2].bytestr().int()
		credentials = credentials[2..]
		// getting username
		username := credentials[0..username_length].bytestr()
		credentials = credentials[username_length..]
		//getting password length
		password_length := credentials[0..2].bytestr().int()
		credentials = credentials[2..]
		//getting password
		password := credentials[..password_length].bytestr()
		if mode == "l" { return app.login(mut user, username, password) }
		if mode == "r" { return app.register(mut user,  username, password) }
	}
	return "This should never happens", ""
}

fn (mut app App) login(mut user &User, username string, password string) (string, string) {
	account := app.get_account_by_pseudo(username)

	if sha256.hexhash(account.salt+password) == account.password {
		if app.is_pseudo_connected(username) {
			user.write_string("1Already connected !") or {
				return "Error while sending already connected !\n", ""
			}
			return "Already connected\n", ""
		}

		user.write_string("0Welcome $username") or {
			return "Error while sending welcome\n", ""
		}
		return "", username
	}

	println("[LOG] ${user.peer_ip() or {"IPERROR"}} => 'Wrong password !'")
	user.write_string("1Wrong password !\n") or {
		return "Error while sending 'Wrong password' to ${user.peer_ip() or {"IPERROR"}}", ""
	}
	return "This should never append !", ""
}

fn (mut app App) register(mut user &User, pseudo string, password string) (string, string) {
	username := pseudo.trim_space()
	if username.len < 3 || password.len < 8 {
		user.write_string("1Username or password too short !\n") or {
			return "Error while sending username or password too short !", ""
		}
		return "Username or password too short !", ""
	}
	if app.account_exists(username) {
		user.write_string("1Account with same username already exists !\n") or {
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
	user.write_string("0Welcome $username") or {
		return "Error while sending welcome\n", ""
	}
	user.write_string("0Account $username created !") or {
		return "Error while sending welcome\n", ""
	}
	app.broadcast("$username just created his account !".bytes(), user)
	return "", username
}

fn (mut app App) is_pseudo_connected(username string) bool {
	for user in app.users {
		if user.pseudo == username {
			return true
		}
	}
	return false
}