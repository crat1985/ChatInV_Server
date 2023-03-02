module main

import net
import utils
import time
import os
import db.sqlite
import libsodium

fn main() {
	mut app := utils.App{
		users: []utils.User{}
		private_key: libsodium.new_private_key()
		accounts_db: sqlite.DB{}
		messages_db: sqlite.DB{}
		port: '8888'
		server: 0
	}

	app.init_databases() or { panic(err) }

	mut port := os.input('Port (default: 8888) : ')
	if !port.is_blank() {
		app.port = port
	}

	app.server = net.listen_tcp(.ip6, ':${app.port}') or { panic(err) }

	app.server.set_accept_timeout(time.infinite)

	println('[LOG] Server started on port ${app.port}')

	for {
		mut socket := app.server.accept() or {
			eprintln(err)
			continue
		}
		socket.set_read_timeout(time.infinite)
		socket.set_write_timeout(time.infinite)
		mut user := &utils.User{
			ip: socket.peer_ip() or { continue }
		}
		spawn handle_user(mut user, mut &app)
	}
}

fn handle_user(mut user utils.User, mut app utils.App) {
	user.box = user.setup_encryption(app.private_key) or {
		eprintln(err)
		return
	}

	account := app.ask_credentials(mut user) or {
		user.send_encrypted_message_with_unknown_receiver_id('1${err}', mut app) or {}
		eprintln("[LOG] ${user.ip} => '${err}'")
		return
	}

	user.username = account.username

	// getting messages
	mut messages := app.get_messages_by_receiver_id(0)

	if messages.len > 50 {
		messages = messages[messages.len - 50..]
	}

	// sending old messages
	for message in messages {
		user.send_encrypted_message(message, false, mut app) or {
			eprintln('[ERROR] Failed to send message to ${user.username}')
		}
	}

	mut message := utils.Message{
		message: '${account.username} joined the chat !'
		author_id: 0
		receiver_id: 0
		timestamp: time.now().unix
	}

	app.users << user

	app.broadcast(message, &utils.User{})
	for {
		mut datas := []u8{len: 1024}
		mut length := user.read(mut datas) or {
			eprintln('[ERROR] ' + err.str())
			app.disconnected(user)
			break
		}
		datas = datas[..length]
		mut string_data := user.decrypt_string(datas) or { continue }
		length = string_data[..5].int()
		if string_data.len < 6 {
			eprintln('${account.username} sent an invalid message : ${string_data}')
			continue
		}
		string_data = string_data[5..]
		if string_data.len < length {
			eprintln('${account.username} sent an invalid message : ${string_data}')
			continue
		}
		message = utils.Message{
			message: string_data
			author_id: account.id
			receiver_id: 0
			timestamp: time.now().unix
		}
		app.broadcast(message, &utils.User{})
	}
}
