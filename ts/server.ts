import WebSocket from 'ws';
import { Server as HttpServer } from 'http'
import Timer = NodeJS.Timer;

const server = new HttpServer();
const port = 8000;
const wss = new WebSocket.Server({ server });

let timer: Timer;
wss.on('connection', (ws: WebSocket) => {
    let counter = 0;
    console.log(`connect ${ws.readyState}`);
    ws.on('message', (data) => {
        console.log('received: %s', data);
    });
    ws.on('close', () => {
        console.log('close');
    })
    ws.on('ping',()=> {
        console.log('ping');
        // ws.pong()
    })
    ws.on('pong', ()=> {
        console.log('pong');
    })
    timer = setInterval(() => {
        if (ws && ws.readyState === WebSocket.OPEN) {
            const value = Math.sin(counter++ * 0.1);
            const data = {
                timestamp: Date.now(),
                value
            };
            console.log(`send someting ${JSON.stringify(data)}`)
            ws.send(JSON.stringify(data))
        } else {
            clearInterval(timer);
        }
    }, 5000);
});

server.listen(port, () => {
    const address = server.address()
    console.log(`listening on port ${port} address ${JSON.stringify(address)}`)
})