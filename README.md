# Kaizen AP 2026

A minimal Node.js HTTP server built with the standard library.

## Run locally

With Node.js and npm installed, run the following from the repository root. The project has no dependencies to install.

```sh
npm start
```

Open [http://127.0.0.1:3000](http://127.0.0.1:3000) to see the greeting. To use a different port, run `PORT=8080 npm start`.

The server entry point is `index.js`. It returns the greeting for `GET /` and a 404 for other requests.
