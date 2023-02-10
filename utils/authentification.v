module utils

import db.sqlite

pub fn ask_credentials(mut user &User, db sqlite.DB) (string, string, string) {
	for {
		mut credentials := []u8{len: 1024}
		length := user.read(mut credentials) or {
			eprintln(err)
			return "Cannot read credentials", "", ""
		}
		credentials = credentials[0..length]
		mut index := -1
		for i, element in credentials {
			if element == 2 {
				index = i
				break
			}
		}
		if index == -1 {
			user.write_string("Bad credentials !") or {
				return "Socket disconnected !", "", ""
			}
			continue
		}
		pseudo := credentials[..index]
		password := credentials[index+1..]

		account := get_account_by_pseudo(db, pseudo.bytestr())

		if password.bytestr() == account.password {
			return "", pseudo.bytestr(), password.bytestr()
		}

		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => 'Wrong password !'")
		user.write_string("Wrong password !\n") or {
			return "Error while sending 'Wrong password' to ${user.peer_ip() or {"IPERROR"}}", "", ""
		}
	}
	return "This should never append !", "", ""
}