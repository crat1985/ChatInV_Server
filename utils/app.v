module utils

import net
import db.sqlite
import time

pub struct App {
	pub mut:
	users []User
	accounts_db sqlite.DB
	messages_db sqlite.DB
	port string
	server &net.TcpListener
}

pub fn (mut app App) handle_user(mut user User) {
	error, account := app.ask_credentials(mut user)
	if error!="" {
		println("[LOG] ${user.peer_ip() or {"IPERROR"}} => '$error'")
		return
	}

	user.username = account.username

	app.users << user

	mut messages := app.get_messages_by_receiver_id(0)

	if messages.len > 50 {
		messages = messages[messages.len-51..]
	}

	for message in messages {
		user.send_message(message, false, mut app)
	}

	mut message := utils.Message{
		message: "${account.username} joined the chat !"
		// Going to be added in the future
		// iv: rand.ascii(16).bytes()
		author_id: 0
		receiver_id: 0
		timestamp: time.now().microsecond
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
			timestamp: time.now().microsecond
		}
		app.broadcast(message, &utils.User{})
	}
}