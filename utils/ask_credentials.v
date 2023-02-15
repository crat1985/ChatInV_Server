module utils

pub fn (mut app App) ask_credentials(mut user &User) (string, string) {
	mut data := []u8{len: 1024}
	data_length := user.read(mut data) or {
		eprintln(err)
		return "Cannot read credentials", ""
	}
	//removing null bytes
	data = data#[..data_length]
	if data.len == 0 {
		return "Bad credentials 0", ""
	}
	mut credentials_string := data.bytestr()
	//getting mode
	credentials_string_length := credentials_string#[..5].int()
	if credentials_string_length == 0 {
		return "Bad credentials length !", ""
	}
	credentials_string = credentials_string#[5..]
	if credentials_string.len == 0 {
		return "Credentials too short !", ""
	}
	credentials_string = credentials_string#[..credentials_string_length]
	if credentials_string.len <= 1 {
		return "Bad credentials 3 !", ""
	}
	mode := credentials_string[0].ascii_str()
	credentials_string = credentials_string#[1..]
	if credentials_string.len == 0 {
		return "Credentials too short !", ""
	}
	//getting username length
	username_length := credentials_string#[..2].int()
	if username_length == 0 {
		return "Bad username length !", ""
	}
	credentials_string = credentials_string#[2..]
	if credentials_string.len == 0 {
		return "Bad credentials !", ""
	}
	// getting username
	username := credentials_string#[..username_length]
	if username.len == 0 {
		return "Username too short !", ""
	}
	credentials_string = credentials_string#[username_length..]
	if credentials_string.len == 0 {
		return "Credentials too short !", ""
	}
	//getting password
	password := credentials_string#[..64]
	if password.len == 0 {
		return "Password too short !", ""
	}
	if credentials_string.len > 64 {
		eprintln("[LOG] More characters than expected, message : `${credentials_string[64..]}`")
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