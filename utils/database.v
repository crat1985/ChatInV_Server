module utils

import db.sqlite

[table: 'account']
pub struct Account {
	pub mut:
	id int [primary; sql: serial]
	username string [nonnull]
	password string [nonnull]
	salt string [nonnull]
	created int [nonnull]
}

[table: 'message']
pub struct Message {
	pub mut:
	id int [primary; sql: serial]
	message string [nonnull]
	// Going to be added in the future
	// iv []u8 [nonnull]
	author_id int [nonnull]
	receiver_id int [nonnull]
	timestamp int [nonnull]
}

pub fn insert_message(message Message, db sqlite.DB) {
	sql db {
		insert message into Message
	}
}

pub fn (mut app App) get_messages_by_author_id(author_id int) []Message {
	return sql app.messages_db {
		select from Message where author_id == author_id
	}
}

pub fn (mut app App) get_messages_by_receiver_id(receiver_id int) []Message {
	return sql app.messages_db {
		select from Message where receiver_id == receiver_id
	}
}

pub fn (mut app App) get_all_messages() []Message {
	return sql app.messages_db {
		select from Message
	}
}

pub fn (mut app App) get_message_by_id(id int) Message {
	return sql app.messages_db {
		select from Message where id == id limit 1
	}
}

pub fn (mut app App) init_databases() {
	app.accounts_db = sqlite.connect("accounts.db") or {
		panic(err)
	}
	app.messages_db = sqlite.connect("messages.db") or {
		panic(err)
	}

	sql app.accounts_db {
		create table Account
	}

	sql app.messages_db {
		create table Message
	}
}

pub fn (mut app App) delete_account(username string) {
	sql app.accounts_db {
		delete from Account where username == username
	}
}

pub fn (mut app App) get_number_of_accounts() int {
	return sql app.accounts_db {
		select count from Account
	}
}

pub fn (mut app App) get_account_by_pseudo(username string) Account {
	return sql app.accounts_db {
		select from Account where username == username limit 1
	}
}

pub fn (mut app App) get_account_by_id(id int) Account {
	return sql app.accounts_db {
		select from Account where id == id limit 1
	}
}

pub fn (mut app App) insert_account(account Account) {
	if app.account_exists(account.username) {
		println("ALREADY EXISTS")
		return
	}
	sql app.accounts_db {
		insert account into Account
	}
}

pub fn (mut app App) get_all_accounts() []Account {
	return sql app.accounts_db {
		select from Account
	}
}

pub fn (mut app App) account_exists(username string) bool {
	return app.get_account_by_pseudo(username).id != 0
}
