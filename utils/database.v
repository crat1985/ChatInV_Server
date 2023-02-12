module utils

import db.sqlite

[table: 'account']
pub struct Account {
	pub mut:
	id int [primary; sql: serial]
	username string [nonnull]
	password string [nonnull]
	salt string [nonnull]
}

pub fn (mut app App) init_database() {
	app.db = sqlite.connect("accounts.db") or {
		panic(err)
	}

	sql app.db {
		create table Account
	}
}

pub fn (mut app App) delete_account(username string) {
	sql app.db {
		delete from Account where username == username
	}
}

pub fn (mut app App) get_number_of_accounts() int {
	return sql app.db {
		select count from Account
	}
}

pub fn (mut app App) get_account_by_pseudo(username string) Account {
	return sql app.db {
		select from Account where username == username limit 1
	}
}

pub fn (mut app App) insert_account(account Account) {
	if app.account_exists(account.username) {
		println("ALREADY EXISTS")
		return
	}
	sql app.db {
		insert account into Account
	}
}

pub fn (mut app App) get_all_accounts() []Account {
	return sql app.db {
		select from Account
	}
}

pub fn (mut app App) account_exists(username string) bool {
	return app.get_account_by_pseudo(username).id != 0
}
