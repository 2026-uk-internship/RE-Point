package com.repoint.domain.enums;

import lombok.Getter;

@Getter
public enum ReportType {
    USER("user"),
    CHAT("chat"),
    PRODUCT("product");

    private final String value;

    ReportType(String value) {
        this.value = value;
    }

    public static ReportType fromValue(String value) {
        for (ReportType type : values()) {
            if (type.value.equals(value)) {
                return type;
            }
        }
        throw new IllegalArgumentException("Unknown ReportType value: " + value);
    }
}
