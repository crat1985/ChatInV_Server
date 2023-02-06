module utils

import net
import db.sqlite

pub fn ask_credentials(mut socket &net.TcpConn, db sqlite.DB) (string, string, string) {
	for {
		mut data := []u8{len: 1024}
		socket.write_string("Pseudo : ") or {
			return "Error while asking pseudo : $err", "", ""
		}
		lenght := socket.read(mut data) or {
			return "Error while reading pseudo : $err", "", ""
		}
		mut pseudo := data[0..lenght].bytestr()
		socket.write_string("Password : ") or {
			return "Error while asking password : $err", "", ""
		}
		data = []u8{len: 1024}
		socket.read(mut data) or {
			return "Error while reading password : $err", "", ""
		}
		mut password := data[0..lenght].bytestr()
		if pseudo.len < 8 || password.len < 8 {
			println("[LOG] ${socket.addr()!} => 'Pseudo or password too short !'")
			socket.write_string("Pseudo or password too short !") or {
				return "Error while writing too short error : $err", "", ""
			}
			continue
		}

		account := get_account_by_pseudo(db, pseudo)
		if password == account.password {
			return "", pseudo, password
		}

		println("[LOG] ${socket.addr()!} => 'Wrong password !'")
		socket.write_string("Wrong password !\n")
	}

}
