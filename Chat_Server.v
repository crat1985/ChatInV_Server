module main

import net
import utils
import time
import os
import db.sqlite
import libsodium

fn main() {
	mut app := &utils.App{
		users: []utils.User{}
		private_key: libsodium.new_private_key()
		accounts_db: sqlite.DB{}
		messages_db: sqlite.DB{}
		port: '8888'
		server: 0
	}

	app.init_databases() or { panic('Error while initializing databases : ${err}') }

	mut port := os.input('Port (default: 8888) : ')
	if !port.is_blank() {
		app.port = port
	}

	app.server = net.listen_tcp(.ip6, ':${app.port}') or {
		panic('Error while listening on port ${app.port} : ${err}')
	}

	app.server.set_accept_timeout(time.infinite)

	println('[LOG] Server started on port ${app.port}')

	for {
		mut socket := app.server.accept() or {
			dump(err)
			continue
		}
		socket.set_read_timeout(time.infinite)
		socket.set_write_timeout(time.infinite)
		mut user := &utils.User{
			conn: socket
			ip: socket.peer_ip() or {
				eprintln('[ERROR] Invalid user IP')
				continue
			}
		}
		spawn handle_user(mut user, mut app)
	}
}

fn handle_user(mut user utils.User, mut app utils.App) {
	user.setup_encryption(app.private_key) or {
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
		mut data := []u8{len: 1024}
		mut length := user.conn.read(mut data) or {
			eprintln('[ERROR] ' + err.str())
			app.disconnected(user)
			break
		}
		data = data[..length]
		message_length := data#[..5].bytestr().int()
		if message_length == 0 {
			eprintln('${account.username} sent an invalid message : ${data}')
			continue
		}
		data = data[5..]
		if data.len < message_length {
			eprintln('${account.username} sent an invalid message : ${data}')
			continue
		}
		mut string_data := user.decrypt_string(data) or {
			eprintln('[ERROR] Cannot decrypt message from ${user.username} !')
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
