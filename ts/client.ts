import WebSocket from 'ws';
import Timer = NodeJS.Timer;

const ws = new WebSocket("ws://127.0.0.1:8000");
let timer: Timer;
let counter = 0;
ws.on('open', () => {
  console.log('open');
  ws.send('something');
  ws.send(JSON.stringify({ 'yyy': "xxx" }));
  timer = setInterval(() => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      const value = Math.sin(counter++ * 0.1);
      const data = {
        timestamp: Date.now(),
        value
      };
      console.log(`send someting`)
      ws.send(JSON.stringify(data))
    } else {
      clearInterval(timer);
    }
  }, 5000);
});

ws.on('message', (data) => {
  console.log('received: %s', data);
});
ws.on('ping',()=> {
  console.log('ping');
})
ws.on('pong', ()=> {
  console.log('pong');
})


