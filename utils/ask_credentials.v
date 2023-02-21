module utils

import time

pub fn (mut app App) ask_credentials(mut user &User) (string, Account) {
	mut data := []u8{len: 1024}
	data_length := user.read(mut data) or {
		eprintln(err)
		return "Cannot read credentials", Account{}
	}
	//removing null bytes
	data = data[..data_length]
	if data.len == 0 {
		return "Bad credentials 0", Account{}
	}
	mut credentials_string := user.decrypt_string(data) or {
		return "Cannot decrypt credentials", Account{}
	}
	//getting mode
	credentials_string_length := credentials_string#[..5].int()
	if credentials_string_length == 0 {
		return "Bad credentials length !", Account{}
	}
	credentials_string = credentials_string#[5..]
	if credentials_string.len == 0 {
		return "Credentials too short !", Account{}
	}
	credentials_string = credentials_string#[..credentials_string_length]
	if credentials_string.len <= 1 {
		return "Bad credentials 3 !", Account{}
	}
	mode := credentials_string[0].ascii_str()
	credentials_string = credentials_string#[1..]
	if credentials_string.len == 0 {
		return "Credentials too short !", Account{}
	}
	//getting username length
	username_length := credentials_string#[..2].int()
	if username_length == 0 {
		return "Bad username length !", Account{}
	}
	credentials_string = credentials_string#[2..]
	if credentials_string.len == 0 {
		return "Bad credentials !", Account{}
	}
	// getting username
	username := credentials_string#[..username_length]
	if username.len == 0 {
		return "Username too short !", Account{}
	}
	credentials_string = credentials_string#[username_length..]
	if credentials_string.len == 0 {
		return "Credentials too short !", Account{}
	}
	//getting password
	password_length := credentials_string#[..2].int()
	if password_length == 0 {
		return "Bad password length !", Account{}
	}
	credentials_string = credentials_string#[2..]
	if credentials_string.len == 0 {
		return "Credentials too short !", Account{}
	}
	password := credentials_string#[..password_length]
	if password.len == 0 {
		return "Password too short !", Account{}
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
					return "Failed to send \"the server is private ! Cannot create an account !\"", Account{}
				}
				return "The server is private ! Cannot create an account !", Account{}
			}
			$else { return app.register(mut user,  username, password) }
		}
		else { return "Else block executed ! This should never happen !", Account{} }
	}
	return "This should never happen !", Account{}
}