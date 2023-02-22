module main

import net
import os
import libsodium

fn main() {
	private_key := libsodium.new_private_key()

	mut addr := os.input("Address (localhost): ")
	if addr.is_blank() {
		addr = "localhost"
	}
	mut port := os.input("Port (8888): ")
	if port.is_blank() {
		port = "8888"
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

	mut connection := net.dial_tcp("$addr:$port") or {
		panic(err)
	}

	mut public_key := []u8{len: 1024}
	mut length := connection.read(mut public_key) or {
		panic(err)
	}
	public_key = public_key[..length]

	connection.write(private_key.public_key) or {
		panic(err)
	}

	box := libsodium.new_box(private_key, public_key)

	send_encrypted_message(mut connection, "l${pseudo.len:02}$pseudo${password.len:02}$password", box)

	mut data := []u8{len: 1024}
	length = connection.read(mut data) or {
		eprintln(err.msg())
		return
	}

	show_message(decrypt_string(mut data[..length], box) or { panic(err) }, true)
}

fn send_encrypted_message(mut socket &net.TcpConn, data string, box libsodium.Box) {
	socket.write(encrypt_string("${data.len:05}$data", box)) or {
		panic(err)
	}
}

fn encrypt_string(text string, box libsodium.Box) []u8 {
	return box.encrypt_string(text)
}

fn decrypt_string(mut data []u8, box libsodium.Box) !string {
	decrypted := box.decrypt_string(data)
	if decrypted.is_blank() {
		return error("Error while decrypting data")
	}
	return decrypted
}

fn show_message(data string, check0or1 bool) {
	mut msg := data
	if msg.len < 6 {
		eprintln("msg.len < 6")
		return
	}
	mut length := msg[..5].int()
	msg = msg[5..]
	if msg.len < length {
		eprintln("msg.len < length ($length) : $msg")
		return
	}
	if check0or1 {
		match msg[0].ascii_str() {
			'1' {
				msg = msg[1..length]
				eprintln(msg)
				return
			}
			'0' {
				println("Success : ${msg[1..length]}")
				msg = msg[1..]
			}
			else {
				eprintln("Error while receiving server's response, this should never happens.\nReport it to the developer.")
				return
			}
		}
	}

	if !check0or1 {
		println(msg[..length])
	}

	if msg.len <= length {
		return
	}

	show_message(msg[length..], false)
}