module main

import net
import utils
import time
import db.sqlite
import crypto.sha256
import rand
import os

fn main() {
	mut users := []utils.User{}

	db := utils.init_database()

	println("Number of accounts : ${utils.get_number_of_accounts(db)}")

	mut port := os.input("Port (default: 8888) : ")
	if port.is_blank() {
		port = "8888"
	}

	mut server := net.listen_tcp(.ip6, ":$port") or {
		panic(err)
	}

	mut account := utils.Account{
		username: "Guest"
		password: sha256.hexhash("mdr")
		salt: rand.ascii(8)
	}
	println(account.password)
	account.password = sha256.hexhash(account.salt+account.password)
	println(account.password)
	utils.insert_account(db, account)

	server.set_accept_timeout(time.infinite)

	println("Server started at http://localhost:8888/")

	for {
		mut socket := server.accept() or {
			eprintln(err)
			continue
		}
		socket.set_read_timeout(time.infinite)
		socket.set_write_timeout(time.infinite)
		mut user := utils.User{socket, ""}
		spawn handle_user(mut &user, mut &users, db)
	}
}

fn handle_user(mut user &utils.User, mut users []utils.User, db sqlite.DB) {
	error, pseudo, _ := utils.ask_credentials(mut user, db, mut users)
	if error!="" {
		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => '$error'")
		disconnected(mut users, user)
		return
	}

	user.pseudo = pseudo

	users.insert(users.len,  user)

	broadcast(mut users, "$pseudo joined the chat !".bytes(), user)
	for {
		mut datas := []u8{len: 1024}
		length := user.read(mut datas) or {
			eprintln("[ERROR] "+err.str())
			disconnected(mut users, user)
			break
		}
		broadcast(mut users, datas[0..length], &utils.User{})
	}
}

fn disconnected(mut users []utils.User, user &utils.User) {
	delete_socket_from_sockets(mut users, user)
	if user.pseudo != "" {
		broadcast(mut users, "${user.pseudo} left the chat !".bytes(), &utils.User{})
	}
}

fn delete_socket_from_sockets(mut sockets []utils.User, client &utils.User) {
	mut i := -1
	for index, socket in sockets {
		if socket == client {
			i = index
		}
	}
	if i != -1 {
		sockets.delete(i)
	}
}

fn broadcast(mut users []utils.User, data []u8, ignore &utils.User) {
	for mut user in users {
		if ignore!=user {
			user.write_string("${data.bytestr()}\n") or {
				disconnected(mut users, user)
			}
		}
	}
	println("[LOG] ${data.bytestr()}")
}
