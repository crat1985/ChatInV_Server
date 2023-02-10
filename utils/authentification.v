module utils

import db.sqlite
import crypto.sha256

pub fn ask_credentials(mut user &User, db sqlite.DB) (string, string, string) {
	for {
		mut data := []u8{len: 1024}
		user.write_string("Pseudo : ") or {
			return "Error while asking pseudo : $err", "", ""
		}
		mut lenght := user.read(mut data) or {
			return "Error while reading pseudo : $err", "", ""
		}
		mut pseudo := data[0..lenght].bytestr()
		user.write_string("Password : ") or {
			return "Error while asking password : $err", "", ""
		}
		data = []u8{len: 1024}
		lenght = user.read(mut data) or {
			return "Error while reading password : $err", "", ""
		}
		mut password_hash := data[0..lenght].bytestr()

		account := get_account_by_pseudo(db, pseudo)
		if sha256.hexhash(account.salt+password_hash) == account.password {
			return "", pseudo, password_hash
		}
		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => 'Wrong password !'")
		user.write_string("Wrong password !\n") or {
			return "Error while sending 'Wrong password' to ${user.peer_ip() or {"IPERROR"}}", "", ""
		}
	}

	return "This could never happens !", "", ""

}

pub fn ask_credentials_new_way(mut user &User, db sqlite.DB) (string, string, string) {
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