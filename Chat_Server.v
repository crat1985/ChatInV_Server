module main

import net
import utils
import time
import os
import db.sqlite

fn main() {
	mut app := utils.App{
		users: []utils.User{}
		accounts_db: sqlite.DB{}
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
		mut user := &utils.User{socket, ""}
		spawn handle_user(mut user, mut &app)
	}
}

pub fn handle_user(mut user utils.User, mut app utils.App) {
	error, account := app.ask_credentials(mut user)
	if error!="" {
		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => '$error'")
		return
	}

	user.username = account.username

	app.users.insert(app.users.len,  user)

	mut message := utils.Message{
		message: "${account.username} joined the chat !"
		// Going to be added in the future
		// iv: rand.ascii(16).bytes()
		author_id: 0
		receiver_id: 0
	}

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
		}
		app.broadcast(message, &utils.User{})
	}
}