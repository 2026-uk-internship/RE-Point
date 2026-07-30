package com.repoint.repoint.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DatabaseController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/db-test")
    public String testDatabase() {
        try {
            String result = jdbcTemplate.queryForObject(
                    "SELECT VERSION()",
                    String.class
            );

            return "MySQL 연결 성공! 버전: " + result;

        } catch (Exception e) {
            return "MySQL 연결 실패: " + e.getMessage();
        }
    }
}