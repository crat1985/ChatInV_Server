module utils

import net

pub struct User {
	net.TcpConn
	pub mut:
		pseudo string
}

pub fn (mut app App) disconnected(user &User) {
	app.delete_socket_from_sockets(user)
	if user.pseudo != "" {
		app.broadcast("${user.pseudo} left the chat !".bytes(), &User{})
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

pub fn (mut app App) broadcast(data []u8, ignore &User) {
	for mut user in app.users {
		if ignore!=user {
			user.write(data) or {
				app.disconnected(user)
			}
		}
	}
	println("[LOG] ${data.bytestr()}")
}
