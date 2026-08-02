// src/app.js
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
require("dotenv").config({ path: ".env.local" });

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: "*" }, // 개발 단계는 전체 허용, 배포 시엔 실제 도메인으로 제한
});

app.use(express.json());
app.use(cors());

const authRoutes = require("./routes/authRoutes");
const productRoutes = require("./routes/productRoutes");
const categoryRoutes = require("./routes/categoryRoutes");
const reportRoutes = require("./routes/reportRoutes");

app.use("/auth", authRoutes);
app.use("/category", categoryRoutes);
app.use("/report", reportRoutes);
app.use("/products", productRoutes);

require("./sockets/chatSocket")(io);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
