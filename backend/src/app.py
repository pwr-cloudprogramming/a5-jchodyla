from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  

is_game_running = False
turn = None
winner = None
board = ['', '', '', '', '', '', '', '', '']
players = {'p1': None, 'p2': None}
game_locked = True

@app.route('/players', methods=['GET'])
def get_players():
    return jsonify({'players': players})

@app.route('/send_move', methods=['POST'])
def send_move():
    global board, turn, players, game_locked, is_game_running
    move = request.json.get('move')
    currentPlayer = request.json.get('playerNick')
    
    if currentPlayer == turn and board[move] == '' and not game_locked:
        if currentPlayer == players['p1']:
            board[move] = 'x'
            turn = players['p2']
            check_win()
            return jsonify({'status': 'success'})  
        elif currentPlayer == players['p2']:
            board[move] = 'o'
            turn = players['p1']
            check_win()
            return jsonify({'status': 'success'})  
    else:
        return jsonify({'status': 'error', 'message': 'Invalid move'}) 

@app.route('/end_current_game', methods=['POST'])
def end_game():
    end_running_game()
    return jsonify({'status': 'registered'})  

@app.route('/register', methods=['POST'])
def register_player():
    global players, turn, is_game_running, game_locked

    if players['p1'] == request.json.get('nick') or players['p2'] == request.json.get('nick'):
        return jsonify({'status': 'taken'})
    if not players['p1']:
        players['p1'] = request.json.get('nick')
        is_game_running = True
        return jsonify({'status': 'registered'})  
    elif not players['p2']:
        players['p2'] = request.json.get('nick')
        turn = players['p1']
        game_locked = False
        return jsonify({'status': 'registered'})  
    else:
        return jsonify({'status': 'full'})  

@app.route('/game_running', methods=['GET'])
def is_game_running_route():
    return jsonify({'gameRunning': is_game_running})

def check_win():
    global winner, game_locked, board
    if win_diagonally_top_left_to_bottom_right() or win_diagonally_bottom_left_to_top_right():
        game_locked = True
        winner = board[4]
    else:
        for i in range(3):
            if win_horizontally(i):
                winner = board[i]
                game_locked = True
                break
            if win_vertically(3*i):
                winner = board[3*i]
                game_locked = True
                break
    if '' not in board:
        winner = 'draw'
        game_locked = True

def win_diagonally_top_left_to_bottom_right():
    global board
    return board[0] == board[4] == board[8] and board[0] != ""

def win_diagonally_bottom_left_to_top_right():
    global board
    return board[6] == board[4] == board[2] and board[6] != ""

def win_horizontally(i):
    global board
    return board[i] == board[i+3] == board[i+6] and board[i] != ""


def win_vertically(i):
    global board
    return board[i] == board[i+1] == board[i+2] and board[i] != ""

@app.route('/board', methods=['GET'])
def get_board():
    return jsonify({'board': board})

@app.route('/winner', methods=['GET'])
def get_winner():
    global winner
    winner_nick = None
    if winner == None:
        winner_nick = 'None'
    if winner == 'x':
        winner_nick = players['p1']
    elif winner =='o':
        winner_nick = players['p2']
    elif winner =='draw':
        winner_nick = 'draw'
    return jsonify({'winner': winner_nick})

def end_running_game():
    global board, turn, players, game_locked, is_game_running, winner
    board = ['', '', '', '', '', '', '', '', '']
    players = {'p1': None, 'p2': None}
    turn = None
    winner = None
    game_locked = True
    is_game_running = False

if __name__ == '__main__':
    app.run(port=8080, host="0.0.0.0")


#python3 -m http.server --bind 0.0.0.0 8081
    
