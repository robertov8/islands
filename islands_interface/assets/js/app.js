// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import '../css/app.css';

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import socket from "./socket"
//
import 'phoenix_html';
import { Socket } from 'phoenix';

window.app = {
  socket: () => window._socket,
  channel: () => window._channel,
  start: (player_name = 'player1', channel_name = 'moon') => {
    window._socket = app.new_socket();
    window._channel = app.new_channel(player_name, player_name);
    app.join(app.channel());
    // say_hello(game_channel, 'Hello, world!');
    // new_game(window.game_channel);
  },
  new_socket: (params = {}) => {
    const socket = new Socket('/socket', {});

    socket.connect();

    return socket;
  },
  new_channel: (subtopic, screen_name) => {
    return app.socket().channel('game:' + subtopic, { screen_name: screen_name });
  },
  join: () => {
    app
      .channel()
      .join()
      .receive('ok', response => console.log('Joined successfully!', response))
      .receive('error', response => console.log('Unable to join', response));
  },
  leave: channel => {
    app
      .channel()
      .leave()
      .receive('ok', response => {
        console.log('Left successfully', response);
      })
      .receive('error', response => {
        console.log('Unable to leave', response);
      });
  },
  say_hello: greeting => {
    app
      .channel()
      .push('hello', { message: greeting })
      .receive('ok', response => {
        console.log('Hello', response.message);
      })
      .receive('error', response => {
        console.log('Unable to say hello to the channel.', response.message);
      });
  },
  new_game: () => {
    app
      .channel()
      .push('new_game')
      .receive('ok', response => {
        console.log('New game created!', response);
      })
      .receive('error', response => {
        console.log('Unable to start a new game.', response);
      });
  },
  add_player: player => {
    app
      .channel()
      .push('add_player', player)
      .receive('error', response => {
        console.log('Unable to add new player', response);
      });
  }
};

// function new_socket(params = {}) {
//   const socket = new Socket('/socket', {});

//   socket.connect();

//   return socket;
// }

// function new_channel(socket, subtopic, screen_name) {
//   return socket.channel('game:' + subtopic, { screen_name: screen_name });
// }

// function join(channel) {
//   channel
//     .join()
//     .receive('ok', response => console.log('Joined successfully!', response))
//     .receive('error', response => console.log('Unable to join', response));
// }

// function leave(channel) {
//   channel
//     .leave()
//     .receive('ok', response => {
//       console.log('Left successfully', response);
//     })
//     .receive('error', response => {
//       console.log('Unable to leave', response);
//     });
// }

// function say_hello(channel, greeting) {
//   channel
//     .push('hello', { message: greeting })
//     .receive('ok', response => {
//       console.log('Hello', response.message);
//     })
//     .receive('error', response => {
//       console.log('Unable to say hello to the channel.', response.message);
//     });
// }

// function new_game(channel) {
//   channel
//     .push('new_game')
//     .receive('ok', response => {
//       console.log('New game created!', response);
//     })
//     .receive('error', response => {
//       console.log('Unable to start a new game.', response);
//     });
// }

// function add_player(channel, player) {
//   channel.push('add_player', player).receive('error', response => {
//     console.log('Unable to add new player', response);
//   });
// }

// function _start(player_name = 'player1', channel_name = 'moon') {
//   window.socket = new_socket();
//   window.game_channel = new_channel(window.socket, player_name, player_name);
//   join(window.game_channel);
//   // say_hello(game_channel, 'Hello, world!');
//   // new_game(window.game_channel);
// }

// window.Socket = Socket;
// window.new_socket = new_socket;
// window.new_channel = new_channel;
// window.join = join;
// window.leave = leave;
// window.say_hello = say_hello;
// window.new_game = new_game;
// window._start = _start;
// window.add_player = add_player;
