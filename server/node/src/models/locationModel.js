// src/models/locationModel.js
const pool = require("../config/db");

exports.getAllLocations = async () => {
  const [rows] = await pool.query(
    `SELECT id, city FROM location ORDER BY id ASC`,
  );
  return rows;
};
