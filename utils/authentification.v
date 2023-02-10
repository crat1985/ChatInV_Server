module utils

import db.sqlite
import crypto.sha256

pub fn ask_credentials(mut user &User, db sqlite.DB) (string, string, string) {
	for {
		mut credentials := []u8{len: 1024}
		length := user.read(mut credentials) or {
			eprintln(err)
			return "Cannot read credentials", "", ""
		}
		credentials = credentials[0..length]
		pseudo_length := credentials[0..2].bytestr().int()
		credentials = credentials[2..]
		pseudo := credentials[0..pseudo_length].bytestr()
		println("Pseudo : $pseudo len: $pseudo_length")
		credentials = credentials[pseudo_length..]
		password_length := credentials[0..2].bytestr().int()
		println("Password len : $password_length")
		credentials = credentials[2..]
		password := credentials[..password_length].bytestr()

		account := get_account_by_pseudo(db, pseudo)

		if sha256.hexhash(account.salt+password) == account.password {
			user.write_string("0Welcome $pseudo") or {
				return "Error while sending welcome\n", "", ""
			}
			return "", pseudo, password
		}

		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => 'Wrong password !'")
		user.write_string("1Wrong password !\n") or {
			return "Error while sending 'Wrong password' to ${user.peer_ip() or {"IPERROR"}}", "", ""
		}
	}
	return "This should never append !", "", ""
}