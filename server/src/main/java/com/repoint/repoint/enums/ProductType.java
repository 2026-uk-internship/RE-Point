package com.repoint.domain.enums;

import lombok.Getter;

@Getter
public enum ProductType {
    GENERAL("general"),
    POINT("point"),
    AUCTION("auction");

    private final String value;

    ProductType(String value) {
        this.value = value;
    }

    public static ProductType fromValue(String value) {
        for (ProductType type : values()) {
            if (type.value.equals(value)) {
                return type;
            }
        }
        throw new IllegalArgumentException("Unknown ProductType value: " + value);
    }
}
