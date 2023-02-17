module utils

import net
import db.sqlite

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
			if user.send_message(message, true, app.messages_db) {
				app.disconnected(user)
			}
		}
	}
	println("[LOG] ${message.message}")
}

pub fn (mut user User) send_message(message Message, is_broadcast bool, db sqlite.DB) bool {
	if !is_broadcast {
		insert_message(message, db)
	}
	user.write_string("${message.message.len:05}${message.message}") or {
		return true
	}
	return false
}