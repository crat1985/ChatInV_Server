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
		mut user := &utils.User{socket, ""}
		spawn app.handle_user(mut user)
	}
}
