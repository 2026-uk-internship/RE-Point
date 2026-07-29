package com.repoint.domain.enums;

import lombok.Getter;

@Getter
public enum TradeStatus {
    REQUESTED("requested"),
    ACCEPTED("accepted"),
    REJECTED("rejected"),
    COMPLETED("completed"),
    CANCELED("canceled");

    private final String value;

    TradeStatus(String value) {
        this.value = value;
    }

    public static TradeStatus fromValue(String value) {
        for (TradeStatus status : values()) {
            if (status.value.equals(value)) {
                return status;
            }
        }
        throw new IllegalArgumentException("Unknown TradeStatus value: " + value);
    }
}
