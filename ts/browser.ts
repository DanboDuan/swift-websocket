
/// no need to import
const ws = new WebSocket("ws://localhost:8000");
ws.addEventListener('open', (event: MessageEvent) => {
    console.log(`open ${event.data}`);
    ws.send('something');
    setTimeout(() => {
        ws.close();
    }, 10000);
});
ws.addEventListener('close', (event: MessageEvent) => {
    console.log(`close ${event.data}`);
});
ws.addEventListener('message', (event: MessageEvent) => {
    console.log(`message ${event.data}`);
});