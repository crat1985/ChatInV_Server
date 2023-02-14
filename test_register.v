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

	send_message(mut connection, "r${pseudo.len:02}$pseudo$password")

	mut data := []u8{len: 1024}
	length := connection.read(mut data) or {
		eprintln(err.msg())
		return
	}

	show_message(data[..length].bytestr(), true)
}

fn send_message(mut socket &net.TcpConn, data string) {
	socket.write_string("${data.len:05}$data") or {
		panic(err)
	}
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

	if msg.len == length {
		return
	}

	show_message(msg[length..], false)
}