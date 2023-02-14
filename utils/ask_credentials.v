module utils

pub fn (mut app App) ask_credentials(mut user &User) (string, string) {
	mut data := []u8{len: 1024}
	data_length := user.read(mut data) or {
		eprintln(err)
		return "Cannot read credentials", ""
	}
	//removing null bytes
	data = data[..data_length]
	mut credentials_string := data.bytestr()
	//getting mode
	if credentials_string.len < 10 {
		if user.send_message("1Bad credentials") {
			return "Error while sending bad credentials 1 !", ""
		}
		return "Bad credentials 1", ""
	}
	credentials_string_length := credentials_string[..5].int()
	credentials_string = credentials_string[5..]
	if credentials_string.len < credentials_string_length {
		if user.send_message("1Bad credentials") {
			return "Error while sending bad credentials 2 !", ""
		}
		return "Bad credentials 2", ""
	}
	credentials_string = credentials_string[..credentials_string_length]
	if credentials_string.len < 2 {
		if user.send_message("1Bad credentials") {
			return "Error while sending bad credentials 3 !", ""
		}
		return "Bad credentials 3", ""
	}
	mode := credentials_string[0].ascii_str()
	credentials_string = credentials_string[1..]
	//getting username length
	username_length := credentials_string[..2].int()
	credentials_string = credentials_string[2..]
	if credentials_string.len < username_length {
		if user.send_message("1Bad credentials") {
			return "Error while sending bad credentials 4 !", ""
		}
		return "Bad credentials 4", ""
	}
	// getting username
	username := credentials_string[..username_length]
	credentials_string = credentials_string[username_length..]
	//getting password
	if credentials_string.len < 64 {
		if user.send_message("1Bad credentials") {
			return "Error while sending bad credentials 6 !", ""
		}
		return "Bad credentials 6", ""
	}
	password := credentials_string[..64]
	if credentials_string.len > 64 {
		println("[LOG] More characters than expected, message : `${credentials_string[64..]}`")
	}
	match mode {
		"l" { return app.login(mut user, username, password) }
		"r" {
			$if private ? {
				if user.send_message("1The server is private ! Cannot create an account !") {
					return "Failed to send \"the server is private ! Cannot create an account !\"", ""
				}
				return "The server is private ! Cannot create an account !", ""
			}
			$else { return app.register(mut user,  username, password) }
		}
		else { return "Else block executed ! This should never happen !", "" }
	}
	return "This should never happen !", ""
}