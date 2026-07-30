package com.repoint.domain.enums;

import lombok.Getter;

@Getter
public enum ProductStatus {
    SALE("sale"),
    RESERVED("reserved"),
    SOLD("sold");

    private final String value;

    ProductStatus(String value) {
        this.value = value;
    }

    public static ProductStatus fromValue(String value) {
        for (ProductStatus status : values()) {
            if (status.value.equals(value)) {
                return status;
            }
        }
        throw new IllegalArgumentException("Unknown ProductStatus value: " + value);
    }
}
