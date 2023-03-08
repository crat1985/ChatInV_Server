module utils

import net
import time
import libsodium

pub struct User {
pub mut:
	conn     net.TcpConn
	username string
	box      libsodium.Box
	ip       string
}

pub fn (mut user User) setup_encryption(private_key libsodium.PrivateKey) ! {
	// sending server's public key
	user.conn.write(private_key.public_key) or {
		return error('[ERROR] Failed to send public key : ${err.msg()}')
	}

	mut public_key := []u8{len: 32}
	// reading client's public key
	user.conn.read(mut public_key) or { return error('[ERROR] Failed to receive public key') }

	// returning a new box
	user.box = libsodium.new_box(private_key, public_key)
}

pub fn (mut app App) disconnected(user &User) {
	app.delete_socket_from_sockets(user)
	if user.username != '' {
		message := Message{
			message: '${user.username} left the chat !'
			author_id: 0
			receiver_id: 0
			timestamp: time.now().unix
		}
		app.broadcast(message, &User{})
	}
}

fn (mut app App) delete_socket_from_sockets(client &User) {
	mut i := -1
	for index, user in app.users {
		if user == client {
			i = index
		}
	}
	if i != -1 {
		app.users.delete(i)
	}
}

pub fn (mut app App) broadcast(message Message, ignore &User) {
	insert_message(message, app.messages_db)
	for mut user in app.users {
		if ignore != user {
			user.send_encrypted_message(message, false, mut app) or { app.disconnected(user) }
		}
	}
	println('[LOG] ${message.message}')
}

pub fn (mut user User) send_encrypted_message(message Message, save_to_db bool, mut app App) !bool {
	if save_to_db {
		insert_message(message, app.messages_db)
	}
	mut text_to_send := ''
	if message.author_id > 0 {
		text_to_send += '${app.get_account_by_id(message.author_id).username}> '
	}
	text_to_send += message.message
	encrypted := user.encrypt_string(text_to_send)
	mut all_data := '${encrypted.len:05}'.bytes()
	all_data << encrypted
	user.conn.write(all_data) or { return error('Error while sending message : ${err}') }
	return true
}

pub fn (mut user User) send_encrypted_message_with_unknown_receiver_id(message string, mut app App) !bool {
	user.send_encrypted_message(Message{
		message: message
		author_id: 0
		receiver_id: -1
		timestamp: time.now().unix
	}, false, mut app) or { return error('Error while sending message') }
	return true
}
