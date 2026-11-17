'use strict';

const { createServer } = require('node:http');

const host = '127.0.0.1';
const port = Number(process.env.PORT ?? 3000);

const server = createServer((request, response) => {
  if (request.method === 'GET' && request.url === '/') {
    response.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Hello from Kaizen AP 2026!\n');
    return;
  }

  response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
  response.end('Not found\n');
});

server.listen(port, host, () => {
  console.log(`Listening on http://${host}:${server.address().port}`);
});
