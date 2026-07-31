// src/app.js
const express = require("express");
const cors = require("cors");
require("dotenv").config();

const authRoutes = require("./routes/authRoutes");
const categoryRoutes = require("./routes/categoryRoutes");
const reportRoutes = require("./routes/reportRoutes");

const app = express();

app.use(express.json());
app.use(cors());

app.use("/auth", authRoutes);
app.use("/category", categoryRoutes);
app.use("/report", reportRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
