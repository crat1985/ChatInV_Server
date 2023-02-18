module main

import net
import utils
import time
import os
import db.sqlite
import libsodium
import rand

fn main() {
	mut app := utils.App{
		users: []utils.User{}
		private_key: libsodium.new_private_key()
		accounts_db: sqlite.DB{}
		messages_db: sqlite.DB{}
		port: "8888"
		server: 0
	}

	app.init_databases()

	mut port := os.input("Port (default: 8888) : ")
	if !port.is_blank() {
		app.port = port
	}

	app.server = net.listen_tcp(.ip6, ":${app.port}") or {
		panic(err)
	}

	app.server.set_accept_timeout(time.infinite)

	println("Server started on port ${app.port}")

	for {
		mut socket := app.server.accept() or {
			eprintln(err)
			continue
		}
		socket.set_read_timeout(time.infinite)
		socket.set_write_timeout(time.infinite)
		mut user := &utils.User{
			username: ''
			box: libsodium.Box{}
			session_key: []
			sock: socket.sock
		}
		spawn handle_user(mut user, mut &app)
	}
}


pub fn handle_user(mut user utils.User, mut app &utils.App) {
	user.write(app.private_key.public_key) or {
		eprintln("[ERROR] Failed to send public key")
		return
	}
	mut public_key := []u8{len: 32}
	user.read(mut public_key) or {
		eprintln("[ERROR] Failed to receive public key")
		return
	}
	user.box = libsodium.new_box(app.private_key, public_key)

	user.session_key = rand.ascii(32).bytes()

	user.write(user.box.encrypt(user.session_key)) or {
		eprintln("[ERROR] Failed to send session key")
		return
	}

	println(user.session_key.bytestr())

	if true {
		return
	}

	error, account := app.ask_credentials(mut user)
	if error!="" {
		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => '$error'")
		return
	}

	user.username = account.username

	mut messages := app.get_messages_by_receiver_id(0)

	if messages.len > 50 {
		messages = messages[messages.len-50..]
	}

	for message in messages {
		user.send_message(message, false, mut app)
	}

	mut message := utils.Message{
		message: "${account.username} joined the chat !"
		// Going to be added in the future
		// iv: rand.ascii(16).bytes()
		author_id: 0
		receiver_id: 0
		timestamp: time.now().microsecond
	}

	app.users << user

	app.broadcast(message, &utils.User{})
	for {
		mut datas := []u8{len: 1024}
		mut length := user.read(mut datas) or {
			eprintln("[ERROR] "+err.str())
			app.disconnected(user)
			break
		}
		datas = datas[0..length]
		mut string_data := datas.bytestr()
		length = string_data[..5].int()
		if string_data.len < 6 {
			eprintln("${account.username} sent an invalid message : $string_data")
			continue
		}
		string_data = string_data[5..]
		if string_data.len < length {
			eprintln("${account.username} sent an invalid message : $string_data")
			continue
		}
		message = utils.Message{
			message: string_data
			author_id: account.id
			receiver_id: 0
			timestamp: time.now().microsecond
		}
		app.broadcast(message, &utils.User{})
	}
}