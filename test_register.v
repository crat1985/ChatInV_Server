module main

import net
import os
import libsodium

struct App {
mut:
	private_key libsodium.PrivateKey
	addr string
	port string
	pseudo string
	password string
	connection net.TcpConn
	box libsodium.Box
}

fn main() {
	mut app := App{
		private_key: libsodium.new_private_key()
		addr: "localhost"
		port: "8888"
		pseudo: ""
		password: ""
		connection: net.TcpConn{}
		box: libsodium.Box{}
	}

	app.addr = os.input("Address (localhost): ")
	if app.addr.is_blank() {
		app.addr = "localhost"
	}
	app.port = os.input("Port (8888): ")
	if app.port.is_blank() {
		app.port = "8888"
	}

	for {
		app.pseudo = os.input("Pseudo : ")
		if app.pseudo.is_blank() {
			continue
		}
		if app.pseudo.trim_space().len < 3 {
			println("The pseudo must be at least 3 characters long !")
			continue
		}
		break
	}

	for {
		app.password = os.input_password("Password : ")!
		if app.password.is_blank() {
			continue
		}
		if app.password.len < 8 {
			println("The password must be at least 8 characters long !")
			continue
		}
		break
	}

	app.connection = net.dial_tcp("${app.addr}:${app.port}") or {
		panic(err)
	}

	mut public_key := []u8{len: 1024}
	mut length := connection.read(mut public_key) or {
		panic(err)
	}
	public_key = public_key[..length]

	app.connection.write(private_key.public_key) or {
		panic(err)
	}

	app.box = libsodium.new_box(app.private_key, public_key)

	app.send_encrypted_message(mut connection, "r${pseudo.len:02}$pseudo${password.len:02}$password", app.box)

	mut data := []u8{len: 1024}
	length = connection.read(mut data) or {
		eprintln(err.msg())
		return
	}

	show_message(app.decrypt_string(data[..length]) or { panic(err) }, true)
}

fn (mut app App) send_encrypted_message(mut socket &net.TcpConn, data string) {
	socket.write(encrypt_string("${data.len:05}$data", box)) or {
		panic(err)
	}
}

fn (mut app App) encrypt_string(text string) []u8 {
	return box.encrypt_string(text)
}

fn (mut app App) decrypt_string(data []u8) !string {
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