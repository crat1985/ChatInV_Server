module main

import net
import utils
import time
import db.sqlite

fn main() {
	mut sockets := []net.TcpConn{}

	db := utils.init_database()

	println("Number of accounts : ${utils.get_number_of_accounts(db)}")

	mut server := net.listen_tcp(.ip6, ":8888") or {
		panic(err)
	}

	server.set_accept_timeout(time.infinite)

	println("Server started at http://localhost:8888/")

	for {
		mut socket := server.accept() or {
			eprintln(err)
			continue
		}
		socket.set_read_timeout(time.hour)
		socket.set_write_timeout(time.minute)
		spawn handle_user(mut socket, mut &sockets, db)
	}
}

fn handle_user(mut socket &net.TcpConn, mut sockets []net.TcpConn, db sqlite.DB) {
	error, pseudo, password := utils.ask_credentials(mut socket, db)
	if error!="" {
		socket.write_string(error) or {
			delete_socket_from_sockets(mut sockets, socket)
			return
		}
		handle_user(socket, sockets, db)
		return
	}

	sockets.insert(sockets.len,  socket)

	socket.write_string("Welcome $pseudo !\n") or {
		eprintln(err)
		delete_socket_from_sockets(mut sockets, socket)
		return
	}
	println("[LOG] $pseudo logged in with password '$password'")
	for {
		mut datas := []u8{len: 1024}
		length := socket.read(mut datas) or {
			eprintln("[ERROR] "+err.str())
			delete_socket_from_sockets(mut sockets, socket)
			//sockets = sockets.filter( it!=client )
			break
		}
		broadcast(mut sockets, datas[0..length], socket)
	}
}

fn delete_socket_from_sockets(mut sockets []net.TcpConn, client &net.TcpConn) {
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

fn broadcast(mut sockets []net.TcpConn, datas []u8, ignore &net.TcpConn) {
	for mut socket in sockets {
		if ignore!=socket {
			socket.write_string("${datas.bytestr()}\n") or {
				delete_socket_from_sockets(mut sockets, socket)
			}
		}
	}
	println("[LOG] New message : ${datas.bytestr()}")
}
