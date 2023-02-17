module utils

import net
import time

pub struct User {
	net.TcpConn
	pub mut:
		username string
}



pub fn (mut app App) disconnected(user &User) {
	app.delete_socket_from_sockets(user)
	if user.username != "" {
		message := Message{
			message: "${user.username} left the chat !"
			author_id: 0
			receiver_id: 0
			timestamp: time.now().microsecond
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
		if ignore!=user {
			if user.send_message(message, false, mut app) {
				app.disconnected(user)
			}
		}
	}
	println("[LOG] ${message.message}")
}

pub fn (mut user User) send_message(message Message, save_to_db bool, mut app App) bool {
	if save_to_db {
		insert_message(message, app.messages_db)
	}
	mut text_to_send := ""
	if message.author_id > 0 {
		text_to_send += "${app.get_account_by_id(message.author_id).username}> "
	}
	text_to_send+=message.message
	user.write_string("${text_to_send.len:05}$text_to_send") or {
		return true
	}
	return false
}