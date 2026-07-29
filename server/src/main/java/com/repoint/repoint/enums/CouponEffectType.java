package com.repoint.domain.enums;

import lombok.Getter;

@Getter
public enum CouponEffectType {
    PERCENT_DISCOUNT("percent_discount"),
    FIXED_DISCOUNT("fixed_discount"),
    POINT_BONUS("point_bonus");

    private final String value;

    CouponEffectType(String value) {
        this.value = value;
    }

    public static CouponEffectType fromValue(String value) {
        for (CouponEffectType type : values()) {
            if (type.value.equals(value)) {
                return type;
            }
        }
        throw new IllegalArgumentException("Unknown CouponEffectType value: " + value);
    }
}
