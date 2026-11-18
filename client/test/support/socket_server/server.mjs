// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// A scriptable socket.io server for the client's SocketClient tests. It
// listens on port 0 with the backend's path and namespace, prints
// `PORT=<n>`, records handshake auth payloads and received events, and is
// driven over HTTP:
//
// - POST /__control with a JSON command:
//   - { "command": "emit", "event", "payload", "room"?, "socketId"? }
//   - { "command": "rejectHandshake", "message" }: rejects the next
//     handshake with that message (repeatable; rejections queue up)
//   - { "command": "disconnect", "socketId"? }: server-side disconnect
//   - { "command": "ack", "event", "responses": [...] }: the next acks of
//     that event, in order; a response `{ "drop": true }` sends none,
//     `{ "delayMs": n, "body": {...} }` sends `body` after n ms
//   - { "command": "reset" }: forgets scripts, records and rejections
// - GET /__handshakes: the recorded `handshake.auth` payloads
// - GET /__events: the recorded `{ socketId, event, payload }` events
// - GET /__sockets: the ids of the connected sockets
//
// The path prefix comes from the SOCKET_PATH_PREFIX environment variable.

import { createServer } from "node:http";
import { Server } from "socket.io";

const pathPrefix = process.env.SOCKET_PATH_PREFIX ?? "";
const clientEvents = [
    "join-group",
    "leave-group",
    "playback",
    "queue",
    "ready",
    "track:playback-failed",
    "lt-ping",
];

let handshakes = [];
let events = [];
let rejections = [];
let ackScripts = new Map();

function readJson(request) {
    return new Promise((resolve, reject) => {
        let body = "";
        request.on("data", (chunk) => {
            body += chunk;
        });
        request.on("end", () => {
            try {
                resolve(body ? JSON.parse(body) : {});
            } catch (error) {
                reject(error);
            }
        });
        request.on("error", reject);
    });
}

function sendJson(response, status, body) {
    response.writeHead(status, { "content-type": "application/json" });
    response.end(JSON.stringify(body));
}

function defaultAck(event) {
    return event === "lt-ping" ? { serverTime: Date.now() } : { ok: true };
}

function respond(event, ack) {
    if (typeof ack !== "function") return;
    const script = ackScripts.get(event);
    const response = script?.shift();
    if (response === undefined) {
        ack(defaultAck(event));
        return;
    }
    if (response.drop) return;
    if (typeof response.delayMs === "number") {
        setTimeout(
            () => ack(response.body ?? defaultAck(event)),
            response.delayMs,
        );
        return;
    }
    ack(response);
}

const httpServer = createServer();
const io = new Server(httpServer, {
    path: `${pathPrefix}/socket.io/listen-together`,
    transports: ["websocket"],
});
const namespace = io.of("/listen-together");

namespace.use((socket, next) => {
    const auth = socket.handshake.auth ?? {};
    handshakes.push(auth);
    const rejection = rejections.shift();
    if (rejection !== undefined) return next(new Error(rejection));
    if (!auth.token === !auth.apiKey) {
        return next(new Error("Authentication required"));
    }
    next();
});

namespace.on("connection", (socket) => {
    for (const event of clientEvents) {
        socket.on(event, (...args) => {
            const ack =
                typeof args[args.length - 1] === "function"
                    ? args.pop()
                    : undefined;
            const payload = args.length > 0 ? args[0] : null;
            events.push({ socketId: socket.id, event, payload });
            if (event === "join-group" && payload?.groupId) {
                socket.join(payload.groupId);
            }
            if (event === "leave-group") {
                for (const room of socket.rooms) {
                    if (room !== socket.id) socket.leave(room);
                }
            }
            respond(event, ack);
        });
    }
});

async function control(command) {
    switch (command.command) {
        case "emit": {
            if (command.socketId) {
                namespace.sockets
                    .get(command.socketId)
                    ?.emit(command.event, command.payload);
            } else if (command.room) {
                namespace.to(command.room).emit(command.event, command.payload);
            } else {
                namespace.emit(command.event, command.payload);
            }
            return {};
        }
        case "rejectHandshake":
            rejections.push(command.message);
            return {};
        case "disconnect": {
            for (const [id, socket] of namespace.sockets) {
                if (!command.socketId || command.socketId === id) {
                    socket.disconnect(true);
                }
            }
            return {};
        }
        case "ack":
            ackScripts.set(command.event, [...command.responses]);
            return {};
        case "reset":
            handshakes = [];
            events = [];
            rejections = [];
            ackScripts = new Map();
            return {};
        default:
            throw new Error(`Unknown command: ${command.command}`);
    }
}

httpServer.on("request", async (request, response) => {
    if (!request.url?.startsWith("/__")) return;
    try {
        if (request.method === "POST" && request.url === "/__control") {
            sendJson(response, 200, await control(await readJson(request)));
        } else if (request.url === "/__handshakes") {
            sendJson(response, 200, handshakes);
        } else if (request.url === "/__events") {
            sendJson(response, 200, events);
        } else if (request.url === "/__sockets") {
            sendJson(response, 200, [...namespace.sockets.keys()]);
        } else {
            sendJson(response, 404, { error: "Not found" });
        }
    } catch (error) {
        sendJson(response, 400, { error: String(error) });
    }
});

httpServer.listen(0, "127.0.0.1", () => {
    process.stdout.write(`PORT=${httpServer.address().port}\n`);
});
