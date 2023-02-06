module utils

import net

pub fn ask_credentials(mut socket &net.TcpConn) (string, string, string) {
	mut data := []u8{len: 1024}
	mut error := ""
	socket.write_string("Pseudo : ") or {
		error = "Error while asking pseudo : $err"
		eprintln(error)
		return error, "", ""
	}
	lenght := socket.read(mut data) or {
		error = "Error while reading pseudo : $err"
		eprintln(error)
		return error, "", ""
	}
	mut pseudo := data[0..lenght].bytestr()
	/*for element in data {
		if element != 0 {
			pseudo += element.ascii_str()
		} else {
			break
		}
	}*/
	println("Pseudo : $pseudo")
	socket.write_string("Password : ") or {
		error = "Error while asking password : $err"
		eprintln(error)
		return error, "", ""
	}
	data = []u8{len: 1024}
	socket.read(mut data) or {
 		error = "Error while reading password : $err"
		eprintln(error)
		return error, "", ""
	}
	mut password := data[0..lenght].bytestr()
	println("Password length : ${password.len}")
	if pseudo.len < 8 || password.len < 8 {
		return "Too short !\n", "", ""
	}
	return "", pseudo, password
}
