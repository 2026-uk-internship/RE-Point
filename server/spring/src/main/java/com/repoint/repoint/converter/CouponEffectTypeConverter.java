package com.repoint.domain.converter;

import com.repoint.domain.enums.CouponEffectType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class CouponEffectTypeConverter implements AttributeConverter<CouponEffectType, String> {
    @Override
    public String convertToDatabaseColumn(CouponEffectType attribute) {
        return attribute == null ? null : attribute.getValue();
    }

    @Override
    public CouponEffectType convertToEntityAttribute(String dbData) {
        return dbData == null ? null : CouponEffectType.fromValue(dbData);
    }
}
