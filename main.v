module main

import ui
import net
import readline
import time

[heap]
struct State {
mut:
	connection &net.TcpConn
	input      string
	output     string
}

fn main() {
	remote := readline.read_line('remote host address and port: ')!

	mut app := &State{
		connection: net.dial_tcp(remote) or { panic("couldn't establish connection to ${remote}") }
		input: ''
		output: ''
	}
	app.connection.set_read_timeout(time.infinite)

	spawn app.update_output()

	ui.run(ui.window(
		width: 400
		height: 600
		title: 'TCP-Client'
		children: [
			ui.column(
				margin: ui.Margin{10, 10, 10, 10}
				spacing: 5
				children: [
					ui.textbox(
						is_multiline: true
						height: 100
						text: &app.input
					),
					ui.button(
						text: 'Send'
						on_click: fn [mut app] (_ &ui.Button) {
							app.send()
						}
					),
					ui.textbox(
						read_only: true
						is_multiline: true
						height: 445
						text: &app.output
					),
				]
			),
		]
	))
}

fn (mut app State) update_output() {
	mut buffer := []u8{len: 1024 * 1024 * 10}

	for {
		app.connection.wait_for_read() or {
			elog('wait_for_read(): failed')
			continue
		}
		strlen := app.connection.read(mut buffer) or {
			elog('read(): failed')
			continue
		}
		app.output = buffer[..strlen].bytestr() + '\n' + app.output
	}
}

fn (mut app State) send() {
	app.connection.write(app.input.bytes()) or { elog('write(): failed') }
	log('packet sent')
}

fn log(text string) {
	println('[${time.now()}] [info]: ${text}')
}

fn elog(text string) {
	eprintln('[${time.now()}] [error]: ${text}')
}
