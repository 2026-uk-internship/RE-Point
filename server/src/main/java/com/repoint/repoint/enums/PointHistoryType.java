package com.repoint.domain.enums;

import lombok.Getter;

@Getter
public enum PointHistoryType {
    EARN_SALE("earn_sale"),
    SPEND_PURCHASE("spend_purchase"),
    CHARGE("charge"),
    AUCTION_WIN("auction_win");

    private final String value;

    PointHistoryType(String value) {
        this.value = value;
    }

    public static PointHistoryType fromValue(String value) {
        for (PointHistoryType type : values()) {
            if (type.value.equals(value)) {
                return type;
            }
        }
        throw new IllegalArgumentException("Unknown PointHistoryType value: " + value);
    }
}
