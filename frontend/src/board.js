const hostAddress = 'http://localhost:8080';
let playerNick = null;

function getPlayer() {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', `${hostAddress}/players`, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send();

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                console.error('Fetching players error!');
                return;
            }
            const data = JSON.parse(xhr.responseText);
            const players = data.players;
            if (players.p1 == playerNick || players.p2 == playerNick) {
                if (players.p2 === null) {
                    document.getElementById('player_info').innerHTML = players.p1 + ' - X';
                    document.getElementById('opponent_info').innerHTML = 'Waiting for an opponent...';
                } else if (players.p2 === playerNick) {
                    document.getElementById('opponent_info').innerHTML = players.p1 + ' - X';
                    document.getElementById('player_info').innerHTML = players.p2 + ' - O';
                } else {
                    document.getElementById('player_info').innerHTML = players.p1 + ' - X';
                    document.getElementById('opponent_info').innerHTML = players.p2 + ' - O';
                }
            }
        }
    };
}

function drawGame(board) {
    const cells = document.getElementsByClassName('cell');
    for (let i = 0; i < cells.length; i++) {
        if (board[i] === '') {
            cells[i].setAttribute('onclick', `makeMove(${i})`);
        } else if (board[i] === 'x') {
            cells[i].innerHTML = `<img src='x.png'>`;
        } else if (board[i] === 'o') {
            cells[i].innerHTML = `<img src='o.png'>`;
        }
    }
}

function refreshBoard() {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', `${hostAddress}/board`, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send();

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                console.error('Getting board error!');
                return;
            }
            const data = JSON.parse(xhr.responseText);
            const board = data.board;
            drawGame(board);
        }
    };
}

function makeMove(move) {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', `${hostAddress}/send_move`, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send(JSON.stringify({ move: move, playerNick: playerNick }));

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                console.error('Move error!');
                return;
            }
            refreshBoard();
        }
    };
}

function end() {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', `${hostAddress}/end_current_game`, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send();

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                console.error('Error ending game');
                return;
            }
            endCheck();
        }
    };
}

function checkWin() {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', `${hostAddress}/winner`, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send();

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                console.error('Error getting winner');
                return;
            }
            const data = JSON.parse(xhr.responseText);
            const winner = data.winner;
            if (winner == playerNick) {
                document.getElementById('topInfo').innerHTML = 'You are a winner';
            } else if (winner == 'draw') {
                document.getElementById('topInfo').innerHTML = 'Draw';
            } else if (winner != 'None') {
                document.getElementById('topInfo').innerHTML = 'Game over';
            }
        }
    };
}

function endCheck() {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', `${hostAddress}/game_running`, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send();

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                console.error('Error checking game end');
                return;
            }
            const data = JSON.parse(xhr.responseText);
            const gameRunning = data.gameRunning;
            if (gameRunning == false) {
                window.location = "index.html";
            }
        }
    };
}

function refresh() {
    checkWin();
    getPlayer();
    refreshBoard();
    endCheck();
}

const intervalId = setInterval(refresh, 1000);

const parametr = window.location.search.substring(1);
playerNick = parametr.split('=')[1];
