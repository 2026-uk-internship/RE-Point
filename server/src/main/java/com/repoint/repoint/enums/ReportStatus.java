package com.repoint.domain.enums;

import lombok.Getter;

@Getter
public enum ReportStatus {
    IN_PROGRESS("in_progress"),
    END("end");

    private final String value;

    ReportStatus(String value) {
        this.value = value;
    }

    public static ReportStatus fromValue(String value) {
        for (ReportStatus status : values()) {
            if (status.value.equals(value)) {
                return status;
            }
        }
        throw new IllegalArgumentException("Unknown ReportStatus value: " + value);
    }
}
