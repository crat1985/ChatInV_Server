module utils

import time

pub fn (mut app App) ask_credentials(mut user &User) !Account {
	mut data := []u8{len: 1024}
	data_length := user.read(mut data) or {
		return error("Cannot read credentials")
	}
	//removing null bytes
	data = data[..data_length]
	if data.len == 0 {
		return error("Bad credentials 0")
	}
	mut credentials_string := user.decrypt_string(data) or {
		return error("Cannot decrypt credentials")
	}
	//getting mode
	credentials_string_length := credentials_string#[..5].int()
	if credentials_string_length == 0 {
		return error("Bad credentials length !")
	}
	credentials_string = credentials_string#[5..]
	if credentials_string.len == 0 {
		return error("Credentials too short !")
	}
	credentials_string = credentials_string#[..credentials_string_length]
	if credentials_string.len <= 1 {
		return error("Bad credentials 3 !")
	}
	mode := credentials_string[0].ascii_str()
	credentials_string = credentials_string#[1..]
	if credentials_string.len == 0 {
		return error("Credentials too short !")
	}
	//getting username length
	username_length := credentials_string#[..2].int()
	if username_length == 0 {
		return error("Bad username length !")
	}
	credentials_string = credentials_string#[2..]
	if credentials_string.len == 0 {
		return error("Bad credentials !")
	}
	// getting username
	username := credentials_string#[..username_length]
	if username.len == 0 {
		return error("Username too short !")
	}
	credentials_string = credentials_string#[username_length..]
	if credentials_string.len == 0 {
		return error("Credentials too short !")
	}
	//getting password
	password_length := credentials_string#[..2].int()
	if password_length == 0 {
		return error("Bad password length !")
	}
	credentials_string = credentials_string#[2..]
	if credentials_string.len == 0 {
		return error("Credentials too short !")
	}
	password := credentials_string#[..password_length]
	if password.len == 0 {
		return error("Password too short !")
	}
	if credentials_string.len > password_length {
		eprintln("[LOG] More characters than expected, message : `${credentials_string[password_length..]}`")
	}
	match mode {
		"l" { return app.login(mut user, username, password) }
		"r" {
			$if private ? {
				message := Message{
					message: "1The server is private ! Cannot create an account !"
					author_id: 0
					receiver_id: -1
					timestamp: time.now().microsecond
				}
				if user.send_encrypted_message(message, false, mut app) {
					return error("Failed to send \"the server is private ! Cannot create an account !\"")
				}
				return error("The server is private ! Cannot create an account !")
			}
			$else { return app.register(mut user,  username, password) }
		}
		else { return error("Else block executed ! This should never happen !") }
	}
	return error("This should never happen !")
}