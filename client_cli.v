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
	mut pseudo := ""
	for {
		pseudo = os.input("Pseudo :")
		if pseudo.is_blank() {
			continue
		}
		if pseudo.trim_space().len < 3 {
			println("The pseudo must be at least 3 characters long !")
			continue
		}
	}

	mut password := ""
	for {
		password = os.input("Password :")
		if password.is_blank() {
			continue
		}
		if password.len < 8 {
			println("The password must be at least 8 characters long !")
			continue
		}
	}

	password = sha256.hexhash(password)

	connection := net.dial_tcp("$addr:$port") or {
		panic(err)
	}


}

fn listen_for_messages(connection &net.TcpConn) {
	for {

	}
}