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
	error, pseudo := app.ask_credentials(mut user)
	if error!="" {
		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => '$error'")
		return
	}

	user.pseudo = pseudo

	app.users.insert(app.users.len,  user)

	app.broadcast("$pseudo joined the chat !", &utils.User{})
	for {
		mut datas := []u8{len: 1024}
		mut length := user.read(mut datas) or {
			eprintln("[ERROR] "+err.str())
			app.disconnected( user)
			break
		}
		datas = datas[0..length]
		mut string_data := datas.bytestr()
		length = string_data[..5].int()
		if string_data.len < 6 {
			eprintln("$pseudo sent an invalid message : $string_data")
			continue
		}
		string_data = string_data[5..]
		if string_data.len < length {
			eprintln("$pseudo sent an invalid message : $string_data")
			continue
		}
		app.broadcast("$pseudo> $string_data", &utils.User{})
	}
}