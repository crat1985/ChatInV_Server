module main

import net
import utils
import time
import os
import db.sqlite

fn main() {
	mut app := utils.App{
		users: []utils.User{}
		db: sqlite.DB{}
		port: "8888"
		server: 0
	}

	app.init_database()

	mut port := os.input("Port (default: 8888) : ")
	if !port.is_blank() {
		app.port = port
	}

	app.server = net.listen_tcp(.ip6, ":${app.port}") or {
		panic(err)
	}

	app.server.set_accept_timeout(time.infinite)

	println("Server started at http://localhost:${app.port}/")

	for {
		mut socket := app.server.accept() or {
			eprintln(err)
			continue
		}
		socket.set_read_timeout(time.infinite)
		socket.set_write_timeout(time.infinite)
		mut user := utils.User{socket, ""}
		spawn handle_user(mut &user, mut &app)
	}
}

pub fn handle_user(mut user utils.User, mut app utils.App) {
	error, pseudo := app.ask_credentials(mut user)
	if error!="" {
		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => '$error'")
		return
	}

	user.pseudo = pseudo

	app.users.insert(app.users.len,  user)

	app.broadcast("$pseudo joined the chat !".bytes(), &utils.User{})
	for {
		mut datas := []u8{len: 1024}
		length := user.read(mut datas) or {
			eprintln("[ERROR] "+err.str())
			app.disconnected( user)
			break
		}
		datas = datas[0..length]
		mut string_datas := datas.bytestr()
		string_datas = string_datas.trim_space()
		if string_datas.is_blank() { continue }
		app.broadcast("$pseudo> $string_datas".bytes(), &utils.User{})
	}
}