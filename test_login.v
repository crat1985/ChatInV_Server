module main

import net
import os
import crypto.sha256

fn main() {
	mut addr := os.input("Address (localhost): ")
	if addr.is_blank() {
		addr = "localhost"
	}
	mut port := os.input("Port (8888): ")
	if port.is_blank() {
		port = "8888"
	}

	mut connection := net.dial_tcp("$addr:$port") or {
		panic(err)
	}
	mut pseudo := ""
	for {
		pseudo = os.input("Pseudo : ")
		if pseudo.is_blank() {
			continue
		}
		if pseudo.trim_space().len < 3 {
			println("The pseudo must be at least 3 characters long !")
			continue
		}
		break
	}

	mut password := ""
	for {
		password = os.input_password("Password : ")!
		if password.is_blank() {
			continue
		}
		if password.len < 8 {
			println("The password must be at least 8 characters long !")
			continue
		}
		break
	}

	password = sha256.hexhash(password)

	connection.write_string("l${pseudo.len:02}$pseudo${password.len:02}$password") or {
		panic(err)
	}

	mut data := []u8{len: 1024}
	length := connection.read(mut data) or {
		eprintln(err.msg())
		return
	}
	data = data[..length]

	match data[0].ascii_str() {
		'1' {
			data = data[1..]
			eprintln(data.bytestr())
		}
		'0' {
			data = data[1..]
			println("Success : ${data.bytestr()}")
		}
		else {
			eprintln("Error while receiving server's response, this should never happens.\nReport it to the developer.")
			return
		}
	}
}