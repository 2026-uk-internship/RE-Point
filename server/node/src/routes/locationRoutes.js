const express = require("express");
const router = express.Router();
const locationController = require("../controllers/locationController");

router.get("/", locationController.getLocations); // GET /locations

module.exports = router;
