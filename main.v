module main

import net
import utils
import time

fn main() {
	mut sockets := []net.TcpConn{}

	db := utils.init_database()

	//nb_account := utils.get_number_of_accounts(db)

	//println("Number of accounts : $nb_account")
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
		spawn handle_user(mut socket, mut &sockets)
	}
}

fn handle_user(mut socket &net.TcpConn, mut sockets []net.TcpConn) {
	error, pseudo, password := utils.ask_credentials(mut socket)
	if error!="" {
		socket.write_string(error) or {}
		delete_socket_from_sockets(mut sockets, socket)
		return
	}

	println("Pseudo : $pseudo")
	println("Password : $password")

	sockets.insert(sockets.len,  socket)

	socket.write_string("Welcome !\n") or {
		eprintln(err)
		delete_socket_from_sockets(mut sockets, socket)
		return
	}
	mut datas := []u8{len: 1024}
	for {
		socket.read(mut datas) or {
			eprintln("[ERROR] "+err.str())
			delete_socket_from_sockets(mut sockets, socket)
			//sockets = sockets.filter( it!=client )
			break
		}
		broadcast(mut sockets, datas, socket)
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
	println(" ${datas.bytestr()}")
}
